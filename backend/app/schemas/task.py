from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class TaskCreate(BaseModel):
    user_id: int
    text: str
    due_date: Optional[datetime] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    type: Optional[str] = "todo"

class TaskUpdate(BaseModel):
    status: Optional[str] = None
    text: Optional[str] = None
    due_date: Optional[datetime] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    type: Optional[str] = None

class TaskResponse(BaseModel):
    id: int
    user_id: int
    text: str
    due_date: Optional[datetime]
    start_date: Optional[datetime]
    end_date: Optional[datetime]
    status: str
    type: str
    created_at: Optional[datetime]
    updated_at: Optional[datetime]

    class Config:
        orm_mode = True
