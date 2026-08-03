"""
آزمون تعیین سطح آنلاین — انواع آزمون، مخزن سوالات، قوانین سطح، شرکت زبان‌آموز
"""
from __future__ import annotations

import random
from datetime import datetime
from typing import Any, Literal, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field, field_validator
from zoneinfo import ZoneInfo

from auth import get_current_user, require_roles
from database import db_cursor, execute, execute_returning_id, fetch_all, fetch_one

router = APIRouter(prefix="/placement", tags=["placement"])

AuthDep = Depends(get_current_user)
TeacherStaffDep = Depends(require_roles("admin", "secretary", "education", "teacher"))
# مشاهده نتایج آزمون تعیین سطح — بدون مدرس
PlacementResultsDep = Depends(require_roles("admin", "secretary", "education"))

SkillType = Literal["grammar", "vocabulary", "reading", "listening", "general"]
CorrectOpt = Literal["A", "B", "C", "D"]

SKILL_FA = {
    "grammar": "گرامر",
    "vocabulary": "واژگان",
    "reading": "درک مطلب",
    "listening": "شنیداری",
    "general": "عمومی",
}


class PlacementTestTypeCreate(BaseModel):
    code: str = Field(..., min_length=1, max_length=40)
    name: str = Field(..., min_length=1, max_length=200)
    language_ref: int
    description: Optional[str] = None
    duration_minutes: int = Field(30, ge=5, le=180)
    questions_to_ask: int = Field(10, ge=1, le=100)
    is_active: bool = True


class PlacementTestTypeUpdate(BaseModel):
    code: Optional[str] = Field(None, min_length=1, max_length=40)
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    language_ref: Optional[int] = None
    description: Optional[str] = None
    duration_minutes: Optional[int] = Field(None, ge=5, le=180)
    questions_to_ask: Optional[int] = Field(None, ge=1, le=100)
    is_active: Optional[bool] = None


class PlacementQuestionCreate(BaseModel):
    test_type_ref: int
    skill: SkillType = "general"
    difficulty: int = Field(1, ge=1, le=5)
    prompt: str = Field(..., min_length=1)
    option_a: str = Field(..., min_length=1, max_length=500)
    option_b: str = Field(..., min_length=1, max_length=500)
    option_c: str = Field(..., min_length=1, max_length=500)
    option_d: str = Field(..., min_length=1, max_length=500)
    correct_option: CorrectOpt
    points: float = Field(1.0, gt=0, le=100)
    explanation: Optional[str] = None
    is_active: bool = True


class PlacementQuestionUpdate(BaseModel):
    test_type_ref: Optional[int] = None
    skill: Optional[SkillType] = None
    difficulty: Optional[int] = Field(None, ge=1, le=5)
    prompt: Optional[str] = Field(None, min_length=1)
    option_a: Optional[str] = Field(None, min_length=1, max_length=500)
    option_b: Optional[str] = Field(None, min_length=1, max_length=500)
    option_c: Optional[str] = Field(None, min_length=1, max_length=500)
    option_d: Optional[str] = Field(None, min_length=1, max_length=500)
    correct_option: Optional[CorrectOpt] = None
    points: Optional[float] = Field(None, gt=0, le=100)
    explanation: Optional[str] = None
    is_active: Optional[bool] = None


class PlacementLevelRuleCreate(BaseModel):
    test_type_ref: int
    min_percent: float = Field(..., ge=0, le=100)
    max_percent: float = Field(..., ge=0, le=100)
    level_ref: int
    label: Optional[str] = Field(None, max_length=200)

    @field_validator("max_percent")
    @classmethod
    def max_ge_min(cls, v: float, info) -> float:
        mn = info.data.get("min_percent")
        if mn is not None and v < mn:
            raise ValueError("حداکثر درصد باید از حداقل بزرگ‌تر یا مساوی باشد")
        return v


class PlacementLevelRuleUpdate(BaseModel):
    min_percent: Optional[float] = Field(None, ge=0, le=100)
    max_percent: Optional[float] = Field(None, ge=0, le=100)
    level_ref: Optional[int] = None
    label: Optional[str] = Field(None, max_length=200)


class PlacementStartRequest(BaseModel):
    test_type_ref: int


class PlacementAnswerRequest(BaseModel):
    question_ref: int
    selected_option: Optional[CorrectOpt] = None


