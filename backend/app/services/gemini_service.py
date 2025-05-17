import requests
import json
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)

def chat_with_gemini(messages, model="gemini-1.5-flash"):
    """
    使用Google Gemini API进行聊天
    
    Args:
        messages: 消息列表，每条消息应包含'role'和'content'
        model: Gemini模型名称
    
    Returns:
        生成的文本响应
    """
    if not settings.GEMINI_API_KEY:
        err_msg = "Gemini API Key is not set. Please set GEMINI_API_KEY environment variable."
        logger.error(err_msg)
        raise ValueError(err_msg)
        
    try:
        # 构建Gemini API请求格式
        gemini_contents = []
        
        for msg in messages:
            # 处理系统消息 - Gemini不直接支持系统消息，将其转换为模型消息
            if msg["role"] == "system":
                role = "model"
            else:
                role = "user" if msg["role"] == "user" else "model"
                
            gemini_contents.append({
                "role": role,
                "parts": [{"text": msg["content"]}]
            })
        
        # 记录请求信息
        logger.info(f"Sending request to Gemini API using model: {model}")
        logger.debug(f"Request contents (first 100 chars): {str(gemini_contents)[:100]}...")
        
        # 创建请求体
        request_body = {
            "contents": gemini_contents,
            "generationConfig": {
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1024,
            }
        }
        
        # 发送请求到Gemini API
        api_endpoint = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
        response = requests.post(
            f"{api_endpoint}?key={settings.GEMINI_API_KEY}",
            headers={"Content-Type": "application/json"},
            json=request_body,
            timeout=30  # 设置超时时间为30秒
        )
        
        if response.status_code == 200:
            data = response.json()
            
            # 解析Gemini响应
            if (data.get('candidates') and 
                data['candidates'][0].get('content') and 
                data['candidates'][0]['content'].get('parts')):
                
                result = data['candidates'][0]['content']['parts'][0]['text']
                logger.info(f"Received response from Gemini API (first 100 chars): {result[:100]}...")
                return result
            else:
                error_msg = "Unexpected Gemini API response format"
                logger.error(f"{error_msg}: {data}")
                raise Exception(error_msg)
        else:
            error_msg = f"Gemini API error: {response.status_code}"
            logger.error(f"{error_msg} - {response.text}")
            raise Exception(f"{error_msg} - {response.text}")
    except requests.exceptions.Timeout:
        error_msg = "Gemini API request timed out"
        logger.error(error_msg)
        raise Exception(error_msg)
    except requests.exceptions.RequestException as e:
        error_msg = f"Network error when calling Gemini API: {str(e)}"
        logger.error(error_msg)
        raise Exception(error_msg)
    except Exception as e:
        error_msg = f"Failed to get Gemini response: {str(e)}"
        logger.error(error_msg)
        raise Exception(error_msg) 