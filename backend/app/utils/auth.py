from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime, timedelta

from app.db.session import get_db
from app.models.user import User
from app.core.config import settings

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/token", auto_error=False)

def decode_token(token: str) -> dict:
    """
    解码JWT令牌
    """
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        return payload
    except JWTError:
        return {}

async def get_current_user(token: Optional[str] = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> Optional[User]:
    """
    获取当前用户
    
    如果令牌无效或没有提供令牌，返回None
    """
    if not token:
        return None
        
    payload = decode_token(token)
    user_id = payload.get("sub")
    
    if not user_id:
        return None
        
    try:
        user_id = int(user_id)
    except (ValueError, TypeError):
        return None
        
    user = db.query(User).filter(User.id == user_id).first()
    return user

async def get_current_active_user(current_user: Optional[User] = Depends(get_current_user)) -> User:
    """
    获取当前活跃用户
    
    如果用户未登录或不活跃，抛出异常
    """
    if not current_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user"
        )
        
    return current_user 