def ensure_placement_schema() -> None:
    execute(
        """
        IF OBJECT_ID(N'dbo.PlacementTestType', N'U') IS NULL
        CREATE TABLE dbo.PlacementTestType (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            Code NVARCHAR(40) NOT NULL,
            Name NVARCHAR(200) NOT NULL,
            LanguageRef INT NOT NULL,
            Description NVARCHAR(MAX) NULL,
            DurationMinutes INT NOT NULL CONSTRAINT DF_PTT_Dur DEFAULT (30),
            QuestionsToAsk INT NOT NULL CONSTRAINT DF_PTT_Q DEFAULT (10),
            IsActive BIT NOT NULL CONSTRAINT DF_PTT_Active DEFAULT (1),
            CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_PTT_Created DEFAULT (SYSUTCDATETIME()),
            CONSTRAINT UQ_PlacementTestType_Code UNIQUE (Code),
            CONSTRAINT FK_PTT_Language FOREIGN KEY (LanguageRef) REFERENCES dbo.Language(Id),
            CONSTRAINT CK_PTT_Dur CHECK (DurationMinutes BETWEEN 5 AND 180),
            CONSTRAINT CK_PTT_Q CHECK (QuestionsToAsk BETWEEN 1 AND 100)
        )
        """
    )
    execute(
        """
        IF OBJECT_ID(N'dbo.PlacementQuestion', N'U') IS NULL
        CREATE TABLE dbo.PlacementQuestion (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            TestTypeRef INT NOT NULL,
            Skill NVARCHAR(20) NOT NULL CONSTRAINT DF_PQ_Skill DEFAULT (N'general'),
            Difficulty INT NOT NULL CONSTRAINT DF_PQ_Diff DEFAULT (1),
            Prompt NVARCHAR(MAX) NOT NULL,
            OptionA NVARCHAR(500) NOT NULL,
            OptionB NVARCHAR(500) NOT NULL,
            OptionC NVARCHAR(500) NOT NULL,
            OptionD NVARCHAR(500) NOT NULL,
            CorrectOption CHAR(1) NOT NULL,
            Points FLOAT NOT NULL CONSTRAINT DF_PQ_Pts DEFAULT (1),
            Explanation NVARCHAR(MAX) NULL,
            IsActive BIT NOT NULL CONSTRAINT DF_PQ_Active DEFAULT (1),
            Creator NVARCHAR(100) NULL,
            CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_PQ_Created DEFAULT (SYSUTCDATETIME()),
            UpdatedAt DATETIME2 NULL,
            CONSTRAINT FK_PQ_TestType FOREIGN KEY (TestTypeRef) REFERENCES dbo.PlacementTestType(Id),
            CONSTRAINT CK_PQ_Skill CHECK (Skill IN (N'grammar', N'vocabulary', N'reading', N'listening', N'general')),
            CONSTRAINT CK_PQ_Diff CHECK (Difficulty BETWEEN 1 AND 5),
            CONSTRAINT CK_PQ_Correct CHECK (CorrectOption IN ('A','B','C','D')),
            CONSTRAINT CK_PQ_Pts CHECK (Points > 0)
        )
        """
    )
    execute(
        """
        IF OBJECT_ID(N'dbo.PlacementLevelRule', N'U') IS NULL
        CREATE TABLE dbo.PlacementLevelRule (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            TestTypeRef INT NOT NULL,
            MinPercent FLOAT NOT NULL,
            MaxPercent FLOAT NOT NULL,
            LevelRef INT NOT NULL,
            Label NVARCHAR(200) NULL,
            CONSTRAINT FK_PLR_TestType FOREIGN KEY (TestTypeRef) REFERENCES dbo.PlacementTestType(Id),
            CONSTRAINT FK_PLR_Level FOREIGN KEY (LevelRef) REFERENCES dbo.Level(Id),
            CONSTRAINT CK_PLR_Range CHECK (MinPercent >= 0 AND MaxPercent <= 100 AND MaxPercent >= MinPercent)
        )
        """
    )
    execute(
        """
        IF OBJECT_ID(N'dbo.PlacementAttempt', N'U') IS NULL
        CREATE TABLE dbo.PlacementAttempt (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            TestTypeRef INT NOT NULL,
            StudentRef INT NOT NULL,
            Status NVARCHAR(20) NOT NULL CONSTRAINT DF_PA_Status DEFAULT (N'in_progress'),
            StartedAt DATETIME2 NOT NULL CONSTRAINT DF_PA_Started DEFAULT (SYSUTCDATETIME()),
            FinishedAt DATETIME2 NULL,
            ScoreValue FLOAT NULL,
            MaxScore FLOAT NULL,
            PercentScore FLOAT NULL,
            SuggestedLevelRef INT NULL,
            ScoreRecordRef INT NULL,
            CONSTRAINT FK_PA_TestType FOREIGN KEY (TestTypeRef) REFERENCES dbo.PlacementTestType(Id),
            CONSTRAINT FK_PA_Student FOREIGN KEY (StudentRef) REFERENCES dbo.Student(Id),
            CONSTRAINT FK_PA_Level FOREIGN KEY (SuggestedLevelRef) REFERENCES dbo.Level(Id),
            CONSTRAINT CK_PA_Status CHECK (Status IN (N'in_progress', N'completed', N'abandoned'))
        )
        """
    )
    execute(
        """
        IF OBJECT_ID(N'dbo.PlacementAttemptAnswer', N'U') IS NULL
        CREATE TABLE dbo.PlacementAttemptAnswer (
            Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            AttemptRef INT NOT NULL,
            QuestionRef INT NOT NULL,
            SelectedOption CHAR(1) NULL,
            IsCorrect BIT NULL,
            PointsAwarded FLOAT NULL,
            SortOrder INT NOT NULL CONSTRAINT DF_PAA_Sort DEFAULT (0),
            CONSTRAINT FK_PAA_Attempt FOREIGN KEY (AttemptRef) REFERENCES dbo.PlacementAttempt(Id),
            CONSTRAINT FK_PAA_Question FOREIGN KEY (QuestionRef) REFERENCES dbo.PlacementQuestion(Id),
            CONSTRAINT UQ_PAA_Attempt_Q UNIQUE (AttemptRef, QuestionRef),
            CONSTRAINT CK_PAA_Opt CHECK (SelectedOption IS NULL OR SelectedOption IN ('A','B','C','D'))
        )
        """
    )
    _seed_demo_if_empty()


