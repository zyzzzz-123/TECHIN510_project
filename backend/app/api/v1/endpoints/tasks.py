from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.task import Task
from app.schemas.task import TaskResponse, TaskCreate, TaskUpdate
from typing import List

router = APIRouter(prefix="/api/tasks", tags=["tasks"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
def create_task(task: TaskCreate, db: Session = Depends(get_db)):
    new_task = Task(user_id=task.user_id, text=task.text, due_date=task.due_date, type=task.type or "todo")
    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    return new_task

@router.patch("/{task_id}", response_model=TaskResponse)
def update_task_status(task_id: int, update: TaskUpdate, db: Session = Depends(get_db)):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    if update.status is not None:
        task.status = update.status
    if update.text is not None:
        task.text = update.text
    if update.due_date is not None:
        task.due_date = update.due_date
    if update.type is not None:
        task.type = update.type
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
