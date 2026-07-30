"""مدل‌های Pydantic برای اعتبارسنجی ورودی/خروجی API"""
from __future__ import annotations

import re
from typing import Any, Literal, Optional

from pydantic import BaseModel, Field, field_validator, model_validator

# ارقام فارسی/عربی → انگلیسی
_DIGIT_MAP = str.maketrans("۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩", "01234567890123456789")

_JALALI_DATE_RE = re.compile(r"^\d{4}/\d{2}/\d{2}$")
_TIME_RE = re.compile(r"^([01]\d|2[0-3]):([0-5]\d)$")


def normalize_digits(value: str) -> str:
    return (value or "").strip().translate(_DIGIT_MAP)


def normalize_national_code(value: str) -> str:
    return normalize_digits(value)


def is_valid_national_code(value: str) -> bool:
    """همان الگوریتم dbo.CheckNationalCode در SQL Server"""
    code = normalize_national_code(value)
    if len(code) != 10 or not code.isdigit():
        return False
    total = sum(int(code[i]) * (10 - i) for i in range(9))
    rem = total % 11
    if rem >= 2:
        rem = 11 - rem
    return int(code[9]) == rem


def validate_national_code(value: str) -> str:
    code = normalize_national_code(value)
    if len(code) != 10 or not code.isdigit():
        raise ValueError("کد ملی باید ۱۰ رقم باشد")
    if not is_valid_national_code(code):
        raise ValueError("کد ملی نامعتبر است")
    return code


_MOBILE_RE = re.compile(r"^09\d{9}$")


def validate_mobile(value: str) -> str:
    """موبایل ایران: دقیقاً ۱۱ رقم، فقط عدد، شروع با ۰۹"""
    text = normalize_digits(value)
    if not text.isdigit():
        raise ValueError("موبایل باید فقط عدد باشد")
    if len(text) != 11:
        raise ValueError("موبایل باید ۱۱ رقم باشد")
    if not _MOBILE_RE.fullmatch(text):
        raise ValueError("موبایل باید با ۰۹ شروع شود")
    return text


def validate_jalali_date(value: str, *, field_name: str = "تاریخ") -> str:
    text = normalize_digits(value)
    if not _JALALI_DATE_RE.fullmatch(text):
        raise ValueError(f"{field_name} باید به صورت YYYY/MM/DD باشد")
    return text


def _today_jalali_str() -> str:
    from datetime import date

    gy, gm, gd = date.today().year, date.today().month, date.today().day
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
    return f"{jy}/{jm:02d}/{jd:02d}"


def validate_birth_date(value: str) -> str:
    """تاریخ تولد معتبر و نه در آینده"""
    text = validate_jalali_date(value, field_name="تاریخ تولد")
    if text > _today_jalali_str():
        raise ValueError("تاریخ تولد نمی‌تواند در آینده باشد")
    return text


def validate_time_hhmm(value: str, *, field_name: str = "ساعت") -> str:
    """ساعت معتبر ۲۴ساعته: ۰۰:۰۰ تا ۲۳:۵۹"""
    text = normalize_digits(value)
    if re.fullmatch(r"\d{2}:\d{2}:\d{2}", text):
        text = text[:5]
    if not _TIME_RE.fullmatch(text):
        raise ValueError(f"{field_name} باید به صورت HH:MM و بین ۰۰:۰۰ تا ۲۳:۵۹ باشد")
    return text