def _seed_demo_if_empty() -> None:
    if fetch_one("SELECT COUNT(*) AS C FROM PlacementTestType")["C"]:
        return
    lang = fetch_one("SELECT TOP 1 Id FROM Language ORDER BY Id")
    if not lang:
        return
    lang_id = int(lang["Id"])
    levels = fetch_all(
        "SELECT TOP 4 Id, Code, Name FROM Level WHERE LanguageRef = ? AND IsActive = 1 ORDER BY SortOrder, Id",
        (lang_id,),
    )
    if len(levels) < 2:
        levels = fetch_all("SELECT TOP 4 Id, Code, Name FROM Level WHERE IsActive = 1 ORDER BY SortOrder, Id")
    if len(levels) < 2:
        return

    tid = execute_returning_id(
        """INSERT INTO PlacementTestType
            (Code, Name, LanguageRef, Description, DurationMinutes, QuestionsToAsk, IsActive)
           VALUES (N'EN-PLACEMENT', N'آزمون تعیین سطح عمومی انگلیسی', ?,
                   N'آزمون چندگزینه‌ای برای پیشنهاد سطح مناسب. نتیجه بلافاصله پس از پایان اعلام می‌شود.',
                   20, 8, 1)""",
        (lang_id,),
    )

    bands = [
        (0, 39, levels[0]),
        (40, 59, levels[min(1, len(levels) - 1)]),
        (60, 79, levels[min(2, len(levels) - 1)]),
        (80, 100, levels[min(3, len(levels) - 1)]),
    ]
    for mn, mx, lv in bands:
        execute(
            """INSERT INTO PlacementLevelRule (TestTypeRef, MinPercent, MaxPercent, LevelRef, Label)
               VALUES (?, ?, ?, ?, ?)""",
            (tid, mn, mx, int(lv["Id"]), f"پیشنهاد: {lv['Name']}"),
        )

    samples = [
        ("grammar", 1, "She _____ to school every day.", "go", "goes", "going", "gone", "B", "فاعل سوم‌شخص مفرد → goes"),
        ("grammar", 2, "If it rains, we _____ at home.", "stay", "stayed", "will stay", "staying", "C", "شرطی نوع اول"),
        ("vocabulary", 1, "A synonym of 'happy' is:", "sad", "angry", "glad", "tired", "C", None),
        ("vocabulary", 2, "Please _____ the door when you leave.", "open", "close", "break", "paint", "B", None),
        ("reading", 2, "Tom has two cats. They are black. How many cats does Tom have?", "One", "Two", "Three", "None", "B", None),
        ("grammar", 3, "I have _____ finished my homework.", "yet", "already", "never", "ever", "B", "already برای عمل کامل‌شده"),
        ("vocabulary", 3, "The opposite of 'expensive' is:", "cheap", "heavy", "large", "fast", "A", None),
        ("general", 2, "_____ are you from?", "What", "Where", "Who", "Which", "B", None),
        ("grammar", 4, "Neither John nor his friends _____ coming.", "is", "are", "be", "was", "B", None),
        ("vocabulary", 4, "To 'postpone' means to:", "cancel", "delay", "finish", "start", "B", None),
    ]
    for skill, diff, prompt, a, b, c, d, correct, expl in samples:
        execute(
            """INSERT INTO PlacementQuestion
                (TestTypeRef, Skill, Difficulty, Prompt, OptionA, OptionB, OptionC, OptionD,
                 CorrectOption, Points, Explanation, IsActive, Creator)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, 1, N'system')""",
            (tid, skill, diff, prompt, a, b, c, d, correct, expl),
        )


def _ok_list(key: str, rows: list[dict[str, Any]]) -> dict[str, Any]:
    return {key: rows, "count": len(rows)}


def _not_found(entity: str = "مورد") -> HTTPException:
    return HTTPException(status_code=404, detail=f"{entity} یافت نشد")


def _bad(msg: str) -> HTTPException:
    return HTTPException(status_code=400, detail=msg)


def _forbidden(msg: str = "دسترسی مجاز نیست") -> HTTPException:
    return HTTPException(status_code=403, detail=msg)


def _student_ref(user: dict[str, Any]) -> int:
    sid = user.get("StudentRef")
    if not sid:
        raise _forbidden("حساب شما به زبان‌آموز متصل نیست")
    return int(sid)


def _today_jalali() -> str:
    now = datetime.now(ZoneInfo("Asia/Tehran"))
    gy, gm, gd = now.year, now.month, now.day
    gdm = (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334)
    gy2 = gy + 1 if gm > 2 else gy
    days = 365 * gy + gy2 // 4 - gy2 // 100 + gy2 // 400 - 80 + gd + gdm[gm - 1]
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
    return f"{jy:04d}/{jm:02d}/{jd:02d}"


def _public_question(q: dict[str, Any], *, include_answer: bool = False) -> dict[str, Any]:
    out = {
        "Id": q["Id"],
        "Skill": q["Skill"],
        "SkillLabel": SKILL_FA.get(q["Skill"], q["Skill"]),
        "Difficulty": q["Difficulty"],
        "Prompt": q["Prompt"],
        "OptionA": q["OptionA"],
        "OptionB": q["OptionB"],
        "OptionC": q["OptionC"],
        "OptionD": q["OptionD"],
        "Points": float(q["Points"] or 1),
        "SortOrder": q.get("SortOrder"),
        "SelectedOption": q.get("SelectedOption"),
    }
    if include_answer:
        out["CorrectOption"] = q["CorrectOption"]
        out["Explanation"] = q.get("Explanation")
        raw_ok = q.get("IsCorrect")
        out["IsCorrect"] = bool(raw_ok) if raw_ok is not None else None
        out["PointsAwarded"] = q.get("PointsAwarded")
    return out


def _resolve_level(test_type_ref: int, percent: float) -> Optional[dict[str, Any]]:
    return fetch_one(
        """
        SELECT TOP 1 R.Id, R.LevelRef, R.Label, R.MinPercent, R.MaxPercent,
               L.Name AS LevelName, L.Code AS LevelCode
        FROM PlacementLevelRule R
        JOIN Level L ON L.Id = R.LevelRef
        WHERE R.TestTypeRef = ?
          AND ? >= R.MinPercent AND ? <= R.MaxPercent
        ORDER BY R.MinPercent DESC
        """,
        (test_type_ref, percent, percent),
    )


