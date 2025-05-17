from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import List, Dict, Any, Optional
from pydantic import BaseModel
from datetime import datetime, timedelta

from app.db.session import get_db
from app.services.chat_message_service import ChatMessageService
from app.models.user import User
from app.utils.auth import get_current_active_user

router = APIRouter(prefix="/chat-history", tags=["chat history"])

class ChatMessageResponse(BaseModel):
    id: int
    role: str
    content: str
    created_at: datetime
    model_provider: Optional[str] = None
    
    class Config:
        orm_mode = True

class GroupedChatResponse(BaseModel):
    date: str
    messages: List[ChatMessageResponse]

@router.get("/", response_model=List[GroupedChatResponse])
def get_chat_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
    days: int = Query(7, description="获取最近几天的聊天记录"),
    limit: int = Query(200, description="每次获取的最大消息数量"),
):
    """
    获取当前用户的聊天历史记录，按日期分组
    """
    # 计算开始日期
    start_date = datetime.utcnow() - timedelta(days=days)
    
    # 获取消息
    messages = ChatMessageService.get_messages_by_user(
        db=db,
        user_id=current_user.id,
        limit=limit,
        start_date=start_date
    )
    
    # 按日期分组
    grouped_messages = ChatMessageService.group_messages_by_date(messages)
    
    # 构建响应
    result = []
    for date, msgs in grouped_messages.items():
        result.append(GroupedChatResponse(
            date=date,
            messages=[ChatMessageResponse.from_orm(msg) for msg in msgs]
        ))
    
    # 按日期排序
    result.sort(key=lambda x: x.date, reverse=True)
    
    return result

@router.delete("/{message_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_message(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    删除单条聊天消息
    """
    success = ChatMessageService.delete_message(db, message_id, current_user.id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found or not owned by current user"
        )

@router.delete("/", status_code=status.HTTP_204_NO_CONTENT)
def clear_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """
    清空当前用户的所有聊天记录
    """
    ChatMessageService.clear_user_history(db, current_user.id) 