"""احراز هویت JWT، هش رمز عبور و وابستگی‌های FastAPI"""
from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

import bcrypt
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from config import settings
from database import execute, execute_returning_id, fetch_all, fetch_one

security = HTTPBearer(auto_error=False)


# ---------------------------------------------------------------------------
# Password
# ---------------------------------------------------------------------------

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))
    except Exception:
        return False


# ---------------------------------------------------------------------------
# JWT
# ---------------------------------------------------------------------------

def create_access_token(user_id: int, username: str, roles: list[str]) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "username": username,
        "roles": roles,
        "type": "access",
        "iat": now,
        "exp": now + timedelta(minutes=settings.access_token_expire_minutes),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_refresh_token_value() -> str:
    return secrets.token_urlsafe(48)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def decode_access_token(token: str) -> dict[str, Any]:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except jwt.ExpiredSignatureError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="توکن منقضی شده است") from exc
    except jwt.InvalidTokenError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="توکن نامعتبر است") from exc
    if payload.get("type") != "access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="نوع توکن نامعتبر است")
    return payload


# ---------------------------------------------------------------------------
# User helpers
# ---------------------------------------------------------------------------

def get_user_by_username(username: str) -> Optional[dict[str, Any]]:
    return fetch_one(
        """SELECT U.Id, U.Username, U.Email, U.PasswordHash, U.FullName,
                  U.RoleRef, R.Code AS RoleCode, R.Name AS RoleName,
                  U.StudentRef, U.TeacherRef, U.IsActive,
                  U.FailedLoginCount, U.LockedUntil, U.PreferredUILanguage
           FROM AppUser U
           JOIN Role R ON U.RoleRef = R.Id
           WHERE U.Username = ?""",
        (username,),
    )


def get_user_by_id(user_id: int) -> Optional[dict[str, Any]]:
    return fetch_one(
        """SELECT U.Id, U.Username, U.Email, U.PasswordHash, U.FullName,
                  U.RoleRef, R.Code AS RoleCode, R.Name AS RoleName,
                  U.StudentRef, U.TeacherRef, U.IsActive,
                  U.FailedLoginCount, U.LockedUntil, U.PreferredUILanguage
           FROM AppUser U
           JOIN Role R ON U.RoleRef = R.Id
           WHERE U.Id = ?""",
        (user_id,),
    )


def get_user_roles(user: dict[str, Any]) -> list[str]:
    code = user.get("RoleCode")
    return [code] if code else []


def public_user(user: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": user["Id"],
        "username": user["Username"],
        "email": user.get("Email"),
        "full_name": user.get("FullName"),
        "role": user.get("RoleCode"),
        "role_name": user.get("RoleName"),
        "student_ref": user.get("StudentRef"),
        "teacher_ref": user.get("TeacherRef"),
        "preferred_ui_language": user.get("PreferredUILanguage") or "fa",
        "is_active": bool(user.get("IsActive")),
    }


def store_refresh_token(user_id: int, refresh_token: str) -> None:
    token_hash = hash_token(refresh_token)
    expires = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
    execute(
        """INSERT INTO UserSession (UserRef, TokenHash, ExpiresAt)
           VALUES (?, ?, ?)""",
        (user_id, token_hash, expires.replace(tzinfo=None)),
    )


def revoke_refresh_token(refresh_token: str) -> None:
    execute(
        "UPDATE UserSession SET RevokedAt = SYSUTCDATETIME() WHERE TokenHash = ? AND RevokedAt IS NULL",
        (hash_token(refresh_token),),
    )


def revoke_all_user_sessions(user_id: int) -> None:
    execute(
        """UPDATE UserSession SET RevokedAt = SYSUTCDATETIME()
           WHERE UserRef = ? AND RevokedAt IS NULL""",
        (user_id,),
    )


def find_valid_refresh_session(refresh_token: str) -> Optional[dict[str, Any]]:
    return fetch_one(
        """SELECT S.Id, S.UserRef, S.ExpiresAt, S.RevokedAt
           FROM UserSession S
           WHERE S.TokenHash = ? AND S.RevokedAt IS NULL""",
        (hash_token(refresh_token),),
    )


def register_failed_login(user_id: int, failed_count: int) -> None:
    new_count = failed_count + 1
    if new_count >= settings.max_failed_logins:
        execute(
            """UPDATE AppUser
               SET FailedLoginCount = ?, LockedUntil = DATEADD(MINUTE, ?, SYSUTCDATETIME())
               WHERE Id = ?""",
            (new_count, settings.lockout_minutes, user_id),
        )
    else:
        execute("UPDATE AppUser SET FailedLoginCount = ? WHERE Id = ?", (new_count, user_id))


def reset_failed_login(user_id: int) -> None:
    execute(
        "UPDATE AppUser SET FailedLoginCount = 0, LockedUntil = NULL, LastLoginAt = SYSUTCDATETIME() WHERE Id = ?",
        (user_id,),
    )


# ---------------------------------------------------------------------------
# FastAPI dependencies
# ---------------------------------------------------------------------------

async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
) -> dict[str, Any]:
    if credentials is None or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="احراز هویت لازم است",
            headers={"WWW-Authenticate": "Bearer"},
        )
    payload = decode_access_token(credentials.credentials)
    user_id = int(payload["sub"])
    user = get_user_by_id(user_id)
    if not user or not user.get("IsActive"):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="کاربر یافت نشد یا غیرفعال است")
    user["_roles"] = get_user_roles(user)
    return user


async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
) -> Optional[dict[str, Any]]:
    if credentials is None or not credentials.credentials:
        return None
    try:
        return await get_current_user(credentials)
    except HTTPException:
        return None


def require_roles(*allowed_roles: str):
    async def _checker(user: dict[str, Any] = Depends(get_current_user)) -> dict[str, Any]:
        roles = user.get("_roles") or get_user_roles(user)
        if "admin" in roles:
            return user
        if not any(r in roles for r in allowed_roles):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="دسترسی مجاز نیست")
        return user

    return _checker