TEST_TYPE_SELECT = """
    SELECT T.Id, T.Code, T.Name, T.LanguageRef, T.Description, T.DurationMinutes,
           T.QuestionsToAsk, T.IsActive, T.CreatedAt,
           L.Name AS LanguageName,
           (SELECT COUNT(*) FROM PlacementQuestion Q
            WHERE Q.TestTypeRef = T.Id AND Q.IsActive = 1) AS ActiveQuestionCount
    FROM PlacementTestType T
    JOIN Language L ON L.Id = T.LanguageRef
"""

QUESTION_SELECT = """
    SELECT Q.Id, Q.TestTypeRef, Q.Skill, Q.Difficulty, Q.Prompt,
           Q.OptionA, Q.OptionB, Q.OptionC, Q.OptionD, Q.CorrectOption,
           Q.Points, Q.Explanation, Q.IsActive, Q.Creator, Q.CreatedAt, Q.UpdatedAt,
           T.Name AS TestTypeName
    FROM PlacementQuestion Q
    JOIN PlacementTestType T ON T.Id = Q.TestTypeRef
"""


@router.get("/test-types")
async def list_test_types(
    include_inactive: bool = False,
    language_ref: Optional[int] = None,
    user: dict = AuthDep,
):
    roles = set(user.get("_roles") or [])
    is_staff = bool(roles & {"admin", "secretary", "education", "teacher"})
    q = TEST_TYPE_SELECT + " WHERE 1=1"
    params: list[Any] = []
    if not include_inactive or not is_staff:
        q += " AND T.IsActive = 1"
    if language_ref is not None:
        q += " AND T.LanguageRef = ?"
        params.append(language_ref)
    q += " ORDER BY T.Name"
    return _ok_list("test_types", fetch_all(q, tuple(params)))


@router.post("/test-types", status_code=201)
async def create_test_type(body: PlacementTestTypeCreate, user: dict = TeacherStaffDep):
    if not fetch_one("SELECT Id FROM Language WHERE Id = ?", (body.language_ref,)):
        raise _bad("زبان معتبر نیست")
    if fetch_one("SELECT Id FROM PlacementTestType WHERE Code = ?", (body.code.strip(),)):
        raise _bad("کد آزمون تکراری است")
    new_id = execute_returning_id(
        """INSERT INTO PlacementTestType
            (Code, Name, LanguageRef, Description, DurationMinutes, QuestionsToAsk, IsActive)
           VALUES (?, ?, ?, ?, ?, ?, ?)""",
        (
            body.code.strip(),
            body.name.strip(),
            body.language_ref,
            body.description,
            body.duration_minutes,
            body.questions_to_ask,
            1 if body.is_active else 0,
        ),
    )
    return {"message": "نوع آزمون ایجاد شد", "id": new_id}


@router.put("/test-types/{type_id}")
async def update_test_type(type_id: int, body: PlacementTestTypeUpdate, user: dict = TeacherStaffDep):
    if not fetch_one("SELECT Id FROM PlacementTestType WHERE Id = ?", (type_id,)):
        raise _not_found("نوع آزمون")
    data = body.model_dump(exclude_unset=True)
    if not data:
        raise _bad("فیلدی برای به‌روزرسانی نیست")
    if "code" in data and data["code"]:
        data["code"] = data["code"].strip()
        dup = fetch_one(
            "SELECT Id FROM PlacementTestType WHERE Code = ? AND Id <> ?",
            (data["code"], type_id),
        )
        if dup:
            raise _bad("کد آزمون تکراری است")
    if "language_ref" in data and data["language_ref"] is not None:
        if not fetch_one("SELECT Id FROM Language WHERE Id = ?", (data["language_ref"],)):
            raise _bad("زبان معتبر نیست")
    fields = []
    params: list[Any] = []
    colmap = {
        "code": "Code",
        "name": "Name",
        "language_ref": "LanguageRef",
        "description": "Description",
        "duration_minutes": "DurationMinutes",
        "questions_to_ask": "QuestionsToAsk",
        "is_active": "IsActive",
    }
    for k, col in colmap.items():
        if k in data:
            val = data[k]
            if k == "is_active":
                val = 1 if val else 0
            elif k == "name" and isinstance(val, str):
                val = val.strip()
            fields.append(f"[{col}] = ?")
            params.append(val)
    params.append(type_id)
    execute(f"UPDATE PlacementTestType SET {', '.join(fields)} WHERE Id = ?", tuple(params))
    return {"message": "نوع آزمون به‌روز شد"}


@router.delete("/test-types/{type_id}")
async def delete_test_type(type_id: int, user: dict = TeacherStaffDep):
    row = fetch_one("SELECT Id FROM PlacementTestType WHERE Id = ?", (type_id,))
    if not row:
        raise _not_found("نوع آزمون")
    used = fetch_one("SELECT COUNT(*) AS C FROM PlacementAttempt WHERE TestTypeRef = ?", (type_id,))["C"]
    if used:
        execute("UPDATE PlacementTestType SET IsActive = 0 WHERE Id = ?", (type_id,))
        return {"message": "نوع آزمون آرشیو شد (سوابق آزمون حفظ شد)"}
    execute("DELETE FROM PlacementLevelRule WHERE TestTypeRef = ?", (type_id,))
    execute("DELETE FROM PlacementQuestion WHERE TestTypeRef = ?", (type_id,))
    execute("DELETE FROM PlacementTestType WHERE Id = ?", (type_id,))
    return {"message": "نوع آزمون حذف شد"}


