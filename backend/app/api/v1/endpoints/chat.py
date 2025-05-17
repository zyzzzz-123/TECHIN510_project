from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel
from typing import List, Optional, Dict, Any, Union
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.services.ai_service import chat_with_ai, get_goal_assistant_system_prompt
from app.services.task_intent_service import parse_user_request
from app.services.chat_message_service import ChatMessageService
from app.utils.logger import logger
from app.models.user import User
from app.utils.auth import get_current_user
import json

router = APIRouter(prefix="/chat", tags=["chat"])

class ChatRequest(BaseModel):
    message: Optional[str] = None
    messages: Optional[List[Dict[str, str]]] = None
    model_provider: Optional[str] = None  # 可选参数，指定模型提供商
    analyze_task_intent: bool = False  # 是否分析任务意图
    use_history: bool = True  # 是否使用历史记录作为上下文

class ChatResponse(BaseModel):
    response: str
    task_intent: Optional[Dict[str, Any]] = None  # 任务意图结果

@router.post("/", response_model=ChatResponse)
def chat(
    request: ChatRequest, 
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user)
):
    try:
        # 处理消息输入
        if request.messages:
            messages = request.messages
            user_message = messages[-1]["content"] if messages and messages[-1]["role"] == "user" else None
        elif request.message:
            user_message = request.message
            messages = [{"role": "user", "content": user_message}]
        else:
            raise HTTPException(status_code=400, detail="No message(s) provided.")
        
        # 获取系统提示
        system_prompt = get_goal_assistant_system_prompt()
        
        # 如果用户已登录且启用了历史记录
        context_messages = []
        if current_user and request.use_history:
            # 获取历史消息作为上下文
            context_messages = ChatMessageService.get_messages_for_context(
                db=db, 
                user_id=current_user.id,
                max_messages=20  # 最多使用20条历史消息
            )
            
            # 将新消息添加到上下文中
            if not request.messages:  # 只有单条消息时才需要手动添加
                context_messages.append({"role": "user", "content": user_message})
                
            messages = context_messages if request.messages is None else messages
        
        # 分析任务意图（如果需要）
        task_intent = None
        if request.analyze_task_intent and current_user and user_message:
            intent_result = parse_user_request(user_message, request.model_provider)
            if not intent_result.is_empty:
                # 找到任务意图，返回
                task_intent = intent_result.to_dict()
                
                # 如果客户端请求分析任务意图，且找到了有效意图，则不再调用聊天API
                # 直接返回意图结果作为响应
                response_text = intent_result.confirmation_prompt
                
                # 保存用户消息和系统回复
                if current_user:
                    ChatMessageService.create_message(
                        db=db,
                        user_id=current_user.id,
                        role="user",
                        content=user_message,
                        model_provider=request.model_provider
                    )
                    ChatMessageService.create_message(
                        db=db,
                        user_id=current_user.id,
                        role="assistant",
                        content=response_text,
                        model_provider=request.model_provider
                    )
                
                return ChatResponse(
                    response=response_text,
                    task_intent=task_intent
                )
            
        # 没有找到任务意图或不需要分析，调用AI服务
        ai_response = chat_with_ai(
            messages=messages, 
            model_provider=request.model_provider,
            system_prompt=system_prompt
        )
        
        # 保存用户消息和AI回复
        if current_user:
            # 只保存最新的用户消息和AI回复，不保存整个历史
            if user_message:
                ChatMessageService.create_message(
                    db=db,
                    user_id=current_user.id,
                    role="user",
                    content=user_message,
                    model_provider=request.model_provider
                )
            
            ChatMessageService.create_message(
                db=db,
                user_id=current_user.id,
                role="assistant",
                content=ai_response,
                model_provider=request.model_provider
            )
        
        # 检查AI返回的是否可能是任务操作（向后兼容）
        if request.analyze_task_intent and current_user:
            try:
                data = json.loads(ai_response)
                if isinstance(data, dict) and "action" in data and "confirmation_prompt" in data:
                    task_intent = data
            except:
                pass
        
        return ChatResponse(response=ai_response, task_intent=task_intent)
    except Exception as e:
        logger.error(f"[Chat Endpoint Error] {e}")
        raise HTTPException(status_code=500, detail=str(e)) 