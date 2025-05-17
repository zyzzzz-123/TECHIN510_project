from app.core.config import settings
from app.services.openai_service import chat_with_openai
from app.services.gemini_service import chat_with_gemini
import logging

logger = logging.getLogger(__name__)

def chat_with_ai(messages, model_provider=None, system_prompt=None):
    """
    与AI模型聊天的统一接口
    
    Args:
        messages: 消息列表
        model_provider: 模型提供商，可选"openai"或"gemini"，默认使用settings中的配置
        system_prompt: 可选的系统提示，将会添加到消息列表开头
    
    Returns:
        AI生成的回复
    """
    # 如果未指定提供商，使用设置中的可用模型
    if not model_provider:
        try:
            model_provider = settings.get_available_ai_model()
            logger.info(f"Using AI model: {model_provider}")
        except ValueError as e:
            logger.error(f"No AI model available: {e}")
            raise
    
    # 检查指定的提供商是否可用
    if model_provider == "openai" and not settings.is_openai_available():
        logger.warning("OpenAI API key not set, trying Gemini")
        if settings.is_gemini_available():
            model_provider = "gemini"
        else:
            raise ValueError("OpenAI API key not set and no alternative available")
    elif model_provider == "gemini" and not settings.is_gemini_available():
        logger.warning("Gemini API key not set, trying OpenAI")
        if settings.is_openai_available():
            model_provider = "openai"
        else:
            raise ValueError("Gemini API key not set and no alternative available")
    
    # 准备消息列表，可能添加系统提示
    processed_messages = messages.copy()
    
    # 如果提供了系统提示且第一条消息不是系统提示
    if system_prompt and (not messages or messages[0].get("role") != "system"):
        processed_messages.insert(0, {"role": "system", "content": system_prompt})
    
    # 根据提供商选择相应的API
    if model_provider == "openai":
        return chat_with_openai(processed_messages)
    elif model_provider == "gemini":
        return chat_with_gemini(processed_messages)
    else:
        raise ValueError(f"Unsupported model provider: {model_provider}")

def get_goal_assistant_system_prompt():
    """
    获取目标助手的系统提示
    """
    return (
        "You are a helpful goal planning assistant. "
        "When the user wants to add, update, or delete a todo/task, always reply with a JSON object in the following format: "
        "{\"action\": \"add_task|update_task|delete_task\", \"task\": { ... }, \"confirmation_prompt\": \"...\"}. "
        "The confirmation_prompt should be a clear question for the user to confirm or cancel the action. "
        "If the user replies '确认' (confirm), the action will be executed. If '取消' (cancel), do nothing. "
        "If the user's message is not a task operation, reply as usual. "
        "Remember the full conversation history until the user confirms or cancels an action."
    ) 