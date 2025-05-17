import openai
from app.core.config import settings

client = openai.OpenAI(api_key=settings.OPENAI_API_KEY)

def chat_with_openai(messages, model="gpt-3.5-turbo"):
    response = client.chat.completions.create(
        model=model,
        messages=messages
    )
    return response.choices[0].message.content 