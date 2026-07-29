"""
API بک‌اند سیستم مدیریت آموزشگاه زبان (LIMS)
فاز ۱ — مطابق SRS v2: Language → Level → Course → Class → Session + JWT Auth
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Optional

from fastapi import Depends, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

from auth import (
    create_access_token,
    create_refresh_token_value,
    find_valid_refresh_session,
    get_current_user,
    get_user_by_id,
    get_user_by_username,
    get_user_roles,
    hash_password,
    public_user,
    register_failed_login,
    require_roles,
    reset_failed_login,
    revoke_all_user_sessions,
    revoke_refresh_token,
    store_refresh_token,
    verify_password,
)
from config import settings
from database import execute, execute_returning_id, fetch_all, fetch_one, health_check
from models import (
    AttendanceBulkCreate,
    AttendanceCreate,
    ChangePasswordRequest,
    ClassCreate,
    ClassUpdate,
    CourseCreate,
    CourseUpdate,
    EnrollmentCreate,
    EnrollmentUpdate,
    LanguageCreate,
    LevelCreate,
    LoginRequest,
    PaymentCreate,
    RefreshRequest,
    RegisterRequest,
    ScoreCreate,
    SessionCreate,
    SessionUpdate,
    StudentCreate,
    TeacherCreate,
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

# نقش‌های پرکاربرد
StaffDep = Depends(require_roles("admin", "secretary"))
FinanceDep = Depends(require_roles("admin", "secretary", "finance"))
TeacherStaffDep = Depends(require_roles("admin", "secretary", "teacher"))
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


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------

@app.post("/auth/login")
async def login(body: LoginRequest):
    user = get_user_by_username(body.username)
    if not user:
        raise HTTPException(status_code=401, detail="نام کاربری یا رمز عبور اشتباه است")

    locked_until = user.get("LockedUntil")
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    if locked_until and locked_until > now:
        raise HTTPException(status_code=423, detail="حساب موقتاً قفل است؛ بعداً تلاش کنید")

    if not user.get("IsActive"):
        raise HTTPException(status_code=403, detail="حساب کاربری غیرفعال است")

    if not verify_password(body.password, user["PasswordHash"]):
        register_failed_login(user["Id"], int(user.get("FailedLoginCount") or 0))
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


@app.get("/auth/roles")
async def list_roles(user: dict = StaffDep):
    rows = fetch_all("SELECT Id, Code, Name, IsActive FROM Role WHERE IsActive = 1 ORDER BY Id")
    return _ok_list("roles", rows)


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


# ---------------------------------------------------------------------------
# Session Types
# ---------------------------------------------------------------------------

@app.get("/session-types")
async def list_session_types():
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


# ---------------------------------------------------------------------------
# Branches
# ---------------------------------------------------------------------------

@app.get("/branches")
async def list_branches():
    rows = fetch_all(
        """SELECT Id, Name, Address, Phone, IsActive
           FROM Branch WHERE IsActive = 1 ORDER BY Name"""
    )
    return _ok_list("branches", rows)


@app.post("/branches", status_code=201)
async def create_branch(body: dict, user: dict = StaffDep):
    name = (body.get("name") or "").strip()
    if not name:
        raise _bad_request("نام شعبه الزامی است")
    if fetch_one("SELECT Id FROM Branch WHERE Name = ?", (name,)):
        raise _bad_request("نام شعبه تکراری است")
    new_id = execute_returning_id(
        """INSERT INTO Branch ([Name], [Address], [Phone])
           VALUES (?, ?, ?)""",
        (name, body.get("address"), body.get("phone")),
    )
    return {"message": "Branch created", "id": new_id}


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
               BirthDate, Mobile, Email, Specialty, Bio, IsActive, Creator, CreatedAt
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
                  BirthDate, Mobile, Email, Specialty, Bio, IsActive, Creator, CreatedAt
           FROM Teacher WHERE Id = ?""",
        (teacher_id,),
    )
    if not row:
        raise _not_found("Teacher")
    return {"teacher": row}


@app.post("/teachers", status_code=201)
async def create_teacher(body: TeacherCreate, user: dict = StaffDep):
    if fetch_one("SELECT Id FROM Teacher WHERE NationalCode = ?", (body.national_code,)):
        raise _bad_request("کد ملی مدرس تکراری است")
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
    return {"message": "Teacher created", "id": new_id}


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
async def list_students(search: Optional[str] = None, include_inactive: bool = False, user: dict = StaffDep):
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
    return {"message": "Student created", "id": new_id}


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
    return {"class": row}


