from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.task import Task
from app.schemas.task import TaskResponse, TaskCreate, TaskUpdate
from typing import List, Dict, Any, Optional
from app.services.task_intent_service import parse_user_request, parse_query_intent, get_tasks_by_query, TaskIntent
import json
from datetime import datetime
from app.utils.logger import logger
from app.models.user import User
from app.utils.auth import get_current_active_user
from pydantic import BaseModel

router = APIRouter(prefix="/api/tasks", tags=["tasks"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
def create_task(task: TaskCreate, db: Session = Depends(get_db)):
    print(f"[create_task] start_date={task.start_date}, end_date={task.end_date}")
    # Validation based on type
    if task.type == "ddl" and not task.due_date:
        raise HTTPException(status_code=422, detail="DDL task requires due_date.")
    if task.type == "event" and (not task.start_date or not task.end_date):
        raise HTTPException(status_code=422, detail="Event task requires start_date and end_date.")
    new_task = Task(
        user_id=task.user_id,
        text=task.text,
        due_date=task.due_date,
        start_date=task.start_date,
        end_date=task.end_date,
        type=task.type or "todo"
    )
    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    return new_task

@router.patch("/{task_id}", response_model=TaskResponse)
def update_task_status(task_id: int, update: TaskUpdate, db: Session = Depends(get_db)):
    print(f"[update_task_status] start_date={update.start_date}, end_date={update.end_date}")
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if update.status is not None:
        task.status = update.status
    if update.text is not None:
        task.text = update.text
    if update.due_date is not None:
        task.due_date = update.due_date
    if update.start_date is not None:
        task.start_date = update.start_date
    if update.end_date is not None:
        task.end_date = update.end_date
    if update.type is not None:
        task.type = update.type
    # Validation based on type after update
    if task.type == "ddl" and not task.due_date:
        raise HTTPException(status_code=422, detail="DDL task requires due_date.")
    if task.type == "event" and (not task.start_date or not task.end_date):
        raise HTTPException(status_code=422, detail="Event task requires start_date and end_date.")
    db.commit()
    db.refresh(task)
    return task

@router.get("/user/{user_id}", response_model=List[TaskResponse])
def get_user_tasks(user_id: int, db: Session = Depends(get_db), status: str = None):
    query = db.query(Task).filter(Task.user_id == user_id)
    if status:
        query = query.filter(Task.status == status)
    tasks = query.order_by(Task.due_date).all()
    return tasks

@router.delete("/{task_id}", status_code=204)
def delete_task(task_id: int, db: Session = Depends(get_db)):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    db.delete(task)
    db.commit()
    return Response(status_code=204)

# 添加这些Pydantic模型来约束请求结构
class TaskIntentRequest(BaseModel):
    message: str
    model_provider: Optional[str] = None

class ExecuteIntentRequest(BaseModel):
    intent: Dict[str, Any]

# 修改analyze_task_intent端点
@router.post("/intent")
def analyze_task_intent(
    request: TaskIntentRequest,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_active_user)
):
    """
    分析用户消息中的任务意图
    """
    try:
        if not current_user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication required for this operation"
            )
            
        # 解析用户消息中的任务意图
        task_intent = parse_user_request(request.message, request.model_provider)
        
        # 如果是查询意图，直接执行查询
        if task_intent.is_query:
            # 解析查询参数
            query_params = parse_query_intent(request.message, request.model_provider)
            # 执行查询
            tasks = get_tasks_by_query(current_user.id, query_params, db)
            # 转换为dict
            tasks_data = [
                {
                    "id": task.id,
                    "text": task.text,
                    "status": task.status,
                    "type": task.type,
                    "due_date": task.due_date.isoformat() if task.due_date else None,
                    "created_at": task.created_at.isoformat() if task.created_at else None
                }
                for task in tasks
            ]
            
            # 返回查询结果和任务意图
            return {
                "intent": task_intent.to_dict(),
                "tasks": tasks_data
            }
            
        # 其他任务意图，需要客户端确认后再执行
        return {
            "intent": task_intent.to_dict()
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error analyzing task intent: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# 修改execute_task_intent端点
@router.post("/execute_intent")
def execute_task_intent(
    request: ExecuteIntentRequest,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_active_user)
):
    """
    执行任务意图
    """
    try:
        if not current_user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication required for this operation"
            )
            
        # 解析任务意图
        task_intent = TaskIntent.from_dict(request.intent)
        
        # 如果是空意图，返回错误
        if task_intent.is_empty:
            raise HTTPException(status_code=400, detail="Invalid intent")
        
        # 执行相应的操作
        result = {"success": True, "message": "操作成功"}
        
        if task_intent.is_create:
            # 创建任务
            task_data = task_intent.task_data
            task = Task(
                user_id=current_user.id,
                text=task_data.get("text", "新任务"),
                status="todo",
                type=task_data.get("type", "todo")
            )
            
            # 设置截止日期
            due_date_str = task_data.get("due_date")
            if due_date_str:
                try:
                    task.due_date = datetime.fromisoformat(due_date_str.replace("Z", "+00:00"))
                except ValueError:
                    logger.warning(f"Invalid due_date format: {due_date_str}")
            
            db.add(task)
            db.commit()
            db.refresh(task)
            
            result["task"] = {
                "id": task.id,
                "text": task.text,
                "status": task.status,
                "type": task.type,
                "due_date": task.due_date.isoformat() if task.due_date else None
            }
            result["message"] = f"已创建任务: {task.text}"
            
        elif task_intent.is_update:
            # 更新任务
            task_data = task_intent.task_data
            task_id = task_data.get("id")
            
            if not task_id:
                raise HTTPException(status_code=400, detail="No task ID provided")
            
            # 查找任务
            task = db.query(Task).filter(Task.id == task_id, Task.user_id == current_user.id).first()
            if not task:
                raise HTTPException(status_code=404, detail=f"Task {task_id} not found")
            
            # 更新任务属性
            if "text" in task_data:
                task.text = task_data["text"]
            
            if "type" in task_data:
                task.type = task_data["type"]
            
            if "status" in task_data:
                task.status = task_data["status"]
            
            if "due_date" in task_data:
                due_date_str = task_data["due_date"]
                if due_date_str:
                    try:
                        task.due_date = datetime.fromisoformat(due_date_str.replace("Z", "+00:00"))
                    except ValueError:
                        logger.warning(f"Invalid due_date format: {due_date_str}")
                else:
                    task.due_date = None
            
            db.commit()
            db.refresh(task)
            
            result["task"] = {
                "id": task.id,
                "text": task.text,
                "status": task.status,
                "type": task.type,
                "due_date": task.due_date.isoformat() if task.due_date else None
            }
            result["message"] = f"已更新任务ID: {task.id}"
            
        elif task_intent.is_delete:
            # 删除任务
            task_data = task_intent.task_data
            task_id = task_data.get("id")
            
            if not task_id:
                raise HTTPException(status_code=400, detail="No task ID provided")
            
            # 查找任务
            task = db.query(Task).filter(Task.id == task_id, Task.user_id == current_user.id).first()
            if not task:
                raise HTTPException(status_code=404, detail=f"Task {task_id} not found")
            
            # 删除任务
            task_text = task.text
            db.delete(task)
            db.commit()
            
            result["message"] = f"已删除任务ID: {task_id} ({task_text})"
        
        return result
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error executing task intent: {e}")
        raise HTTPException(status_code=500, detail=str(e))
