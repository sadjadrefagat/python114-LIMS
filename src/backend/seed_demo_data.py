"""
دادهٔ نمایشی تصادفی برای داشبورد مدیران
حداقل ۱۰۰ رکورد در جداول عملیاتی با وضعیت‌های متنوع
"""
from __future__ import annotations

import random
from typing import Any

from database import execute, fetch_all, fetch_one, get_connection

RNG = random.Random(20260730)

FIRST = [
    "علی", "سارا", "رضا", "مریم", "حسین", "نازنین", "امیر", "زهرا", "مهدی", "نگار",
    "پارسا", "آیدا", "کیان", "هستی", "آرین", "یاسمن", "نیما", "الهام", "شایان", "سحر",
]
LAST = [
    "محمدی", "حسینی", "رضایی", "کریمی", "موسوی", "نوری", "کاظمی", "جعفری", "احمدی", "صادقی",
    "باقری", "طاهری", "اکبری", "شریفی", "حیدری", "مرادی", "یوسفی", "رحیمی", "عباسی", "فرهادی",
]
SPECIALTIES = ["مکالمه", "گرامر", "IELTS", "TOEFL", "کودک", "آلمانی", "فرانسه", "اسپانیایی"]
METHODS = ["حضوری", "آنلاین", "ترکیبی", "مکالمه‌محور", "گرامرمحور", "مهارت‌محور", "آزمون‌محور", "فشرده"]
AGES = ["کودک", "نوجوان", "جوان", "بزرگسال", "همه سنین"]
CLASS_STATUSES = ["draft", "open", "full", "in_progress", "finished", "cancelled"]
CLASS_TYPES = ["group", "semi_private", "private", "vip"]
SESSION_STATUSES = ["scheduled", "in_progress", "completed", "cancelled", "rescheduled"]
REG_STATUSES = [
    "pending_payment",
    "pending_approval",
    "active",
    "frozen",
    "completed",
    "withdrawn",
    "transferred",
]
FIN_STATUSES = ["debtor", "settled", "creditor"]
PAY_STATUSES = ["draft", "pending", "paid", "failed", "refunded", "partially_paid", "overdue"]
PAY_METHODS = ["cash", "card", "online", "installment", "other"]


def valid_national_code(seed: int) -> str:
    """تولید کد ملی معتبر یکتا بر اساس seed"""
    base = f"{(seed % 900000000) + 100000000:09d}"
    total = sum(int(base[i]) * (10 - i) for i in range(9))
    rem = total % 11
    check = rem if rem < 2 else 11 - rem
    return base + str(check)


def jalali(y: int, m: int, d: int) -> str:
    return f"{y}/{m:02d}/{d:02d}"


def pick(seq: list[Any]) -> Any:
    return RNG.choice(seq)


def weighted(pairs: list[tuple[Any, int]]) -> Any:
    items, weights = zip(*pairs)
    return RNG.choices(list(items), weights=list(weights), k=1)[0]


def existing_codes() -> set[str]:
    rows = fetch_all("SELECT NationalCode AS C FROM Student UNION SELECT NationalCode FROM Teacher")
    return {str(r["C"]) for r in rows}