# برچسب فارسی فیلدها برای پیام‌های Validation
FIELD_LABELS_FA: dict[str, str] = {
    "username": "نام کاربری",
    "password": "رمز عبور",
    "password_confirm": "تکرار رمز عبور",
    "current_password": "رمز فعلی",
    "new_password": "رمز جدید",
    "email": "ایمیل",
    "first_name": "نام",
    "last_name": "نام خانوادگی",
    "father_name": "نام پدر",
    "mobile": "موبایل",
    "national_code": "کد ملی",
    "gender": "جنسیت",
    "birth_date": "تاریخ تولد",
    "date": "تاریخ",
    "start_date": "تاریخ شروع",
    "end_date": "تاریخ پایان",
    "start_time": "ساعت شروع",
    "end_time": "ساعت پایان",
    "class_ref": "کلاس",
    "course_ref": "دوره",
    "teacher_ref": "مدرس",
    "student_ref": "زبان‌آموز",
    "session_type_ref": "نوع جلسه",
    "session_ref": "جلسه",
    "language_ref": "زبان",
    "level_ref": "سطح",
    "branch_ref": "شعبه",
    "name": "نام",
    "code": "کد",
    "cost": "هزینه",
    "capacity": "ظرفیت",
    "sessions_count": "تعداد جلسات",
    "description": "توضیحات",
    "specialty": "تخصص",
    "teaching_method": "روش تدریس",
    "age_group": "رده سنی",
    "status": "وضعیت",
    "amount": "مبلغ",
    "score_value": "نمره",
    "max_score": "سقف نمره",
    "refresh_token": "توکن تازه‌سازی",
    "meeting_link": "لینک جلسه",
    "location_address": "آدرس",
    "cancel_reason": "دلیل لغو",
    "notes": "یادداشت",
    "class_type": "نوع کلاس",
    "attendance_status": "وضعیت حضور",
    "target_language_ref": "زبان هدف",
    "preferred_ui_language": "زبان رابط",
}


