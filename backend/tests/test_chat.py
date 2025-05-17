import pytest
from httpx import AsyncClient
from fastapi import status
from app.main import app
from app.core.config import settings

@pytest.mark.asyncio
async def test_chat_endpoint_default():
    """Test chat endpoint with default AI model"""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        data = {"message": "Give me a motivational quote about achieving goals."}
        response = await ac.post("/chat/", json=data)
        assert response.status_code == status.HTTP_200_OK
        assert "response" in response.json()
        assert isinstance(response.json()["response"], str)
        assert len(response.json()["response"]) > 0

@pytest.mark.asyncio
async def test_chat_endpoint_openai():
    """Test chat endpoint with OpenAI model provider if available"""
    if not settings.is_openai_available():
        pytest.skip("OpenAI API key not set, skipping test")
        
    async with AsyncClient(app=app, base_url="http://test") as ac:
        data = {
            "message": "Give me a motivational quote about achieving goals.",
            "model_provider": "openai"
        }
        response = await ac.post("/chat/", json=data)
        assert response.status_code == status.HTTP_200_OK
        assert "response" in response.json()
        assert isinstance(response.json()["response"], str)
        assert len(response.json()["response"]) > 0

@pytest.mark.asyncio
async def test_chat_endpoint_gemini():
    """Test chat endpoint with Gemini model provider if available"""
    if not settings.is_gemini_available():
        pytest.skip("Gemini API key not set, skipping test")
        
    async with AsyncClient(app=app, base_url="http://test") as ac:
        data = {
            "message": "Give me a motivational quote about achieving goals.",
            "model_provider": "gemini"
        }
        response = await ac.post("/chat/", json=data)
        assert response.status_code == status.HTTP_200_OK
        assert "response" in response.json()
        assert isinstance(response.json()["response"], str)
        assert len(response.json()["response"]) > 0 