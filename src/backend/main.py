"""
API بک‌اند سیستم مدیریت آموزشگاه زبان (LIMS)
فاز ۱ — مطابق SRS v2: Language → Level → Course → Class → Session + JWT Auth
"""
from __future__ import annotations

from datetime import date, datetime, timezone
from typing import Any, Optional
from zoneinfo import ZoneInfo

import pyodbc
from fastapi import Depends, FastAPI, File, HTTPException, Query, Request, UploadFile
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response
from pydantic import ValidationError

from auth import (
    create_access_token,
    create_refresh_token_value,
    decode_access_token,
    find_valid_refresh_session,
    get_current_user,
    get_user_by_id,
    get_user_by_username,
    get_user_roles,
    hash_password,
    is_admin_user,
    public_user,
    register_failed_login,
    require_roles,
    reset_failed_login,
    revoke_all_user_sessions,
    revoke_refresh_token,
    store_refresh_token,
    unlock_admin_accounts,
    verify_password,
)
from config import settings
from database import db_cursor, execute, execute_returning_id, fetch_all, fetch_one, health_check
from placement import ensure_placement_schema, router as placement_router
from shop import ensure_shop_schema, router as shop_router
from activity import (
    ACTION_LABELS,
    ENTITY_LABELS,
    ensure_activity_schema,
    list_activities,
    log_activity,
    path_to_entity,
)
from models import (
    AdminResetPasswordRequest,
    AGE_GROUP_RULES,
    age_group_catalog,
    age_group_range_label,
    AttendanceBulkCreate,
    AttendanceCreate,
    BranchCreate,
    BranchUpdate,
    ChangePasswordRequest,
    ClassCreate,
    ClassUpdate,
    CourseCreate,
    CourseUpdate,
    EnrollmentBulkCreate,
    EnrollmentCreate,
    EnrollmentUpdate,
    LanguageCreate,
    LanguageUpdate,
    LevelCreate,
    LevelUpdate,
    LoginRequest,
    PaymentCreate,
    PaymentUpdate,
    RefreshRequest,
    RegisterRequest,
    ScoreCreate,
    ScoreUpdate,
    SessionCreate,
    SessionUpdate,
    StaffUserCreate,
    StaffUserUpdate,
    StudentCreate,
    StudentBulkDelete,
    StudentUpdate,
    TeacherCreate,
    TeacherUpdate,
    ThemeUpdateRequest,
    format_validation_errors,
)

