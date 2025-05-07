from fastapi import FastAPI
from app.api.v1.endpoints.auth import router as auth_router
from app.api.v1.endpoints.tasks import router as tasks_router
from app.api.v1.endpoints.users import router as users_router
from app.db.base import Base
from app.db.session import engine

app = FastAPI(title="GoalAchiever Backend API")

@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)

app.include_router(auth_router)
app.include_router(tasks_router)
app.include_router(users_router)

@app.get("/")
def read_root():
    return {"msg": "GoalAchiever FastAPI backend is running!"}
