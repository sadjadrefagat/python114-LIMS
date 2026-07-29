"""لایه اتصال و اجرای کوئری روی SQL Server"""
from __future__ import annotations

import os
from contextlib import contextmanager
from typing import Any, Iterable, Optional

import pyodbc

DEFAULT_CONN_STR = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=(local)\\SQLEXPRESS2019;"
    "DATABASE=LIMDB;"
    "UID=limdbadmin;"
    "PWD=123@123!"
)


def get_connection_string() -> str:
    return os.getenv("LIMS_DB_CONNECTION", DEFAULT_CONN_STR)


def get_connection() -> pyodbc.Connection:
    return pyodbc.connect(get_connection_string(), autocommit=False)


@contextmanager
def db_cursor():
    conn = get_connection()
    cursor = conn.cursor()
    try:
        yield cursor
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()


def rows_to_dicts(cursor: pyodbc.Cursor, rows: Iterable[pyodbc.Row] | None = None) -> list[dict[str, Any]]:
    if rows is None:
        rows = cursor.fetchall()
    columns = [col[0] for col in cursor.description] if cursor.description else []
    return [dict(zip(columns, row)) for row in rows]


def fetch_all(query: str, params: tuple = ()) -> list[dict[str, Any]]:
    with db_cursor() as cursor:
        cursor.execute(query, params)
        return rows_to_dicts(cursor)


def fetch_one(query: str, params: tuple = ()) -> Optional[dict[str, Any]]:
    rows = fetch_all(query, params)
    return rows[0] if rows else None


def execute(query: str, params: tuple = ()) -> int:
    """اجرای INSERT/UPDATE/DELETE و بازگرداندن rowcount"""
    with db_cursor() as cursor:
        cursor.execute(query, params)
        return cursor.rowcount


def execute_returning_id(query: str, params: tuple = ()) -> int:
    """اجرای INSERT و بازگرداندن شناسه تولیدشده"""
    with db_cursor() as cursor:
        q = query.rstrip().rstrip(";")
        cursor.execute(f"{q}; SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewId", params)
        # رد شدن از پیام‌های DONE_IN_PROC در SQL Server
        while cursor.description is None:
            if not cursor.nextset():
                break
        row = cursor.fetchone()
        return int(row[0]) if row and row[0] is not None else 0


def health_check() -> bool:
    try:
        row = fetch_one("SELECT 1 AS Ok")
        return bool(row and row.get("Ok") == 1)
    except Exception:
        return False
