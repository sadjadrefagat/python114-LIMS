"""تنظیمات برنامه از متغیر محیطی / فایل .env"""
from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv

_ENV_PATH = Path(__file__).resolve().parent / ".env"
load_dotenv(_ENV_PATH)


class Settings:
    jwt_secret: str = os.getenv(
        "LIMS_JWT_SECRET",
        "LIMS-Jwt-Secret-Key-9f3a7c2e1b8d4e6a0c5f7d2b9e1a3c8f6d0b4e7a2c9f1d5e8b3a6c0f4e7d2a9",
    )
    jwt_algorithm: str = os.getenv("LIMS_JWT_ALGORITHM", "HS256")
    access_token_expire_minutes: int = int(os.getenv("LIMS_ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
    refresh_token_expire_days: int = int(os.getenv("LIMS_REFRESH_TOKEN_EXPIRE_DAYS", "14"))
    max_failed_logins: int = int(os.getenv("LIMS_MAX_FAILED_LOGINS", "5"))
    lockout_minutes: int = int(os.getenv("LIMS_LOCKOUT_MINUTES", "15"))


settings = Settings()