def ensure_people(need_students: int = 40, need_teachers: int = 20) -> None:
    codes = existing_codes()
    langs = [r["Id"] for r in fetch_all("SELECT Id FROM Language")]
    st_count = fetch_one("SELECT COUNT(*) AS C FROM Student WHERE IsActive = 1")["C"]
    te_count = fetch_one("SELECT COUNT(*) AS C FROM Teacher WHERE IsActive = 1")["C"]

    seed = 50000
    while st_count < need_students:
        code = valid_national_code(seed)
        seed += 1
        if code in codes:
            continue
        codes.add(code)
        fn, ln = pick(FIRST), pick(LAST)
        execute(
            """INSERT INTO Student
                ([FirstName],[LastName],[FatherName],[NationalCode],[Gender],[BirthDate],
                 [Mobile],[Creator],[Email],[TargetLanguageRef],[PreferredUILanguage],
                 [NotificationsEnabled],[IsActive])
               VALUES (?,?,?,?,?,?,?,?,?,?,?,1,1)""",
            (
                fn,
                ln,
                pick(FIRST),
                code,
                pick([1, 2]),
                jalali(RNG.randint(1365, 1395), RNG.randint(1, 12), RNG.randint(1, 28)),
                f"09{RNG.randint(100000000, 199999999)}",
                "seed",
                f"{fn}.{ln}{seed}@demo.lims".replace(" ", ""),
                pick(langs) if langs else None,
                "fa",
            ),
        )
        st_count += 1

    while te_count < need_teachers:
        code = valid_national_code(seed)
        seed += 1
        if code in codes:
            continue
        codes.add(code)
        fn, ln = pick(FIRST), pick(LAST)
        execute(
            """INSERT INTO Teacher
                ([FirstName],[LastName],[FatherName],[NationalCode],[Gender],[BirthDate],
                 [Creator],[Mobile],[Email],[Specialty],[Bio],[IsActive])
               VALUES (?,?,?,?,?,?,?,?,?,?,?,1)""",
            (
                fn,
                ln,
                pick(FIRST),
                code,
                pick([1, 2]),
                jalali(RNG.randint(1345, 1375), RNG.randint(1, 12), RNG.randint(1, 28)),
                "seed",
                f"09{RNG.randint(300000000, 399999999)}",
                f"teacher.{seed}@demo.lims",
                pick(SPECIALTIES),
                "مدرس نمایشی برای داشبورد",
            ),
        )
        te_count += 1


def ensure_courses(min_count: int = 40) -> None:
    langs = fetch_all("SELECT Id, Name FROM Language")
    levels = fetch_all("SELECT Id, LanguageRef FROM Level WHERE IsActive = 1")
    count = fetch_one("SELECT COUNT(*) AS C FROM Course WHERE IsActive = 1")["C"]
    i = 0
    while count < min_count and langs:
        lang = pick(langs)
        lvl_opts = [lv for lv in levels if lv["LanguageRef"] == lang["Id"]]
        level_ref = pick(lvl_opts)["Id"] if lvl_opts else None
        i += 1
        name = f"دوره نمایشی {lang['Name']} #{count + 1}"
        execute(
            """INSERT INTO Course
                ([Name],[LanguageRef],[LevelRef],[SessionsCount],[Cost],[Creator],
                 [Description],[TeachingMethod],[AgeGroup],[IsHighlighted],[IsActive])
               VALUES (?,?,?,?,?,?,?,?,?,?,1)""",
            (
                name[:50],
                lang["Id"],
                level_ref,
                RNG.choice([12, 16, 20, 24, 30]),
                RNG.choice([8, 12, 15, 20, 25, 35, 45]) * 1_000_000,
                "seed",
                "توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.",
                pick(METHODS),
                pick(AGES),
                1 if RNG.random() < 0.2 else 0,
            ),
        )
        count += 1


