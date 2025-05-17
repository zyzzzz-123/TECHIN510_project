from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.endpoints.auth import router as auth_router
from app.api.v1.endpoints.tasks import router as tasks_router
from app.api.v1.endpoints.users import router as users_router
from app.api.v1.endpoints.chat import router as chat_router
from app.api.v1.endpoints.chat_history import router as chat_history_router
from app.db.base import Base
from app.db.session import engine
from app.core.config import settings
import logging
from sqlalchemy.exc import OperationalError

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title=settings.PROJECT_NAME)

# Set up CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
def on_startup():
    # 尝试创建数据库表，但如果失败不会阻止应用启动
    try:
        logger.info("Attempting to create database tables...")
        Base.metadata.create_all(bind=engine)
        logger.info("Database tables created successfully")
    except OperationalError as e:
        logger.error(f"Failed to connect to database: {e}")
        logger.warning("Application will start without database connection. Some features may not work.")
    except Exception as e:
        logger.error(f"An error occurred during startup: {e}")
        logger.warning("Application will start with potential issues.")

app.include_router(auth_router)
app.include_router(tasks_router)
app.include_router(users_router)
app.include_router(chat_router)
app.include_router(chat_history_router)

@app.get("/")
def read_root():
    return {"msg": "GoalAchiever FastAPI backend is running!"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}