@router.get("/questions")
async def list_questions(
    test_type_ref: Optional[int] = None,
    skill: Optional[str] = None,
    search: Optional[str] = None,
    include_inactive: bool = False,
    user: dict = TeacherStaffDep,
):
    q = QUESTION_SELECT + " WHERE 1=1"
    params: list[Any] = []
    if not include_inactive:
        q += " AND Q.IsActive = 1"
    if test_type_ref is not None:
        q += " AND Q.TestTypeRef = ?"
        params.append(test_type_ref)
    if skill:
        q += " AND Q.Skill = ?"
        params.append(skill)
    if search and search.strip():
        q += " AND Q.Prompt LIKE ?"
        params.append(f"%{search.strip()}%")
    q += " ORDER BY Q.Id DESC"
    rows = fetch_all(q, tuple(params))
    for r in rows:
        r["SkillLabel"] = SKILL_FA.get(r["Skill"], r["Skill"])
    return _ok_list("questions", rows)


@router.post("/questions", status_code=201)
async def create_question(body: PlacementQuestionCreate, user: dict = TeacherStaffDep):
    if not fetch_one("SELECT Id FROM PlacementTestType WHERE Id = ?", (body.test_type_ref,)):
        raise _bad("نوع آزمون معتبر نیست")
    creator = user.get("Username") or user.get("username") or "staff"
    new_id = execute_returning_id(
        """INSERT INTO PlacementQuestion
            (TestTypeRef, Skill, Difficulty, Prompt, OptionA, OptionB, OptionC, OptionD,
             CorrectOption, Points, Explanation, IsActive, Creator)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            body.test_type_ref,
            body.skill,
            body.difficulty,
            body.prompt.strip(),
            body.option_a.strip(),
            body.option_b.strip(),
            body.option_c.strip(),
            body.option_d.strip(),
            body.correct_option,
            body.points,
            body.explanation,
            1 if body.is_active else 0,
            creator,
        ),
    )
    return {"message": "سوال افزوده شد", "id": new_id}


@router.put("/questions/{question_id}")
async def update_question(question_id: int, body: PlacementQuestionUpdate, user: dict = TeacherStaffDep):
    if not fetch_one("SELECT Id FROM PlacementQuestion WHERE Id = ?", (question_id,)):
        raise _not_found("سوال")
    data = body.model_dump(exclude_unset=True)
    if not data:
        raise _bad("فیلدی برای به‌روزرسانی نیست")
    if "test_type_ref" in data and data["test_type_ref"] is not None:
        if not fetch_one("SELECT Id FROM PlacementTestType WHERE Id = ?", (data["test_type_ref"],)):
            raise _bad("نوع آزمون معتبر نیست")
    colmap = {
        "test_type_ref": "TestTypeRef",
        "skill": "Skill",
        "difficulty": "Difficulty",
        "prompt": "Prompt",
        "option_a": "OptionA",
        "option_b": "OptionB",
        "option_c": "OptionC",
        "option_d": "OptionD",
        "correct_option": "CorrectOption",
        "points": "Points",
        "explanation": "Explanation",
        "is_active": "IsActive",
    }
    fields = ["UpdatedAt = SYSUTCDATETIME()"]
    params: list[Any] = []
    for k, col in colmap.items():
        if k not in data:
            continue
        val = data[k]
        if k == "is_active":
            val = 1 if val else 0
        elif isinstance(val, str) and k in ("prompt", "option_a", "option_b", "option_c", "option_d"):
            val = val.strip()
        fields.append(f"[{col}] = ?")
        params.append(val)
    params.append(question_id)
    execute(f"UPDATE PlacementQuestion SET {', '.join(fields)} WHERE Id = ?", tuple(params))
    return {"message": "سوال به‌روز شد"}


@router.delete("/questions/{question_id}")
async def delete_question(question_id: int, user: dict = TeacherStaffDep):
    row = fetch_one("SELECT Id FROM PlacementQuestion WHERE Id = ?", (question_id,))
    if not row:
        raise _not_found("سوال")
    used = fetch_one(
        "SELECT COUNT(*) AS C FROM PlacementAttemptAnswer WHERE QuestionRef = ?",
        (question_id,),
    )["C"]
    if used:
        execute(
            "UPDATE PlacementQuestion SET IsActive = 0, UpdatedAt = SYSUTCDATETIME() WHERE Id = ?",
            (question_id,),
        )
        return {"message": "سوال آرشیو شد (در آزمون‌های قبلی استفاده شده)"}
    execute("DELETE FROM PlacementQuestion WHERE Id = ?", (question_id,))
    return {"message": "سوال حذف شد"}


@router.get("/level-rules")
async def list_level_rules(test_type_ref: Optional[int] = None, user: dict = TeacherStaffDep):
    q = """
        SELECT R.Id, R.TestTypeRef, R.MinPercent, R.MaxPercent, R.LevelRef, R.Label,
               L.Name AS LevelName, L.Code AS LevelCode, T.Name AS TestTypeName
        FROM PlacementLevelRule R
        JOIN Level L ON L.Id = R.LevelRef
        JOIN PlacementTestType T ON T.Id = R.TestTypeRef
        WHERE 1=1
    """
    params: list[Any] = []
    if test_type_ref is not None:
        q += " AND R.TestTypeRef = ?"
        params.append(test_type_ref)
    q += " ORDER BY R.TestTypeRef, R.MinPercent"
    return _ok_list("level_rules", fetch_all(q, tuple(params)))


@router.post("/level-rules", status_code=201)
async def create_level_rule(body: PlacementLevelRuleCreate, user: dict = TeacherStaffDep):
    if not fetch_one("SELECT Id FROM PlacementTestType WHERE Id = ?", (body.test_type_ref,)):
        raise _bad("نوع آزمون معتبر نیست")
    if not fetch_one("SELECT Id FROM Level WHERE Id = ? AND IsActive = 1", (body.level_ref,)):
        raise _bad("سطح معتبر نیست")
    new_id = execute_returning_id(
        """INSERT INTO PlacementLevelRule (TestTypeRef, MinPercent, MaxPercent, LevelRef, Label)
           VALUES (?, ?, ?, ?, ?)""",
        (body.test_type_ref, body.min_percent, body.max_percent, body.level_ref, body.label),
    )
    return {"message": "قانون سطح افزوده شد", "id": new_id}


@router.put("/level-rules/{rule_id}")
async def update_level_rule(rule_id: int, body: PlacementLevelRuleUpdate, user: dict = TeacherStaffDep):
    cur = fetch_one("SELECT * FROM PlacementLevelRule WHERE Id = ?", (rule_id,))
    if not cur:
        raise _not_found("قانون سطح")
    data = body.model_dump(exclude_unset=True)
    if not data:
        raise _bad("فیلدی برای به‌روزرسانی نیست")
    mn = data.get("min_percent", float(cur["MinPercent"]))
    mx = data.get("max_percent", float(cur["MaxPercent"]))
    if mx < mn:
        raise _bad("حداکثر درصد نامعتبر است")
    if "level_ref" in data and data["level_ref"] is not None:
        if not fetch_one("SELECT Id FROM Level WHERE Id = ? AND IsActive = 1", (data["level_ref"],)):
            raise _bad("سطح معتبر نیست")
    colmap = {
        "min_percent": "MinPercent",
        "max_percent": "MaxPercent",
        "level_ref": "LevelRef",
        "label": "Label",
    }
    fields, params = [], []
    for k, col in colmap.items():
        if k in data:
            fields.append(f"[{col}] = ?")
            params.append(data[k])
    params.append(rule_id)
    execute(f"UPDATE PlacementLevelRule SET {', '.join(fields)} WHERE Id = ?", tuple(params))
    return {"message": "قانون سطح به‌روز شد"}


@router.delete("/level-rules/{rule_id}")
async def delete_level_rule(rule_id: int, user: dict = TeacherStaffDep):
    if not fetch_one("SELECT Id FROM PlacementLevelRule WHERE Id = ?", (rule_id,)):
        raise _not_found("قانون سطح")
    execute("DELETE FROM PlacementLevelRule WHERE Id = ?", (rule_id,))
    return {"message": "قانون سطح حذف شد"}


@router.get("/attempts/me")
async def my_attempts(user: dict = AuthDep):
    sid = _student_ref(user)
    rows = fetch_all(
        """
        SELECT A.Id, A.TestTypeRef, A.Status, A.StartedAt, A.FinishedAt,
               A.ScoreValue, A.MaxScore, A.PercentScore, A.SuggestedLevelRef,
               T.Name AS TestTypeName, L.Name AS SuggestedLevelName, L.Code AS SuggestedLevelCode
        FROM PlacementAttempt A
        JOIN PlacementTestType T ON T.Id = A.TestTypeRef
        LEFT JOIN Level L ON L.Id = A.SuggestedLevelRef
        WHERE A.StudentRef = ?
        ORDER BY A.Id DESC
        """,
        (sid,),
    )
    return _ok_list("attempts", rows)


@router.get("/attempts")
async def list_attempts(
    test_type_ref: Optional[int] = None,
    student_ref: Optional[int] = None,
    status: Optional[str] = None,
    user: dict = PlacementResultsDep,
):
    q = """
        SELECT A.Id, A.TestTypeRef, A.StudentRef, A.Status, A.StartedAt, A.FinishedAt,
               A.ScoreValue, A.MaxScore, A.PercentScore, A.SuggestedLevelRef,
               T.Name AS TestTypeName,
               S.FirstName + N' ' + S.LastName AS StudentName,
               L.Name AS SuggestedLevelName
        FROM PlacementAttempt A
        JOIN PlacementTestType T ON T.Id = A.TestTypeRef
        JOIN Student S ON S.Id = A.StudentRef
        LEFT JOIN Level L ON L.Id = A.SuggestedLevelRef
        WHERE 1=1
    """
    params: list[Any] = []
    if test_type_ref is not None:
        q += " AND A.TestTypeRef = ?"
        params.append(test_type_ref)
    if student_ref is not None:
        q += " AND A.StudentRef = ?"
        params.append(student_ref)
    if status:
        q += " AND A.Status = ?"
        params.append(status)
    q += " ORDER BY A.Id DESC"
    return _ok_list("attempts", fetch_all(q, tuple(params)))


def _attempt_taking_payload(attempt_id: int, sid: int) -> dict[str, Any]:
    attempt = fetch_one(
        """
        SELECT A.*, T.Name AS TestTypeName, T.DurationMinutes, T.QuestionsToAsk,
               T.Description AS TestDescription, Lang.Name AS LanguageName
        FROM PlacementAttempt A
        JOIN PlacementTestType T ON T.Id = A.TestTypeRef
        JOIN Language Lang ON Lang.Id = T.LanguageRef
        WHERE A.Id = ?
        """,
        (attempt_id,),
    )
    if not attempt or int(attempt["StudentRef"]) != sid:
        raise _not_found("آزمون")
    if attempt["Status"] != "in_progress":
        return _attempt_result_payload(attempt_id, sid, is_staff=False)

    questions = fetch_all(
        """
        SELECT Q.Id, Q.Skill, Q.Difficulty, Q.Prompt, Q.OptionA, Q.OptionB, Q.OptionC, Q.OptionD,
               Q.Points, A.SortOrder, A.SelectedOption
        FROM PlacementAttemptAnswer A
        JOIN PlacementQuestion Q ON Q.Id = A.QuestionRef
        WHERE A.AttemptRef = ?
        ORDER BY A.SortOrder, A.Id
        """,
        (attempt_id,),
    )
    return {
        "attempt": {
            "Id": attempt["Id"],
            "Status": attempt["Status"],
            "TestTypeRef": attempt["TestTypeRef"],
            "TestTypeName": attempt["TestTypeName"],
            "DurationMinutes": attempt["DurationMinutes"],
            "LanguageName": attempt["LanguageName"],
            "TestDescription": attempt["TestDescription"],
            "StartedAt": attempt["StartedAt"],
            "AnsweredCount": sum(1 for q in questions if q.get("SelectedOption")),
            "TotalQuestions": len(questions),
        },
        "questions": [_public_question(q) for q in questions],
    }


def _result_message(attempt: dict[str, Any]) -> str:
    pct = attempt.get("PercentScore")
    level = attempt.get("SuggestedLevelName")
    if level:
        return (
            f"آزمون شما با موفقیت به پایان رسید. نمره: {attempt.get('ScoreValue')} از "
            f"{attempt.get('MaxScore')} ({pct}٪). سطح پیشنهادی سیستم: «{level}»."
        )
    return (
        f"آزمون شما به پایان رسید. نمره: {attempt.get('ScoreValue')} از "
        f"{attempt.get('MaxScore')} ({pct}٪). برای این بازه هنوز قانون سطح تعریف نشده است."
    )


def _attempt_result_payload(attempt_id: int, sid: Optional[int], *, is_staff: bool) -> dict[str, Any]:
    attempt = fetch_one(
        """
        SELECT A.*, T.Name AS TestTypeName, T.Description AS TestDescription,
               Lang.Name AS LanguageName,
               L.Name AS SuggestedLevelName, L.Code AS SuggestedLevelCode,
               S.FirstName + N' ' + S.LastName AS StudentName
        FROM PlacementAttempt A
        JOIN PlacementTestType T ON T.Id = A.TestTypeRef
        JOIN Language Lang ON Lang.Id = T.LanguageRef
        JOIN Student S ON S.Id = A.StudentRef
        LEFT JOIN Level L ON L.Id = A.SuggestedLevelRef
        WHERE A.Id = ?
        """,
        (attempt_id,),
    )
    if not attempt:
        raise _not_found("آزمون")
    if not is_staff and sid is not None and int(attempt["StudentRef"]) != sid:
        raise _forbidden()
    if attempt["Status"] != "completed" and not is_staff:
        raise _bad("نتیجه هنوز آماده نیست")

    include_answer = attempt["Status"] == "completed"
    questions = fetch_all(
        """
        SELECT Q.Id, Q.Skill, Q.Difficulty, Q.Prompt, Q.OptionA, Q.OptionB, Q.OptionC, Q.OptionD,
               Q.Points, Q.CorrectOption, Q.Explanation,
               A.SortOrder, A.SelectedOption, A.IsCorrect, A.PointsAwarded
        FROM PlacementAttemptAnswer A
        JOIN PlacementQuestion Q ON Q.Id = A.QuestionRef
        WHERE A.AttemptRef = ?
        ORDER BY A.SortOrder, A.Id
        """,
        (attempt_id,),
    )
    return {
        "attempt": {
            "Id": attempt["Id"],
            "Status": attempt["Status"],
            "TestTypeRef": attempt["TestTypeRef"],
            "TestTypeName": attempt["TestTypeName"],
            "TestDescription": attempt["TestDescription"],
            "LanguageName": attempt["LanguageName"],
            "StudentName": attempt["StudentName"],
            "StartedAt": attempt["StartedAt"],
            "FinishedAt": attempt["FinishedAt"],
            "ScoreValue": attempt["ScoreValue"],
            "MaxScore": attempt["MaxScore"],
            "PercentScore": attempt["PercentScore"],
            "SuggestedLevelRef": attempt["SuggestedLevelRef"],
            "SuggestedLevelName": attempt["SuggestedLevelName"],
            "SuggestedLevelCode": attempt["SuggestedLevelCode"],
            "ScoreRecordRef": attempt["ScoreRecordRef"],
        },
        "questions": [_public_question(q, include_answer=include_answer) for q in questions],
        "result_message": _result_message(attempt) if include_answer else None,
    }


@router.post("/attempts", status_code=201)
async def start_attempt(body: PlacementStartRequest, user: dict = AuthDep):
    sid = _student_ref(user)
    tt = fetch_one(TEST_TYPE_SELECT + " WHERE T.Id = ? AND T.IsActive = 1", (body.test_type_ref,))
    if not tt:
        raise _not_found("نوع آزمون")

    existing = fetch_one(
        """
        SELECT Id FROM PlacementAttempt
        WHERE StudentRef = ? AND TestTypeRef = ? AND Status = N'in_progress'
        """,
        (sid, body.test_type_ref),
    )
    if existing:
        return _attempt_taking_payload(int(existing["Id"]), sid)

    pool = fetch_all(
        "SELECT Id, Points FROM PlacementQuestion WHERE TestTypeRef = ? AND IsActive = 1",
        (body.test_type_ref,),
    )
    if not pool:
        raise _bad("برای این آزمون هنوز سوالی در مخزن نیست")
    n = min(int(tt["QuestionsToAsk"]), len(pool))
    picked = random.sample(pool, n)

    with db_cursor() as cursor:
        cursor.execute(
            """INSERT INTO PlacementAttempt (TestTypeRef, StudentRef, Status)
               OUTPUT INSERTED.Id
               VALUES (?, ?, N'in_progress')""",
            (body.test_type_ref, sid),
        )
        attempt_id = int(cursor.fetchone()[0])
        for i, q in enumerate(picked):
            cursor.execute(
                """INSERT INTO PlacementAttemptAnswer (AttemptRef, QuestionRef, SortOrder)
                   VALUES (?, ?, ?)""",
                (attempt_id, int(q["Id"]), i + 1),
            )

    return _attempt_taking_payload(attempt_id, sid)


@router.get("/attempts/{attempt_id}")
async def get_attempt(attempt_id: int, user: dict = AuthDep):
    roles = set(user.get("_roles") or [])
    # مدرس حق مشاهده نتیجه تعیین سطح را ندارد
    can_view_results = bool(roles & {"admin", "secretary", "education"})
    attempt = fetch_one("SELECT * FROM PlacementAttempt WHERE Id = ?", (attempt_id,))
    if not attempt:
        raise _not_found("آزمون")
    if can_view_results:
        return _attempt_result_payload(attempt_id, None, is_staff=True)
    if "teacher" in roles and not user.get("StudentRef"):
        raise _forbidden("مدرس مجاز به مشاهده نتایج تعیین سطح نیست")
    sid = _student_ref(user)
    if int(attempt["StudentRef"]) != sid:
        raise _forbidden()
    if attempt["Status"] == "in_progress":
        return _attempt_taking_payload(attempt_id, sid)
    return _attempt_result_payload(attempt_id, sid, is_staff=False)


@router.put("/attempts/{attempt_id}/answer")
async def save_answer(attempt_id: int, body: PlacementAnswerRequest, user: dict = AuthDep):
    sid = _student_ref(user)
    attempt = fetch_one("SELECT * FROM PlacementAttempt WHERE Id = ?", (attempt_id,))
    if not attempt or int(attempt["StudentRef"]) != sid:
        raise _not_found("آزمون")
    if attempt["Status"] != "in_progress":
        raise _bad("این آزمون دیگر قابل پاسخ‌دهی نیست")
    row = fetch_one(
        "SELECT Id FROM PlacementAttemptAnswer WHERE AttemptRef = ? AND QuestionRef = ?",
        (attempt_id, body.question_ref),
    )
    if not row:
        raise _bad("این سوال متعلق به این آزمون نیست")
    # None یا خالی = پاک کردن پاسخ (سوال بدون پاسخ می‌ماند)
    opt = body.selected_option
    if isinstance(opt, str):
        opt = opt.strip().upper() or None
    execute(
        """UPDATE PlacementAttemptAnswer
           SET SelectedOption = ?, IsCorrect = NULL, PointsAwarded = NULL
           WHERE AttemptRef = ? AND QuestionRef = ?""",
        (opt, attempt_id, body.question_ref),
    )
    answered = fetch_one(
        """SELECT COUNT(*) AS C FROM PlacementAttemptAnswer
           WHERE AttemptRef = ? AND SelectedOption IS NOT NULL""",
        (attempt_id,),
    )["C"]
    total = fetch_one(
        "SELECT COUNT(*) AS C FROM PlacementAttemptAnswer WHERE AttemptRef = ?",
        (attempt_id,),
    )["C"]
    return {"message": "پاسخ ذخیره شد", "answered": answered, "total": total}


@router.post("/attempts/{attempt_id}/submit")
async def submit_attempt(attempt_id: int, user: dict = AuthDep):
    sid = _student_ref(user)
    attempt = fetch_one("SELECT * FROM PlacementAttempt WHERE Id = ?", (attempt_id,))
    if not attempt or int(attempt["StudentRef"]) != sid:
        raise _not_found("آزمون")
    if attempt["Status"] != "in_progress":
        return _attempt_result_payload(attempt_id, sid, is_staff=False)

    items = fetch_all(
        """
        SELECT A.Id AS AnswerId, A.QuestionRef, A.SelectedOption,
               Q.CorrectOption, Q.Points
        FROM PlacementAttemptAnswer A
        JOIN PlacementQuestion Q ON Q.Id = A.QuestionRef
        WHERE A.AttemptRef = ?
        """,
        (attempt_id,),
    )
    if not items:
        raise _bad("سوالی برای تصحیح نیست")

    # سوالات بدون پاسخ مجازند و صفر نمره می‌گیرند
    score = 0.0
    max_score = 0.0
    with db_cursor() as cursor:
        for it in items:
            pts = float(it["Points"] or 1)
            max_score += pts
            selected = (it.get("SelectedOption") or "").strip().upper()
            ok = bool(selected) and selected == (it["CorrectOption"] or "").upper()
            awarded = pts if ok else 0.0
            score += awarded
            cursor.execute(
                """UPDATE PlacementAttemptAnswer
                   SET IsCorrect = ?, PointsAwarded = ?
                   WHERE Id = ?""",
                (1 if ok else 0, awarded, int(it["AnswerId"])),
            )

        percent = round((score / max_score) * 100, 2) if max_score else 0.0
        level = _resolve_level(int(attempt["TestTypeRef"]), percent)
        level_ref = int(level["LevelRef"]) if level else None

        notes = f"آزمون آنلاین تعیین سطح #{attempt_id}"
        if level:
            notes += f" — پیشنهاد: {level.get('LevelName')}"
        cursor.execute(
            """INSERT INTO Score
                (StudentRef, RegistrationRef, ExamType, ScoreValue, MaxScore, Notes, ExamDate, SuggestedLevelRef)
               OUTPUT INSERTED.Id
               VALUES (?, NULL, N'placement', ?, ?, ?, ?, ?)""",
            (sid, score, max_score, notes, _today_jalali(), level_ref),
        )
        score_id = int(cursor.fetchone()[0])

        cursor.execute(
            """UPDATE PlacementAttempt
               SET Status = N'completed', FinishedAt = SYSUTCDATETIME(),
                   ScoreValue = ?, MaxScore = ?, PercentScore = ?,
                   SuggestedLevelRef = ?, ScoreRecordRef = ?
               WHERE Id = ?""",
            (score, max_score, percent, level_ref, score_id, attempt_id),
        )

        if level_ref:
            cursor.execute(
                "UPDATE Student SET CurrentLevelRef = ? WHERE Id = ?",
                (level_ref, sid),
            )

    return _attempt_result_payload(attempt_id, sid, is_staff=False)