def seed_classes(n: int = 120) -> list[int]:
    courses = [r["Id"] for r in fetch_all("SELECT Id FROM Course WHERE IsActive = 1")]
    teachers = [r["Id"] for r in fetch_all("SELECT Id FROM Teacher WHERE IsActive = 1")]
    stypes = [r["Id"] for r in fetch_all("SELECT Id FROM SessionType")]
    branches = [r["Id"] for r in fetch_all("SELECT Id FROM Branch WHERE IsActive = 1")]
    if not (courses and teachers and stypes):
        raise RuntimeError("داده پایه Course/Teacher/SessionType کافی نیست")

    ids: list[int] = []
    for i in range(n):
        status = weighted(
            [
                ("open", 28),
                ("in_progress", 22),
                ("full", 12),
                ("finished", 15),
                ("draft", 10),
                ("cancelled", 13),
            ]
        )
        y = RNG.choice([1403, 1404, 1405])
        sm = RNG.randint(1, 10)
        start = jalali(y, sm, RNG.randint(1, 20))
        end = jalali(y, min(sm + RNG.randint(1, 3), 12), RNG.randint(10, 28))
        cancel = "لغو نمایشی" if status == "cancelled" else None
        st = pick(stypes)
        loc = "کلاس نمایشی طبقه ۲" if st == 1 else None
        link = "https://meet.demo.lims/class" if st == 2 else None
        new_id = None
        conn = get_connection()
        cur = conn.cursor()
        try:
            cur.execute(
                """INSERT INTO Class
                    ([CourseRef],[TeacherRef],[SessionTypeRef],[StartDate],[EndDate],
                     [Capacity],[Status],[CancelReason],[ClassType],[BranchRef],
                     [LocationAddress],[MeetingLink])
                   VALUES (?,?,?,?,?,?,?,?,?,?,?,?);
                   SELECT CAST(SCOPE_IDENTITY() AS INT)""",
                (
                    pick(courses),
                    pick(teachers),
                    st,
                    start,
                    end,
                    RNG.choice([8, 10, 12, 15, 18, 20]),
                    status,
                    cancel,
                    pick(CLASS_TYPES),
                    pick(branches) if branches else None,
                    loc,
                    link,
                ),
            )
            while cur.description is None:
                if not cur.nextset():
                    break
            row = cur.fetchone()
            new_id = int(row[0]) if row and row[0] is not None else None
            conn.commit()
        finally:
            cur.close()
            conn.close()
        if new_id:
            ids.append(new_id)
    return ids


def seed_sessions(class_ids: list[int], n: int = 150) -> None:
    stypes = [r["Id"] for r in fetch_all("SELECT Id FROM SessionType")]
    if not class_ids or not stypes:
        return
    for _ in range(n):
        status = weighted(
            [
                ("scheduled", 35),
                ("completed", 25),
                ("in_progress", 10),
                ("cancelled", 15),
                ("rescheduled", 15),
            ]
        )
        sh = RNG.randint(8, 18)
        execute(
            """INSERT INTO [Session]
                ([ClassRef],[Date],[StartTime],[EndTime],[SessionTypeRef],[Status],
                 [CancelReason],[IsMakeup],[Notes])
               VALUES (?,?,?,?,?,?,?,?,?)""",
            (
                pick(class_ids),
                jalali(RNG.choice([1404, 1405]), RNG.randint(1, 12), RNG.randint(1, 28)),
                f"{sh:02d}:00",
                f"{sh + 2:02d}:00",
                pick(stypes),
                status,
                "لغو جلسه نمایشی" if status == "cancelled" else None,
                1 if RNG.random() < 0.1 else 0,
                "جلسه نمایشی داشبورد",
            ),
        )


def seed_registrations(class_ids: list[int], n: int = 200) -> list[dict[str, Any]]:
    students = [r["Id"] for r in fetch_all("SELECT Id FROM Student WHERE IsActive = 1")]
    class_rows = fetch_all(
        f"SELECT Id, CourseRef FROM Class WHERE Id IN ({','.join('?' * len(class_ids))})",
        tuple(class_ids),
    ) if class_ids else []
    if not students or not class_rows:
        return []

    created: list[dict[str, Any]] = []
    used: set[tuple[int, int]] = set()
    # existing pairs
    for r in fetch_all(
        """SELECT Studentref AS S, ClassRef AS C FROM Registration
           WHERE ClassRef IS NOT NULL AND Status NOT IN (N'withdrawn', N'transferred')"""
    ):
        if r["C"] is not None:
            used.add((int(r["S"]), int(r["C"])))

    attempts = 0
    while len(created) < n and attempts < n * 8:
        attempts += 1
        cl = pick(class_rows)
        st = pick(students)
        key = (st, int(cl["Id"]))
        if key in used:
            continue
        status = weighted(
            [
                ("active", 30),
                ("pending_payment", 18),
                ("pending_approval", 12),
                ("completed", 12),
                ("frozen", 8),
                ("withdrawn", 12),
                ("transferred", 8),
            ]
        )
        fin = weighted([("debtor", 40), ("settled", 35), ("creditor", 25)])
        withdraw = "انصراف نمایشی" if status == "withdrawn" else None
        conn = get_connection()
        cur = conn.cursor()
        try:
            cur.execute(
                """INSERT INTO Registration
                    ([Studentref],[CourseRef],[ClassRef],[Date],[Status],[WithdrawReason],[FinancialStatus])
                   VALUES (?,?,?,?,?,?,?);
                   SELECT CAST(SCOPE_IDENTITY() AS INT)""",
                (
                    st,
                    cl["CourseRef"],
                    cl["Id"],
                    jalali(1405, RNG.randint(1, 7), RNG.randint(1, 28)),
                    status,
                    withdraw,
                    fin,
                ),
            )
            while cur.description is None:
                if not cur.nextset():
                    break
            row = cur.fetchone()
            rid = int(row[0]) if row and row[0] is not None else None
            conn.commit()
        except Exception:
            conn.rollback()
            rid = None
        finally:
            cur.close()
            conn.close()
        if rid:
            used.add(key)
            created.append({"id": rid, "student": st, "course": cl["CourseRef"]})
    return created


