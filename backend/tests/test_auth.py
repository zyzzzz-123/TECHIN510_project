import pytest
from httpx import AsyncClient
from fastapi import status
from app.main import app
from app.db.base import Base
from app.db.session import engine

import asyncio
import random

# Ensure all tables are created before tests
Base.metadata.create_all(bind=engine)

@pytest.mark.asyncio
async def test_register_and_login():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        # Register a new user with a unique email
        unique_email = f"testuser_{random.randint(10000,99999)}@example.com"
        register_data = {
            "email": unique_email,
            "password": "testpassword123"
        }
        response = await ac.post("/api/auth/register", json=register_data)
        assert response.status_code == status.HTTP_201_CREATED
        assert "id" in response.json()
        assert response.json()["email"] == register_data["email"]

        # Login with the same user
        login_data = {
            "email": unique_email,
            "password": "testpassword123"
        }
        response = await ac.post("/api/auth/login", json=login_data)
        assert response.status_code == status.HTTP_200_OK
        assert "access_token" in response.json()
        assert response.json()["token_type"] == "bearer"

@pytest.mark.asyncio
async def test_create_task():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        # Register and login a user
        unique_email = f"chatuser_{random.randint(10000,99999)}@example.com"
        register_data = {"email": unique_email, "password": "testpassword123"}
        response = await ac.post("/api/auth/register", json=register_data)
        user_id = response.json()["id"]
        # Create a new task for this user
        task_data = {"user_id": user_id, "text": "Test chat todo"}
        response = await ac.post("/api/tasks/", json=task_data)
        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["text"] == "Test chat todo"
        assert response.json()["status"] == "todo"
        assert response.json()["user_id"] == user_id

@pytest.mark.asyncio
async def test_update_task_status_and_query_done():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        # Register and create a task
        unique_email = f"doneuser_{random.randint(10000,99999)}@example.com"
        register_data = {"email": unique_email, "password": "testpassword123"}
        response = await ac.post("/api/auth/register", json=register_data)
        user_id = response.json()["id"]
        task_data = {"user_id": user_id, "text": "Finish homework"}
        response = await ac.post("/api/tasks/", json=task_data)
        task_id = response.json()["id"]
        # Mark the task as done
        update_data = {"status": "done"}
        response = await ac.patch(f"/api/tasks/{task_id}", json=update_data)
        assert response.status_code == status.HTTP_200_OK
        assert response.json()["status"] == "done"
        # Query done tasks
        response = await ac.get(f"/api/tasks/user/{user_id}?status=done")
        assert response.status_code == status.HTTP_200_OK
        done_tasks = response.json()
        assert any(t["id"] == task_id for t in done_tasks)

@pytest.mark.asyncio
async def test_get_user_tasks():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        # Assume user_id=1 exists, but no tasks yet
        response = await ac.get("/api/tasks/user/1")
        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.json(), list)
        assert len(response.json()) == 0
        # (Optional) You can add more logic to create a task and test retrieval 