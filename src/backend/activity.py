"""لاگ فعالیت‌های سامانه برای مشاهده مدیر"""
from __future__ import annotations

import json
from typing import Any, Optional

from database import execute, execute_returning_id, fetch_all, fetch_one


def ensure_activity_schema() -> None:
    execute(
        """
        IF OBJECT_ID(N'dbo.ActivityLog', N'U') IS NULL
        CREATE TABLE dbo.ActivityLog (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            UserRef INT NULL,
            Username NVARCHAR(100) NULL,
            ActionCode NVARCHAR(40) NOT NULL,
            EntityType NVARCHAR(40) NULL,
            EntityId INT NULL,
            Message NVARCHAR(500) NOT NULL,
            DetailJson NVARCHAR(MAX) NULL,
            Method NVARCHAR(10) NULL,
            Path NVARCHAR(300) NULL,
            StatusCode INT NULL,
            IpAddress NVARCHAR(64) NULL,
            CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_ActivityLog_Created DEFAULT (SYSUTCDATETIME())
        )
        """
    )
    execute(
        """
        IF NOT EXISTS (
            SELECT 1 FROM sys.indexes WHERE name = N'IX_ActivityLog_Created' AND object_id = OBJECT_ID(N'dbo.ActivityLog')
        )
        CREATE INDEX IX_ActivityLog_Created ON dbo.ActivityLog (CreatedAt DESC)
        """
    )


def log_activity(
    *,
    message: str,
    action_code: str = "event",
    entity_type: Optional[str] = None,
    entity_id: Optional[int] = None,
    user: Optional[dict[str, Any]] = None,
    detail: Optional[dict[str, Any] | list | str] = None,
    method: Optional[str] = None,
    path: Optional[str] = None,
    status_code: Optional[int] = None,
    ip_address: Optional[str] = None,
) -> int:
    detail_json = None
    if detail is not None:
        if isinstance(detail, str):
            detail_json = detail[:4000]
        else:
            try:
                detail_json = json.dumps(detail, ensure_ascii=False, default=str)[:4000]
            except Exception:
                detail_json = str(detail)[:4000]

    user_ref = None
    username = None
    if user:
        user_ref = user.get("Id") or user.get("id")
        username = user.get("Username") or user.get("username") or user.get("full_name")

    return execute_returning_id(
        """
        INSERT INTO ActivityLog
            ([UserRef], [Username], [ActionCode], [EntityType], [EntityId],
             [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress])
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            user_ref,
            (username or "")[:100] or None,
            (action_code or "event")[:40],
            (entity_type or "")[:40] or None,
            entity_id,
            (message or "")[:500],
            detail_json,
            (method or "")[:10] or None,
            (path or "")[:300] or None,
            status_code,
            (ip_address or "")[:64] or None,
        ),
    )


def list_activities(
    *,
    search: Optional[str] = None,
    action_code: Optional[str] = None,
    entity_type: Optional[str] = None,
    user_ref: Optional[int] = None,
    limit: int = 100,
    offset: int = 0,
) -> dict[str, Any]:
    limit = max(1, min(int(limit or 100), 500))
    offset = max(0, int(offset or 0))

    where = " WHERE 1=1"
    params: list[Any] = []
    if search:
        like = f"%{search.strip()}%"
        where += """ AND (
            Message LIKE ? OR Username LIKE ? OR Path LIKE ?
            OR ActionCode LIKE ? OR EntityType LIKE ?
        )"""
        params.extend([like, like, like, like, like])
    if action_code:
        where += " AND ActionCode = ?"
        params.append(action_code)
    if entity_type:
        where += " AND EntityType = ?"
        params.append(entity_type)
    if user_ref is not None:
        where += " AND UserRef = ?"
        params.append(user_ref)

    total_row = fetch_one(f"SELECT COUNT(*) AS Cnt FROM ActivityLog{where}", tuple(params))
    total = int((total_row or {}).get("Cnt") or 0)

    rows = fetch_all(
        f"""
        SELECT Id, UserRef, Username, ActionCode, EntityType, EntityId,
               Message, DetailJson, Method, Path, StatusCode, IpAddress, CreatedAt
        FROM ActivityLog
        {where}
        ORDER BY Id DESC
        OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
        """,
        tuple(params + [offset, limit]),
    )
    return {"activities": rows, "count": len(rows), "total": total, "limit": limit, "offset": offset}


ENTITY_LABELS = {
    "enrollment": "ثبت‌نام",
    "payment": "پرداخت",
    "student": "زبان‌آموز",
    "teacher": "مدرس",
    "course": "دوره",
    "class": "کلاس",
    "session": "جلسه",
    "user": "کاربر",
    "shop": "فروشگاه",
    "auth": "احراز هویت",
    "language": "زبان",
    "level": "سطح",
    "branch": "شعبه",
}

ACTION_LABELS = {
    "create": "ایجاد",
    "update": "ویرایش",
    "delete": "حذف",
    "login": "ورود",
    "logout": "خروج",
    "register": "ثبت‌نام کاربری",
    "request": "درخواست",
    "event": "رویداد",
}


def path_to_entity(path: str) -> tuple[str, str]:
    """برگرداندن (entity_type, action_hint) از مسیر API"""
    p = (path or "").strip("/")
    parts = p.split("/")
    root = parts[0] if parts else ""
    mapping = {
        "enrollments": "enrollment",
        "payments": "payment",
        "students": "student",
        "teachers": "teacher",
        "courses": "course",
        "classes": "class",
        "sessions": "session",
        "users": "user",
        "auth": "auth",
        "languages": "language",
        "levels": "level",
        "branches": "branch",
        "shop": "shop",
        "scores": "score",
        "attendance": "attendance",
    }
    entity = mapping.get(root, root or "system")
    return entity, "request"
