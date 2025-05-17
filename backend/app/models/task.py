from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, func
from app.db.base import Base

class Task(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    text = Column(String, nullable=False)
    due_date = Column(DateTime, nullable=True)
    status = Column(String, default="todo")  # todo, done, etc.
    type = Column(String, default="todo")  # todo, long_term, ...
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    start_date = Column(DateTime, nullable=True)
    end_date = Column(DateTime, nullable=True)