def seed_payments(regs: list[dict[str, Any]], n: int = 160) -> None:
    students = [r["Id"] for r in fetch_all("SELECT Id FROM Student WHERE IsActive = 1")]
    for i in range(n):
        reg = pick(regs) if regs and RNG.random() < 0.75 else None
        student = reg["student"] if reg else pick(students)
        status = weighted(
            [
                ("paid", 40),
                ("pending", 15),
                ("partially_paid", 12),
                ("failed", 10),
                ("draft", 8),
                ("refunded", 8),
                ("overdue", 7),
            ]
        )
        execute(
            """INSERT INTO Payment
                ([StudentRef],[Date],[Amount],[PaymentType],[Status],[PaymentMethod],
                 [RegistrationRef],[Description])
               VALUES (?,?,?,?,?,?,?,?)""",
            (
                student,
                jalali(1405, RNG.randint(1, 7), RNG.randint(1, 28)),
                RNG.choice([5, 8, 10, 12, 15, 20, 25, 30]) * 1_000_000,
                RNG.choice([1, 2, 3]),
                status,
                pick(PAY_METHODS),
                reg["id"] if reg else None,
                "پرداخت نمایشی داشبورد",
            ),
        )


def main() -> None:
    print("Seeding demo data...")
    ensure_people(80, 25)
    ensure_courses(45)
    class_ids = seed_classes(120)
    print("classes created", len(class_ids))
    # include existing classes too
    all_classes = [r["Id"] for r in fetch_all("SELECT Id FROM Class")]
    seed_sessions(all_classes, 160)
    print("sessions done")
    regs = seed_registrations(all_classes, 220)
    print("registrations created", len(regs))
    seed_payments(regs, 180)
    print("payments done")

    summary = {
        "students": fetch_one("SELECT COUNT(*) AS C FROM Student WHERE IsActive=1")["C"],
        "teachers": fetch_one("SELECT COUNT(*) AS C FROM Teacher WHERE IsActive=1")["C"],
        "courses": fetch_one("SELECT COUNT(*) AS C FROM Course WHERE IsActive=1")["C"],
        "classes": fetch_one("SELECT COUNT(*) AS C FROM Class")["C"],
        "sessions": fetch_one("SELECT COUNT(*) AS C FROM [Session]")["C"],
        "registrations": fetch_one("SELECT COUNT(*) AS C FROM Registration")["C"],
        "payments": fetch_one("SELECT COUNT(*) AS C FROM Payment")["C"],
        "payments_paid": fetch_one(
            "SELECT ISNULL(SUM(Amount),0) AS T FROM Payment WHERE Status=N'paid'"
        )["T"],
    }
    print("SUMMARY", summary)
    print("Class statuses", fetch_all("SELECT Status, COUNT(*) AS C FROM Class GROUP BY Status"))
    print("Reg statuses", fetch_all("SELECT Status, COUNT(*) AS C FROM Registration GROUP BY Status"))
    print("Session statuses", fetch_all("SELECT Status, COUNT(*) AS C FROM [Session] GROUP BY Status"))
    print("Payment statuses", fetch_all("SELECT Status, COUNT(*) AS C FROM Payment GROUP BY Status"))


if __name__ == "__main__":
    main()
