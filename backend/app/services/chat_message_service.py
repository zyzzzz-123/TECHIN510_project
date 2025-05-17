from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from app.models.chat_message import ChatMessage
from datetime import datetime, timedelta

class ChatMessageService:
    @staticmethod
    def create_message(
        db: Session, 
        user_id: int, 
        role: str, 
        content: str,
        model_provider: Optional[str] = None
    ) -> ChatMessage:
        """
        创建并保存新的聊天消息
        """
        message = ChatMessage(
            user_id=user_id,
            role=role,
            content=content,
            model_provider=model_provider
        )
        db.add(message)
        db.commit()
        db.refresh(message)
        return message
    
    @staticmethod
    def get_messages_by_user(
        db: Session, 
        user_id: int, 
        limit: int = 100,
        skip: int = 0,
        start_date: Optional[datetime] = None
    ) -> List[ChatMessage]:
        """
        获取用户的聊天历史记录
        """
        query = db.query(ChatMessage).filter(ChatMessage.user_id == user_id)
        
        if start_date:
            query = query.filter(ChatMessage.created_at >= start_date)
            
        return query.order_by(ChatMessage.created_at).offset(skip).limit(limit).all()
    
    @staticmethod
    def get_messages_for_context(
        db: Session, 
        user_id: int, 
        max_messages: int = 20,
        hours_limit: int = 24
    ) -> List[Dict[str, Any]]:
        """
        获取供AI上下文使用的最近消息
        """
        time_threshold = datetime.utcnow() - timedelta(hours=hours_limit)
        messages = db.query(ChatMessage).filter(
            ChatMessage.user_id == user_id,
            ChatMessage.created_at >= time_threshold
        ).order_by(ChatMessage.created_at.desc()).limit(max_messages).all()
        
        # 反转排序，使最旧的消息先出现
        messages.reverse()
        
        # 转换为AI可用的格式
        return [
            {"role": msg.role, "content": msg.content}
            for msg in messages
        ]
    
    @staticmethod
    def group_messages_by_date(messages: List[ChatMessage]) -> Dict[str, List[ChatMessage]]:
        """
        将消息按日期分组
        """
        grouped_messages = {}
        
        for message in messages:
            date_key = message.created_at.strftime("%Y-%m-%d")
            if date_key not in grouped_messages:
                grouped_messages[date_key] = []
            grouped_messages[date_key].append(message)
            
        return grouped_messages
    
    @staticmethod
    def delete_message(db: Session, message_id: int, user_id: int) -> bool:
        """
        删除单条消息
        """
        message = db.query(ChatMessage).filter(
            ChatMessage.id == message_id,
            ChatMessage.user_id == user_id
        ).first()
        
        if not message:
            return False
            
        db.delete(message)
        db.commit()
        return True
    
    @staticmethod
    def clear_user_history(db: Session, user_id: int) -> int:
        """
        清空用户所有聊天记录，返回删除的记录数
        """
        result = db.query(ChatMessage).filter(ChatMessage.user_id == user_id).delete()
        db.commit()
        return result 