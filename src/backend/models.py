"""مدل‌های Pydantic برای اعتبارسنجی ورودی/خروجی API"""
from __future__ import annotations

from typing import Literal, Optional

from pydantic import BaseModel, Field, field_validator


# ---------- Auth ----------
class LoginRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6, max_length=100)


class RegisterRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=8, max_length=100)
    email: Optional[str] = Field(None, max_length=100)
    first_name: str = Field(..., min_length=1, max_length=50)
    last_name: str = Field(..., min_length=1, max_length=50)
    father_name: str = Field(..., min_length=1, max_length=50)
    mobile: str = Field(..., min_length=8, max_length=20)
    national_code: str = Field(..., min_length=10, max_length=10)
    gender: Literal[1, 2] = 1
    birth_date: str = Field(..., pattern=r"^\d{4}/\d{2}/\d{2}$")
    target_language_ref: Optional[int] = None
    preferred_ui_language: Literal["fa", "en"] = "fa"

    @field_validator("email")
    @classmethod
    def empty_email_to_none(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        v = v.strip()
        return v or None

    @field_validator("national_code")
    @classmethod
    def national_code_digits(cls, v: str) -> str:
        if not v.isdigit() or len(v) != 10:
            raise ValueError("کد ملی باید ۱۰ رقم باشد")
        return v


class RefreshRequest(BaseModel):
    refresh_token: str


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(..., min_length=6, max_length=100)
    new_password: str = Field(..., min_length=8, max_length=100)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in_minutes: int
    user: dict


# ---------- Language / Level ----------
class LanguageCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)


class LevelCreate(BaseModel):
    language_ref: int
    code: str = Field(..., min_length=1, max_length=20)
    name: str = Field(..., min_length=1, max_length=50)
    sort_order: int = 0


# ---------- Course ----------
class CourseCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    language_ref: int
    level_ref: Optional[int] = None
    sessions_count: int = Field(..., gt=0)
    cost: int = Field(..., ge=0)
    description: Optional[str] = Field(None, min_length=10, max_length=1000)
    prerequisite_course_ref: Optional[int] = None
    duration_hours: Optional[int] = Field(None, ge=0)
    syllabus: Optional[str] = None
    teaching_method: Optional[str] = None
    age_group: Optional[str] = None
    is_highlighted: bool = False


class CourseUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=50)
    language_ref: Optional[int] = None
    level_ref: Optional[int] = None
    sessions_count: Optional[int] = Field(None, gt=0)
    cost: Optional[int] = Field(None, ge=0)
    description: Optional[str] = Field(None, max_length=1000)
    prerequisite_course_ref: Optional[int] = None
    duration_hours: Optional[int] = Field(None, ge=0)
    syllabus: Optional[str] = None
    teaching_method: Optional[str] = None
    age_group: Optional[str] = None
    is_highlighted: Optional[bool] = None
    is_active: Optional[bool] = None


# ---------- Class ----------
ClassStatus = Literal["draft", "open", "full", "in_progress", "finished", "cancelled"]
ClassType = Literal["group", "semi_private", "private", "vip"]


