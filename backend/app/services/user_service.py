from sqlalchemy.orm import Session
from app.models.user import User
from app.core.security import hash_password, verify_password
from sqlalchemy.exc import IntegrityError

class UserService:
    @staticmethod
    def get_by_email(db: Session, email: str):
        return db.query(User).filter(User.email == email).first()

    @staticmethod
    def create_user(db: Session, email: str, password: str):
        user = User(email=email, password_hash=hash_password(password))
        db.add(user)
        try:
            db.commit()
            db.refresh(user)
            return user
        except IntegrityError:
            db.rollback()
            return None

    @staticmethod
    def authenticate(db: Session, email: str, password: str):
        user = UserService.get_by_email(db, email)
        if user and verify_password(password, user.password_hash):
            return user
        return None