app = FastAPI(
    title="LIMS API",
    description="Language Institute Management System — Phase 1 + JWT",
    version="1.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(shop_router)
app.include_router(placement_router)


SKIP_ACTIVITY_PREFIXES = (
    "/docs",
    "/openapi",
    "/redoc",
    "/health",
    "/time",
    "/favicon",
)


@app.middleware("http")
async def activity_audit_middleware(request: Request, call_next):
    response = await call_next(request)
    try:
        path = request.url.path or ""
        method = (request.method or "").upper()
        if any(path.startswith(p) for p in SKIP_ACTIVITY_PREFIXES):
            return response
        # همهٔ تغییرات + ورود/خروج
        interesting = method in ("POST", "PUT", "PATCH", "DELETE") or path.startswith("/auth/")
        if not interesting:
            return response
        if method == "GET":
            return response

        user = None
        auth = request.headers.get("authorization") or ""
        if auth.lower().startswith("bearer "):
            try:
                payload = decode_access_token(auth.split(" ", 1)[1].strip())
                uid = int(payload.get("sub") or 0)
                if uid:
                    user = get_user_by_id(uid)
            except Exception:
                user = None

        entity, _ = path_to_entity(path)
        action = {
            "POST": "create",
            "PUT": "update",
            "PATCH": "update",
            "DELETE": "delete",
        }.get(method, "request")
        if path.startswith("/auth/login"):
            action = "login"
            entity = "auth"
        elif path.startswith("/auth/logout"):
            action = "logout"
            entity = "auth"
        elif path.startswith("/auth/register"):
            action = "register"
            entity = "auth"

        status = response.status_code
        entity_fa = ENTITY_LABELS.get(entity, entity)
        action_fa = ACTION_LABELS.get(action, action)
        ok = status < 400
        message = f"{action_fa} {entity_fa}" if ok else f"ناموفق: {action_fa} {entity_fa} ({status})"
        if path.startswith("/auth/login") and ok:
            message = "ورود موفق به سامانه"
        elif path.startswith("/auth/login") and not ok:
            message = "تلاش ناموفق برای ورود"
        elif path.startswith("/auth/logout") and ok:
            message = "خروج از سامانه"

        ip = request.client.host if request.client else None
        log_activity(
            message=message,
            action_code=action,
            entity_type=entity,
            user=user,
            method=method,
            path=path,
            status_code=status,
            ip_address=ip,
            detail={"query": str(request.url.query)[:200] if request.url.query else None},
        )
    except Exception as exc:
        print(f"[activity] middleware log failed: {exc}")
    return response


@app.exception_handler(pyodbc.IntegrityError)
async def integrity_error_handler(_request: Request, exc: pyodbc.IntegrityError):
    """تبدیل خطاهای CHECK/UNIQUE دیتابیس به پیام قابل‌فهم برای کاربر"""
    msg = str(exc)
    if "کد ملی" in msg:
        return JSONResponse(status_code=400, content={"detail": "کد ملی نامعتبر یا تکراری است"})
    if "جنسیت" in msg:
        return JSONResponse(status_code=400, content={"detail": "جنسیت نامعتبر است"})
    if "UNIQUE" in msg.upper() or "duplicate" in msg.lower():
        return JSONResponse(status_code=400, content={"detail": "مقدار تکراری است"})
    return JSONResponse(status_code=400, content={"detail": "داده با محدودیت‌های دیتابیس سازگار نیست"})


@app.exception_handler(RequestValidationError)
async def request_validation_handler(_request: Request, exc: RequestValidationError):
    """همه خطاهای Validation به‌صورت فارسی برگردانده می‌شوند"""
    formatted = format_validation_errors(exc.errors())
    # برای سازگاری با کلاینت: هم آرایه و هم پیام یکپارچه
    messages = [item["msg"] for item in formatted]
    return JSONResponse(
        status_code=422,
        content={
            "detail": formatted,
            "message": "، ".join(messages) if messages else "داده ارسالی نامعتبر است",
        },
    )


@app.exception_handler(ValidationError)
async def pydantic_validation_handler(_request: Request, exc: ValidationError):
    formatted = format_validation_errors(exc.errors())
    messages = [item["msg"] for item in formatted]
    return JSONResponse(
        status_code=422,
        content={
            "detail": formatted,
            "message": "، ".join(messages) if messages else "داده ارسالی نامعتبر است",
        },
    )


# نقش‌های پرکاربرد
AdminDep = Depends(require_roles("admin"))
StaffDep = Depends(require_roles("admin", "secretary", "education"))
FinanceDep = Depends(require_roles("admin", "secretary", "education", "finance"))
TeacherStaffDep = Depends(require_roles("admin", "secretary", "education", "teacher"))
# خواندن فهرست زبان‌آموز برای صفحات نمرات / پرداخت / ثبت‌نام
StudentsReadDep = Depends(require_roles("admin", "secretary", "education", "finance", "teacher"))


def ensure_roles_seed() -> None:
    """اطمینان از وجود نقش‌های پایه از جمله مسئول آموزش"""
    roles = [
        ("admin", "مدیر سیستم"),
        ("finance", "کارشناس مالی"),
        ("secretary", "منشی"),
        ("education", "مسئول آموزش"),
        ("teacher", "مدرس"),
        ("student", "زبان‌آموز"),
        ("parent", "والدین"),
    ]
    for code, name in roles:
        if not fetch_one("SELECT Id FROM Role WHERE Code = ?", (code,)):
            execute(
                "INSERT INTO Role ([Code], [Name], [IsActive]) VALUES (?, ?, 1)",
                (code, name),
            )


TEACHER_PHOTO_MAX_BYTES = 2 * 1024 * 1024
TEACHER_PHOTO_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif"}


def ensure_teacher_photo_schema() -> None:
    """افزودن ستون‌های عکس مدرس در صورت نبود"""
    if not fetch_one(
        """SELECT 1 AS Ok FROM sys.columns
           WHERE object_id = OBJECT_ID(N'dbo.Teacher') AND name = N'Photo'"""
    ):
        execute("ALTER TABLE dbo.Teacher ADD [Photo] VARBINARY(MAX) NULL")
    if not fetch_one(
        """SELECT 1 AS Ok FROM sys.columns
           WHERE object_id = OBJECT_ID(N'dbo.Teacher') AND name = N'PhotoMime'"""
    ):
        execute("ALTER TABLE dbo.Teacher ADD [PhotoMime] VARCHAR(100) NULL")


def ensure_financial_status_schema() -> None:
    """وضعیت مالی: بدهکار / بستانکار / تسویه‌شده"""
    execute(
        """UPDATE dbo.Registration
           SET FinancialStatus = N'debtor'
           WHERE FinancialStatus = N'partial'"""
    )
    row = fetch_one(
        """SELECT definition FROM sys.check_constraints
           WHERE name = N'CK_Registration_FinancialStatus'"""
    )
    definition = (row or {}).get("definition") or ""
    if "creditor" not in definition:
        try:
            execute("ALTER TABLE dbo.Registration DROP CONSTRAINT [CK_Registration_FinancialStatus]")
        except Exception:
            pass
        execute(
            """ALTER TABLE dbo.Registration ADD CONSTRAINT [CK_Registration_FinancialStatus]
               CHECK ([FinancialStatus] IN (N'debtor', N'creditor', N'settled'))"""
        )


def compute_finance_metrics(course_cost: Any, paid_amount: Any) -> dict[str, Any]:
    """
    قاعده مالی:
    balance = paid - due
    balance < 0 → بدهکار (شدت = درصد باقی‌مانده از شهریه)
    balance = 0 → تسویه‌شده
    balance > 0 → بستانکار (شدت = درصد مازاد نسبت به شهریه، سقف ۱۰۰)
    """
    due = float(course_cost or 0)
    paid = float(paid_amount or 0)
    balance = paid - due
    if due <= 0:
        if paid > 0:
            status, intensity = "creditor", 100
        else:
            status, intensity = "settled", 100
    elif balance < 0:
        status = "debtor"
        intensity = int(round(min(100.0, max(0.0, (-balance) / due * 100.0))))
    elif balance > 0:
        status = "creditor"
        intensity = int(round(min(100.0, max(0.0, balance / due * 100.0))))
    else:
        status, intensity = "settled", 100
    debt = max(0.0, -balance)
    credit = max(0.0, balance)
    return {
        "CourseCost": due,
        "PaidAmount": paid,
        "Balance": balance,
        "DebtAmount": debt,
        "CreditAmount": credit,
        "FinanceIntensity": intensity,
        "DerivedFinancialStatus": status,
    }


def enrich_enrollment_finance(row: dict[str, Any]) -> dict[str, Any]:
    """وضعیت مالی همیشه از شهریه و پرداخت‌های موفق محاسبه می‌شود (هم‌تراز با مانده حساب)."""
    linked = float(row.get("PaidAmount") or 0)
    allocated = float(row.get("PaidAllocatedFromUnlinked") or 0)
    effective_paid = linked + allocated
    metrics = compute_finance_metrics(row.get("CourseCost"), effective_paid)
    stored = (row.get("FinancialStatus") or "").strip()
    if stored == "partial":
        stored = "debtor"
    row.update(metrics)
    row["StoredFinancialStatus"] = stored or None
    row["PaidLinked"] = linked
    row["PaidAllocatedFromUnlinked"] = allocated
    row["PaidAmount"] = effective_paid  # مبلغ مؤثر برای نمایش مانده
    row["FinancialStatus"] = metrics["DerivedFinancialStatus"]
    row["DebtAmount"] = metrics["DebtAmount"]
    row["CreditAmount"] = metrics["CreditAmount"]
    row["Balance"] = metrics["Balance"]
    row["FinanceIntensity"] = metrics["FinanceIntensity"]
    return row


def _unallocated_paid_by_student(student_ids: list[int]) -> dict[int, float]:
    if not student_ids:
        return {}
    placeholders = ",".join("?" for _ in student_ids)
    rows = fetch_all(
        f"""
        SELECT StudentRef, ISNULL(SUM(Amount), 0) AS Total
        FROM Payment
        WHERE Status = N'paid'
          AND RegistrationRef IS NULL
          AND StudentRef IN ({placeholders})
        GROUP BY StudentRef
        """,
        tuple(student_ids),
    )
    return {int(r["StudentRef"]): float(r["Total"] or 0) for r in rows}


def apply_unallocated_payments(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """
    پرداخت‌های موفق بدون ثبت‌نام را به بدهی ثبت‌نام‌های همان زبان‌آموز تخصیص می‌دهد (FIFO بر اساس Id).
    """
    if not rows:
        return rows
    by_student: dict[int, list[dict[str, Any]]] = {}
    for r in rows:
        by_student.setdefault(int(r["StudentRef"]), []).append(r)

    unalloc_map = _unallocated_paid_by_student(list(by_student.keys()))
    out: list[dict[str, Any]] = []
    for sid, items in by_student.items():
        remaining = float(unalloc_map.get(sid, 0))
        # قدیمی‌ترین ثبت‌نام‌ها اول بدهی‌شان پوشش داده شود
        ordered = sorted(items, key=lambda x: (str(x.get("Date") or ""), int(x["Id"])))
        for r in ordered:
            linked = float(r.get("PaidAmount") or 0)
            due = float(r.get("CourseCost") or 0)
            debt = max(0.0, due - linked)
            applied = min(debt, remaining) if remaining > 0 else 0.0
            remaining -= applied
            r = dict(r)
            r["PaidAllocatedFromUnlinked"] = applied
            r["StudentUnallocatedPaid"] = float(unalloc_map.get(sid, 0))
            out.append(enrich_enrollment_finance(r))
        # اگر هنوز اعتبار تخصیص‌نیافته ماند، روی آخرین ردیف علامت بزن
        if remaining > 0 and out:
            # پیدا کردن آخرین آیتم این دانشجو در out
            for i in range(len(out) - 1, -1, -1):
                if int(out[i]["StudentRef"]) == sid:
                    out[i]["StudentUnallocatedRemaining"] = remaining
                    # مازاد به‌عنوان بستانکاری اضافه روی همان ثبت‌نام
                    if remaining > 0:
                        linked = float(out[i].get("PaidLinked") or 0)
                        allocated = float(out[i].get("PaidAllocatedFromUnlinked") or 0) + remaining
                        out[i]["PaidAllocatedFromUnlinked"] = allocated
                        metrics = compute_finance_metrics(out[i].get("CourseCost"), linked + allocated)
                        out[i].update(metrics)
                        out[i]["PaidAmount"] = linked + allocated
                        out[i]["FinancialStatus"] = metrics["DerivedFinancialStatus"]
                        out[i]["DebtAmount"] = metrics["DebtAmount"]
                        out[i]["CreditAmount"] = metrics["CreditAmount"]
                        out[i]["Balance"] = metrics["Balance"]
                        out[i]["FinanceIntensity"] = metrics["FinanceIntensity"]
                        out[i]["StudentUnallocatedRemaining"] = 0
                    break
    # حفظ ترتیب اولیه فهرست
    by_id = {int(r["Id"]): r for r in out}
    return [by_id[int(r["Id"])] for r in rows if int(r["Id"]) in by_id]


def repair_orphan_payments() -> int:
    """
    اگر زبان‌آموز فقط یک ثبت‌نام دارد، پرداخت‌های بدون RegistrationRef را به همان وصل کن.
    """
    orphans = fetch_all(
        """
        SELECT P.Id, P.StudentRef
        FROM Payment P
        WHERE P.RegistrationRef IS NULL
        """
    )
    fixed = 0
    touched: set[int] = set()
    for o in orphans:
        regs = fetch_all(
            "SELECT Id FROM Registration WHERE Studentref = ? ORDER BY Id",
            (o["StudentRef"],),
        )
        if len(regs) != 1:
            continue
        reg_id = int(regs[0]["Id"])
        execute(
            "UPDATE Payment SET RegistrationRef = ? WHERE Id = ?",
            (reg_id, o["Id"]),
        )
        touched.add(reg_id)
        fixed += 1
    for reg_id in touched:
        sync_registration_financial_status(reg_id)
    return fixed


def sync_registration_financial_status(registration_id: int) -> str:
    """به‌روزرسانی FinancialStatus ثبت‌نام بر اساس شهریه و پرداخت‌های موفق"""
    row = fetch_one(
        """SELECT C.Cost AS CourseCost,
                  ISNULL((
                      SELECT SUM(P.Amount) FROM Payment P
                      WHERE P.RegistrationRef = R.Id AND P.Status = N'paid'
                  ), 0) AS PaidAmount
           FROM Registration R
           JOIN Course C ON R.CourseRef = C.Id
           WHERE R.Id = ?""",
        (registration_id,),
    )
    if not row:
        return "debtor"
    status = compute_finance_metrics(row.get("CourseCost"), row.get("PaidAmount"))["DerivedFinancialStatus"]
    execute(
        "UPDATE Registration SET FinancialStatus = ? WHERE Id = ?",
        (status, registration_id),
    )
    return status


def sync_all_registration_financial_statuses() -> int:
    """همگام‌سازی همهٔ ثبت‌نام‌ها تا برچسب مالی با مانده حساب یکی شود"""
    rows = fetch_all(
        """SELECT R.Id, R.FinancialStatus, C.Cost AS CourseCost,
                  ISNULL((
                      SELECT SUM(P.Amount) FROM Payment P
                      WHERE P.RegistrationRef = R.Id AND P.Status = N'paid'
                  ), 0) AS PaidAmount
           FROM Registration R
           JOIN Course C ON R.CourseRef = C.Id"""
    )
    fixed = 0
    for r in rows:
        status = compute_finance_metrics(r.get("CourseCost"), r.get("PaidAmount"))["DerivedFinancialStatus"]
        stored = (r.get("FinancialStatus") or "").strip()
        if stored == "partial":
            stored = "debtor"
        if stored != status:
            execute(
                "UPDATE Registration SET FinancialStatus = ? WHERE Id = ?",
                (status, r["Id"]),
            )
            fixed += 1
    return fixed


def ensure_ui_theme_schema() -> None:
    """ستون تم رابط کاربری برای هر حساب"""
    execute(
        """
        IF COL_LENGTH('dbo.AppUser', 'UiTheme') IS NULL
            ALTER TABLE dbo.AppUser ADD UiTheme NVARCHAR(30) NOT NULL
                CONSTRAINT DF_AppUser_UiTheme DEFAULT (N'light')
        """
    )


@app.on_event("startup")
def on_startup() -> None:
    try:
        ensure_roles_seed()
    except Exception as exc:
        print(f"[startup] ensure_roles_seed failed: {exc}")
    try:
        ensure_ui_theme_schema()
    except Exception as exc:
        print(f"[startup] ensure_ui_theme_schema failed: {exc}")
    try:
        ensure_teacher_photo_schema()
    except Exception as exc:
        print(f"[startup] ensure_teacher_photo_schema failed: {exc}")
    try:
        ensure_financial_status_schema()
    except Exception as exc:
        print(f"[startup] ensure_financial_status_schema failed: {exc}")
    try:
        n_fix = repair_orphan_payments()
        if n_fix:
            print(f"[startup] linked {n_fix} orphan payment(s) to sole enrollment")
    except Exception as exc:
        print(f"[startup] repair_orphan_payments failed: {exc}")
    try:
        n = sync_all_registration_financial_statuses()
        if n:
            print(f"[startup] synced FinancialStatus on {n} enrollment(s)")
    except Exception as exc:
        print(f"[startup] sync_all_registration_financial_statuses failed: {exc}")
    try:
        ensure_shop_schema()
    except Exception as exc:
        print(f"[startup] ensure_shop_schema failed: {exc}")
    try:
        ensure_activity_schema()
    except Exception as exc:
        print(f"[startup] ensure_activity_schema failed: {exc}")
    try:
        ensure_score_schema()
    except Exception as exc:
        print(f"[startup] ensure_score_schema failed: {exc}")
    try:
        ensure_placement_schema()
    except Exception as exc:
        print(f"[startup] ensure_placement_schema failed: {exc}")


def ensure_score_schema() -> None:
    """ستون‌های StudentRef / SuggestedLevelRef و امکان ثبت تعیین‌سطح بدون ثبت‌نام"""
    execute(
        """
        IF COL_LENGTH('dbo.Score', 'StudentRef') IS NULL
            ALTER TABLE dbo.Score ADD StudentRef INT NULL
        """
    )
    execute(
        """
        IF COL_LENGTH('dbo.Score', 'SuggestedLevelRef') IS NULL
            ALTER TABLE dbo.Score ADD SuggestedLevelRef INT NULL
        """
    )
    execute(
        """
        UPDATE Sc
           SET StudentRef = R.Studentref
        FROM dbo.Score Sc
        JOIN dbo.Registration R ON Sc.RegistrationRef = R.Id
        WHERE Sc.StudentRef IS NULL AND Sc.RegistrationRef IS NOT NULL
        """
    )

    nullable = fetch_one(
        """
        SELECT c.is_nullable AS IsNullable
        FROM sys.columns c
        WHERE c.object_id = OBJECT_ID(N'dbo.Score') AND c.name = N'RegistrationRef'
        """
    )
    if nullable and int(nullable.get("IsNullable") or 0) == 0:
        fk = fetch_one(
            """
            SELECT TOP 1 fk.name AS FkName
            FROM sys.foreign_keys fk
            JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
            JOIN sys.columns c
              ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
            WHERE fk.parent_object_id = OBJECT_ID(N'dbo.Score') AND c.name = N'RegistrationRef'
            """
        )
        if fk and fk.get("FkName"):
            execute(f"ALTER TABLE dbo.Score DROP CONSTRAINT [{fk['FkName']}]")
        execute("ALTER TABLE dbo.Score ALTER COLUMN RegistrationRef INT NULL")
        execute(
            """
            IF NOT EXISTS (
                SELECT 1 FROM sys.foreign_keys
                WHERE name = N'FK_Score_Registration' AND parent_object_id = OBJECT_ID(N'dbo.Score')
            )
                ALTER TABLE dbo.Score WITH CHECK ADD CONSTRAINT FK_Score_Registration
                  FOREIGN KEY (RegistrationRef) REFERENCES dbo.Registration(Id)
            """
        )

    execute(
        """
        IF NOT EXISTS (
            SELECT 1 FROM sys.foreign_keys
            WHERE name = N'FK_Score_Student' AND parent_object_id = OBJECT_ID(N'dbo.Score')
        )
        AND COL_LENGTH('dbo.Score', 'StudentRef') IS NOT NULL
            ALTER TABLE dbo.Score WITH CHECK ADD CONSTRAINT FK_Score_Student
              FOREIGN KEY (StudentRef) REFERENCES dbo.Student(Id)
        """
    )
    execute(
        """
        IF NOT EXISTS (
            SELECT 1 FROM sys.foreign_keys
            WHERE name = N'FK_Score_SuggestedLevel' AND parent_object_id = OBJECT_ID(N'dbo.Score')
        )
        AND COL_LENGTH('dbo.Score', 'SuggestedLevelRef') IS NOT NULL
            ALTER TABLE dbo.Score WITH CHECK ADD CONSTRAINT FK_Score_SuggestedLevel
              FOREIGN KEY (SuggestedLevelRef) REFERENCES dbo.Level(Id)
        """
    )


async def _read_teacher_photo(photo: UploadFile) -> tuple[bytes, str]:
    mime = (photo.content_type or "").lower().strip()
    if mime not in TEACHER_PHOTO_TYPES:
        raise _bad_request("فرمت تصویر مجاز نیست (jpeg، png، webp، gif)")
    data = await photo.read()
    if not data:
        raise _bad_request("فایل تصویر خالی است")
    if len(data) > TEACHER_PHOTO_MAX_BYTES:
        raise _bad_request("حجم تصویر نباید بیشتر از ۲ مگابایت باشد")
    return data, mime

def _user_role_set(user: dict[str, Any]) -> set[str]:
    return set(user.get("_roles") or get_user_roles(user))


def _assert_can_create_enrollment(user: dict[str, Any], student_ref: int) -> None:
    """ثبت‌نام: فقط منشی/آموزش/مدیر برای دیگران، یا زبان‌آموز برای خودش — مالی ممنوع"""
    roles = _user_role_set(user)
    # مالی حتی اگر StudentRef داشته باشد هم مجاز به ثبت‌نام نیست
    if "finance" in roles and not ({"admin", "secretary", "education"} & roles):
        raise HTTPException(
            status_code=403,
            detail="کارشناس مالی مجاز به ثبت‌نام نیست؛ فقط ثبت پرداخت مجاز است",
        )
    if "admin" in roles or "secretary" in roles or "education" in roles:
        return
    own = user.get("StudentRef")
    if not own or int(own) != int(student_ref):
        raise HTTPException(status_code=403, detail="فقط می‌توانید برای حساب خودتان ثبت‌نام کنید")


# وضعیت‌هایی که هنوز ثبت‌نام «جاری» در دوره محسوب می‌شوند
CONCURRENT_ENROLLMENT_STATUSES = (
    "pending_payment",
    "pending_approval",
    "active",
    "frozen",
)


def _assert_no_parallel_course_enrollment(
    student_ref: int,
    course_ref: int,
    target_class_ref: int,
) -> None:
    """
    یک زبان‌آموز نباید هم‌زمان در بیش از یک کلاسِ همان دوره ثبت‌نام باشد.
    انصراف / انتقال / تکمیل‌شده مانع ثبت‌نام جدید در کلاس دیگر نیست.
    """
    placeholders = ",".join("?" for _ in CONCURRENT_ENROLLMENT_STATUSES)
    existing = fetch_one(
        f"""SELECT R.Id, R.ClassRef, R.Status,
                   St.FirstName + N' ' + St.LastName AS StudentName,
                   C.Name AS CourseName
            FROM Registration R
            JOIN Student St ON R.Studentref = St.Id
            JOIN Course C ON R.CourseRef = C.Id
            WHERE R.Studentref = ?
              AND R.CourseRef = ?
              AND R.ClassRef IS NOT NULL
              AND R.ClassRef <> ?
              AND R.Status IN ({placeholders})""",
        (student_ref, course_ref, target_class_ref, *CONCURRENT_ENROLLMENT_STATUSES),
    )
    if existing:
        name = existing.get("StudentName") or f"#{student_ref}"
        course = existing.get("CourseName") or f"دوره #{course_ref}"
        raise _bad_request(
            f"{name} هم‌اکنون در کلاس #{existing['ClassRef']} از دوره «{course}» ثبت‌نام دارد؛ "
            f"ثبت‌نام هم‌زمان در بیش از یک کلاس همان دوره مجاز نیست (ثبت‌نام #{existing['Id']})"
        )


AuthDep = Depends(get_current_user)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _not_found(entity: str = "Resource") -> HTTPException:
    return HTTPException(status_code=404, detail=f"{entity} not found")


def _bad_request(detail: str) -> HTTPException:
    return HTTPException(status_code=400, detail=detail)


def _ok_list(key: str, rows: list[dict[str, Any]]) -> dict[str, Any]:
    return {key: rows, "count": len(rows)}


def _partial_update(table: str, id_value: int, column_map: dict[str, str], data: dict[str, Any]) -> None:
    fields: list[str] = []
    params: list[Any] = []
    for key, col in column_map.items():
        if key in data and data[key] is not None:
            fields.append(f"[{col}] = ?")
            params.append(data[key])
    if not fields:
        raise _bad_request("هیچ فیلدی برای به‌روزرسانی ارسال نشده است")
    params.append(id_value)
    execute(f"UPDATE [{table}] SET {', '.join(fields)} WHERE Id = ?", tuple(params))


def _gregorian_to_jalali(gy: int, gm: int, gd: int) -> tuple[int, int, int]:
    """تبدیل میلادی به شمسی برای مقایسه تاریخ‌های YYYY/MM/DD"""
    gdm = (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334)
    gy2 = gy + 1 if gm > 2 else gy
    days = (
        355666
        + 365 * gy
        + (gy2 + 3) // 4
        - (gy2 + 99) // 100
        + (gy2 + 399) // 400
        + gd
        + gdm[gm - 1]
    )
    jy = -1595 + 33 * (days // 12053)
    days %= 12053
    jy += 4 * (days // 1461)
    days %= 1461
    if days > 365:
        jy += (days - 1) // 365
        days = (days - 1) % 365
    if days < 186:
        jm = 1 + days // 31
        jd = 1 + days % 31
    else:
        jm = 7 + (days - 186) // 30
        jd = 1 + (days - 186) % 30
    return jy, jm, jd


def _jalali_to_gregorian(jy: int, jm: int, jd: int) -> tuple[int, int, int]:
    """تبدیل شمسی به میلادی (مکمل _gregorian_to_jalali)"""
    jy2 = jy + 1595
    days = -355668 + (365 * jy2) + ((jy2 // 33) * 8) + (((jy2 % 33) + 3) // 4) + jd
    if jm < 7:
        days += (jm - 1) * 31
    else:
        days += ((jm - 7) * 30) + 186
    gy = 400 * (days // 146097)
    days %= 146097
    if days > 36524:
        days -= 1
        gy += 100 * (days // 36524)
        days %= 36524
        if days >= 365:
            days += 1
    gy += 4 * (days // 1461)
    days %= 1461
    if days > 365:
        gy += (days - 1) // 365
        days = (days - 1) % 365
    gd = days + 1
    sal_a = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if (gy % 4 == 0 and gy % 100 != 0) or (gy % 400 == 0):
        sal_a[2] = 29
    gm = 1
    while gm < 13 and gd > sal_a[gm]:
        gd -= sal_a[gm]
        gm += 1
    return gy, gm, gd


def _parse_jalali_to_date(value: Optional[str]) -> Optional[date]:
    if not value:
        return None
    try:
        parts = str(value).strip().split("/")
        if len(parts) != 3:
            return None
        jy, jm, jd = int(parts[0]), int(parts[1]), int(parts[2])
        gy, gm, gd = _jalali_to_gregorian(jy, jm, jd)
        return date(gy, gm, gd)
    except (ValueError, TypeError, OverflowError):
        return None


def _years_old(birth: date, on: Optional[date] = None) -> int:
    """سن کامل بر اساس تاریخ میلادی"""
    on = on or date.today()
    years = on.year - birth.year
    if (on.month, on.day) < (birth.month, birth.day):
        years -= 1
    return max(0, years)


def _assert_student_fits_course_age(student_ref: int, course_ref: int) -> None:
    """ثبت‌نام فقط اگر سن زبان‌آموز در بازه رده سنی دوره باشد."""
    student = fetch_one(
        "SELECT Id, FirstName, LastName, BirthDate FROM Student WHERE Id = ?",
        (student_ref,),
    )
    course = fetch_one(
        "SELECT Id, Name, AgeGroup FROM Course WHERE Id = ?",
        (course_ref,),
    )
    if not student or not course:
        return

    age_group = (course.get("AgeGroup") or "").strip()
    rules = AGE_GROUP_RULES.get(age_group)
    if not rules:
        # برچسب قدیمی/آزاد در دیتابیس — محدودیت اعمال نمی‌شود
        return

    min_age, max_age = rules
    if min_age is None and max_age is None:
        return

    birth = _parse_jalali_to_date(student.get("BirthDate"))
    if not birth:
        raise _bad_request(
            "تاریخ تولد زبان‌آموز نامعتبر است؛ بدون تاریخ تولد معتبر نمی‌توان در این رده سنی ثبت‌نام کرد"
        )

    age = _years_old(birth)
    name = f"{student.get('FirstName') or ''} {student.get('LastName') or ''}".strip() or f"#{student_ref}"
    course_name = course.get("Name") or f"#{course_ref}"
    band = age_group_range_label(age_group)

    if min_age is not None and age < min_age:
        raise _bad_request(
            f"سن «{name}» ({age} سال) برای دوره «{course_name}» مناسب نیست. "
            f"این دوره ویژهٔ {band} است."
        )
    if max_age is not None and age > max_age:
        raise _bad_request(
            f"سن «{name}» ({age} سال) برای دوره «{course_name}» مناسب نیست. "
            f"این دوره ویژهٔ {band} است."
        )


def _pct(part: float, whole: float) -> float:
    if not whole:
        return 0.0
    return round(100.0 * float(part) / float(whole), 1)


def _parse_time_minutes(value: Optional[str]) -> Optional[int]:
    if not value:
        return None
    try:
        parts = str(value).strip().split(":")
        if len(parts) < 2:
            return None
        return int(parts[0]) * 60 + int(parts[1])
    except (ValueError, TypeError):
        return None


def _compute_class_stats(class_id: int, class_row: dict[str, Any]) -> dict[str, Any]:
    """آمار جلسات، ظرفیت، حضور و مالی یک کلاس"""
    course = fetch_one(
        "SELECT Id, Name, SessionsCount, Cost FROM Course WHERE Id = ?",
        (class_row.get("CourseRef"),),
    ) or {}
    planned_sessions = int(course.get("SessionsCount") or 0)

    sessions = fetch_all(
        """SELECT Id, [Date] AS SessionDate, StartTime, EndTime, Status, IsMakeup
           FROM Session WHERE ClassRef = ? ORDER BY [Date], StartTime""",
        (class_id,),
    )

    by_status: dict[str, int] = {
        "scheduled": 0,
        "in_progress": 0,
        "completed": 0,
        "cancelled": 0,
        "rescheduled": 0,
    }
    makeup_count = 0
    duration_sum = 0
    duration_n = 0
    for s in sessions:
        st = (s.get("Status") or "").strip()
        if st in by_status:
            by_status[st] += 1
        if s.get("IsMakeup"):
            makeup_count += 1
        start_m = _parse_time_minutes(s.get("StartTime"))
        end_m = _parse_time_minutes(s.get("EndTime"))
        if start_m is not None and end_m is not None and end_m > start_m:
            duration_sum += end_m - start_m
            duration_n += 1

    total_sessions = len(sessions)
    held = by_status["completed"]
    remaining_scheduled = by_status["scheduled"] + by_status["in_progress"]
    # پیشرفت نسبت به جلسات برنامه‌ریزی‌شده دوره، وگرنه نسبت به جلسات ثبت‌شده
    progress_base = planned_sessions if planned_sessions > 0 else total_sessions
    held_pct = _pct(held, progress_base)

    today = _today_jalali()
    past_dates = [s["SessionDate"] for s in sessions if s.get("SessionDate") and s["SessionDate"] <= today]
    future_dates = [s["SessionDate"] for s in sessions if s.get("SessionDate") and s["SessionDate"] > today]
    last_session_date = past_dates[-1] if past_dates else None
    next_session_date = future_dates[0] if future_dates else None

    # میانگین جلسات برگزارشده در هفته (بر اساس بازه کلاس یا بازه جلسات)
    span_start = _parse_jalali_to_date(class_row.get("StartDate"))
    span_end = _parse_jalali_to_date(class_row.get("EndDate"))
    session_dates = [_parse_jalali_to_date(s.get("SessionDate")) for s in sessions]
    session_dates = [d for d in session_dates if d]
    if session_dates:
        if not span_start or span_start > min(session_dates):
            span_start = min(session_dates)
        if not span_end or span_end < max(session_dates):
            span_end = max(session_dates)
    weeks = 1.0
    if span_start and span_end and span_end >= span_start:
        weeks = max(1.0, (span_end - span_start).days / 7.0)
    avg_held_per_week = round(held / weeks, 2)
    avg_all_per_week = round(total_sessions / weeks, 2) if total_sessions else 0.0

    capacity = int(class_row.get("Capacity") or 0)
    enrolled = int(class_row.get("EnrolledCount") or 0)
    fill_pct = _pct(enrolled, capacity)

    attendance = fetch_one(
        """SELECT
               COUNT(*) AS TotalMarks,
               SUM(CASE WHEN SS.AttendanceStatus = N'present' THEN 1 ELSE 0 END) AS PresentCount,
               SUM(CASE WHEN SS.AttendanceStatus = N'absent' THEN 1 ELSE 0 END) AS AbsentCount,
               SUM(CASE WHEN SS.AttendanceStatus = N'late' THEN 1 ELSE 0 END) AS LateCount,
               SUM(CASE WHEN SS.AttendanceStatus = N'leave' THEN 1 ELSE 0 END) AS LeaveCount
           FROM SessionStudent SS
           JOIN Session S ON SS.SessionRef = S.Id
           WHERE S.ClassRef = ?""",
        (class_id,),
    ) or {}
    total_marks = int(attendance.get("TotalMarks") or 0)
    present_count = int(attendance.get("PresentCount") or 0)
    absent_count = int(attendance.get("AbsentCount") or 0)
    late_count = int(attendance.get("LateCount") or 0)
    leave_count = int(attendance.get("LeaveCount") or 0)
    # حاضر + تأخیر به‌عنوان حضور مؤثر
    effective_present = present_count + late_count
    attendance_pct = _pct(effective_present, total_marks)

    finance = fetch_one(
        """SELECT
               COUNT(*) AS RegCount,
               SUM(CASE WHEN R.Status IN (N'active', N'pending_payment', N'pending_approval') THEN 1 ELSE 0 END) AS ActiveLike,
               SUM(CASE WHEN R.Status = N'withdrawn' THEN 1 ELSE 0 END) AS Withdrawn,
               SUM(CASE WHEN R.Status = N'completed' THEN 1 ELSE 0 END) AS CompletedRegs,
               SUM(CASE WHEN R.FinancialStatus = N'debtor' THEN 1 ELSE 0 END) AS Debtors,
               SUM(CASE WHEN R.FinancialStatus = N'creditor' THEN 1 ELSE 0 END) AS Creditors,
               SUM(CASE WHEN R.FinancialStatus = N'settled' THEN 1 ELSE 0 END) AS Settled
           FROM Registration R
           WHERE R.ClassRef = ?""",
        (class_id,),
    ) or {}

    avg_duration = round(duration_sum / duration_n, 1) if duration_n else None

    return {
        "planned_sessions": planned_sessions,
        "sessions_total": total_sessions,
        "sessions_completed": held,
        "sessions_scheduled": by_status["scheduled"],
        "sessions_in_progress": by_status["in_progress"],
        "sessions_cancelled": by_status["cancelled"],
        "sessions_rescheduled": by_status["rescheduled"],
        "sessions_remaining": remaining_scheduled,
        "sessions_held_pct": held_pct,
        "makeup_count": makeup_count,
        "avg_sessions_per_week": avg_held_per_week,
        "avg_all_sessions_per_week": avg_all_per_week,
        "span_weeks": round(weeks, 1),
        "last_session_date": last_session_date,
        "next_session_date": next_session_date,
        "avg_duration_minutes": avg_duration,
        "capacity": capacity,
        "enrolled_count": enrolled,
        "fill_pct": fill_pct,
        "seats_left": max(0, capacity - enrolled),
        "attendance_total_marks": total_marks,
        "attendance_present": present_count,
        "attendance_absent": absent_count,
        "attendance_late": late_count,
        "attendance_leave": leave_count,
        "attendance_pct": attendance_pct,
        "registrations_total": int(finance.get("RegCount") or 0),
        "registrations_withdrawn": int(finance.get("Withdrawn") or 0),
        "registrations_completed": int(finance.get("CompletedRegs") or 0),
        "finance_debtors": int(finance.get("Debtors") or 0),
        "finance_creditors": int(finance.get("Creditors") or 0),
        "finance_settled": int(finance.get("Settled") or 0),
        "course_name": course.get("Name"),
        "course_cost": course.get("Cost"),
    }


def _today_jalali() -> str:
    """تاریخ شمسی امروز به وقت ایران (نه لزوماً timezone سیستم سرور)"""
    t = datetime.now(ZoneInfo("Asia/Tehran"))
    jy, jm, jd = _gregorian_to_jalali(t.year, t.month, t.day)
    return f"{jy}/{jm:02d}/{jd:02d}"


def _normalize_jalali_date(value: str) -> str:
    parts = value.strip().split("/")
    if len(parts) != 3:
        raise _bad_request("فرمت تاریخ باید YYYY/MM/DD باشد")
    try:
        jy, jm, jd = int(parts[0]), int(parts[1]), int(parts[2])
    except ValueError as exc:
        raise _bad_request("فرمت تاریخ نامعتبر است") from exc
    return f"{jy}/{jm:02d}/{jd:02d}"


def _reject_past_jalali_date(value: str, *, entity: str = "جلسه") -> str:
    """BR-021 — ثبت با تاریخ گذشته ممنوع است"""
    normalized = _normalize_jalali_date(value)
    if normalized < _today_jalali():
        raise _bad_request(f"ثبت {entity} با تاریخ گذشته مجاز نیست (BR-021)")
    return normalized


def _issue_tokens(user: dict[str, Any]) -> dict[str, Any]:
    roles = get_user_roles(user)
    access = create_access_token(user["Id"], user["Username"], roles)
    refresh = create_refresh_token_value()
    store_refresh_token(user["Id"], refresh)
    return {
        "access_token": access,
        "refresh_token": refresh,
        "token_type": "bearer",
        "expires_in_minutes": settings.access_token_expire_minutes,
        "user": public_user(user),
    }


# ---------------------------------------------------------------------------
# Health / Root
# ---------------------------------------------------------------------------

@app.get("/")
async def read_root():
    return {"message": "LIMS API is running", "docs": "/docs", "auth": "/auth/login"}


@app.get("/health")
async def health():
    db_ok = health_check()
    if not db_ok:
        raise HTTPException(status_code=503, detail="Database unavailable")
    return {"status": "ok", "database": "connected"}


@app.get("/time")
async def server_time():
    """ساعت و تاریخ سرور به وقت ایران — برای نمایش در هدر سایت"""
    tehran = ZoneInfo("Asia/Tehran")
    now_utc = datetime.now(timezone.utc)
    now = now_utc.astimezone(tehran)
    jy, jm, jd = _gregorian_to_jalali(now.year, now.month, now.day)
    # یکشنبه=0 ... شنبه=6 (مثل JS getDay)
    weekday_idx = (now.weekday() + 1) % 7
    weekdays = ["یکشنبه", "دوشنبه", "سه‌شنبه", "چهارشنبه", "پنجشنبه", "جمعه", "شنبه"]
    months = [
        "فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور",
        "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند",
    ]
    weekday = weekdays[weekday_idx]
    month_name = months[jm - 1]
    return {
        "unix_ms": int(now_utc.timestamp() * 1000),
        "timezone": "Asia/Tehran",
        "utc": now_utc.isoformat(),
        "hour": now.hour,
        "minute": now.minute,
        "second": now.second,
        "time": f"{now.hour:02d}:{now.minute:02d}",
        "jalali": {
            "year": jy,
            "month": jm,
            "day": jd,
            "iso": f"{jy}/{jm:02d}/{jd:02d}",
            "weekday": weekday,
            "month_name": month_name,
            "label": f"{weekday} {jd} {month_name} {jy}",
        },
    }


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------

@app.post("/auth/login")
async def login(body: LoginRequest):
    user = get_user_by_username(body.username)
    if not user:
        raise HTTPException(status_code=401, detail="نام کاربری یا رمز عبور اشتباه است")

    admin = is_admin_user(user)

    # ادمین هرگز قفل نمی‌شود؛ اگر قبلاً قفل شده بود، فوراً باز می‌شود
    if admin and (user.get("LockedUntil") or user.get("FailedLoginCount")):
        unlock_admin_accounts()
        user = get_user_by_username(body.username) or user

    locked_until = user.get("LockedUntil")
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    if not admin and locked_until and locked_until > now:
        raise HTTPException(status_code=423, detail="حساب موقتاً قفل است؛ بعداً تلاش کنید")

    if not user.get("IsActive"):
        raise HTTPException(status_code=403, detail="حساب کاربری غیرفعال است")

    if not verify_password(body.password, user["PasswordHash"]):
        register_failed_login(
            user["Id"],
            int(user.get("FailedLoginCount") or 0),
            is_admin=admin,
        )
        raise HTTPException(status_code=401, detail="نام کاربری یا رمز عبور اشتباه است")

    reset_failed_login(user["Id"])
    user = get_user_by_id(user["Id"])
    return _issue_tokens(user)


@app.post("/auth/register", status_code=201)
async def register(body: RegisterRequest):
    """ثبت‌نام عمومی زبان‌آموز — بدون تأیید ایمیل"""
    if get_user_by_username(body.username):
        raise _bad_request("نام کاربری تکراری است")
    if fetch_one("SELECT Id FROM Student WHERE NationalCode = ?", (body.national_code,)):
        raise _bad_request("کد ملی قبلاً ثبت شده است")
    if body.email and fetch_one("SELECT Id FROM AppUser WHERE Email = ?", (body.email,)):
        raise _bad_request("ایمیل تکراری است")

    role = fetch_one("SELECT Id FROM Role WHERE Code = N'student'")
    if not role:
        raise HTTPException(status_code=500, detail="نقش student تعریف نشده است")

    full_name = f"{body.first_name} {body.last_name}".strip()
    try:
        student_id = execute_returning_id(
            """INSERT INTO Student
                ([FirstName], [LastName], [FatherName], [NationalCode], [Gender],
                 [BirthDate], [Mobile], [Email], [TargetLanguageRef], [PreferredUILanguage])
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                body.first_name,
                body.last_name,
                body.father_name,
                body.national_code,
                body.gender,
                body.birth_date,
                body.mobile,
                body.email,
                body.target_language_ref,
                body.preferred_ui_language,
            ),
        )
    except pyodbc.IntegrityError as exc:
        msg = str(exc)
        if "کد ملی" in msg or "NationalCode" in msg:
            raise _bad_request("کد ملی نامعتبر است") from exc
        raise _bad_request("ثبت‌نام با محدودیت‌های دیتابیس سازگار نیست") from exc

    user_id = execute_returning_id(
        """INSERT INTO AppUser
            ([Username], [Email], [PasswordHash], [FullName], [RoleRef],
             [StudentRef], [PreferredUILanguage])
           VALUES (?, ?, ?, ?, ?, ?, ?)""",
        (
            body.username,
            body.email,
            hash_password(body.password),
            full_name,
            role["Id"],
            student_id,
            body.preferred_ui_language,
        ),
    )
    user = get_user_by_id(user_id)
    return _issue_tokens(user)


@app.post("/auth/refresh")
async def refresh_token(body: RefreshRequest):
    session = find_valid_refresh_session(body.refresh_token)
    if not session:
        raise HTTPException(status_code=401, detail="رفرش‌توکن نامعتبر است")
    expires = session["ExpiresAt"]
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    if expires < now:
        revoke_refresh_token(body.refresh_token)
        raise HTTPException(status_code=401, detail="رفرش‌توکن منقضی شده است")

    user = get_user_by_id(int(session["UserRef"]))
    if not user or not user.get("IsActive"):
        raise HTTPException(status_code=401, detail="کاربر معتبر نیست")

    revoke_refresh_token(body.refresh_token)
    return _issue_tokens(user)


@app.post("/auth/logout")
async def logout(body: RefreshRequest, user: dict = AuthDep):
    revoke_refresh_token(body.refresh_token)
    return {"message": "خروج انجام شد"}


@app.post("/auth/logout-all")
async def logout_all(user: dict = AuthDep):
    revoke_all_user_sessions(user["Id"])
    return {"message": "همه نشست‌ها باطل شدند"}


@app.get("/auth/me")
async def me(user: dict = AuthDep):
    return {"user": public_user(user)}


@app.post("/auth/change-password")
async def change_password(body: ChangePasswordRequest, user: dict = AuthDep):
    full = get_user_by_id(user["Id"])
    if not verify_password(body.current_password, full["PasswordHash"]):
        raise HTTPException(status_code=400, detail="رمز فعلی اشتباه است")
    execute(
        "UPDATE AppUser SET PasswordHash = ? WHERE Id = ?",
        (hash_password(body.new_password), user["Id"]),
    )
    revoke_all_user_sessions(user["Id"])
    return {"message": "رمز عبور تغییر کرد؛ دوباره وارد شوید"}


@app.put("/auth/theme")
async def update_my_theme(body: ThemeUpdateRequest, user: dict = AuthDep):
    execute(
        "UPDATE AppUser SET UiTheme = ? WHERE Id = ?",
        (body.ui_theme, user["Id"]),
    )
    fresh = get_user_by_id(user["Id"])
    fresh["_roles"] = user.get("_roles") or get_user_roles(fresh)
    return {"message": "تم ذخیره شد", "ui_theme": body.ui_theme, "user": public_user(fresh)}


@app.get("/auth/roles")
async def list_roles(user: dict = AdminDep):
    rows = fetch_all("SELECT Id, Code, Name, IsActive FROM Role WHERE IsActive = 1 ORDER BY Id")
    return _ok_list("roles", rows)


USER_SELECT = """
    SELECT
        U.Id, U.Username, U.Email, U.FullName, U.IsActive,
        U.StudentRef, U.TeacherRef, U.PreferredUILanguage,
        U.LastLoginAt, U.CreatedAt, U.LockedUntil,
        R.Code AS RoleCode, R.Name AS RoleName,
        CASE
            WHEN U.TeacherRef IS NOT NULL THEN T.FirstName + N' ' + T.LastName
            ELSE NULL
        END AS TeacherName,
        CASE
            WHEN U.StudentRef IS NOT NULL THEN St.FirstName + N' ' + St.LastName
            ELSE NULL
        END AS StudentName
    FROM AppUser U
    JOIN Role R ON U.RoleRef = R.Id
    LEFT JOIN Teacher T ON U.TeacherRef = T.Id
    LEFT JOIN Student St ON U.StudentRef = St.Id
"""


def _serialize_user_row(row: dict[str, Any]) -> dict[str, Any]:
    return {
        "Id": row["Id"],
        "Username": row["Username"],
        "Email": row.get("Email"),
        "FullName": row.get("FullName"),
        "IsActive": bool(row.get("IsActive")),
        "RoleCode": row.get("RoleCode"),
        "RoleName": row.get("RoleName"),
        "StudentRef": row.get("StudentRef"),
        "TeacherRef": row.get("TeacherRef"),
        "StudentName": row.get("StudentName"),
        "TeacherName": row.get("TeacherName"),
        "LastLoginAt": row.get("LastLoginAt"),
        "CreatedAt": row.get("CreatedAt"),
        "LockedUntil": row.get("LockedUntil"),
    }


def _validate_user_links(
    role_code: str,
    teacher_ref: Optional[int],
    student_ref: Optional[int],
    *,
    exclude_user_id: Optional[int] = None,
) -> None:
    """اعتبارسنجی اتصال یکتای حساب به پروفایل مدرس/زبان‌آموز"""
    if role_code == "teacher":
        if not teacher_ref:
            raise _bad_request("برای نقش مدرس باید پروفایل مدرس را انتخاب کنید")
        if student_ref:
            raise _bad_request("حساب مدرس نباید به پروفایل زبان‌آموز متصل باشد")
    elif role_code == "student":
        if not student_ref:
            raise _bad_request("برای نقش زبان‌آموز باید پروفایل زبان‌آموز را انتخاب کنید")
        if teacher_ref:
            raise _bad_request("حساب زبان‌آموز نباید به پروفایل مدرس متصل باشد")
    else:
        if teacher_ref or student_ref:
            raise _bad_request("فقط نقش مدرس/زبان‌آموز می‌تواند به پروفایل متصل شود")

    if teacher_ref:
        t = fetch_one("SELECT Id, IsActive FROM Teacher WHERE Id = ?", (teacher_ref,))
        if not t:
            raise _bad_request("مدرس نامعتبر است")
        if not t.get("IsActive"):
            raise _bad_request("این پروفایل مدرس غیرفعال است")
        q = "SELECT Id, Username FROM AppUser WHERE TeacherRef = ?"
        params: list[Any] = [teacher_ref]
        if exclude_user_id is not None:
            q += " AND Id <> ?"
            params.append(exclude_user_id)
        taken = fetch_one(q, tuple(params))
        if taken:
            raise _bad_request(
                f"پروفایل این مدرس قبلاً به حساب «{taken['Username']}» متصل است"
            )

    if student_ref:
        s = fetch_one("SELECT Id, IsActive FROM Student WHERE Id = ?", (student_ref,))
        if not s:
            raise _bad_request("زبان‌آموز نامعتبر است")
        if not s.get("IsActive"):
            raise _bad_request("این پروفایل زبان‌آموز غیرفعال است")
        q = "SELECT Id, Username FROM AppUser WHERE StudentRef = ?"
        params = [student_ref]
        if exclude_user_id is not None:
            q += " AND Id <> ?"
            params.append(exclude_user_id)
        taken = fetch_one(q, tuple(params))
        if taken:
            raise _bad_request(
                f"پروفایل این زبان‌آموز قبلاً به حساب «{taken['Username']}» متصل است"
            )


@app.get("/users/link-options")
async def user_link_options(user: dict = AdminDep):
    """
    فهرست پروفایل‌های مدرس/زبان‌آموز برای اتصال حساب.
    LinkedUsername مشخص می‌کند پروفایل آزاد است یا به حساب دیگری وصل است.
    """
    teachers = fetch_all(
        """
        SELECT T.Id, T.FirstName, T.LastName, T.NationalCode, T.Mobile, T.IsActive,
               U.Id AS LinkedUserId, U.Username AS LinkedUsername
        FROM Teacher T
        LEFT JOIN AppUser U ON U.TeacherRef = T.Id
        WHERE T.IsActive = 1
        ORDER BY T.LastName, T.FirstName
        """
    )
    students = fetch_all(
        """
        SELECT S.Id, S.FirstName, S.LastName, S.NationalCode, S.Mobile, S.IsActive,
               U.Id AS LinkedUserId, U.Username AS LinkedUsername
        FROM Student S
        LEFT JOIN AppUser U ON U.StudentRef = S.Id
        WHERE S.IsActive = 1
        ORDER BY S.LastName, S.FirstName
        """
    )
    return {
        "teachers": teachers,
        "students": students,
        "teachers_count": len(teachers),
        "students_count": len(students),
    }


@app.get("/users")
async def list_users(
    search: Optional[str] = None,
    role_code: Optional[str] = None,
    include_inactive: bool = True,
    user: dict = AdminDep,
):
    query = USER_SELECT + " WHERE 1=1"
    params: list[Any] = []
    if not include_inactive:
        query += " AND U.IsActive = 1"
    if role_code:
        query += " AND R.Code = ?"
        params.append(role_code)
    if search:
        like = f"%{search.strip()}%"
        query += """ AND (
            U.Username LIKE ? OR U.FullName LIKE ? OR U.Email LIKE ?
            OR R.Name LIKE ?
        )"""
        params.extend([like, like, like, like])
    query += " ORDER BY U.Id DESC"
    rows = [_serialize_user_row(r) for r in fetch_all(query, tuple(params))]
    return _ok_list("users", rows)


@app.post("/users", status_code=201)
async def create_user(body: StaffUserCreate, user: dict = AdminDep):
    if get_user_by_username(body.username):
        raise _bad_request("نام کاربری تکراری است")
    if body.email and fetch_one("SELECT Id FROM AppUser WHERE Email = ?", (body.email,)):
        raise _bad_request("ایمیل تکراری است")
    role = fetch_one("SELECT Id, Code FROM Role WHERE Code = ? AND IsActive = 1", (body.role_code,))
    if not role:
        raise _bad_request("نقش نامعتبر است")
    teacher_ref = body.teacher_ref if body.role_code == "teacher" else None
    student_ref = body.student_ref if body.role_code == "student" else None
    _validate_user_links(body.role_code, teacher_ref, student_ref)

    new_id = execute_returning_id(
        """INSERT INTO AppUser
            ([Username], [Email], [PasswordHash], [FullName], [RoleRef],
             [StudentRef], [TeacherRef], [IsActive], [PreferredUILanguage])
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, N'fa')""",
        (
            body.username.strip(),
            body.email,
            hash_password(body.password),
            body.full_name.strip(),
            role["Id"],
            student_ref,
            teacher_ref,
            1 if body.is_active else 0,
        ),
    )
    row = fetch_one(USER_SELECT + " WHERE U.Id = ?", (new_id,))
    return {"message": "کاربر ایجاد شد", "user": _serialize_user_row(row)}


@app.put("/users/{user_id}")
async def update_user(user_id: int, body: StaffUserUpdate, user: dict = AdminDep):
    existing = fetch_one(USER_SELECT + " WHERE U.Id = ?", (user_id,))
    if not existing:
        raise _not_found("User")

    data = body.model_dump(exclude_unset=True)
    role_code = data.get("role_code", existing["RoleCode"])
    teacher_ref = data["teacher_ref"] if "teacher_ref" in data else existing["TeacherRef"]
    student_ref = data["student_ref"] if "student_ref" in data else existing["StudentRef"]
    if role_code != "teacher":
        teacher_ref = None
    if role_code != "student":
        student_ref = None

    _validate_user_links(role_code, teacher_ref, student_ref, exclude_user_id=user_id)

    if "email" in data and data["email"]:
        dup = fetch_one("SELECT Id FROM AppUser WHERE Email = ? AND Id <> ?", (data["email"], user_id))
        if dup:
            raise _bad_request("ایمیل تکراری است")

    role_id = None
    if "role_code" in data:
        role = fetch_one("SELECT Id FROM Role WHERE Code = ? AND IsActive = 1", (role_code,))
        if not role:
            raise _bad_request("نقش نامعتبر است")
        role_id = role["Id"]

    # جلوگیری از غیرفعال کردن آخرین ادمین
    if existing["RoleCode"] == "admin" and (
        data.get("is_active") is False or ("role_code" in data and role_code != "admin")
    ):
        active_admins = fetch_one(
            """SELECT COUNT(*) AS Cnt
               FROM AppUser U JOIN Role R ON U.RoleRef = R.Id
               WHERE R.Code = N'admin' AND U.IsActive = 1 AND U.Id <> ?""",
            (user_id,),
        )
        if not active_admins or int(active_admins["Cnt"] or 0) < 1:
            raise _bad_request("نمی‌توان آخرین مدیر فعال را حذف/تغییر نقش داد")

    sets: list[str] = []
    params: list[Any] = []
    if "full_name" in data:
        sets.append("[FullName] = ?")
        params.append(str(data["full_name"]).strip())
    if "email" in data:
        sets.append("[Email] = ?")
        params.append(data["email"])
    if role_id is not None:
        sets.append("[RoleRef] = ?")
        params.append(role_id)
    if "role_code" in data or "teacher_ref" in data:
        sets.append("[TeacherRef] = ?")
        params.append(teacher_ref)
    if "role_code" in data or "student_ref" in data:
        sets.append("[StudentRef] = ?")
        params.append(student_ref)
    if "is_active" in data:
        sets.append("[IsActive] = ?")
        params.append(1 if data["is_active"] else 0)
    if data.get("password"):
        sets.append("[PasswordHash] = ?")
        params.append(hash_password(data["password"]))

    if not sets:
        raise _bad_request("هیچ فیلدی برای به‌روزرسانی ارسال نشده است")

    params.append(user_id)
    execute(f"UPDATE AppUser SET {', '.join(sets)} WHERE Id = ?", tuple(params))
    if data.get("password") or data.get("is_active") is False:
        revoke_all_user_sessions(user_id)

    row = fetch_one(USER_SELECT + " WHERE U.Id = ?", (user_id,))
    return {"message": "کاربر به‌روزرسانی شد", "user": _serialize_user_row(row)}


@app.post("/users/{user_id}/reset-password")
async def admin_reset_password(
    user_id: int, body: AdminResetPasswordRequest, user: dict = AdminDep
):
    """ریست رمز توسط مدیر — جلسات قبلی باطل و قفل ورود پاک می‌شود."""
    existing = fetch_one(USER_SELECT + " WHERE U.Id = ?", (user_id,))
    if not existing:
        raise _not_found("User")

    execute(
        """UPDATE AppUser
           SET PasswordHash = ?, FailedLoginCount = 0, LockedUntil = NULL
           WHERE Id = ?""",
        (hash_password(body.new_password), user_id),
    )
    revoke_all_user_sessions(user_id)
    return {
        "message": "رمز عبور با موفقیت بازنشانی شد",
        "username": existing["Username"],
        "full_name": existing.get("FullName"),
    }


# ---------------------------------------------------------------------------
# Languages
# ---------------------------------------------------------------------------

@app.get("/languages")
async def list_languages(search: Optional[str] = None):
    if search:
        rows = fetch_all(
            "SELECT Id, Name FROM Language WHERE Name LIKE ? ORDER BY Name",
            (f"%{search}%",),
        )
    else:
        rows = fetch_all("SELECT Id, Name FROM Language ORDER BY Name")
    return _ok_list("languages", rows)


@app.get("/languages/{language_id}")
async def get_language(language_id: int):
    row = fetch_one("SELECT Id, Name FROM Language WHERE Id = ?", (language_id,))
    if not row:
        raise _not_found("Language")
    return {"language": row}


@app.post("/languages", status_code=201)
async def create_language(body: LanguageCreate, user: dict = StaffDep):
    existing = fetch_one("SELECT Id FROM Language WHERE Name = ?", (body.name,))
    if existing:
        raise _bad_request("نام زبان تکراری است")
    new_id = execute_returning_id(
        "INSERT INTO Language ([Name]) VALUES (?)",
        (body.name,),
    )
    return {"message": "Language created", "id": new_id}


@app.put("/languages/{language_id}")
async def update_language(language_id: int, body: LanguageUpdate, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM Language WHERE Id = ?", (language_id,)):
        raise _not_found("Language")
    name = (body.name or "").strip()
    if not name:
        raise _bad_request("نام زبان را وارد کنید")
    dup = fetch_one("SELECT Id FROM Language WHERE Name = ? AND Id <> ?", (name, language_id))
    if dup:
        raise _bad_request("نام زبان تکراری است")
    try:
        execute("UPDATE Language SET Name = ? WHERE Id = ?", (name, language_id))
    except pyodbc.IntegrityError as exc:
        raise _bad_request("نام زبان تکراری یا نامعتبر است") from exc
    return {"message": "Language updated", "id": language_id}


@app.delete("/languages/{language_id}")
async def delete_language(language_id: int, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM Language WHERE Id = ?", (language_id,)):
        raise _not_found("Language")
    if fetch_one("SELECT TOP 1 Id FROM Course WHERE LanguageRef = ?", (language_id,)):
        raise _bad_request("این زبان در دوره استفاده شده و قابل حذف نیست")
    if fetch_one("SELECT TOP 1 Id FROM Level WHERE LanguageRef = ?", (language_id,)):
        raise _bad_request("این زبان سطح فعال دارد و قابل حذف نیست")
    execute("DELETE FROM Language WHERE Id = ?", (language_id,))
    return {"message": "Language deleted", "id": language_id}


# ---------------------------------------------------------------------------
# Levels
# ---------------------------------------------------------------------------

@app.get("/levels")
async def list_levels(language_ref: Optional[int] = None, search: Optional[str] = None):
    query = """
        SELECT Lv.Id, Lv.LanguageRef, Lv.Code, Lv.Name, Lv.SortOrder, Lv.IsActive,
               L.Name AS LanguageName
        FROM Level Lv
        JOIN Language L ON Lv.LanguageRef = L.Id
        WHERE Lv.IsActive = 1
    """
    params: list[Any] = []
    if language_ref is not None:
        query += " AND Lv.LanguageRef = ?"
        params.append(language_ref)
    if search:
        query += " AND (Lv.Name LIKE ? OR Lv.Code LIKE ?)"
        params.extend([f"%{search}%", f"%{search}%"])
    query += " ORDER BY Lv.LanguageRef, Lv.SortOrder, Lv.Code"
    return _ok_list("levels", fetch_all(query, tuple(params)))


@app.post("/levels", status_code=201)
async def create_level(body: LevelCreate, user: dict = StaffDep):
    lang = fetch_one("SELECT Id FROM Language WHERE Id = ?", (body.language_ref,))
    if not lang:
        raise _bad_request("زبان معتبر نیست")
    existing = fetch_one(
        "SELECT Id FROM Level WHERE LanguageRef = ? AND Code = ?",
        (body.language_ref, body.code),
    )
    if existing:
        raise _bad_request("کد سطح در این زبان تکراری است")
    new_id = execute_returning_id(
        """INSERT INTO Level ([LanguageRef], [Code], [Name], [SortOrder])
           VALUES (?, ?, ?, ?)""",
        (body.language_ref, body.code, body.name, body.sort_order),
    )
    return {"message": "Level created", "id": new_id}


@app.put("/levels/{level_id}")
async def update_level(level_id: int, body: LevelUpdate, user: dict = StaffDep):
    current = fetch_one("SELECT * FROM Level WHERE Id = ? AND IsActive = 1", (level_id,))
    if not current:
        raise _not_found("Level")
    data = body.model_dump(exclude_unset=True)
    language_ref = data.get("language_ref", current["LanguageRef"])
    code = data.get("code", current["Code"])
    if "language_ref" in data and not fetch_one("SELECT Id FROM Language WHERE Id = ?", (language_ref,)):
        raise _bad_request("زبان معتبر نیست")
    dup = fetch_one(
        "SELECT Id FROM Level WHERE LanguageRef = ? AND Code = ? AND Id <> ? AND IsActive = 1",
        (language_ref, code, level_id),
    )
    if dup:
        raise _bad_request("کد سطح در این زبان تکراری است")
    _partial_update(
        "Level",
        level_id,
        {
            "language_ref": "LanguageRef",
            "code": "Code",
            "name": "Name",
            "sort_order": "SortOrder",
        },
        data,
    )
    return {"message": "Level updated", "id": level_id}


@app.delete("/levels/{level_id}")
async def archive_level(level_id: int, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM Level WHERE Id = ?", (level_id,)):
        raise _not_found("Level")
    execute("UPDATE Level SET IsActive = 0 WHERE Id = ?", (level_id,))
    return {"message": "Level archived (soft delete)", "id": level_id}


# ---------------------------------------------------------------------------
# Session Types
# ---------------------------------------------------------------------------

@app.get("/session-types")
async def list_session_types(search: Optional[str] = None):
    if search:
        rows = fetch_all(
            "SELECT Id, Name FROM SessionType WHERE Name LIKE ? ORDER BY Id",
            (f"%{search}%",),
        )
    else:
        rows = fetch_all("SELECT Id, Name FROM SessionType ORDER BY Id")
    return _ok_list("session_types", rows)


@app.post("/session-types", status_code=201)
async def create_session_type(body: LanguageCreate, user: dict = StaffDep):
    """ایجاد نوع جلسه جدید (از مدل ساده name)"""
    if fetch_one("SELECT Id FROM SessionType WHERE Name = ?", (body.name,)):
        raise _bad_request("نام نوع جلسه تکراری است")
    new_id = execute_returning_id(
        "INSERT INTO SessionType ([Name]) VALUES (?)",
        (body.name,),
    )
    return {"message": "Session type created", "id": new_id}


@app.put("/session-types/{session_type_id}")
async def update_session_type(session_type_id: int, body: LanguageUpdate, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM SessionType WHERE Id = ?", (session_type_id,)):
        raise _not_found("SessionType")
    dup = fetch_one("SELECT Id FROM SessionType WHERE Name = ? AND Id <> ?", (body.name, session_type_id))
    if dup:
        raise _bad_request("نام نوع جلسه تکراری است")
    execute("UPDATE SessionType SET Name = ? WHERE Id = ?", (body.name, session_type_id))
    return {"message": "Session type updated", "id": session_type_id}


@app.delete("/session-types/{session_type_id}")
async def delete_session_type(session_type_id: int, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM SessionType WHERE Id = ?", (session_type_id,)):
        raise _not_found("SessionType")
    if fetch_one("SELECT TOP 1 Id FROM Class WHERE SessionTypeRef = ?", (session_type_id,)):
        raise _bad_request("این نوع جلسه در کلاس استفاده شده و قابل حذف نیست")
    if fetch_one("SELECT TOP 1 Id FROM Session WHERE SessionTypeRef = ?", (session_type_id,)):
        raise _bad_request("این نوع جلسه در جلسات استفاده شده و قابل حذف نیست")
    execute("DELETE FROM SessionType WHERE Id = ?", (session_type_id,))
    return {"message": "Session type deleted", "id": session_type_id}


# ---------------------------------------------------------------------------
# Branches
# ---------------------------------------------------------------------------

@app.get("/branches")
async def list_branches(search: Optional[str] = None):
    query = """SELECT Id, Name, Address, Phone, IsActive
               FROM Branch WHERE IsActive = 1"""
    params: list[Any] = []
    if search:
        query += " AND (Name LIKE ? OR Address LIKE ? OR Phone LIKE ?)"
        like = f"%{search}%"
        params.extend([like, like, like])
    query += " ORDER BY Name"
    return _ok_list("branches", fetch_all(query, tuple(params)))


@app.get("/age-groups")
async def list_age_groups():
    """فهرست رده‌های سنی دوره با بازه مجاز سن"""
    return {"age_groups": age_group_catalog(), "count": len(AGE_GROUP_RULES)}


@app.post("/branches", status_code=201)
async def create_branch(body: BranchCreate, user: dict = StaffDep):
    if fetch_one("SELECT Id FROM Branch WHERE Name = ?", (body.name,)):
        raise _bad_request("نام شعبه تکراری است")
    new_id = execute_returning_id(
        """INSERT INTO Branch ([Name], [Address], [Phone])
           VALUES (?, ?, ?)""",
        (body.name, body.address, body.phone),
    )
    return {"message": "Branch created", "id": new_id}


@app.put("/branches/{branch_id}")
async def update_branch(branch_id: int, body: BranchUpdate, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM Branch WHERE Id = ? AND IsActive = 1", (branch_id,)):
        raise _not_found("Branch")
    data = body.model_dump(exclude_unset=True)
    if "name" in data:
        dup = fetch_one("SELECT Id FROM Branch WHERE Name = ? AND Id <> ?", (data["name"], branch_id))
        if dup:
            raise _bad_request("نام شعبه تکراری است")
    _partial_update(
        "Branch",
        branch_id,
        {"name": "Name", "address": "Address", "phone": "Phone"},
        data,
    )
    return {"message": "Branch updated", "id": branch_id}


@app.delete("/branches/{branch_id}")
async def archive_branch(branch_id: int, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM Branch WHERE Id = ?", (branch_id,)):
        raise _not_found("Branch")
    execute("UPDATE Branch SET IsActive = 0 WHERE Id = ?", (branch_id,))
    return {"message": "Branch archived (soft delete)", "id": branch_id}


# ---------------------------------------------------------------------------
# Courses
# ---------------------------------------------------------------------------

COURSE_SELECT = """
    SELECT
        C.Id, C.Name, C.LanguageRef, L.Name AS LanguageName,
        C.LevelRef, Lv.Code AS LevelCode, Lv.Name AS LevelName,
        C.SessionsCount, C.Cost, C.Description,
        C.PrerequisiteCourseRef, C.DurationHours, C.Syllabus,
        C.TeachingMethod, C.AgeGroup, C.IsHighlighted, C.IsActive,
        C.Creator, C.CreatedAt, C.UpdatedAt
    FROM Course C
    JOIN Language L ON C.LanguageRef = L.Id
    LEFT JOIN Level Lv ON C.LevelRef = Lv.Id
"""


@app.get("/courses")
async def list_courses(
    search: Optional[str] = None,
    language_ref: Optional[int] = None,
    level_ref: Optional[int] = None,
    min_cost: Optional[int] = None,
    max_cost: Optional[int] = None,
    highlighted_only: bool = False,
    include_inactive: bool = False,
):
    query = COURSE_SELECT + " WHERE 1=1"
    params: list[Any] = []
    if not include_inactive:
        query += " AND C.IsActive = 1"
    if search:
        query += " AND C.Name LIKE ?"
        params.append(f"%{search}%")
    if language_ref is not None:
        query += " AND C.LanguageRef = ?"
        params.append(language_ref)
    if level_ref is not None:
        query += " AND C.LevelRef = ?"
        params.append(level_ref)
    if min_cost is not None:
        query += " AND C.Cost >= ?"
        params.append(min_cost)
    if max_cost is not None:
        query += " AND C.Cost <= ?"
        params.append(max_cost)
    if highlighted_only:
        query += " AND C.IsHighlighted = 1"
    query += " ORDER BY C.IsHighlighted DESC, C.Name"
    return _ok_list("courses", fetch_all(query, tuple(params)))


@app.get("/courses/{course_id}")
async def get_course(course_id: int):
    row = fetch_one(COURSE_SELECT + " WHERE C.Id = ?", (course_id,))
    if not row:
        raise _not_found("Course")
    return {"course": row}


@app.post("/courses", status_code=201)
async def create_course(body: CourseCreate, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM Language WHERE Id = ?", (body.language_ref,)):
        raise _bad_request("زبان معتبر نیست (BR-001)")
    if body.level_ref and not fetch_one("SELECT Id FROM Level WHERE Id = ?", (body.level_ref,)):
        raise _bad_request("سطح معتبر نیست (BR-001)")
    if not body.description or len(body.description.strip()) < 10:
        raise _bad_request("توضیحات دوره کافی نیست (BR-001)")
    if fetch_one("SELECT Id FROM Course WHERE Name = ? AND IsActive = 1", (body.name,)):
        raise _bad_request("نام دوره تکراری است (BR-002)")
    if body.cost < 0:
        raise _bad_request("قیمت منفی مجاز نیست (BR-003)")

    new_id = execute_returning_id(
        """INSERT INTO Course
            ([Name], [LanguageRef], [LevelRef], [SessionsCount], [Cost],
             [Description], [PrerequisiteCourseRef], [DurationHours],
             [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted])
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            body.name,
            body.language_ref,
            body.level_ref,
            body.sessions_count,
            body.cost,
            body.description,
            body.prerequisite_course_ref,
            body.duration_hours,
            body.syllabus,
            body.teaching_method,
            body.age_group,
            1 if body.is_highlighted else 0,
        ),
    )
    return {"message": "Course created", "id": new_id}


@app.put("/courses/{course_id}")
async def update_course(course_id: int, body: CourseUpdate, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM Course WHERE Id = ?", (course_id,)):
        raise _not_found("Course")

    fields: list[str] = []
    params: list[Any] = []
    mapping = {
        "name": body.name,
        "language_ref": body.language_ref,
        "level_ref": body.level_ref,
        "sessions_count": body.sessions_count,
        "cost": body.cost,
        "description": body.description,
        "prerequisite_course_ref": body.prerequisite_course_ref,
        "duration_hours": body.duration_hours,
        "syllabus": body.syllabus,
        "teaching_method": body.teaching_method,
        "age_group": body.age_group,
        "is_highlighted": (None if body.is_highlighted is None else (1 if body.is_highlighted else 0)),
        "is_active": (None if body.is_active is None else (1 if body.is_active else 0)),
    }
    column_map = {
        "name": "Name",
        "language_ref": "LanguageRef",
        "level_ref": "LevelRef",
        "sessions_count": "SessionsCount",
        "cost": "Cost",
        "description": "Description",
        "prerequisite_course_ref": "PrerequisiteCourseRef",
        "duration_hours": "DurationHours",
        "syllabus": "Syllabus",
        "teaching_method": "TeachingMethod",
        "age_group": "AgeGroup",
        "is_highlighted": "IsHighlighted",
        "is_active": "IsActive",
    }
    for key, value in mapping.items():
        if value is not None:
            fields.append(f"[{column_map[key]}] = ?")
            params.append(value)

    if not fields:
        raise _bad_request("هیچ فیلدی برای به‌روزرسانی ارسال نشده است")

    params.append(course_id)
    execute(f"UPDATE Course SET {', '.join(fields)} WHERE Id = ?", tuple(params))
    return {"message": "Course updated", "id": course_id}


@app.delete("/courses/{course_id}")
async def archive_course(course_id: int, user: dict = StaffDep):
    """حذف نرم — BR-022"""
    course = fetch_one("SELECT Id, IsActive FROM Course WHERE Id = ?", (course_id,))
    if not course:
        raise _not_found("Course")
    active_class = fetch_one(
        """SELECT Id FROM Class
           WHERE CourseRef = ? AND Status IN ('open', 'full', 'in_progress')""",
        (course_id,),
    )
    if active_class:
        # فقط آرشیو، نه خطا — مطابق soft delete
        pass
    execute("UPDATE Course SET IsActive = 0, UpdatedAt = SYSUTCDATETIME() WHERE Id = ?", (course_id,))
    return {"message": "Course archived (soft delete)", "id": course_id}


@app.get("/courses/{course_id}/history")
async def course_history(course_id: int, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM Course WHERE Id = ?", (course_id,)):
        raise _not_found("Course")
    rows = fetch_all(
        """SELECT Id, CourseRef, ChangedBy, ChangedAt, FieldName, OldValue, NewValue
           FROM CourseHistory WHERE CourseRef = ? ORDER BY ChangedAt DESC""",
        (course_id,),
    )
    return _ok_list("history", rows)


# ---------------------------------------------------------------------------
# Teachers
# ---------------------------------------------------------------------------

@app.get("/teachers")
async def list_teachers(search: Optional[str] = None, include_inactive: bool = False, user: dict = AuthDep):
    query = """
        SELECT Id, FirstName, LastName, FatherName, NationalCode, Gender,
               BirthDate, Mobile, Email, Specialty, Bio, IsActive, Creator, CreatedAt,
               CASE WHEN Photo IS NULL THEN 0 ELSE 1 END AS HasPhoto
        FROM Teacher WHERE 1=1
    """
    params: list[Any] = []
    if not include_inactive:
        query += " AND IsActive = 1"
    if search:
        query += " AND (FirstName + N' ' + LastName LIKE ? OR Specialty LIKE ?)"
        params.extend([f"%{search}%", f"%{search}%"])
    query += " ORDER BY LastName, FirstName"
    return _ok_list("teachers", fetch_all(query, tuple(params)))

@app.get("/teachers/{teacher_id}")
async def get_teacher(teacher_id: int, user: dict = AuthDep):
    row = fetch_one(
        """SELECT Id, FirstName, LastName, FatherName, NationalCode, Gender,
                  BirthDate, Mobile, Email, Specialty, Bio, IsActive, Creator, CreatedAt,
                  CASE WHEN Photo IS NULL THEN 0 ELSE 1 END AS HasPhoto
           FROM Teacher WHERE Id = ?""",
        (teacher_id,),
    )
    if not row:
        raise _not_found("Teacher")
    return {"teacher": row}


@app.get("/teachers/{teacher_id}/photo")
async def get_teacher_photo(teacher_id: int):
    """سرو عکس مدرس — بدون احراز هویت تا <img> بتواند مستقیم لود کند"""
    row = fetch_one(
        "SELECT Photo, PhotoMime FROM Teacher WHERE Id = ? AND IsActive = 1",
        (teacher_id,),
    )
    if not row or not row.get("Photo"):
        raise _not_found("Teacher photo")
    photo = row["Photo"]
    if isinstance(photo, memoryview):
        photo = photo.tobytes()
    mime = row.get("PhotoMime") or "image/jpeg"
    return Response(content=photo, media_type=mime, headers={"Cache-Control": "private, max-age=3600"})


@app.post("/teachers/{teacher_id}/photo")
async def upload_teacher_photo(
    teacher_id: int,
    photo: UploadFile = File(...),
    user: dict = StaffDep,
):
    if not fetch_one("SELECT Id FROM Teacher WHERE Id = ?", (teacher_id,)):
        raise _not_found("Teacher")
    data, mime = await _read_teacher_photo(photo)
    execute(
        "UPDATE Teacher SET Photo = ?, PhotoMime = ? WHERE Id = ?",
        (data, mime, teacher_id),
    )
    return {"message": "Teacher photo updated", "id": teacher_id, "has_photo": True}


@app.delete("/teachers/{teacher_id}/photo")
async def delete_teacher_photo(teacher_id: int, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM Teacher WHERE Id = ?", (teacher_id,)):
        raise _not_found("Teacher")
    execute("UPDATE Teacher SET Photo = NULL, PhotoMime = NULL WHERE Id = ?", (teacher_id,))
    return {"message": "Teacher photo removed", "id": teacher_id, "has_photo": False}


@app.post("/teachers", status_code=201)
async def create_teacher(body: TeacherCreate, user: dict = StaffDep):
    if fetch_one("SELECT Id FROM Teacher WHERE NationalCode = ?", (body.national_code,)):
        raise _bad_request("کد ملی مدرس تکراری است")
    try:
        new_id = execute_returning_id(
            """INSERT INTO Teacher
                ([FirstName], [LastName], [FatherName], [NationalCode], [Gender],
                 [BirthDate], [Mobile], [Email], [Specialty], [Bio])
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                body.first_name,
                body.last_name,
                body.father_name,
                body.national_code,
                body.gender,
                body.birth_date,
                body.mobile,
                body.email,
                body.specialty,
                body.bio,
            ),
        )
    except pyodbc.IntegrityError as exc:
        msg = str(exc)
        if "کد ملی" in msg or "NationalCode" in msg:
            raise _bad_request("کد ملی نامعتبر است") from exc
        raise _bad_request("ثبت مدرس با محدودیت‌های دیتابیس سازگار نیست") from exc
    return {"message": "Teacher created", "id": new_id}


@app.put("/teachers/{teacher_id}")
async def update_teacher(teacher_id: int, body: TeacherUpdate, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM Teacher WHERE Id = ?", (teacher_id,)):
        raise _not_found("Teacher")
    data = body.model_dump(exclude_unset=True)
    if "national_code" in data and data["national_code"]:
        dup = fetch_one(
            "SELECT Id FROM Teacher WHERE NationalCode = ? AND Id <> ?",
            (data["national_code"], teacher_id),
        )
        if dup:
            raise _bad_request("کد ملی مدرس تکراری است")
    if "is_makeup" in data:
        pass
    try:
        _partial_update(
            "Teacher",
            teacher_id,
            {
                "first_name": "FirstName",
                "last_name": "LastName",
                "father_name": "FatherName",
                "national_code": "NationalCode",
                "gender": "Gender",
                "birth_date": "BirthDate",
                "mobile": "Mobile",
                "email": "Email",
                "specialty": "Specialty",
                "bio": "Bio",
            },
            data,
        )
    except pyodbc.IntegrityError as exc:
        msg = str(exc)
        if "کد ملی" in msg or "NationalCode" in msg:
            raise _bad_request("کد ملی نامعتبر است") from exc
        raise _bad_request("ویرایش مدرس با محدودیت‌های دیتابیس سازگار نیست") from exc
    return {"message": "Teacher updated", "id": teacher_id}


@app.delete("/teachers/{teacher_id}")
async def archive_teacher(teacher_id: int, user: dict = StaffDep):
    """حذف نرم مدرس — BR-022"""
    if not fetch_one("SELECT Id FROM Teacher WHERE Id = ?", (teacher_id,)):
        raise _not_found("Teacher")
    execute("UPDATE Teacher SET IsActive = 0 WHERE Id = ?", (teacher_id,))
    return {"message": "Teacher archived (soft delete)", "id": teacher_id}


# ---------------------------------------------------------------------------
# Students
# ---------------------------------------------------------------------------

@app.get("/students")
async def list_students(search: Optional[str] = None, include_inactive: bool = False, user: dict = StudentsReadDep):
    query = """
        SELECT S.Id, S.FirstName, S.LastName, S.FatherName, S.NationalCode, S.Gender,
               S.BirthDate, S.Mobile, S.Email, S.TargetLanguageRef, S.CurrentLevelRef,
               S.PreferredUILanguage, S.NotificationsEnabled, S.IsActive, S.Creator, S.CreatedAt,
               L.Name AS TargetLanguageName, Lv.Name AS CurrentLevelName
        FROM Student S
        LEFT JOIN Language L ON S.TargetLanguageRef = L.Id
        LEFT JOIN Level Lv ON S.CurrentLevelRef = Lv.Id
        WHERE 1=1
    """
    params: list[Any] = []
    if not include_inactive:
        query += " AND S.IsActive = 1"
    if search:
        query += " AND (S.FirstName + N' ' + S.LastName LIKE ? OR S.NationalCode LIKE ? OR S.Mobile LIKE ?)"
        params.extend([f"%{search}%", f"%{search}%", f"%{search}%"])
    query += " ORDER BY S.LastName, S.FirstName"
    return _ok_list("students", fetch_all(query, tuple(params)))


@app.get("/students/{student_id}")
async def get_student(student_id: int, user: dict = AuthDep):
    row = fetch_one(
        """SELECT S.Id, S.FirstName, S.LastName, S.FatherName, S.NationalCode, S.Gender,
                  S.BirthDate, S.Mobile, S.Email, S.TargetLanguageRef, S.CurrentLevelRef,
                  S.PreferredUILanguage, S.NotificationsEnabled, S.IsActive,
                  L.Name AS TargetLanguageName, Lv.Name AS CurrentLevelName
           FROM Student S
           LEFT JOIN Language L ON S.TargetLanguageRef = L.Id
           LEFT JOIN Level Lv ON S.CurrentLevelRef = Lv.Id
           WHERE S.Id = ?""",
        (student_id,),
    )
    if not row:
        raise _not_found("Student")
    return {"student": row}


@app.post("/students", status_code=201)
async def create_student(body: StudentCreate, user: dict = StaffDep):
    if not body.mobile:
        raise _bad_request("شماره تماس الزامی است (BR-009)")
    if fetch_one("SELECT Id FROM Student WHERE NationalCode = ?", (body.national_code,)):
        raise _bad_request("کد ملی دانشجو تکراری است")
    try:
        new_id = execute_returning_id(
            """INSERT INTO Student
                ([FirstName], [LastName], [FatherName], [NationalCode], [Gender],
                 [BirthDate], [Mobile], [Email], [TargetLanguageRef], [CurrentLevelRef],
                 [PreferredUILanguage], [NotificationsEnabled])
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                body.first_name,
                body.last_name,
                body.father_name,
                body.national_code,
                body.gender,
                body.birth_date,
                body.mobile,
                body.email,
                body.target_language_ref,
                body.current_level_ref,
                body.preferred_ui_language,
                1 if body.notifications_enabled else 0,
            ),
        )
    except pyodbc.IntegrityError as exc:
        msg = str(exc)
        if "کد ملی" in msg or "NationalCode" in msg:
            raise _bad_request("کد ملی نامعتبر است") from exc
        raise _bad_request("ثبت دانشجو با محدودیت‌های دیتابیس سازگار نیست") from exc
    return {"message": "Student created", "id": new_id}


@app.put("/students/{student_id}")
async def update_student(student_id: int, body: StudentUpdate, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM Student WHERE Id = ?", (student_id,)):
        raise _not_found("Student")
    data = body.model_dump(exclude_unset=True)
    if "national_code" in data and data["national_code"]:
        dup = fetch_one(
            "SELECT Id FROM Student WHERE NationalCode = ? AND Id <> ?",
            (data["national_code"], student_id),
        )
        if dup:
            raise _bad_request("کد ملی دانشجو تکراری است")
    if "notifications_enabled" in data and data["notifications_enabled"] is not None:
        data["notifications_enabled"] = 1 if data["notifications_enabled"] else 0
    try:
        _partial_update(
            "Student",
            student_id,
            {
                "first_name": "FirstName",
                "last_name": "LastName",
                "father_name": "FatherName",
                "national_code": "NationalCode",
                "gender": "Gender",
                "birth_date": "BirthDate",
                "mobile": "Mobile",
                "email": "Email",
                "target_language_ref": "TargetLanguageRef",
                "current_level_ref": "CurrentLevelRef",
                "preferred_ui_language": "PreferredUILanguage",
                "notifications_enabled": "NotificationsEnabled",
            },
            data,
        )
    except pyodbc.IntegrityError as exc:
        msg = str(exc)
        if "کد ملی" in msg or "NationalCode" in msg:
            raise _bad_request("کد ملی نامعتبر است") from exc
        raise _bad_request("ویرایش دانشجو با محدودیت‌های دیتابیس سازگار نیست") from exc
    return {"message": "Student updated", "id": student_id}


@app.delete("/students/{student_id}")
async def archive_student(student_id: int, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM Student WHERE Id = ?", (student_id,)):
        raise _not_found("Student")
    execute("UPDATE Student SET IsActive = 0 WHERE Id = ?", (student_id,))
    return {"message": "Student archived (soft delete)", "id": student_id}


def _hard_delete_students(ids: list[int]) -> dict[str, Any]:
    """حذف فیزیکی زبان‌آموز و وابستگی‌ها در یک تراکنش"""
    if not ids:
        return {"deleted": 0, "ids": []}
    placeholders = ",".join("?" for _ in ids)
    params = tuple(ids)
    with db_cursor() as cursor:
        cursor.execute(
            f"SELECT Id FROM Student WHERE Id IN ({placeholders})",
            params,
        )
        existing = [int(r[0]) for r in cursor.fetchall()]
        if not existing:
            return {"deleted": 0, "ids": []}

        ex_ph = ",".join("?" for _ in existing)
        ex_params = tuple(existing)

        cursor.execute(
            f"SELECT Id FROM Registration WHERE Studentref IN ({ex_ph})",
            ex_params,
        )
        reg_ids = [int(r[0]) for r in cursor.fetchall()]

        # حضور و غیاب
        cursor.execute(
            f"DELETE FROM SessionStudent WHERE StudentRef IN ({ex_ph})",
            ex_params,
        )

        # نمرات متصل به زبان‌آموز یا ثبت‌نام‌هایش
        if reg_ids:
            reg_ph = ",".join("?" for _ in reg_ids)
            cursor.execute(
                f"""DELETE FROM Score
                    WHERE StudentRef IN ({ex_ph})
                       OR RegistrationRef IN ({reg_ph})""",
                ex_params + tuple(reg_ids),
            )
            # نمرات فقط با RegistrationRef (بدون StudentRef)
            cursor.execute(
                f"DELETE FROM Score WHERE RegistrationRef IN ({reg_ph})",
                tuple(reg_ids),
            )
        else:
            cursor.execute(
                f"DELETE FROM Score WHERE StudentRef IN ({ex_ph})",
                ex_params,
            )

        # پرداخت‌ها (زبان‌آموز یا ثبت‌نام مرتبط)
        if reg_ids:
            reg_ph = ",".join("?" for _ in reg_ids)
            cursor.execute(
                f"""DELETE FROM Payment
                    WHERE StudentRef IN ({ex_ph})
                       OR RegistrationRef IN ({reg_ph})""",
                ex_params + tuple(reg_ids),
            )
        else:
            cursor.execute(
                f"DELETE FROM Payment WHERE StudentRef IN ({ex_ph})",
                ex_params,
            )

        # ثبت‌نام‌ها
        if reg_ids:
            cursor.execute(
                f"DELETE FROM Score WHERE RegistrationRef IN ({','.join('?' for _ in reg_ids)})",
                tuple(reg_ids),
            )
            cursor.execute(
                f"DELETE FROM Registration WHERE Id IN ({','.join('?' for _ in reg_ids)})",
                tuple(reg_ids),
            )

        # قطع ارتباط حساب کاربری
        cursor.execute(
            f"UPDATE AppUser SET StudentRef = NULL WHERE StudentRef IN ({ex_ph})",
            ex_params,
        )

        cursor.execute(
            f"DELETE FROM Student WHERE Id IN ({ex_ph})",
            ex_params,
        )
        deleted = cursor.rowcount
    return {"deleted": deleted if deleted >= 0 else len(existing), "ids": existing}


@app.post("/students/bulk-delete")
async def bulk_delete_students(body: StudentBulkDelete, user: dict = StaffDep):
    """حذف گروهی و قطعی زبان‌آموزان از پایگاه داده"""
    try:
        result = _hard_delete_students(body.ids)
    except pyodbc.IntegrityError as exc:
        raise _bad_request(
            "حذف ممکن نیست؛ برخی وابستگی‌ها مانع حذف شده‌اند. ابتدا داده‌های مرتبط را بررسی کنید."
        ) from exc
    if not result["deleted"]:
        raise _not_found("Student")
    return {
        "message": f"{result['deleted']} زبان‌آموز از پایگاه داده حذف شد",
        "deleted": result["deleted"],
        "ids": result["ids"],
    }


# ---------------------------------------------------------------------------
# Classes
# ---------------------------------------------------------------------------

CLASS_SELECT = """
    SELECT
        Cl.Id, Cl.CourseRef, C.Name AS CourseName,
        Cl.TeacherRef, T.FirstName + N' ' + T.LastName AS TeacherName,
        Cl.SessionTypeRef, ST.Name AS SessionTypeName,
        Cl.StartDate, Cl.EndDate, Cl.Capacity, Cl.Status, Cl.CancelReason,
        Cl.ClassType, Cl.BranchRef, B.Name AS BranchName,
        Cl.LocationAddress, Cl.MeetingLink, Cl.CreatedAt,
        (SELECT COUNT(*) FROM Registration R
         WHERE R.ClassRef = Cl.Id AND R.Status IN ('active', 'pending_payment', 'pending_approval'))
         AS EnrolledCount
    FROM Class Cl
    JOIN Course C ON Cl.CourseRef = C.Id
    JOIN Teacher T ON Cl.TeacherRef = T.Id
    JOIN SessionType ST ON Cl.SessionTypeRef = ST.Id
    LEFT JOIN Branch B ON Cl.BranchRef = B.Id
"""


def _validate_class_location(session_type_ref: int, location_address: Optional[str], meeting_link: Optional[str]):
    st = fetch_one("SELECT Id, Name FROM SessionType WHERE Id = ?", (session_type_ref,))
    if not st:
        raise _bad_request("SessionType نامعتبر است (BR-015)")
    name = (st["Name"] or "").strip()
    if name == "حضوری" and not location_address:
        raise _bad_request("کلاس حضوری نیاز به آدرس/مکان دارد (BR-006)")
    if name == "آنلاین" and not meeting_link:
        raise _bad_request("کلاس آنلاین نیاز به لینک جلسه دارد (BR-006)")


@app.get("/classes")
async def list_classes(
    course_ref: Optional[int] = None,
    teacher_ref: Optional[int] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
):
    query = CLASS_SELECT + " WHERE 1=1"
    params: list[Any] = []
    if course_ref is not None:
        query += " AND Cl.CourseRef = ?"
        params.append(course_ref)
    if teacher_ref is not None:
        query += " AND Cl.TeacherRef = ?"
        params.append(teacher_ref)
    if status:
        query += " AND Cl.Status = ?"
        params.append(status)
    if search:
        query += " AND C.Name LIKE ?"
        params.append(f"%{search}%")
    query += " ORDER BY Cl.Id DESC"
    return _ok_list("classes", fetch_all(query, tuple(params)))


@app.get("/classes/{class_id}")
async def get_class(class_id: int):
    row = fetch_one(CLASS_SELECT + " WHERE Cl.Id = ?", (class_id,))
    if not row:
        raise _not_found("Class")
    stats = _compute_class_stats(class_id, row)
    recent_sessions = fetch_all(
        """SELECT TOP 12
               S.Id, S.[Date] AS SessionDate, S.StartTime, S.EndTime, S.Status, S.IsMakeup
           FROM Session S
           WHERE S.ClassRef = ?
           ORDER BY S.[Date] DESC, S.Id DESC""",
        (class_id,),
    )
    return {"class": row, "stats": stats, "recent_sessions": recent_sessions}


@app.post("/classes", status_code=201)
async def create_class(body: ClassCreate, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM Course WHERE Id = ? AND IsActive = 1", (body.course_ref,)):
        raise _bad_request("دوره معتبر/فعال نیست (BR-004)")
    if not fetch_one("SELECT Id FROM Teacher WHERE Id = ? AND IsActive = 1", (body.teacher_ref,)):
        raise _bad_request("مدرس معتبر/فعال نیست (BR-004 / BR-008)")
    _validate_class_location(body.session_type_ref, body.location_address, body.meeting_link)

    start_date = _reject_past_jalali_date(body.start_date, entity="کلاس")
    end_date = _normalize_jalali_date(body.end_date)
    if end_date < start_date:
        raise _bad_request("تاریخ پایان کلاس نباید قبل از تاریخ شروع باشد")

    new_id = execute_returning_id(
        """INSERT INTO Class
            ([CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate],
             [Capacity], [Status], [ClassType], [BranchRef], [LocationAddress], [MeetingLink])
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            body.course_ref,
            body.teacher_ref,
            body.session_type_ref,
            start_date,
            end_date,
            body.capacity,
            body.status,
            body.class_type,
            body.branch_ref,
            body.location_address,
            body.meeting_link,
        ),
    )
    return {"message": "Class created", "id": new_id}


@app.put("/classes/{class_id}")
async def update_class(class_id: int, body: ClassUpdate, user: dict = StaffDep):
    current = fetch_one("SELECT * FROM Class WHERE Id = ?", (class_id,))
    if not current:
        raise _not_found("Class")
    if body.status == "cancelled" and not body.cancel_reason:
        raise _bad_request("لغو کلاس بدون دلیل مجاز نیست (BR-024)")

    fields: list[str] = []
    params: list[Any] = []
    column_map = {
        "teacher_ref": "TeacherRef",
        "session_type_ref": "SessionTypeRef",
        "start_date": "StartDate",
        "end_date": "EndDate",
        "capacity": "Capacity",
        "status": "Status",
        "cancel_reason": "CancelReason",
        "class_type": "ClassType",
        "branch_ref": "BranchRef",
        "location_address": "LocationAddress",
        "meeting_link": "MeetingLink",
    }
    data = body.model_dump(exclude_unset=True)
    if "start_date" in data and data["start_date"]:
        data["start_date"] = _normalize_jalali_date(data["start_date"])
        old_raw = current.get("StartDate")
        old_start = _normalize_jalali_date(str(old_raw)) if old_raw else None
        if data["start_date"] != old_start:
            _reject_past_jalali_date(data["start_date"], entity="کلاس")
    if "end_date" in data and data["end_date"]:
        data["end_date"] = _normalize_jalali_date(data["end_date"])

    start_date = data.get("start_date", current.get("StartDate"))
    end_date = data.get("end_date", current.get("EndDate"))
    if start_date and end_date:
        start_n = _normalize_jalali_date(str(start_date))
        end_n = _normalize_jalali_date(str(end_date))
        if end_n < start_n:
            raise _bad_request("تاریخ پایان کلاس نباید قبل از تاریخ شروع باشد")

    for key, col in column_map.items():
        if key in data:
            fields.append(f"[{col}] = ?")
            params.append(data[key])
    if not fields:
        raise _bad_request("هیچ فیلدی برای به‌روزرسانی ارسال نشده است")
    params.append(class_id)
    execute(f"UPDATE Class SET {', '.join(fields)} WHERE Id = ?", tuple(params))
    return {"message": "Class updated", "id": class_id}


@app.delete("/classes/{class_id}")
async def cancel_class(class_id: int, user: dict = StaffDep):
    """حذف منطقی کلاس = لغو"""
    if not fetch_one("SELECT Id FROM Class WHERE Id = ?", (class_id,)):
        raise _not_found("Class")
    execute(
        "UPDATE Class SET Status = N'cancelled', CancelReason = N'حذف توسط کاربر' WHERE Id = ?",
        (class_id,),
    )
    return {"message": "Class cancelled", "id": class_id}


# ---------------------------------------------------------------------------
# Sessions
# ---------------------------------------------------------------------------

SESSION_SELECT = """
    SELECT
        S.Id, S.ClassRef, S.Date, S.StartTime, S.EndTime,
        S.SessionTypeRef, ST.Name AS SessionTypeName,
        S.Status, S.CancelReason, S.MeetingLink, S.LocationAddress,
        S.SubstituteTeacherRef, S.IsMakeup, S.Notes,
        Cl.CourseRef, C.Name AS CourseName,
        Cl.TeacherRef, T.FirstName + N' ' + T.LastName AS TeacherName
    FROM Session S
    JOIN SessionType ST ON S.SessionTypeRef = ST.Id
    JOIN Class Cl ON S.ClassRef = Cl.Id
    JOIN Course C ON Cl.CourseRef = C.Id
    JOIN Teacher T ON Cl.TeacherRef = T.Id
"""


@app.get("/sessions")
async def list_sessions(
    class_ref: Optional[int] = None,
    teacher_ref: Optional[int] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
    from_date: Optional[str] = Query(None, pattern=r"^\d{4}/\d{2}/\d{2}$"),
    to_date: Optional[str] = Query(None, pattern=r"^\d{4}/\d{2}/\d{2}$"),
):
    query = SESSION_SELECT + " WHERE 1=1"
    params: list[Any] = []
    if class_ref is not None:
        query += " AND S.ClassRef = ?"
        params.append(class_ref)
    if teacher_ref is not None:
        query += " AND Cl.TeacherRef = ?"
        params.append(teacher_ref)
    if status:
        query += " AND S.Status = ?"
        params.append(status)
    if search:
        query += " AND (C.Name LIKE ? OR CAST(S.Id AS NVARCHAR(20)) LIKE ? OR S.Date LIKE ?)"
        like = f"%{search}%"
        params.extend([like, like, like])
    if from_date:
        query += " AND S.Date >= ?"
        params.append(from_date)
    if to_date:
        query += " AND S.Date <= ?"
        params.append(to_date)
    query += " ORDER BY S.Date, S.StartTime"
    return _ok_list("sessions", fetch_all(query, tuple(params)))


@app.get("/sessions/{session_id}")
async def get_session(session_id: int):
    row = fetch_one(SESSION_SELECT + " WHERE S.Id = ?", (session_id,))
    if not row:
        raise _not_found("Session")
    return {"session": row}


@app.post("/sessions", status_code=201)
async def create_session(body: SessionCreate, user: dict = StaffDep):
    class_row = fetch_one("SELECT Id, SessionTypeRef, LocationAddress, MeetingLink FROM Class WHERE Id = ?", (body.class_ref,))
    if not class_row:
        raise _bad_request("کلاس معتبر نیست (BR-005)")
    if not fetch_one("SELECT Id FROM SessionType WHERE Id = ?", (body.session_type_ref,)):
        raise _bad_request("SessionType نامعتبر است (BR-015)")
    if body.start_time >= body.end_time:
        raise _bad_request("ساعت پایان باید بعد از شروع باشد")

    session_date = _reject_past_jalali_date(body.date, entity="جلسه")

    # تداخل زمانی مدرس کلاس (BR-020)
    overlap = fetch_one(
        """SELECT S.Id
           FROM Session S
           JOIN Class Cl ON S.ClassRef = Cl.Id
           WHERE Cl.TeacherRef = (SELECT TeacherRef FROM Class WHERE Id = ?)
             AND S.Date = ?
             AND S.Status NOT IN ('cancelled')
             AND S.StartTime < ? AND S.EndTime > ?""",
        (body.class_ref, session_date, body.end_time, body.start_time),
    )
    if overlap:
        raise _bad_request("تداخل زمانی با جلسه دیگر مدرس وجود دارد (BR-020)")

    location = body.location_address or class_row.get("LocationAddress")
    link = body.meeting_link or class_row.get("MeetingLink")

    new_id = execute_returning_id(
        """INSERT INTO Session
            ([ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef],
             [Status], [MeetingLink], [LocationAddress], [IsMakeup], [Notes])
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            body.class_ref,
            session_date,
            body.start_time,
            body.end_time,
            body.session_type_ref,
            body.status,
            link,
            location,
            1 if body.is_makeup else 0,
            body.notes,
        ),
    )
    return {"message": "Session created", "id": new_id}


@app.put("/sessions/{session_id}")
async def update_session(session_id: int, body: SessionUpdate, user: dict = StaffDep):
    existing = fetch_one("SELECT Id, Date FROM Session WHERE Id = ?", (session_id,))
    if not existing:
        raise _not_found("Session")
    if body.status == "cancelled" and not body.cancel_reason:
        raise _bad_request("لغو جلسه بدون دلیل مجاز نیست (BR-024)")

    fields: list[str] = []
    params: list[Any] = []
    column_map = {
        "date": "Date",
        "start_time": "StartTime",
        "end_time": "EndTime",
        "session_type_ref": "SessionTypeRef",
        "status": "Status",
        "cancel_reason": "CancelReason",
        "meeting_link": "MeetingLink",
        "location_address": "LocationAddress",
        "substitute_teacher_ref": "SubstituteTeacherRef",
        "is_makeup": "IsMakeup",
        "notes": "Notes",
    }
    data = body.model_dump(exclude_unset=True)
    if "date" in data and data["date"] is not None:
        new_date = _normalize_jalali_date(data["date"])
        existing_date = _normalize_jalali_date(str(existing["Date"]))
        today = _today_jalali()
        # تاریخ گذشته فقط اگر همان تاریخ قبلی باشد قابل نگه‌داشتن است؛ انتقال به گذشته ممنوع
        if new_date < today and new_date != existing_date:
            raise _bad_request("تغییر تاریخ جلسه به گذشته مجاز نیست (BR-021)")
        data["date"] = new_date
    if data.get("start_time") and data.get("end_time") and data["start_time"] >= data["end_time"]:
        raise _bad_request("ساعت پایان باید بعد از شروع باشد")
    for key, col in column_map.items():
        if key in data:
            val = data[key]
            if key == "is_makeup" and val is not None:
                val = 1 if val else 0
            fields.append(f"[{col}] = ?")
            params.append(val)
    if not fields:
        raise _bad_request("هیچ فیلدی برای به‌روزرسانی ارسال نشده است")
    params.append(session_id)
    execute(f"UPDATE Session SET {', '.join(fields)} WHERE Id = ?", tuple(params))
    return {"message": "Session updated", "id": session_id}


@app.delete("/sessions/{session_id}")
async def cancel_session(session_id: int, user: dict = StaffDep):
    """حذف منطقی جلسه = لغو"""
    if not fetch_one("SELECT Id FROM Session WHERE Id = ?", (session_id,)):
        raise _not_found("Session")
    execute(
        "UPDATE Session SET Status = N'cancelled', CancelReason = N'حذف توسط کاربر' WHERE Id = ?",
        (session_id,),
    )
    return {"message": "Session cancelled", "id": session_id}


# ---------------------------------------------------------------------------
# Attendance
# ---------------------------------------------------------------------------

@app.get("/attendance")
async def list_attendance(session_ref: Optional[int] = None, student_ref: Optional[int] = None, user: dict = TeacherStaffDep):
    query = """
        SELECT SS.Id, SS.SessionRef, SS.StudentRef, SS.AttendanceStatus, SS.RecordedAt,
               St.FirstName + N' ' + St.LastName AS StudentName,
               S.Date AS SessionDate, S.StartTime, S.EndTime
        FROM SessionStudent SS
        JOIN Student St ON SS.StudentRef = St.Id
        JOIN Session S ON SS.SessionRef = S.Id
        WHERE 1=1
    """
    params: list[Any] = []
    if session_ref is not None:
        query += " AND SS.SessionRef = ?"
        params.append(session_ref)
    if student_ref is not None:
        query += " AND SS.StudentRef = ?"
        params.append(student_ref)
    query += " ORDER BY S.Date DESC, St.LastName"
    return _ok_list("attendance", fetch_all(query, tuple(params)))


@app.post("/attendance", status_code=201)
async def create_attendance(body: AttendanceCreate, user: dict = TeacherStaffDep):
    if not fetch_one("SELECT Id FROM Session WHERE Id = ?", (body.session_ref,)):
        raise _bad_request("جلسه معتبر نیست")
    if not fetch_one("SELECT Id FROM Student WHERE Id = ?", (body.student_ref,)):
        raise _bad_request("دانشجو معتبر نیست")
    existing = fetch_one(
        "SELECT Id FROM SessionStudent WHERE SessionRef = ? AND StudentRef = ?",
        (body.session_ref, body.student_ref),
    )
    if existing:
        execute(
            """UPDATE SessionStudent
               SET AttendanceStatus = ?, RecordedAt = SYSUTCDATETIME()
               WHERE Id = ?""",
            (body.attendance_status, existing["Id"]),
        )
        return {"message": "Attendance updated", "id": existing["Id"]}

    new_id = execute_returning_id(
        """INSERT INTO SessionStudent ([SessionRef], [StudentRef], [AttendanceStatus])
           VALUES (?, ?, ?)""",
        (body.session_ref, body.student_ref, body.attendance_status),
    )
    return {"message": "Attendance created", "id": new_id}


@app.post("/attendance/bulk", status_code=201)
async def bulk_attendance(body: AttendanceBulkCreate, user: dict = TeacherStaffDep):
    if not fetch_one("SELECT Id FROM Session WHERE Id = ?", (body.session_ref,)):
        raise _bad_request("جلسه معتبر نیست")
    results = []
    for item in body.items:
        existing = fetch_one(
            "SELECT Id FROM SessionStudent WHERE SessionRef = ? AND StudentRef = ?",
            (body.session_ref, item.student_ref),
        )
        if existing:
            execute(
                """UPDATE SessionStudent
                   SET AttendanceStatus = ?, RecordedAt = SYSUTCDATETIME()
                   WHERE Id = ?""",
                (item.attendance_status, existing["Id"]),
            )
            results.append({"id": existing["Id"], "student_ref": item.student_ref, "action": "updated"})
        else:
            new_id = execute_returning_id(
                """INSERT INTO SessionStudent ([SessionRef], [StudentRef], [AttendanceStatus])
                   VALUES (?, ?, ?)""",
                (body.session_ref, item.student_ref, item.attendance_status),
            )
            results.append({"id": new_id, "student_ref": item.student_ref, "action": "created"})
    return {"message": "Bulk attendance saved", "results": results}


@app.get("/sessions/{session_id}/roster")
async def session_roster(session_id: int, user: dict = TeacherStaffDep):
    """لیست زبان‌آموزان کلاس برای ثبت حضور و غیاب جلسه"""
    session = fetch_one(
        SESSION_SELECT + " WHERE S.Id = ?",
        (session_id,),
    )
    if not session:
        raise _not_found("Session")

    students = fetch_all(
        """SELECT
               St.Id AS StudentRef,
               St.FirstName + N' ' + St.LastName AS StudentName,
               R.Status AS EnrollmentStatus,
               SS.AttendanceStatus,
               SS.RecordedAt
           FROM Registration R
           JOIN Student St ON R.Studentref = St.Id
           LEFT JOIN SessionStudent SS
               ON SS.SessionRef = ? AND SS.StudentRef = St.Id
           WHERE R.ClassRef = ?
             AND R.Status IN (N'active', N'pending_payment', N'pending_approval', N'frozen')
           ORDER BY St.LastName, St.FirstName""",
        (session_id, session["ClassRef"]),
    )
    return {
        "session": {
            "Id": session["Id"],
            "ClassRef": session["ClassRef"],
            "CourseName": session.get("CourseName"),
            "TeacherName": session.get("TeacherName"),
            "Date": session.get("Date"),
            "StartTime": session.get("StartTime"),
            "EndTime": session.get("EndTime"),
            "Status": session.get("Status"),
        },
        "students": students,
        "count": len(students),
    }


# ---------------------------------------------------------------------------
# Enrollments (Registration)
# ---------------------------------------------------------------------------

ENROLLMENT_SELECT = """
    SELECT
        R.Id, R.Studentref AS StudentRef, R.CourseRef, R.ClassRef, R.Date,
        R.Status, R.WithdrawReason, R.FinancialStatus, R.CreatedAt,
        Stud.FirstName + N' ' + Stud.LastName AS StudentName,
        C.Name AS CourseName,
        C.Cost AS CourseCost,
        C.SessionsCount AS CourseSessionsCount,
        C.TeachingMethod,
        C.LanguageRef,
        Lang.Name AS LanguageName,
        C.LevelRef,
        Lv.Name AS LevelName,
        Lv.Code AS LevelCode,
        Cl.Capacity AS ClassCapacity,
        Cl.Status AS ClassStatus,
        Cl.StartDate AS ClassStartDate,
        Cl.EndDate AS ClassEndDate,
        Cl.TeacherRef,
        Tch.FirstName + N' ' + Tch.LastName AS TeacherName,
        Cl.SessionTypeRef,
        SType.Name AS SessionTypeName,
        Cl.BranchRef,
        Br.Name AS BranchName,
        ISNULL((
            SELECT SUM(Pay.Amount) FROM Payment Pay
            WHERE Pay.RegistrationRef = R.Id AND Pay.Status = N'paid'
        ), 0) AS PaidAmount
    FROM Registration R
    JOIN Student Stud ON R.Studentref = Stud.Id
    JOIN Course C ON R.CourseRef = C.Id
    JOIN Language Lang ON C.LanguageRef = Lang.Id
    LEFT JOIN Level Lv ON C.LevelRef = Lv.Id
    LEFT JOIN Class Cl ON R.ClassRef = Cl.Id
    LEFT JOIN Teacher Tch ON Cl.TeacherRef = Tch.Id
    LEFT JOIN SessionType SType ON Cl.SessionTypeRef = SType.Id
    LEFT JOIN Branch Br ON Cl.BranchRef = Br.Id
"""


def _enrollment_list_roles(user: dict[str, Any]) -> set[str]:
    return _user_role_set(user)


def _can_list_all_enrollments(user: dict[str, Any]) -> bool:
    return bool(
        _enrollment_list_roles(user)
        & {"admin", "secretary", "education", "finance", "teacher"}
    )


def _list_enrollments_rows(
    *,
    student_ref: Optional[int] = None,
    class_ref: Optional[int] = None,
    course_ref: Optional[int] = None,
    status: Optional[str] = None,
    financial_status: Optional[str] = None,
    balance_filter: Optional[str] = None,
    search: Optional[str] = None,
    include_withdrawn: bool = False,
) -> list[dict[str, Any]]:
    query = ENROLLMENT_SELECT + " WHERE 1=1"
    params: list[Any] = []
    if student_ref is not None:
        query += " AND R.Studentref = ?"
        params.append(student_ref)
    if class_ref is not None:
        query += " AND R.ClassRef = ?"
        params.append(class_ref)
    if course_ref is not None:
        query += " AND R.CourseRef = ?"
        params.append(course_ref)
    if status:
        query += " AND R.Status = ?"
        params.append(status)
    elif not include_withdrawn:
        # حذف منطقی = withdrawn؛ از لیست پیش‌فرض پنهان می‌شود تا مثل حذف واقعی دیده شود
        query += " AND R.Status <> N'withdrawn'"
    if financial_status:
        fs = financial_status.strip().lower()
        if fs == "partial":
            fs = "debtor"
        if fs in ("debtor", "creditor", "settled"):
            query += " AND R.FinancialStatus = ?"
            params.append(fs)
    if search:
        query += """ AND (
            Stud.FirstName + N' ' + Stud.LastName LIKE ?
            OR C.Name LIKE ?
            OR CAST(R.Id AS NVARCHAR(20)) LIKE ?
            OR CAST(R.ClassRef AS NVARCHAR(20)) LIKE ?
        )"""
        like = f"%{search}%"
        params.extend([like, like, like, like])
    query += " ORDER BY R.Id DESC"
    raw = fetch_all(query, tuple(params))
    rows = apply_unallocated_payments(raw)

    bf = (balance_filter or "").strip().lower()
    if bf in ("debtor", "creditor", "settled", "nonzero"):
        filtered: list[dict[str, Any]] = []
        for r in rows:
            bal = float(r.get("Balance") or 0)
            derived = r.get("DerivedFinancialStatus") or (
                "debtor" if bal < 0 else "creditor" if bal > 0 else "settled"
            )
            if bf == "nonzero" and bal != 0:
                filtered.append(r)
            elif bf == derived:
                filtered.append(r)
        rows = filtered
    return rows


@app.get("/me/enrollments")
async def my_enrollments(
    status: Optional[str] = None,
    balance_filter: Optional[str] = None,
    user: dict = AuthDep,
):
    """دوره‌ها / ثبت‌نام‌های زبان‌آموز جاری"""
    student_ref = user.get("StudentRef")
    if not student_ref:
        raise HTTPException(
            status_code=403,
            detail="حساب شما به پروفایل زبان‌آموز متصل نیست",
        )
    rows = _list_enrollments_rows(
        student_ref=int(student_ref),
        status=status,
        balance_filter=balance_filter,
    )
    return _ok_list("enrollments", rows)


def _require_teacher_ref(user: dict[str, Any]) -> int:
    tid = user.get("TeacherRef")
    if not tid:
        raise HTTPException(
            status_code=403,
            detail="حساب شما به پروفایل مدرس متصل نیست",
        )
    return int(tid)


@app.get("/me/teaching/summary")
async def my_teaching_summary(user: dict = AuthDep):
    """خلاصه داشبورد مدرس: کلاس‌ها، دوره‌ها، زبان‌آموزان، جلسات"""
    teacher_ref = _require_teacher_ref(user)

    classes = fetch_all(CLASS_SELECT + " WHERE Cl.TeacherRef = ? ORDER BY Cl.Id DESC", (teacher_ref,))
    class_ids = [int(c["Id"]) for c in classes]
    active_classes = [
        c for c in classes if (c.get("Status") or "") in ("open", "in_progress", "full")
    ]

    courses_map: dict[int, dict[str, Any]] = {}
    for c in classes:
        cid = int(c["CourseRef"])
        if cid not in courses_map:
            courses_map[cid] = {
                "Id": cid,
                "Name": c.get("CourseName"),
                "ClassCount": 0,
                "Statuses": set(),
            }
        courses_map[cid]["ClassCount"] += 1
        courses_map[cid]["Statuses"].add(c.get("Status"))

    courses = []
    for c in courses_map.values():
        courses.append(
            {
                "Id": c["Id"],
                "Name": c["Name"],
                "ClassCount": c["ClassCount"],
                "Statuses": sorted(s for s in c["Statuses"] if s),
            }
        )

    students: list[dict[str, Any]] = []
    if class_ids:
        ph = ",".join("?" for _ in class_ids)
        students = fetch_all(
            f"""
            SELECT DISTINCT
                St.Id, St.FirstName, St.LastName, St.Mobile, St.NationalCode,
                R.ClassRef, Cl.CourseRef, C.Name AS CourseName,
                R.Status AS EnrollmentStatus
            FROM Registration R
            JOIN Student St ON R.Studentref = St.Id
            JOIN Class Cl ON R.ClassRef = Cl.Id
            JOIN Course C ON Cl.CourseRef = C.Id
            WHERE Cl.TeacherRef = ?
              AND R.ClassRef IN ({ph})
              AND R.Status IN (N'active', N'pending_payment', N'pending_approval', N'frozen')
            ORDER BY St.LastName, St.FirstName
            """,
            (teacher_ref, *class_ids),
        )

    # یکتا بر اساس دانشجو (اولین کلاس)
    uniq_students: dict[int, dict[str, Any]] = {}
    for s in students:
        sid = int(s["Id"])
        if sid not in uniq_students:
            uniq_students[sid] = s

    upcoming_sessions: list[dict[str, Any]] = []
    recent_sessions: list[dict[str, Any]] = []
    attendance_marked = 0
    if class_ids:
        ph = ",".join("?" for _ in class_ids)
        upcoming_sessions = fetch_all(
            f"""
            SELECT TOP 8
                S.Id, S.ClassRef, S.Date, S.StartTime, S.EndTime, S.Status,
                C.Name AS CourseName,
                ST.Name AS SessionTypeName
            FROM Session S
            JOIN Class Cl ON S.ClassRef = Cl.Id
            JOIN Course C ON Cl.CourseRef = C.Id
            LEFT JOIN SessionType ST ON S.SessionTypeRef = ST.Id
            WHERE Cl.TeacherRef = ?
              AND S.ClassRef IN ({ph})
              AND S.Status IN (N'scheduled', N'in_progress')
            ORDER BY S.Date, S.StartTime
            """,
            (teacher_ref, *class_ids),
        )
        recent_sessions = fetch_all(
            f"""
            SELECT TOP 8
                S.Id, S.ClassRef, S.Date, S.StartTime, S.EndTime, S.Status,
                C.Name AS CourseName,
                (
                    SELECT COUNT(*) FROM SessionStudent SS
                    WHERE SS.SessionRef = S.Id
                ) AS AttendanceCount
            FROM Session S
            JOIN Class Cl ON S.ClassRef = Cl.Id
            JOIN Course C ON Cl.CourseRef = C.Id
            WHERE Cl.TeacherRef = ?
              AND S.ClassRef IN ({ph})
            ORDER BY S.Date DESC, S.Id DESC
            """,
            (teacher_ref, *class_ids),
        )
        row = fetch_one(
            f"""
            SELECT COUNT(DISTINCT SS.SessionRef) AS Cnt
            FROM SessionStudent SS
            JOIN Session S ON SS.SessionRef = S.Id
            JOIN Class Cl ON S.ClassRef = Cl.Id
            WHERE Cl.TeacherRef = ?
              AND S.ClassRef IN ({ph})
            """,
            (teacher_ref, *class_ids),
        )
        attendance_marked = int((row or {}).get("Cnt") or 0)

    teacher = fetch_one(
        "SELECT Id, FirstName, LastName, Specialty FROM Teacher WHERE Id = ?",
        (teacher_ref,),
    )

    return {
        "teacher": teacher,
        "stats": {
            "classes_total": len(classes),
            "classes_active": len(active_classes),
            "courses_total": len(courses),
            "students_total": len(uniq_students),
            "sessions_upcoming": len(upcoming_sessions),
            "attendance_sessions": attendance_marked,
        },
        "classes": classes[:12],
        "courses": courses,
        "students": list(uniq_students.values())[:12],
        "upcoming_sessions": upcoming_sessions,
        "recent_sessions": recent_sessions,
    }


@app.get("/me/teaching/classes")
async def my_teaching_classes(status: Optional[str] = None, user: dict = AuthDep):
    teacher_ref = _require_teacher_ref(user)
    query = CLASS_SELECT + " WHERE Cl.TeacherRef = ?"
    params: list[Any] = [teacher_ref]
    if status:
        query += " AND Cl.Status = ?"
        params.append(status)
    query += " ORDER BY Cl.Id DESC"
    return _ok_list("classes", fetch_all(query, tuple(params)))


@app.get("/me/teaching/courses")
async def my_teaching_courses(user: dict = AuthDep):
    teacher_ref = _require_teacher_ref(user)
    rows = fetch_all(
        """
        SELECT
            C.Id, C.Name, C.Cost, C.SessionsCount, C.TeachingMethod,
            C.LanguageRef, Lang.Name AS LanguageName,
            C.LevelRef, Lv.Name AS LevelName, Lv.Code AS LevelCode,
            COUNT(DISTINCT Cl.Id) AS ClassCount,
            SUM(CASE WHEN Cl.Status IN (N'open', N'in_progress', N'full') THEN 1 ELSE 0 END) AS ActiveClassCount,
            (
                SELECT COUNT(DISTINCT R.Studentref)
                FROM Registration R
                JOIN Class Cl2 ON R.ClassRef = Cl2.Id
                WHERE Cl2.CourseRef = C.Id
                  AND Cl2.TeacherRef = ?
                  AND R.Status IN (N'active', N'pending_payment', N'pending_approval', N'frozen')
            ) AS StudentCount
        FROM Class Cl
        JOIN Course C ON Cl.CourseRef = C.Id
        JOIN Language Lang ON C.LanguageRef = Lang.Id
        LEFT JOIN Level Lv ON C.LevelRef = Lv.Id
        WHERE Cl.TeacherRef = ?
        GROUP BY C.Id, C.Name, C.Cost, C.SessionsCount, C.TeachingMethod,
                 C.LanguageRef, Lang.Name, C.LevelRef, Lv.Name, Lv.Code
        ORDER BY C.Name
        """,
        (teacher_ref, teacher_ref),
    )
    return _ok_list("courses", rows)


@app.get("/me/teaching/students")
async def my_teaching_students(
    class_ref: Optional[int] = None,
    search: Optional[str] = None,
    user: dict = AuthDep,
):
    teacher_ref = _require_teacher_ref(user)
    query = """
        SELECT
            St.Id, St.FirstName, St.LastName, St.Mobile, St.NationalCode, St.Gender,
            R.Id AS EnrollmentId, R.Status AS EnrollmentStatus, R.ClassRef, R.CourseRef,
            C.Name AS CourseName,
            Cl.Status AS ClassStatus,
            Lang.Name AS LanguageName,
            Lv.Name AS LevelName
        FROM Registration R
        JOIN Student St ON R.Studentref = St.Id
        JOIN Class Cl ON R.ClassRef = Cl.Id
        JOIN Course C ON R.CourseRef = C.Id
        JOIN Language Lang ON C.LanguageRef = Lang.Id
        LEFT JOIN Level Lv ON C.LevelRef = Lv.Id
        WHERE Cl.TeacherRef = ?
          AND R.Status IN (N'active', N'pending_payment', N'pending_approval', N'frozen')
    """
    params: list[Any] = [teacher_ref]
    if class_ref is not None:
        # اطمینان از مالکیت کلاس
        owned = fetch_one(
            "SELECT Id FROM Class WHERE Id = ? AND TeacherRef = ?",
            (class_ref, teacher_ref),
        )
        if not owned:
            raise HTTPException(status_code=403, detail="دسترسی به این کلاس ندارید")
        query += " AND R.ClassRef = ?"
        params.append(class_ref)
    if search:
        like = f"%{search.strip()}%"
        query += """ AND (
            St.FirstName + N' ' + St.LastName LIKE ?
            OR St.Mobile LIKE ?
            OR St.NationalCode LIKE ?
            OR C.Name LIKE ?
        )"""
        params.extend([like, like, like, like])
    query += " ORDER BY St.LastName, St.FirstName, R.Id DESC"
    return _ok_list("students", fetch_all(query, tuple(params)))


@app.get("/me/teaching/sessions")
async def my_teaching_sessions(
    status: Optional[str] = None,
    class_ref: Optional[int] = None,
    from_date: Optional[str] = Query(None, pattern=r"^\d{4}/\d{2}/\d{2}$"),
    to_date: Optional[str] = Query(None, pattern=r"^\d{4}/\d{2}/\d{2}$"),
    user: dict = AuthDep,
):
    teacher_ref = _require_teacher_ref(user)
    query = SESSION_SELECT + " WHERE Cl.TeacherRef = ?"
    params: list[Any] = [teacher_ref]
    if class_ref is not None:
        owned = fetch_one(
            "SELECT Id FROM Class WHERE Id = ? AND TeacherRef = ?",
            (class_ref, teacher_ref),
        )
        if not owned:
            raise HTTPException(status_code=403, detail="دسترسی به این کلاس ندارید")
        query += " AND S.ClassRef = ?"
        params.append(class_ref)
    if status:
        query += " AND S.Status = ?"
        params.append(status)
    if from_date:
        query += " AND S.Date >= ?"
        params.append(from_date)
    if to_date:
        query += " AND S.Date <= ?"
        params.append(to_date)
    query += " ORDER BY S.Date DESC, S.StartTime DESC"
    return _ok_list("sessions", fetch_all(query, tuple(params)))


@app.get("/enrollments")
async def list_enrollments(
    student_ref: Optional[int] = None,
    class_ref: Optional[int] = None,
    course_ref: Optional[int] = None,
    status: Optional[str] = None,
    financial_status: Optional[str] = None,
    balance_filter: Optional[str] = None,
    search: Optional[str] = None,
    include_withdrawn: bool = False,
    user: dict = AuthDep,
):
    """
    financial_status: وضعیت ذخیره‌شده در DB (debtor|creditor|settled)
    balance_filter: مانده واقعی حساب بر اساس پرداخت − شهریه
      debtor | creditor | settled | nonzero
    include_withdrawn: برای صفحات مالی که به ثبت‌نام‌های انصرافی هم نیاز دارند
    """
    if not _can_list_all_enrollments(user):
        own = user.get("StudentRef")
        if not own:
            raise HTTPException(
                status_code=403,
                detail="دسترسی به فهرست ثبت‌نام‌ها ندارید",
            )
        student_ref = int(own)

    rows = _list_enrollments_rows(
        student_ref=student_ref,
        class_ref=class_ref,
        course_ref=course_ref,
        status=status,
        financial_status=financial_status,
        balance_filter=balance_filter,
        search=search,
        include_withdrawn=include_withdrawn,
    )
    return _ok_list("enrollments", rows)


@app.get("/enrollments/{enrollment_id}")
async def get_enrollment(enrollment_id: int, user: dict = AuthDep):
    row = fetch_one(ENROLLMENT_SELECT + " WHERE R.Id = ?", (enrollment_id,))
    if not row:
        raise _not_found("Enrollment")
    if not _can_list_all_enrollments(user):
        own = user.get("StudentRef")
        if not own or int(row["StudentRef"]) != int(own):
            raise HTTPException(status_code=403, detail="دسترسی به این ثبت‌نام ندارید")
    # برای تخصیص صحیح پرداخت‌های بدون ثبت‌نام، همهٔ ثبت‌نام‌های همان زبان‌آموز لازم است
    siblings = fetch_all(
        ENROLLMENT_SELECT + " WHERE R.Studentref = ? ORDER BY R.Id",
        (row["StudentRef"],),
    )
    enriched = apply_unallocated_payments(siblings)
    for item in enriched:
        if int(item["Id"]) == int(enrollment_id):
            return {"enrollment": item}
    return {"enrollment": enrich_enrollment_finance(row)}


@app.post("/enrollments", status_code=201)
async def create_enrollment(body: EnrollmentCreate, user: dict = AuthDep):
    _assert_can_create_enrollment(user, body.student_ref)
    if not fetch_one("SELECT Id FROM Student WHERE Id = ? AND IsActive = 1", (body.student_ref,)):
        raise _bad_request("دانشجو معتبر نیست")

    class_row = fetch_one(
        "SELECT Id, CourseRef, Capacity, Status FROM Class WHERE Id = ?",
        (body.class_ref,),
    )
    if not class_row:
        raise _bad_request("کلاس معتبر نیست")
    if class_row["Status"] == "full":
        raise _bad_request("ظرفیت کلاس تکمیل است؛ فقط از مسیر Waitlist مجاز است (BR-025)")
    if class_row["Status"] in ("cancelled", "finished"):
        raise _bad_request("ثبت‌نام در این وضعیت کلاس مجاز نیست")

    course_ref = body.course_ref or class_row["CourseRef"]
    # وضعیت مالی از روی مانده محاسبه می‌شود؛ ثبت اولیه همیشه بدهکار (تا پرداخت ثبت شود)
    initial_finance = compute_finance_metrics(
        fetch_one("SELECT Cost FROM Course WHERE Id = ?", (course_ref,))["Cost"]
        if course_ref
        else 0,
        0,
    )["DerivedFinancialStatus"]

    enrolled = fetch_one(
        """SELECT COUNT(*) AS Cnt FROM Registration
           WHERE ClassRef = ? AND Status IN ('active', 'pending_payment', 'pending_approval')""",
        (body.class_ref,),
    )
    count = int(enrolled["Cnt"]) if enrolled else 0
    if count >= int(class_row["Capacity"]):
        execute("UPDATE Class SET Status = N'full' WHERE Id = ?", (body.class_ref,))
        raise _bad_request("ظرفیت کلاس پر شده است (BR-053 / FR-053)")

    duplicate = fetch_one(
        """SELECT Id FROM Registration
           WHERE Studentref = ? AND ClassRef = ?
             AND Status NOT IN ('withdrawn', 'transferred')""",
        (body.student_ref, body.class_ref),
    )
    if duplicate:
        raise _bad_request("این دانشجو قبلاً در این کلاس ثبت‌نام شده است")

    _assert_no_parallel_course_enrollment(body.student_ref, int(course_ref), body.class_ref)
    _assert_student_fits_course_age(body.student_ref, int(course_ref))

    new_id = execute_returning_id(
        """INSERT INTO Registration
            ([Studentref], [CourseRef], [ClassRef], [Date], [Status], [FinancialStatus])
           VALUES (?, ?, ?, ?, ?, ?)""",
        (
            body.student_ref,
            course_ref,
            body.class_ref,
            body.date,
            body.status,
            initial_finance,
        ),
    )

    # اگر ظرفیت پر شد وضعیت کلاس را full کن
    if count + 1 >= int(class_row["Capacity"]):
        execute("UPDATE Class SET Status = N'full' WHERE Id = ?", (body.class_ref,))

    return {"message": "Enrollment created", "id": new_id}


@app.post("/enrollments/bulk", status_code=201)
async def create_enrollments_bulk(body: EnrollmentBulkCreate, user: dict = StaffDep):
    """ثبت هم‌زمان چند زبان‌آموز در یک کلاس با فیلدهای مشترک"""
    for sid in body.student_refs:
        _assert_can_create_enrollment(user, sid)
    student_refs = body.student_refs
    class_row = fetch_one(
        "SELECT Id, CourseRef, Capacity, Status FROM Class WHERE Id = ?",
        (body.class_ref,),
    )
    if not class_row:
        raise _bad_request("کلاس معتبر نیست")
    if class_row["Status"] == "full":
        raise _bad_request("ظرفیت کلاس تکمیل است؛ فقط از مسیر Waitlist مجاز است (BR-025)")
    if class_row["Status"] in ("cancelled", "finished"):
        raise _bad_request("ثبت‌نام در این وضعیت کلاس مجاز نیست")

    course_ref = body.course_ref or class_row["CourseRef"]
    capacity = int(class_row["Capacity"])
    course_row = fetch_one("SELECT Cost FROM Course WHERE Id = ?", (course_ref,))
    initial_finance = compute_finance_metrics(
        course_row["Cost"] if course_row else 0,
        0,
    )["DerivedFinancialStatus"]

    placeholders = ",".join("?" for _ in student_refs)
    active_students = fetch_all(
        f"SELECT Id FROM Student WHERE IsActive = 1 AND Id IN ({placeholders})",
        tuple(student_refs),
    )
    active_ids = {int(r["Id"]) for r in active_students}
    missing = [sid for sid in student_refs if sid not in active_ids]
    if missing:
        raise _bad_request(f"زبان‌آموز نامعتبر: {', '.join(map(str, missing))}")

    enrolled = fetch_one(
        """SELECT COUNT(*) AS Cnt FROM Registration
           WHERE ClassRef = ? AND Status IN ('active', 'pending_payment', 'pending_approval')""",
        (body.class_ref,),
    )
    count = int(enrolled["Cnt"]) if enrolled else 0
    if count + len(student_refs) > capacity:
        raise _bad_request(
            f"ظرفیت کلاس کافی نیست (باقیمانده: {max(capacity - count, 0)}، درخواست: {len(student_refs)})"
        )

    duplicates = fetch_all(
        f"""SELECT Studentref AS StudentRef FROM Registration
            WHERE ClassRef = ? AND Studentref IN ({placeholders})
              AND Status NOT IN ('withdrawn', 'transferred')""",
        (body.class_ref, *student_refs),
    )
    if duplicates:
        dup_ids = ", ".join(str(r["StudentRef"]) for r in duplicates)
        raise _bad_request(f"این زبان‌آموزان قبلاً در این کلاس ثبت‌نام شده‌اند: {dup_ids}")

    parallel = fetch_all(
        f"""SELECT R.Studentref AS StudentRef,
                   R.ClassRef,
                   R.Id AS EnrollmentId,
                   St.FirstName + N' ' + St.LastName AS StudentName
            FROM Registration R
            JOIN Student St ON R.Studentref = St.Id
            WHERE R.CourseRef = ?
              AND R.Studentref IN ({placeholders})
              AND R.ClassRef IS NOT NULL
              AND R.ClassRef <> ?
              AND R.Status IN ({",".join("?" for _ in CONCURRENT_ENROLLMENT_STATUSES)})""",
        (course_ref, *student_refs, body.class_ref, *CONCURRENT_ENROLLMENT_STATUSES),
    )
    if parallel:
        details = ", ".join(
            f"{r['StudentName']} (کلاس #{r['ClassRef']}, ثبت‌نام #{r['EnrollmentId']})"
            for r in parallel
        )
        raise _bad_request(
            f"این زبان‌آموزان هم‌اکنون در کلاس دیگری از همین دوره ثبت‌نام دارند: {details}"
        )

    for sid in student_refs:
        _assert_student_fits_course_age(sid, int(course_ref))

    new_ids: list[int] = []
    with db_cursor() as cursor:
        for sid in student_refs:
            cursor.execute(
                """INSERT INTO Registration
                    ([Studentref], [CourseRef], [ClassRef], [Date], [Status], [FinancialStatus])
                   VALUES (?, ?, ?, ?, ?, ?);
                   SELECT CAST(SCOPE_IDENTITY() AS INT) AS NewId""",
                (
                    sid,
                    course_ref,
                    body.class_ref,
                    body.date,
                    body.status,
                    initial_finance,
                ),
            )
            while cursor.description is None:
                if not cursor.nextset():
                    break
            row = cursor.fetchone()
            if row and row[0] is not None:
                new_ids.append(int(row[0]))
            while cursor.nextset():
                pass

        if count + len(student_refs) >= capacity:
            cursor.execute("UPDATE Class SET Status = N'full' WHERE Id = ?", (body.class_ref,))

    return {
        "message": f"{len(new_ids)} ثبت‌نام ایجاد شد",
        "ids": new_ids,
        "count": len(new_ids),
    }


@app.put("/enrollments/{enrollment_id}")
async def update_enrollment(enrollment_id: int, body: EnrollmentUpdate, user: dict = StaffDep):
    current = fetch_one("SELECT * FROM Registration WHERE Id = ?", (enrollment_id,))
    if not current:
        raise _not_found("Enrollment")
    if body.status == "withdrawn" and not body.withdraw_reason:
        raise _bad_request("انصراف بدون دلیل مجاز نیست (BR-024)")

    fields: list[str] = []
    params: list[Any] = []
    data = body.model_dump(exclude_unset=True)
    # وضعیت مالی دستی پذیرفته نمی‌شود؛ بعد از ذخیره از روی پرداخت‌ها همگام می‌شود
    data.pop("financial_status", None)
    column_map = {
        "status": "Status",
        "withdraw_reason": "WithdrawReason",
    }
    for key, col in column_map.items():
        if key in data:
            fields.append(f"[{col}] = ?")
            params.append(data[key])
    if not fields:
        raise _bad_request("هیچ فیلدی برای به‌روزرسانی ارسال نشده است")
    params.append(enrollment_id)
    execute(f"UPDATE Registration SET {', '.join(fields)} WHERE Id = ?", tuple(params))

    # آزاد شدن ظرفیت پس از انصراف
    if body.status == "withdrawn" and current.get("ClassRef"):
        execute(
            """UPDATE Class SET Status = N'open'
               WHERE Id = ? AND Status = N'full'""",
            (current["ClassRef"],),
        )
    sync_registration_financial_status(enrollment_id)
    return {"message": "Enrollment updated", "id": enrollment_id}


@app.delete("/enrollments/{enrollment_id}")
async def withdraw_enrollment(enrollment_id: int, user: dict = StaffDep):
    """حذف منطقی ثبت‌نام = انصراف"""
    current = fetch_one("SELECT * FROM Registration WHERE Id = ?", (enrollment_id,))
    if not current:
        raise _not_found("Enrollment")
    execute(
        """UPDATE Registration
           SET Status = N'withdrawn', WithdrawReason = N'حذف توسط کاربر'
           WHERE Id = ?""",
        (enrollment_id,),
    )
    if current.get("ClassRef"):
        execute(
            """UPDATE Class SET Status = N'open'
               WHERE Id = ? AND Status = N'full'""",
            (current["ClassRef"],),
        )
    return {"message": "Enrollment withdrawn", "id": enrollment_id}


# ---------------------------------------------------------------------------
# Payments
# ---------------------------------------------------------------------------

@app.get("/payments")
async def list_payments(
    student_ref: Optional[int] = None,
    registration_ref: Optional[int] = None,
    status: Optional[str] = None,
    user: dict = FinanceDep,
):
    query = """
        SELECT P.Id, P.StudentRef, P.Date, P.Amount, P.PaymentType,
               P.Status, P.PaymentMethod, P.RegistrationRef, P.Description, P.CreatedAt,
               St.FirstName + N' ' + St.LastName AS StudentName
        FROM Payment P
        JOIN Student St ON P.StudentRef = St.Id
        WHERE 1=1
    """
    params: list[Any] = []
    if student_ref is not None:
        query += " AND P.StudentRef = ?"
        params.append(student_ref)
    if registration_ref is not None:
        query += " AND P.RegistrationRef = ?"
        params.append(registration_ref)
    if status:
        query += " AND P.Status = ?"
        params.append(status)
    query += " ORDER BY P.Id DESC"
    return _ok_list("payments", fetch_all(query, tuple(params)))


def _payment_method_to_type(method: str) -> int:
    return {"cash": 1, "card": 2, "online": 3, "installment": 4, "other": 5}.get(method, 5)


def _validate_payment_registration(student_ref: int, registration_ref: int) -> dict[str, Any]:
    reg = fetch_one(
        "SELECT Id, Studentref AS StudentRef FROM Registration WHERE Id = ?",
        (registration_ref,),
    )
    if not reg:
        raise _bad_request("ثبت‌نام معتبر نیست")
    if int(reg["StudentRef"]) != int(student_ref):
        raise _bad_request("ثبت‌نام انتخاب‌شده متعلق به این زبان‌آموز نیست")
    return reg


def _sync_after_payment(registration_ref: Optional[int], status: Optional[str] = None) -> None:
    if not registration_ref:
        return
    sync_registration_financial_status(int(registration_ref))
    if status == "paid":
        execute(
            """UPDATE Registration SET Status = N'active'
               WHERE Id = ? AND Status = N'pending_payment'""",
            (registration_ref,),
        )


@app.post("/payments", status_code=201)
async def create_payment(body: PaymentCreate, user: dict = FinanceDep):
    if not fetch_one("SELECT Id FROM Student WHERE Id = ?", (body.student_ref,)):
        raise _bad_request("پرداخت باید به دانشجو متصل باشد (BR-010)")
    if body.amount < 0:
        raise _bad_request("مبلغ منفی مجاز نیست (BR-003)")
    _validate_payment_registration(body.student_ref, body.registration_ref)

    payment_type = body.payment_type or _payment_method_to_type(body.payment_method)

    new_id = execute_returning_id(
        """INSERT INTO Payment
            ([StudentRef], [Date], [Amount], [PaymentType],
             [Status], [PaymentMethod], [RegistrationRef], [Description])
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            body.student_ref,
            body.date,
            body.amount,
            payment_type,
            body.status,
            body.payment_method,
            body.registration_ref,
            body.description,
        ),
    )

    _sync_after_payment(body.registration_ref, body.status)
    return {"message": "Payment created", "id": new_id}


@app.put("/payments/{payment_id}")
async def update_payment(payment_id: int, body: PaymentUpdate, user: dict = FinanceDep):
    current = fetch_one("SELECT * FROM Payment WHERE Id = ?", (payment_id,))
    if not current:
        raise _not_found("Payment")

    data = body.model_dump(exclude_unset=True)
    if not data:
        raise _bad_request("هیچ فیلدی برای به‌روزرسانی ارسال نشده است")

    student_ref = int(data.get("student_ref", current["StudentRef"]))
    registration_ref = data.get("registration_ref", current.get("RegistrationRef"))
    if registration_ref is None:
        raise _bad_request("ثبت‌نام مرتبط الزامی است")
    registration_ref = int(registration_ref)

    if "student_ref" in data and not fetch_one("SELECT Id FROM Student WHERE Id = ?", (student_ref,)):
        raise _bad_request("پرداخت باید به دانشجو متصل باشد (BR-010)")
    if "amount" in data and data["amount"] is not None and data["amount"] < 0:
        raise _bad_request("مبلغ منفی مجاز نیست (BR-003)")

    _validate_payment_registration(student_ref, registration_ref)

    method = data.get("payment_method", current.get("PaymentMethod") or "cash")
    if "payment_type" not in data and "payment_method" in data:
        data["payment_type"] = _payment_method_to_type(method)

    column_map = {
        "student_ref": "StudentRef",
        "registration_ref": "RegistrationRef",
        "amount": "Amount",
        "date": "Date",
        "payment_method": "PaymentMethod",
        "status": "Status",
        "description": "Description",
        "payment_type": "PaymentType",
    }
    fields: list[str] = []
    params: list[Any] = []
    for key, col in column_map.items():
        if key in data:
            fields.append(f"[{col}] = ?")
            params.append(data[key])
    params.append(payment_id)
    execute(f"UPDATE Payment SET {', '.join(fields)} WHERE Id = ?", tuple(params))

    old_reg = current.get("RegistrationRef")
    new_status = data.get("status", current.get("Status"))
    for reg_id in {int(r) for r in (old_reg, registration_ref) if r}:
        _sync_after_payment(reg_id, new_status if reg_id == registration_ref else None)

    return {"message": "Payment updated", "id": payment_id}


@app.delete("/payments/{payment_id}")
async def delete_payment(payment_id: int, user: dict = FinanceDep):
    current = fetch_one("SELECT * FROM Payment WHERE Id = ?", (payment_id,))
    if not current:
        raise _not_found("Payment")
    execute("DELETE FROM Payment WHERE Id = ?", (payment_id,))
    _sync_after_payment(current.get("RegistrationRef"))
    return {"message": "Payment deleted", "id": payment_id}


# ---------------------------------------------------------------------------
# Scores / Placement
# ---------------------------------------------------------------------------

SCORE_SELECT = """
    SELECT Sc.Id, Sc.StudentRef, Sc.RegistrationRef, Sc.ExamType,
           Sc.ScoreValue, Sc.MaxScore, Sc.Notes, Sc.ExamDate, Sc.CreatedAt,
           Sc.SuggestedLevelRef,
           St.FirstName + N' ' + St.LastName AS StudentName,
           C.Name AS CourseName,
           Lv.Name AS SuggestedLevelName,
           Lv.Code AS SuggestedLevelCode
    FROM Score Sc
    LEFT JOIN Student St ON Sc.StudentRef = St.Id
    LEFT JOIN Registration R ON Sc.RegistrationRef = R.Id
    LEFT JOIN Course C ON R.CourseRef = C.Id
    LEFT JOIN Level Lv ON Sc.SuggestedLevelRef = Lv.Id
"""


def _validate_score_links(
    *,
    student_ref: int,
    registration_ref: Optional[int],
    exam_type: str,
    suggested_level_ref: Optional[int],
) -> None:
    if not fetch_one("SELECT Id FROM Student WHERE Id = ? AND IsActive = 1", (student_ref,)):
        # زبان‌آموز آرشیو هم برای سابقهٔ نمره قابل پذیرش است
        if not fetch_one("SELECT Id FROM Student WHERE Id = ?", (student_ref,)):
            raise _bad_request("زبان‌آموز معتبر نیست")
    if registration_ref is not None:
        reg = fetch_one(
            "SELECT Id, Studentref AS StudentRef FROM Registration WHERE Id = ?",
            (registration_ref,),
        )
        if not reg:
            raise _bad_request("ثبت‌نام معتبر نیست")
        if int(reg["StudentRef"]) != int(student_ref):
            raise _bad_request("ثبت‌نام انتخاب‌شده متعلق به این زبان‌آموز نیست")
    elif exam_type != "placement":
        raise _bad_request("برای این نوع آزمون، ثبت‌نام مرتبط الزامی است")
    if suggested_level_ref is not None:
        if not fetch_one("SELECT Id FROM Level WHERE Id = ? AND IsActive = 1", (suggested_level_ref,)):
            raise _bad_request("سطح پیشنهادی معتبر نیست")


@app.get("/scores")
async def list_scores(
    student_ref: Optional[int] = None,
    registration_ref: Optional[int] = None,
    exam_type: Optional[str] = None,
    search: Optional[str] = None,
    user: dict = AuthDep,
):
    roles = _user_role_set(user)
    can_all = bool(roles & {"admin", "secretary", "education", "teacher"})
    can_see_placement = bool(roles & {"admin", "secretary", "education"})
    query = SCORE_SELECT + " WHERE 1=1"
    params: list[Any] = []

    if not can_all:
        own = user.get("StudentRef")
        if not own:
            raise HTTPException(status_code=403, detail="دسترسی به نمرات ندارید")
        query += " AND Sc.StudentRef = ?"
        params.append(int(own))
    elif student_ref is not None:
        query += " AND Sc.StudentRef = ?"
        params.append(student_ref)

    # مدرس نتایج تعیین سطح را نمی‌بیند
    if can_all and not can_see_placement:
        if exam_type == "placement":
            raise HTTPException(status_code=403, detail="مدرس مجاز به مشاهده نتایج تعیین سطح نیست")
        query += " AND Sc.ExamType <> N'placement'"

    if registration_ref is not None:
        query += " AND Sc.RegistrationRef = ?"
        params.append(registration_ref)
    if exam_type:
        query += " AND Sc.ExamType = ?"
        params.append(exam_type)
    if search:
        like = f"%{search.strip()}%"
        query += """ AND (
            St.FirstName + N' ' + St.LastName LIKE ?
            OR C.Name LIKE ?
            OR Lv.Name LIKE ?
            OR CAST(Sc.Id AS NVARCHAR(20)) LIKE ?
        )"""
        params.extend([like, like, like, like])
    query += " ORDER BY Sc.Id DESC"
    return _ok_list("scores", fetch_all(query, tuple(params)))


@app.post("/scores", status_code=201)
async def create_score(body: ScoreCreate, user: dict = TeacherStaffDep):
    roles = _user_role_set(user)
    if body.exam_type == "placement" and not (roles & {"admin", "secretary", "education"}):
        raise HTTPException(status_code=403, detail="مدرس مجاز به ثبت نتیجه تعیین سطح نیست")
    if body.score_value > body.max_score:
        raise _bad_request("نمره خارج از بازه مجاز است (BR-012)")
    _validate_score_links(
        student_ref=body.student_ref,
        registration_ref=body.registration_ref,
        exam_type=body.exam_type,
        suggested_level_ref=body.suggested_level_ref,
    )
    new_id = execute_returning_id(
        """INSERT INTO Score
            ([StudentRef], [RegistrationRef], [ExamType], [ScoreValue], [MaxScore],
             [Notes], [ExamDate], [SuggestedLevelRef])
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            body.student_ref,
            body.registration_ref,
            body.exam_type,
            body.score_value,
            body.max_score,
            body.notes,
            body.exam_date,
            body.suggested_level_ref,
        ),
    )
    return {"message": "Score created", "id": new_id}


@app.put("/scores/{score_id}")
async def update_score(score_id: int, body: ScoreUpdate, user: dict = TeacherStaffDep):
    current = fetch_one("SELECT * FROM Score WHERE Id = ?", (score_id,))
    if not current:
        raise _not_found("Score")

    roles = _user_role_set(user)
    can_placement = bool(roles & {"admin", "secretary", "education"})
    if (current.get("ExamType") or "") == "placement" and not can_placement:
        raise HTTPException(status_code=403, detail="مدرس مجاز به ویرایش نتایج تعیین سطح نیست")

    data = body.model_dump(exclude_unset=True)
    clear_registration = bool(data.pop("clear_registration", False))
    clear_suggested = bool(data.pop("clear_suggested_level", False))
    if not data and not clear_registration and not clear_suggested:
        raise _bad_request("هیچ فیلدی برای به‌روزرسانی ارسال نشده است")

    student_ref = int(data.get("student_ref", current.get("StudentRef") or 0))
    if not student_ref and current.get("RegistrationRef"):
        reg = fetch_one(
            "SELECT Studentref AS StudentRef FROM Registration WHERE Id = ?",
            (current["RegistrationRef"],),
        )
        student_ref = int(reg["StudentRef"]) if reg else 0

    if "registration_ref" in data:
        registration_ref = data["registration_ref"]
    elif clear_registration:
        registration_ref = None
    else:
        registration_ref = current.get("RegistrationRef")

    exam_type = data.get("exam_type", current.get("ExamType") or "placement")
    if exam_type == "placement" and not can_placement:
        raise HTTPException(status_code=403, detail="مدرس مجاز به ثبت نتیجه تعیین سطح نیست")
    if "suggested_level_ref" in data:
        suggested = data["suggested_level_ref"]
    elif clear_suggested:
        suggested = None
    else:
        suggested = current.get("SuggestedLevelRef")

    score_value = float(data.get("score_value", current["ScoreValue"]))
    max_score = float(data.get("max_score", current["MaxScore"]))
    if score_value > max_score:
        raise _bad_request("نمره خارج از بازه مجاز است (BR-012)")

    _validate_score_links(
        student_ref=student_ref,
        registration_ref=int(registration_ref) if registration_ref is not None else None,
        exam_type=exam_type,
        suggested_level_ref=int(suggested) if suggested is not None else None,
    )

    execute(
        """UPDATE Score SET
              StudentRef = ?,
              RegistrationRef = ?,
              ExamType = ?,
              ScoreValue = ?,
              MaxScore = ?,
              Notes = ?,
              ExamDate = ?,
              SuggestedLevelRef = ?
           WHERE Id = ?""",
        (
            student_ref,
            registration_ref,
            exam_type,
            score_value,
            max_score,
            data["notes"] if "notes" in data else current.get("Notes"),
            data["exam_date"] if "exam_date" in data else current.get("ExamDate"),
            suggested,
            score_id,
        ),
    )
    return {"message": "Score updated", "id": score_id}


@app.delete("/scores/{score_id}")
async def delete_score(score_id: int, user: dict = TeacherStaffDep):
    current = fetch_one("SELECT Id, ExamType FROM Score WHERE Id = ?", (score_id,))
    if not current:
        raise _not_found("Score")
    roles = _user_role_set(user)
    if (current.get("ExamType") or "") == "placement" and not (
        roles & {"admin", "secretary", "education"}
    ):
        raise HTTPException(status_code=403, detail="مدرس مجاز به حذف نتایج تعیین سطح نیست")
    execute("DELETE FROM Score WHERE Id = ?", (score_id,))
    return {"message": "Score deleted", "id": score_id}


# ---------------------------------------------------------------------------
# Reports (فاز ۱ ساده)
# ---------------------------------------------------------------------------

@app.get("/reports/summary")
async def report_summary(user: dict = FinanceDep):
    """خلاصه عملیاتی + دادهٔ نمودار برای داشبورد"""
    students = fetch_one("SELECT COUNT(*) AS Cnt FROM Student WHERE IsActive = 1")["Cnt"]
    teachers = fetch_one("SELECT COUNT(*) AS Cnt FROM Teacher WHERE IsActive = 1")["Cnt"]
    courses = fetch_one("SELECT COUNT(*) AS Cnt FROM Course WHERE IsActive = 1")["Cnt"]
    classes_open = fetch_one(
        "SELECT COUNT(*) AS Cnt FROM Class WHERE Status IN ('open', 'in_progress')"
    )["Cnt"]
    classes_total = fetch_one("SELECT COUNT(*) AS Cnt FROM Class")["Cnt"]
    enrollments_active = fetch_one(
        "SELECT COUNT(*) AS Cnt FROM Registration WHERE Status = N'active'"
    )["Cnt"]
    enrollments_total = fetch_one("SELECT COUNT(*) AS Cnt FROM Registration")["Cnt"]
    payments_paid_total = fetch_one(
        "SELECT ISNULL(SUM(Amount), 0) AS Total FROM Payment WHERE Status = N'paid'"
    )["Total"]
    sessions_scheduled = fetch_one(
        "SELECT COUNT(*) AS Cnt FROM [Session] WHERE Status = N'scheduled'"
    )["Cnt"]
    languages = fetch_one("SELECT COUNT(*) AS Cnt FROM Language")["Cnt"]

    enrollments_by_status = fetch_all(
        """
        SELECT Status AS label, COUNT(*) AS value
        FROM Registration
        GROUP BY Status
        ORDER BY COUNT(*) DESC
        """
    )
    classes_by_status = fetch_all(
        """
        SELECT Status AS label, COUNT(*) AS value
        FROM Class
        GROUP BY Status
        ORDER BY COUNT(*) DESC
        """
    )
    courses_by_language = fetch_all(
        """
        SELECT TOP 6 L.Name AS label, COUNT(*) AS value
        FROM Course C
        JOIN Language L ON C.LanguageRef = L.Id
        WHERE C.IsActive = 1
        GROUP BY L.Name
        ORDER BY COUNT(*) DESC
        """
    )
    payments_by_status = fetch_all(
        """
        SELECT Status AS label, COUNT(*) AS value, ISNULL(SUM(Amount), 0) AS amount
        FROM Payment
        GROUP BY Status
        ORDER BY COUNT(*) DESC
        """
    )
    finance_by_status = fetch_all(
        """
        SELECT FinancialStatus AS label, COUNT(*) AS value
        FROM Registration
        WHERE FinancialStatus IN (N'debtor', N'creditor', N'settled')
        GROUP BY FinancialStatus
        ORDER BY COUNT(*) DESC
        """
    )
    capacity = fetch_one(
        """
        SELECT
            (SELECT ISNULL(SUM(Capacity), 0) FROM Class
             WHERE Status IN (N'open', N'in_progress', N'full')) AS CapacityTotal,
            (SELECT COUNT(*) FROM Registration R
             INNER JOIN Class Cl ON R.ClassRef = Cl.Id
             WHERE Cl.Status IN (N'open', N'in_progress', N'full')
               AND R.Status IN (N'active', N'pending_payment', N'pending_approval')) AS Enrolled
        """
    )

    return {
        "students": int(students or 0),
        "teachers": int(teachers or 0),
        "courses": int(courses or 0),
        "languages": int(languages or 0),
        "classes_open": int(classes_open or 0),
        "classes_total": int(classes_total or 0),
        "enrollments_active": int(enrollments_active or 0),
        "enrollments_total": int(enrollments_total or 0),
        "sessions_scheduled": int(sessions_scheduled or 0),
        "payments_paid_total": int(payments_paid_total or 0),
        "capacity_total": int((capacity or {}).get("CapacityTotal") or 0),
        "capacity_used": int((capacity or {}).get("Enrolled") or 0),
        "enrollments_by_status": [
            {"label": r["label"], "value": int(r["value"])} for r in enrollments_by_status
        ],
        "classes_by_status": [
            {"label": r["label"], "value": int(r["value"])} for r in classes_by_status
        ],
        "courses_by_language": [
            {"label": r["label"], "value": int(r["value"])} for r in courses_by_language
        ],
        "payments_by_status": [
            {
                "label": r["label"],
                "value": int(r["value"]),
                "amount": int(r["amount"] or 0),
            }
            for r in payments_by_status
        ],
        "finance_by_status": [
            {"label": r["label"], "value": int(r["value"])} for r in finance_by_status
        ],
    }


@app.get("/activities")
async def get_activities(
    search: Optional[str] = None,
    action_code: Optional[str] = None,
    entity_type: Optional[str] = None,
    user_ref: Optional[int] = None,
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    user: dict = AdminDep,
):
    data = list_activities(
        search=search,
        action_code=action_code,
        entity_type=entity_type,
        user_ref=user_ref,
        limit=limit,
        offset=offset,
    )
    data["action_labels"] = ACTION_LABELS
    data["entity_labels"] = ENTITY_LABELS
    return data