def format_validation_errors(errors: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """تبدیل خطاهای Pydantic به پیام فارسی برای کلاینت"""
    out: list[dict[str, Any]] = []
    for err in errors:
        loc = [x for x in err.get("loc", ()) if x not in ("body", "query", "path")]
        field = str(loc[-1]) if loc else ""
        label = FIELD_LABELS_FA.get(field, field or "مقدار")
        typ = err.get("type", "")
        raw_msg = str(err.get("msg") or "")
        ctx = err.get("ctx") or {}

        if typ == "value_error":
            msg = raw_msg.replace("Value error, ", "").replace("Value error,", "").strip()
        elif typ in ("missing", "missing_argument"):
            msg = f"{label} الزامی است"
        elif typ == "string_too_short":
            mn = ctx.get("min_length")
            msg = f"{label} نباید کوتاه‌تر از {mn} نویسه باشد" if mn is not None else f"{label} کوتاه است"
        elif typ == "string_too_long":
            mx = ctx.get("max_length")
            msg = f"{label} نباید بلندتر از {mx} نویسه باشد" if mx is not None else f"{label} بلند است"
        elif typ == "string_pattern_mismatch":
            msg = f"فرمت {label} نامعتبر است"
        elif typ in ("greater_than", "gt"):
            msg = f"{label} باید بزرگ‌تر از {ctx.get('gt', '')} باشد"
        elif typ in ("greater_than_equal", "ge"):
            msg = f"{label} باید بزرگ‌تر یا مساوی {ctx.get('ge', '')} باشد"
        elif typ in ("less_than", "lt"):
            msg = f"{label} باید کوچک‌تر از {ctx.get('lt', '')} باشد"
        elif typ in ("less_than_equal", "le"):
            msg = f"{label} باید کوچک‌تر یا مساوی {ctx.get('le', '')} باشد"
        elif typ in ("int_parsing", "int_type"):
            msg = f"{label} باید عدد صحیح باشد"
        elif typ in ("float_parsing", "float_type"):
            msg = f"{label} باید عدد باشد"
        elif typ in ("bool_parsing", "bool_type"):
            msg = f"{label} نامعتبر است"
        elif typ in ("enum", "literal_error"):
            msg = f"{label} مقدار مجاز نیست"
        elif typ == "string_type":
            msg = f"{label} باید متن باشد"
        elif typ == "list_type":
            msg = f"{label} باید لیست باشد"
        elif typ == "model_type":
            msg = "ساختار داده نامعتبر است"
        elif typ == "json_invalid":
            msg = "داده ارسالی نامعتبر است"
        else:
            # اگر پیام از قبل فارسی بود نگه دار؛ وگرنه عمومی
            if any("\u0600" <= ch <= "\u06FF" for ch in raw_msg):
                msg = raw_msg.replace("Value error, ", "").strip()
            else:
                msg = f"{label} نامعتبر است"

        out.append({"loc": list(err.get("loc", ())), "msg": msg, "type": typ})
    return out


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
    mobile: str = Field(..., min_length=1, max_length=20)
    national_code: str = Field(..., min_length=10, max_length=10)
    gender: Literal[1, 2] = 1
    birth_date: str
    target_language_ref: Optional[int] = None
    preferred_ui_language: Literal["fa", "en"] = "fa"

    @field_validator("email")
    @classmethod
    def empty_email_to_none(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        v = v.strip()
        return v or None

    @field_validator("mobile", mode="before")
    @classmethod
    def mobile_check(cls, v: Any) -> str:
        return validate_mobile("" if v is None else str(v))

    @field_validator("national_code")
    @classmethod
    def national_code_check(cls, v: str) -> str:
        return validate_national_code(v)

    @field_validator("birth_date")
    @classmethod
    def birth_date_check(cls, v: str) -> str:
        return validate_birth_date(v)


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


class LanguageUpdate(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)


class LevelCreate(BaseModel):
    language_ref: int
    code: str = Field(..., min_length=1, max_length=20)
    name: str = Field(..., min_length=1, max_length=50)
    sort_order: int = 0


class LevelUpdate(BaseModel):
    language_ref: Optional[int] = None
    code: Optional[str] = Field(None, min_length=1, max_length=20)
    name: Optional[str] = Field(None, min_length=1, max_length=50)
    sort_order: Optional[int] = None


class BranchCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    address: Optional[str] = None
    phone: Optional[str] = None


class BranchUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    address: Optional[str] = None
    phone: Optional[str] = None


# ---------- Course ----------
TeachingMethod = Literal[
    "حضوری",
    "آنلاین",
    "ترکیبی",
    "مکالمه‌محور",
    "گرامرمحور",
    "مهارت‌محور",
    "آزمون‌محور",
    "فشرده",
]
AgeGroup = Literal["کودک", "نوجوان", "جوان", "بزرگسال", "همه سنین"]


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
    teaching_method: TeachingMethod
    age_group: AgeGroup
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
    teaching_method: Optional[TeachingMethod] = None
    age_group: Optional[AgeGroup] = None
    is_highlighted: Optional[bool] = None
    is_active: Optional[bool] = None


# ---------- Class ----------
ClassStatus = Literal["draft", "open", "full", "in_progress", "finished", "cancelled"]
ClassType = Literal["group", "semi_private", "private", "vip"]


class ClassCreate(BaseModel):
    course_ref: int
    teacher_ref: int
    session_type_ref: int
    start_date: str
    end_date: str
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

    @field_validator("start_date")
    @classmethod
    def start_date_check(cls, v: str) -> str:
        return validate_jalali_date(v, field_name="تاریخ شروع")

    @field_validator("end_date")
    @classmethod
    def end_date_check(cls, v: str) -> str:
        return validate_jalali_date(v, field_name="تاریخ پایان")

    @model_validator(mode="after")
    def end_after_start(self):
        if self.start_date and self.end_date and self.end_date < self.start_date:
            raise ValueError("تاریخ پایان کلاس نباید قبل از تاریخ شروع باشد")
        today = _today_jalali_str()
        if self.start_date and self.start_date < today:
            raise ValueError("ثبت کلاس با تاریخ گذشته مجاز نیست")
        return self


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
    date: str
    start_time: str
    end_time: str
    session_type_ref: int
    status: SessionStatus = "scheduled"
    meeting_link: Optional[str] = None
    location_address: Optional[str] = None
    is_makeup: bool = False
    notes: Optional[str] = None
    allow_past_date: bool = False  # فقط برای جبرانی/اصلاحی

    @field_validator("date")
    @classmethod
    def date_check(cls, v: str) -> str:
        return validate_jalali_date(v, field_name="تاریخ جلسه")

    @field_validator("start_time")
    @classmethod
    def start_time_check(cls, v: str) -> str:
        return validate_time_hhmm(v, field_name="ساعت شروع")

    @field_validator("end_time")
    @classmethod
    def end_time_check(cls, v: str) -> str:
        return validate_time_hhmm(v, field_name="ساعت پایان")

    @model_validator(mode="after")
    def end_after_start(self):
        if self.start_time >= self.end_time:
            raise ValueError("ساعت پایان باید بعد از ساعت شروع باشد")
        return self


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

    @field_validator("date")
    @classmethod
    def date_check(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v == "":
            return None
        return validate_jalali_date(v, field_name="تاریخ جلسه")

    @field_validator("start_time")
    @classmethod
    def start_time_check(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v == "":
            return None
        return validate_time_hhmm(v, field_name="ساعت شروع")

    @field_validator("end_time")
    @classmethod
    def end_time_check(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v == "":
            return None
        return validate_time_hhmm(v, field_name="ساعت پایان")

    @model_validator(mode="after")
    def end_after_start(self):
        if self.start_time and self.end_time and self.start_time >= self.end_time:
            raise ValueError("ساعت پایان باید بعد از ساعت شروع باشد")
        return self


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
    birth_date: str
    mobile: str = Field(..., min_length=1, max_length=20)
    email: Optional[str] = None
    target_language_ref: Optional[int] = None
    current_level_ref: Optional[int] = None
    preferred_ui_language: Literal["fa", "en"] = "fa"
    notifications_enabled: bool = True

    @field_validator("national_code")
    @classmethod
    def national_code_check(cls, v: str) -> str:
        return validate_national_code(v)

    @field_validator("mobile", mode="before")
    @classmethod
    def mobile_check(cls, v: Any) -> str:
        return validate_mobile("" if v is None else str(v))

    @field_validator("birth_date")
    @classmethod
    def birth_date_check(cls, v: str) -> str:
        return validate_birth_date(v)


class StudentUpdate(BaseModel):
    first_name: Optional[str] = Field(None, min_length=1, max_length=50)
    last_name: Optional[str] = Field(None, min_length=1, max_length=50)
    father_name: Optional[str] = Field(None, min_length=1, max_length=50)
    national_code: Optional[str] = Field(None, min_length=10, max_length=10)
    gender: Optional[Literal[1, 2]] = None
    birth_date: Optional[str] = None
    mobile: Optional[str] = Field(None, min_length=1, max_length=20)
    email: Optional[str] = None
    target_language_ref: Optional[int] = None
    current_level_ref: Optional[int] = None
    preferred_ui_language: Optional[Literal["fa", "en"]] = None
    notifications_enabled: Optional[bool] = None

    @field_validator("national_code")
    @classmethod
    def national_code_check(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v == "":
            return None
        return validate_national_code(v)

    @field_validator("mobile", mode="before")
    @classmethod
    def mobile_check(cls, v: Any) -> Optional[str]:
        if v is None or v == "":
            return None
        return validate_mobile(str(v))

    @field_validator("birth_date")
    @classmethod
    def birth_date_check(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v == "":
            return None
        return validate_birth_date(v)


class TeacherCreate(BaseModel):
    first_name: str = Field(..., min_length=1, max_length=50)
    last_name: str = Field(..., min_length=1, max_length=50)
    father_name: Optional[str] = None
    national_code: str = Field(..., min_length=10, max_length=10)
    gender: Literal[1, 2]
    birth_date: Optional[str] = None
    mobile: str = Field(..., min_length=1, max_length=20)
    email: Optional[str] = None
    specialty: str = Field(..., min_length=1, max_length=200)
    bio: Optional[str] = None

    @field_validator("national_code")
    @classmethod
    def national_code_check(cls, v: str) -> str:
        return validate_national_code(v)

    @field_validator("mobile", mode="before")
    @classmethod
    def mobile_check(cls, v: Any) -> str:
        return validate_mobile("" if v is None else str(v))

    @field_validator("birth_date")
    @classmethod
    def birth_date_format(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v == "":
            return None
        return validate_birth_date(v)


class TeacherUpdate(BaseModel):
    first_name: Optional[str] = Field(None, min_length=1, max_length=50)
    last_name: Optional[str] = Field(None, min_length=1, max_length=50)
    father_name: Optional[str] = None
    national_code: Optional[str] = Field(None, min_length=10, max_length=10)
    gender: Optional[Literal[1, 2]] = None
    birth_date: Optional[str] = None
    mobile: Optional[str] = Field(None, min_length=1, max_length=20)
    email: Optional[str] = None
    specialty: Optional[str] = Field(None, min_length=1, max_length=200)
    bio: Optional[str] = None

    @field_validator("national_code")
    @classmethod
    def national_code_check(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v == "":
            return None
        return validate_national_code(v)

    @field_validator("mobile", mode="before")
    @classmethod
    def mobile_check(cls, v: Any) -> Optional[str]:
        if v is None or v == "":
            return None
        return validate_mobile(str(v))

    @field_validator("birth_date")
    @classmethod
    def birth_date_format(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v == "":
            return None
        return validate_birth_date(v)


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
    date: str
    status: EnrollmentStatus = "pending_payment"
    financial_status: FinancialStatus = "debtor"

    @field_validator("date")
    @classmethod
    def date_check(cls, v: str) -> str:
        return validate_jalali_date(v, field_name="تاریخ ثبت‌نام")


class EnrollmentBulkCreate(BaseModel):
    """ثبت‌نام چند زبان‌آموز با مقادیر مشترک — بدون تغییر ساختار جدول"""
    student_refs: list[int] = Field(..., min_length=1)
    class_ref: int
    course_ref: Optional[int] = None
    date: str
    status: EnrollmentStatus = "pending_payment"
    financial_status: FinancialStatus = "debtor"

    @field_validator("date")
    @classmethod
    def date_check(cls, v: str) -> str:
        return validate_jalali_date(v, field_name="تاریخ ثبت‌نام")

    @field_validator("student_refs")
    @classmethod
    def unique_students(cls, v: list[int]) -> list[int]:
        seen: set[int] = set()
        out: list[int] = []
        for sid in v:
            if sid not in seen:
                seen.add(sid)
                out.append(sid)
        if not out:
            raise ValueError("حداقل یک زبان‌آموز انتخاب کنید")
        return out


class EnrollmentUpdate(BaseModel):
    status: Optional[EnrollmentStatus] = None
    withdraw_reason: Optional[str] = None
    financial_status: Optional[FinancialStatus] = None


class PaymentCreate(BaseModel):
    student_ref: int
    amount: int = Field(..., ge=0)
    date: str
    payment_method: PaymentMethod
    status: PaymentStatus = "paid"
    registration_ref: Optional[int] = None
    description: Optional[str] = None
    payment_type: Optional[int] = None  # سازگاری با ستون قدیمی

    @field_validator("date")
    @classmethod
    def date_check(cls, v: str) -> str:
        return validate_jalali_date(v, field_name="تاریخ پرداخت")


class ScoreCreate(BaseModel):
    registration_ref: int
    exam_type: ExamType
    score_value: float = Field(..., ge=0)
    max_score: float = Field(100, gt=0)
    notes: Optional[str] = None
    exam_date: Optional[str] = None

    @field_validator("exam_date")
    @classmethod
    def exam_date_check(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v == "":
            return None
        return validate_jalali_date(v, field_name="تاریخ آزمون")


class MessageOut(BaseModel):
    message: str
    id: Optional[int] = None