@app.post("/classes", status_code=201)
async def create_class(body: ClassCreate, user: dict = StaffDep):
    if not fetch_one("SELECT Id FROM Course WHERE Id = ? AND IsActive = 1", (body.course_ref,)):
        raise _bad_request("دوره معتبر/فعال نیست (BR-004)")
    if not fetch_one("SELECT Id FROM Teacher WHERE Id = ? AND IsActive = 1", (body.teacher_ref,)):
        raise _bad_request("مدرس معتبر/فعال نیست (BR-004 / BR-008)")
    _validate_class_location(body.session_type_ref, body.location_address, body.meeting_link)

    new_id = execute_returning_id(
        """INSERT INTO Class
            ([CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate],
             [Capacity], [Status], [ClassType], [BranchRef], [LocationAddress], [MeetingLink])
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            body.course_ref,
            body.teacher_ref,
            body.session_type_ref,
            body.start_date,
            body.end_date,
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
    for key, col in column_map.items():
        if key in data:
            fields.append(f"[{col}] = ?")
            params.append(data[key])
    if not fields:
        raise _bad_request("هیچ فیلدی برای به‌روزرسانی ارسال نشده است")
    params.append(class_id)
    execute(f"UPDATE Class SET {', '.join(fields)} WHERE Id = ?", tuple(params))
    return {"message": "Class updated", "id": class_id}


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
    status: Optional[str] = None,
    from_date: Optional[str] = Query(None, pattern=r"^\d{4}/\d{2}/\d{2}$"),
    to_date: Optional[str] = Query(None, pattern=r"^\d{4}/\d{2}/\d{2}$"),
):
    query = SESSION_SELECT + " WHERE 1=1"
    params: list[Any] = []
    if class_ref is not None:
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

    # تداخل زمانی مدرس کلاس (BR-020)
    overlap = fetch_one(
        """SELECT S.Id
           FROM Session S
           JOIN Class Cl ON S.ClassRef = Cl.Id
           WHERE Cl.TeacherRef = (SELECT TeacherRef FROM Class WHERE Id = ?)
             AND S.Date = ?
             AND S.Status NOT IN ('cancelled')
             AND S.StartTime < ? AND S.EndTime > ?""",
        (body.class_ref, body.date, body.end_time, body.start_time),
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
            body.date,
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
    if not fetch_one("SELECT Id FROM Session WHERE Id = ?", (session_id,)):
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


# ---------------------------------------------------------------------------
# Enrollments (Registration)
# ---------------------------------------------------------------------------

ENROLLMENT_SELECT = """
    SELECT
        R.Id, R.Studentref AS StudentRef, R.CourseRef, R.ClassRef, R.Date,
        R.Status, R.WithdrawReason, R.FinancialStatus, R.CreatedAt,
        St.FirstName + N' ' + St.LastName AS StudentName,
        C.Name AS CourseName,
        Cl.Capacity AS ClassCapacity
    FROM Registration R
    JOIN Student St ON R.Studentref = St.Id
    JOIN Course C ON R.CourseRef = C.Id
    LEFT JOIN Class Cl ON R.ClassRef = Cl.Id
"""


@app.get("/enrollments")
async def list_enrollments(
    student_ref: Optional[int] = None,
    class_ref: Optional[int] = None,
    course_ref: Optional[int] = None,
    status: Optional[str] = None,
    user: dict = AuthDep,
):
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
    query += " ORDER BY R.Id DESC"
    return _ok_list("enrollments", fetch_all(query, tuple(params)))


@app.get("/enrollments/{enrollment_id}")
async def get_enrollment(enrollment_id: int, user: dict = AuthDep):
    row = fetch_one(ENROLLMENT_SELECT + " WHERE R.Id = ?", (enrollment_id,))
    if not row:
        raise _not_found("Enrollment")
    return {"enrollment": row}


@app.post("/enrollments", status_code=201)
async def create_enrollment(body: EnrollmentCreate, user: dict = AuthDep):
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
            body.financial_status,
        ),
    )

    # اگر ظرفیت پر شد وضعیت کلاس را full کن
    if count + 1 >= int(class_row["Capacity"]):
        execute("UPDATE Class SET Status = N'full' WHERE Id = ?", (body.class_ref,))

    return {"message": "Enrollment created", "id": new_id}


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
    column_map = {
        "status": "Status",
        "withdraw_reason": "WithdrawReason",
        "financial_status": "FinancialStatus",
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
    return {"message": "Enrollment updated", "id": enrollment_id}


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


@app.post("/payments", status_code=201)
async def create_payment(body: PaymentCreate, user: dict = FinanceDep):
    if not fetch_one("SELECT Id FROM Student WHERE Id = ?", (body.student_ref,)):
        raise _bad_request("پرداخت باید به دانشجو متصل باشد (BR-010)")
    if body.amount < 0:
        raise _bad_request("مبلغ منفی مجاز نیست (BR-003)")
    if body.registration_ref and not fetch_one(
        "SELECT Id FROM Registration WHERE Id = ?", (body.registration_ref,)
    ):
        raise _bad_request("ثبت‌نام معتبر نیست")

    method_to_type = {"cash": 1, "card": 2, "online": 3, "installment": 4, "other": 5}
    payment_type = body.payment_type or method_to_type.get(body.payment_method, 5)

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

    if body.registration_ref and body.status == "paid":
        execute(
            """UPDATE Registration SET FinancialStatus = N'settled'
               WHERE Id = ?""",
            (body.registration_ref,),
        )
        execute(
            """UPDATE Registration SET Status = N'active'
               WHERE Id = ? AND Status = N'pending_payment'""",
            (body.registration_ref,),
        )

    return {"message": "Payment created", "id": new_id}


# ---------------------------------------------------------------------------
# Scores
# ---------------------------------------------------------------------------

@app.get("/scores")
async def list_scores(registration_ref: Optional[int] = None, exam_type: Optional[str] = None, user: dict = AuthDep):
    query = """
        SELECT Sc.Id, Sc.RegistrationRef, Sc.ExamType, Sc.ScoreValue, Sc.MaxScore,
               Sc.Notes, Sc.ExamDate, Sc.CreatedAt,
               St.FirstName + N' ' + St.LastName AS StudentName,
               C.Name AS CourseName
        FROM Score Sc
        JOIN Registration R ON Sc.RegistrationRef = R.Id
        JOIN Student St ON R.Studentref = St.Id
        JOIN Course C ON R.CourseRef = C.Id
        WHERE 1=1
    """
    params: list[Any] = []
    if registration_ref is not None:
        query += " AND Sc.RegistrationRef = ?"
        params.append(registration_ref)
    if exam_type:
        query += " AND Sc.ExamType = ?"
        params.append(exam_type)
    query += " ORDER BY Sc.Id DESC"
    return _ok_list("scores", fetch_all(query, tuple(params)))


@app.post("/scores", status_code=201)
async def create_score(body: ScoreCreate, user: dict = TeacherStaffDep):
    if not fetch_one("SELECT Id FROM Registration WHERE Id = ?", (body.registration_ref,)):
        raise _bad_request("ثبت‌نام معتبر نیست")
    if body.score_value > body.max_score:
        raise _bad_request("نمره خارج از بازه مجاز است (BR-012)")
    new_id = execute_returning_id(
        """INSERT INTO Score
            ([RegistrationRef], [ExamType], [ScoreValue], [MaxScore], [Notes], [ExamDate])
           VALUES (?, ?, ?, ?, ?, ?)""",
        (
            body.registration_ref,
            body.exam_type,
            body.score_value,
            body.max_score,
            body.notes,
            body.exam_date,
        ),
    )
    return {"message": "Score created", "id": new_id}


# ---------------------------------------------------------------------------
# Reports (فاز ۱ ساده)
# ---------------------------------------------------------------------------

@app.get("/reports/summary")
async def report_summary(user: dict = FinanceDep):
    return {
        "students": fetch_one("SELECT COUNT(*) AS Cnt FROM Student WHERE IsActive = 1")["Cnt"],
        "teachers": fetch_one("SELECT COUNT(*) AS Cnt FROM Teacher WHERE IsActive = 1")["Cnt"],
        "courses": fetch_one("SELECT COUNT(*) AS Cnt FROM Course WHERE IsActive = 1")["Cnt"],
        "classes_open": fetch_one(
            "SELECT COUNT(*) AS Cnt FROM Class WHERE Status IN ('open', 'in_progress')"
        )["Cnt"],
        "enrollments_active": fetch_one(
            "SELECT COUNT(*) AS Cnt FROM Registration WHERE Status = N'active'"
        )["Cnt"],
        "payments_paid_total": fetch_one(
            "SELECT ISNULL(SUM(Amount), 0) AS Total FROM Payment WHERE Status = N'paid'"
        )["Total"],
    }
