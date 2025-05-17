import os
from pathlib import Path
from dotenv import load_dotenv

# Try to load .env file if it exists
env_path = Path(__file__).parents[2] / '.env'
load_dotenv(dotenv_path=env_path)

class Settings:
    # API general settings
    API_V1_STR: str = "/api"
    PROJECT_NAME: str = "GoalAchiever API"
    
    # Authentication settings
    SECRET_KEY: str = os.getenv("SECRET_KEY", "dev-secret-key")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 60 * 24))
    
    # Database settings
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./test.db")
    
    # API keys
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    
    # AI Model Configuration
    DEFAULT_AI_MODEL: str = os.getenv("DEFAULT_AI_MODEL", "openai")  # 可选值: "openai", "gemini"

    # CORS settings
    BACKEND_CORS_ORIGINS: list = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5173",
        "http://localhost:8000",
        "http://localhost",
        "*"  # In production, replace with specific domains
    ]

    # AI Model Configuration Methods
    def is_openai_available(self) -> bool:
        """检查OpenAI API是否可用"""
        return bool(self.OPENAI_API_KEY.strip())
    
    def is_gemini_available(self) -> bool:
        """检查Gemini API是否可用"""
        return bool(self.GEMINI_API_KEY.strip())
    
    def get_available_ai_model(self) -> str:
        """获取可用的AI模型"""
        if self.DEFAULT_AI_MODEL == "gemini" and self.is_gemini_available():
            return "gemini"
        elif self.DEFAULT_AI_MODEL == "openai" and self.is_openai_available():
            return "openai"
        elif self.is_openai_available():
            return "openai"
        elif self.is_gemini_available():
            return "gemini"
        else:
            raise ValueError("No AI model available. Please set OPENAI_API_KEY or GEMINI_API_KEY in environment variables.")

settings = Settings()