class ClassCreate(BaseModel):
    course_ref: int
    teacher_ref: int
    session_type_ref: int
    start_date: Optional[str] = Field(None, pattern=r"^\d{4}/\d{2}/\d{2}$")
    end_date: Optional[str] = Field(None, pattern=r"^\d{4}/\d{2}/\d{2}$")
    capacity: int = Field(15, ge=0)
    status: ClassStatus = "open"
    class_type: ClassType = "group"
    branch_ref: Optional[int] = None
    location_address: Optional[str] = None
    meeting_link: Optional[str] = None

    @field_validator("meeting_link", "location_address")
    @classmethod
    def strip_empty(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and not v.strip():
            return None
        return v


class ClassUpdate(BaseModel):
    teacher_ref: Optional[int] = None
    session_type_ref: Optional[int] = None
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    capacity: Optional[int] = Field(None, ge=0)
    status: Optional[ClassStatus] = None
    cancel_reason: Optional[str] = None
    class_type: Optional[ClassType] = None
    branch_ref: Optional[int] = None
    location_address: Optional[str] = None
    meeting_link: Optional[str] = None


# ---------- Session ----------
SessionStatus = Literal["scheduled", "in_progress", "completed", "cancelled", "rescheduled"]


class SessionCreate(BaseModel):
    class_ref: int
    date: str = Field(..., pattern=r"^\d{4}/\d{2}/\d{2}$")
    start_time: str = Field(..., pattern=r"^\d{2}:\d{2}$")
    end_time: str = Field(..., pattern=r"^\d{2}:\d{2}$")
    session_type_ref: int
    status: SessionStatus = "scheduled"
    meeting_link: Optional[str] = None
    location_address: Optional[str] = None
    is_makeup: bool = False
    notes: Optional[str] = None
    allow_past_date: bool = False  # فقط برای جبرانی/اصلاحی


class SessionUpdate(BaseModel):
    date: Optional[str] = None
    start_time: Optional[str] = None
    end_time: Optional[str] = None
    session_type_ref: Optional[int] = None
    status: Optional[SessionStatus] = None
    cancel_reason: Optional[str] = None
    meeting_link: Optional[str] = None
    location_address: Optional[str] = None
    substitute_teacher_ref: Optional[int] = None
    is_makeup: Optional[bool] = None
    notes: Optional[str] = None


# ---------- Attendance ----------
AttendanceStatus = Literal["present", "absent", "late", "leave"]


class AttendanceCreate(BaseModel):
    session_ref: int
    student_ref: int
    attendance_status: AttendanceStatus = "present"


class AttendanceBulkItem(BaseModel):
    student_ref: int
    attendance_status: AttendanceStatus = "present"


class AttendanceBulkCreate(BaseModel):
    session_ref: int
    items: list[AttendanceBulkItem]


# ---------- Student / Teacher ----------
class StudentCreate(BaseModel):
    first_name: str = Field(..., min_length=1, max_length=50)
    last_name: str = Field(..., min_length=1, max_length=50)
    father_name: str = Field(..., min_length=1, max_length=50)
    national_code: str = Field(..., min_length=10, max_length=10)
    gender: Literal[1, 2]
    birth_date: str = Field(..., pattern=r"^\d{4}/\d{2}/\d{2}$")
    mobile: str = Field(..., min_length=8, max_length=20)
    email: Optional[str] = None
    target_language_ref: Optional[int] = None
    current_level_ref: Optional[int] = None
    preferred_ui_language: Literal["fa", "en"] = "fa"
    notifications_enabled: bool = True


class TeacherCreate(BaseModel):
    first_name: str = Field(..., min_length=1, max_length=50)
    last_name: str = Field(..., min_length=1, max_length=50)
    father_name: Optional[str] = None
    national_code: str = Field(..., min_length=10, max_length=10)
    gender: Literal[1, 2]
    birth_date: Optional[str] = None
    mobile: str = Field(..., min_length=8, max_length=20)
    email: Optional[str] = None
    specialty: str = Field(..., min_length=1, max_length=200)
    bio: Optional[str] = None


# ---------- Enrollment / Payment / Score ----------
EnrollmentStatus = Literal[
    "pending_payment", "pending_approval", "active", "frozen", "completed", "withdrawn", "transferred"
]
FinancialStatus = Literal["debtor", "settled", "partial"]
PaymentStatus = Literal["draft", "pending", "paid", "failed", "refunded", "partially_paid", "overdue"]
PaymentMethod = Literal["cash", "card", "online", "installment", "other"]
ExamType = Literal["placement", "midterm", "final", "quiz", "assignment"]


class EnrollmentCreate(BaseModel):
    student_ref: int
    class_ref: int
    course_ref: Optional[int] = None  # در صورت خالی بودن از Course کلاس پر می‌شود
    date: str = Field(..., pattern=r"^\d{4}/\d{2}/\d{2}$")
    status: EnrollmentStatus = "pending_payment"
    financial_status: FinancialStatus = "debtor"


class EnrollmentUpdate(BaseModel):
    status: Optional[EnrollmentStatus] = None
    withdraw_reason: Optional[str] = None
    financial_status: Optional[FinancialStatus] = None


class PaymentCreate(BaseModel):
    student_ref: int
    amount: int = Field(..., ge=0)
    date: str = Field(..., pattern=r"^\d{4}/\d{2}/\d{2}$")
    payment_method: PaymentMethod
    status: PaymentStatus = "paid"
    registration_ref: Optional[int] = None
    description: Optional[str] = None
    payment_type: Optional[int] = None  # سازگاری با ستون قدیمی


class ScoreCreate(BaseModel):
    registration_ref: int
    exam_type: ExamType
    score_value: float = Field(..., ge=0)
    max_score: float = Field(100, gt=0)
    notes: Optional[str] = None
    exam_date: Optional[str] = None


class MessageOut(BaseModel):
    message: str
    id: Optional[int] = None
