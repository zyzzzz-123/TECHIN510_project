from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import os
import logging

# 配置日志
logger = logging.getLogger(__name__)

# 从环境变量获取数据库URL
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./test.db")

# 根据数据库类型设置连接参数
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

# 记录使用的数据库URL类型（不暴露具体凭据）
db_type = "SQLite" if DATABASE_URL.startswith("sqlite") else "PostgreSQL"
logger.info(f"Using {db_type} database")

try:
    # 创建数据库引擎
    engine = create_engine(DATABASE_URL, connect_args=connect_args)
    
    # 创建会话工厂
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    
    logger.info(f"Database connection established successfully")
except Exception as e:
    logger.error(f"Failed to create database engine: {e}")
    # 如果连接失败，创建一个内存SQLite数据库作为回退选项
    fallback_url = "sqlite:///:memory:"
    logger.warning(f"Falling back to in-memory SQLite database")
    engine = create_engine(fallback_url, connect_args={"check_same_thread": False})
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 数据库依赖项
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
