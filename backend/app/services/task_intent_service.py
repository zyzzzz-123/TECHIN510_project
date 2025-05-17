from datetime import datetime, timedelta
import json
import logging
from typing import Dict, List, Optional, Any, Union

from app.services.ai_service import chat_with_ai
from app.models.task import Task
from app.db.session import get_db
from sqlalchemy.orm import Session
from sqlalchemy.sql.expression import and_, or_
from sqlalchemy import desc

logger = logging.getLogger(__name__)

class TaskIntentType:
    """任务意图类型常量"""
    QUERY = "query_task"
    CREATE = "add_task"
    UPDATE = "update_task"
    DELETE = "delete_task"
    NONE = "none"

class TaskIntent:
    """任务意图数据类"""
    
    def __init__(self, intent_type: str, task_data: Dict[str, Any], confirmation_prompt: Optional[str] = None):
        self.intent_type = intent_type
        self.task_data = task_data
        self.confirmation_prompt = confirmation_prompt or "确认执行此操作？"
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典"""
        return {
            "action": self.intent_type,
            "task": self.task_data,
            "confirmation_prompt": self.confirmation_prompt
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'TaskIntent':
        """从字典构建任务意图"""
        return cls(
            intent_type=data.get("action", TaskIntentType.NONE),
            task_data=data.get("task", {}),
            confirmation_prompt=data.get("confirmation_prompt")
        )
    
    @property
    def is_empty(self) -> bool:
        """是否为空意图"""
        return self.intent_type == TaskIntentType.NONE or not self.task_data
    
    @property
    def is_query(self) -> bool:
        """是否为查询意图"""
        return self.intent_type == TaskIntentType.QUERY
    
    @property
    def is_create(self) -> bool:
        """是否为创建意图"""
        return self.intent_type == TaskIntentType.CREATE
    
    @property
    def is_update(self) -> bool:
        """是否为更新意图"""
        return self.intent_type == TaskIntentType.UPDATE
    
    @property
    def is_delete(self) -> bool:
        """是否为删除意图"""
        return self.intent_type == TaskIntentType.DELETE

def parse_user_request(user_message: str, model_provider: Optional[str] = None) -> TaskIntent:
    """
    解析用户请求，提取任务意图
    
    Args:
        user_message: 用户消息
        model_provider: AI模型提供商
        
    Returns:
        TaskIntent对象
    """
    system_prompt = """你是一个任务管理助手。
如果用户想要添加、更新或删除任务，请以JSON对象形式回应，格式如下：
{"action": "add_task|update_task|delete_task|query_task", "task": { 任务属性 }, "confirmation_prompt": "..."}

对于add_task: 包含text(必需)、due_date(ISO格式，可选)、type(todo/goal，可选)
对于update_task: 包含id(必需)，以及text、due_date、status、type中的任意属性
对于delete_task: 包含id(必需)
对于query_task: 包含过滤条件，如status(todo/done/all)、type(todo/goal/all)、date_filter(today/this_week/this_month/all)

confirmation_prompt应清晰描述操作。
如果不是任务操作请求，请直接回复普通文本。"""
    
    try:
        # 调用AI服务解析用户意图
        response = chat_with_ai(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message}
            ],
            model_provider=model_provider
        )
        
        # 尝试解析为JSON
        try:
            data = json.loads(response)
            if isinstance(data, dict) and "action" in data:
                logger.info(f"Successfully parsed task intent: {data['action']}")
                return TaskIntent.from_dict(data)
        except json.JSONDecodeError:
            # 不是JSON，表示不是任务操作
            logger.debug("Response is not a valid JSON, not a task operation")
            pass
        except Exception as e:
            logger.error(f"Error parsing task intent: {e}")
            
        # 未能解析出任务意图，返回空意图
        return TaskIntent(TaskIntentType.NONE, {})
    except Exception as e:
        logger.error(f"Error processing user request: {e}")
        return TaskIntent(TaskIntentType.NONE, {})

def parse_query_intent(query_text: str, model_provider: Optional[str] = None) -> Dict[str, Any]:
    """
    解析查询意图，提取查询参数
    
    Args:
        query_text: 查询文本
        model_provider: AI模型提供商
        
    Returns:
        查询参数字典
    """
    system_prompt = """解析以下查询并返回包含查询参数的JSON。
返回的JSON应包含以下字段：
- status: todo/done/all
- type: todo/goal/all
- date_filter: today/this_week/this_month/all
- sort_by: due_date/created_at
- sort_order: asc/desc"""
    
    try:
        # 调用AI服务解析查询参数
        response = chat_with_ai(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"查询: {query_text}"}
            ],
            model_provider=model_provider
        )
        
        # 尝试解析为JSON
        try:
            data = json.loads(response)
            if isinstance(data, dict):
                logger.info("Successfully parsed query parameters")
                return data
        except json.JSONDecodeError:
            logger.warning(f"Failed to parse query parameters: {response}")
            
        # 默认查询参数
        return {
            "status": "all",
            "type": "all",
            "date_filter": "all",
            "sort_by": "due_date",
            "sort_order": "asc"
        }
    except Exception as e:
        logger.error(f"Error parsing query intent: {e}")
        return {
            "status": "all",
            "type": "all",
            "date_filter": "all",
            "sort_by": "due_date",
            "sort_order": "asc"
        }

def get_tasks_by_query(user_id: int, query_params: Dict[str, Any], db: Session) -> List[Task]:
    """
    根据查询参数获取任务
    
    Args:
        user_id: 用户ID
        query_params: 查询参数
        db: 数据库会话
        
    Returns:
        任务列表
    """
    try:
        query = db.query(Task).filter(Task.user_id == user_id)
        
        # 状态过滤
        status = query_params.get("status")
        if status and status != "all":
            query = query.filter(Task.status == status)
        
        # 类型过滤
        task_type = query_params.get("type")
        if task_type and task_type != "all":
            query = query.filter(Task.type == task_type)
        
        # 日期过滤
        date_filter = query_params.get("date_filter")
        if date_filter and date_filter != "all":
            today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
            
            if date_filter == "today":
                tomorrow = today + timedelta(days=1)
                query = query.filter(and_(
                    Task.due_date >= today,
                    Task.due_date < tomorrow
                ))
            elif date_filter == "this_week":
                start_of_week = today - timedelta(days=today.weekday())
                end_of_week = start_of_week + timedelta(days=7)
                query = query.filter(and_(
                    Task.due_date >= start_of_week,
                    Task.due_date < end_of_week
                ))
            elif date_filter == "this_month":
                start_of_month = today.replace(day=1)
                if today.month == 12:
                    next_month = today.replace(year=today.year + 1, month=1, day=1)
                else:
                    next_month = today.replace(month=today.month + 1, day=1)
                query = query.filter(and_(
                    Task.due_date >= start_of_month,
                    Task.due_date < next_month
                ))
        
        # 排序
        sort_by = query_params.get("sort_by", "due_date")
        sort_order = query_params.get("sort_order", "asc")
        
        if sort_by == "due_date":
            if sort_order == "desc":
                query = query.order_by(desc(Task.due_date))
            else:
                query = query.order_by(Task.due_date)
        elif sort_by == "created_at":
            if sort_order == "desc":
                query = query.order_by(desc(Task.created_at))
            else:
                query = query.order_by(Task.created_at)
        
        return query.all()
    except Exception as e:
        logger.error(f"Error fetching tasks by query: {e}")
        # 发生错误时，返回空列表
        return [] 