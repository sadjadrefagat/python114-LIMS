"""حذف فیزیکی رکوردهای غیرفعال / آرشیو / لغو‌شده از LIMDB"""
from __future__ import annotations

from database import db_cursor, fetch_all, fetch_one


def ph(ids: list[int]) -> tuple[str, tuple]:
    return ",".join("?" for _ in ids), tuple(ids)


def hard_delete_students(cursor, ids: list[int]) -> int:
    if not ids:
        return 0
    placeholders = ",".join("?" for _ in ids)
    params = tuple(ids)
    cursor.execute(f"SELECT Id FROM Student WHERE Id IN ({placeholders})", params)
    existing = [int(r[0]) for r in cursor.fetchall()]
    if not existing:
        return 0
    ex_ph = ",".join("?" for _ in existing)
    ex_params = tuple(existing)

    cursor.execute(f"SELECT Id FROM Registration WHERE StudentRef IN ({ex_ph})", ex_params)
    reg_ids = [int(r[0]) for r in cursor.fetchall()]

    cursor.execute(f"DELETE FROM SessionStudent WHERE StudentRef IN ({ex_ph})", ex_params)

    if reg_ids:
        reg_ph = ",".join("?" for _ in reg_ids)
        reg_params = tuple(reg_ids)
        cursor.execute(
            f"DELETE FROM Score WHERE StudentRef IN ({ex_ph}) OR RegistrationRef IN ({reg_ph})",
            ex_params + reg_params,
        )
        cursor.execute(
            f"DELETE FROM Payment WHERE StudentRef IN ({ex_ph}) OR RegistrationRef IN ({reg_ph})",
            ex_params + reg_params,
        )
        cursor.execute(f"DELETE FROM Registration WHERE Id IN ({reg_ph})", reg_params)
    else:
        cursor.execute(f"DELETE FROM Score WHERE StudentRef IN ({ex_ph})", ex_params)
        cursor.execute(f"DELETE FROM Payment WHERE StudentRef IN ({ex_ph})", ex_params)

    cursor.execute(f"UPDATE AppUser SET StudentRef = NULL WHERE StudentRef IN ({ex_ph})", ex_params)
    cursor.execute(f"DELETE FROM Student WHERE Id IN ({ex_ph})", ex_params)
    return len(existing)


def delete_classes(cursor, class_ids: list[int]) -> int:
    if not class_ids:
        return 0
    p, params = ph(class_ids)
    cursor.execute(f"SELECT Id FROM Session WHERE ClassRef IN ({p})", params)
    sess = [int(r[0]) for r in cursor.fetchall()]
    if sess:
        sp, sparams = ph(sess)
        cursor.execute(f"DELETE FROM SessionStudent WHERE SessionRef IN ({sp})", sparams)
    cursor.execute(f"SELECT Id FROM Registration WHERE ClassRef IN ({p})", params)
    regs = [int(r[0]) for r in cursor.fetchall()]
    if regs:
        rp, rparams = ph(regs)
        cursor.execute(f"DELETE FROM Score WHERE RegistrationRef IN ({rp})", rparams)
        cursor.execute(f"DELETE FROM Payment WHERE RegistrationRef IN ({rp})", rparams)
        cursor.execute(f"DELETE FROM Registration WHERE Id IN ({rp})", rparams)
    if sess:
        sp, sparams = ph(sess)
        cursor.execute(f"DELETE FROM Session WHERE Id IN ({sp})", sparams)
    cursor.execute(f"DELETE FROM Class WHERE Id IN ({p})", params)
    return len(class_ids)


def main() -> None:
    stats: dict[str, int] = {}

    with db_cursor() as cursor:
        cursor.execute("SELECT Id FROM Student WHERE IsActive = 0")
        stu_ids = [int(r[0]) for r in cursor.fetchall()]
        stats["students_inactive_deleted"] = hard_delete_students(cursor, stu_ids)

        cursor.execute("SELECT Id FROM Registration WHERE Status = N'withdrawn'")
        regs = [int(r[0]) for r in cursor.fetchall()]
        if regs:
            rp, rparams = ph(regs)
            cursor.execute(f"DELETE FROM Score WHERE RegistrationRef IN ({rp})", rparams)
            cursor.execute(f"DELETE FROM Payment WHERE RegistrationRef IN ({rp})", rparams)
            cursor.execute(f"DELETE FROM Registration WHERE Id IN ({rp})", rparams)
            stats["withdrawn_regs_deleted"] = len(regs)
        else:
            stats["withdrawn_regs_deleted"] = 0

        cursor.execute("SELECT Id FROM Session WHERE Status = N'cancelled'")
        sess = [int(r[0]) for r in cursor.fetchall()]
        if sess:
            sp, sparams = ph(sess)
            cursor.execute(f"DELETE FROM SessionStudent WHERE SessionRef IN ({sp})", sparams)
            cursor.execute(f"DELETE FROM Session WHERE Id IN ({sp})", sparams)
            stats["cancelled_sessions_deleted"] = len(sess)
        else:
            stats["cancelled_sessions_deleted"] = 0

        cursor.execute("SELECT Id FROM Class WHERE Status = N'cancelled'")
        cls = [int(r[0]) for r in cursor.fetchall()]
        stats["cancelled_classes_deleted"] = delete_classes(cursor, cls)

        # تریگر INSTEAD OF DELETE دوره‌ها را فقط soft-delete می‌کند — موقتاً غیرفعال
        cursor.execute("DISABLE TRIGGER TRG_PreventDeleteCourse ON Course")
        try:
            cursor.execute("SELECT Id FROM Course WHERE IsActive = 0")
            courses = [int(r[0]) for r in cursor.fetchall()]
            if courses:
                cp, cparams = ph(courses)
                cursor.execute(f"SELECT Id FROM Class WHERE CourseRef IN ({cp})", cparams)
                course_classes = [int(r[0]) for r in cursor.fetchall()]
                delete_classes(cursor, course_classes)
                cursor.execute(
                    f"UPDATE Course SET PrerequisiteCourseRef = NULL WHERE PrerequisiteCourseRef IN ({cp})",
                    cparams,
                )
                cursor.execute(f"DELETE FROM CourseHistory WHERE CourseRef IN ({cp})", cparams)
                cursor.execute(f"SELECT Id FROM Registration WHERE CourseRef IN ({cp})", cparams)
                left_regs = [int(r[0]) for r in cursor.fetchall()]
                if left_regs:
                    rp, rparams = ph(left_regs)
                    cursor.execute(f"DELETE FROM Score WHERE RegistrationRef IN ({rp})", rparams)
                    cursor.execute(f"DELETE FROM Payment WHERE RegistrationRef IN ({rp})", rparams)
                    cursor.execute(f"DELETE FROM Registration WHERE Id IN ({rp})", rparams)
                cursor.execute(f"DELETE FROM Course WHERE Id IN ({cp})", cparams)
                stats["courses_inactive_deleted"] = len(courses)
            else:
                stats["courses_inactive_deleted"] = 0
        finally:
            cursor.execute("ENABLE TRIGGER TRG_PreventDeleteCourse ON Course")

        cursor.execute("DISABLE TRIGGER TRG_PreventDeleteTeacher ON Teacher")
        try:
            cursor.execute("SELECT Id FROM Teacher WHERE IsActive = 0")
            teachers = [int(r[0]) for r in cursor.fetchall()]
            if teachers:
                tp, tparams = ph(teachers)
                cursor.execute(f"SELECT Id FROM Class WHERE TeacherRef IN ({tp})", tparams)
                t_classes = [int(r[0]) for r in cursor.fetchall()]
                delete_classes(cursor, t_classes)
                cursor.execute(
                    f"UPDATE Session SET SubstituteTeacherRef = NULL WHERE SubstituteTeacherRef IN ({tp})",
                    tparams,
                )
                cursor.execute(f"UPDATE AppUser SET TeacherRef = NULL WHERE TeacherRef IN ({tp})", tparams)
                cursor.execute(f"DELETE FROM Teacher WHERE Id IN ({tp})", tparams)
                stats["teachers_inactive_deleted"] = len(teachers)
            else:
                stats["teachers_inactive_deleted"] = 0
        finally:
            cursor.execute("ENABLE TRIGGER TRG_PreventDeleteTeacher ON Teacher")

        cursor.execute("SELECT Id FROM Level WHERE IsActive = 0")
        levels = [int(r[0]) for r in cursor.fetchall()]
        if levels:
            lp, lparams = ph(levels)
            cursor.execute(f"UPDATE Course SET LevelRef = NULL WHERE LevelRef IN ({lp})", lparams)
            cursor.execute(
                f"UPDATE Student SET CurrentLevelRef = NULL WHERE CurrentLevelRef IN ({lp})",
                lparams,
            )
            cursor.execute(
                f"UPDATE Score SET SuggestedLevelRef = NULL WHERE SuggestedLevelRef IN ({lp})",
                lparams,
            )
            cursor.execute(f"DELETE FROM Level WHERE Id IN ({lp})", lparams)
            stats["levels_inactive_deleted"] = len(levels)
        else:
            stats["levels_inactive_deleted"] = 0

        cursor.execute("SELECT Id FROM Branch WHERE IsActive = 0")
        branches = [int(r[0]) for r in cursor.fetchall()]
        if branches:
            bp, bparams = ph(branches)
            cursor.execute(f"UPDATE Class SET BranchRef = NULL WHERE BranchRef IN ({bp})", bparams)
            cursor.execute(f"DELETE FROM Branch WHERE Id IN ({bp})", bparams)
            stats["branches_inactive_deleted"] = len(branches)
        else:
            stats["branches_inactive_deleted"] = 0

        cursor.execute("SELECT Id FROM ShopProduct WHERE IsActive = 0")
        products = [int(r[0]) for r in cursor.fetchall()]
        if products:
            pp, pparams = ph(products)
            cursor.execute(
                f"""
                SELECT P.Id FROM ShopProduct P
                WHERE P.Id IN ({pp})
                  AND NOT EXISTS (SELECT 1 FROM ShopOrderItem OI WHERE OI.ProductRef = P.Id)
                """,
                pparams,
            )
            safe = [int(r[0]) for r in cursor.fetchall()]
            if safe:
                sp, sparams = ph(safe)
                cursor.execute(f"DELETE FROM ShopCartItem WHERE ProductRef IN ({sp})", sparams)
                cursor.execute(f"DELETE FROM ShopProductLike WHERE ProductRef IN ({sp})", sparams)
                cursor.execute(f"DELETE FROM ShopProductBookmark WHERE ProductRef IN ({sp})", sparams)
                cursor.execute(f"DELETE FROM ShopProduct WHERE Id IN ({sp})", sparams)
                stats["shop_products_deleted"] = len(safe)
            else:
                stats["shop_products_deleted"] = 0
            stats["shop_products_skipped_in_orders"] = len(products) - len(safe)
        else:
            stats["shop_products_deleted"] = 0
            stats["shop_products_skipped_in_orders"] = 0

        cursor.execute(
            """
            SELECT C.Id FROM ShopCategory C
            WHERE C.IsActive = 0
              AND NOT EXISTS (SELECT 1 FROM ShopProduct P WHERE P.CategoryRef = C.Id)
            """
        )
        cats = [int(r[0]) for r in cursor.fetchall()]
        if cats:
            cp, cparams = ph(cats)
            cursor.execute(f"DELETE FROM ShopCategory WHERE Id IN ({cp})", cparams)
            stats["shop_categories_deleted"] = len(cats)
        else:
            stats["shop_categories_deleted"] = 0

    print("PURGE_OK")
    for k, v in stats.items():
        print(f"{k}={v}")

    print("VERIFY")
    for label, q in [
        ("students_inactive_left", "SELECT COUNT(*) AS C FROM Student WHERE IsActive = 0"),
        ("teachers_inactive_left", "SELECT COUNT(*) AS C FROM Teacher WHERE IsActive = 0"),
        ("courses_inactive_left", "SELECT COUNT(*) AS C FROM Course WHERE IsActive = 0"),
        ("levels_inactive_left", "SELECT COUNT(*) AS C FROM Level WHERE IsActive = 0"),
        ("branches_inactive_left", "SELECT COUNT(*) AS C FROM Branch WHERE IsActive = 0"),
        ("withdrawn_left", "SELECT COUNT(*) AS C FROM Registration WHERE Status = N'withdrawn'"),
        ("cancelled_classes_left", "SELECT COUNT(*) AS C FROM Class WHERE Status = N'cancelled'"),
        ("cancelled_sessions_left", "SELECT COUNT(*) AS C FROM Session WHERE Status = N'cancelled'"),
        ("shop_products_inactive_left", "SELECT COUNT(*) AS C FROM ShopProduct WHERE IsActive = 0"),
        ("students_active", "SELECT COUNT(*) AS C FROM Student WHERE IsActive = 1"),
        ("teachers_active", "SELECT COUNT(*) AS C FROM Teacher WHERE IsActive = 1"),
        ("courses_active", "SELECT COUNT(*) AS C FROM Course WHERE IsActive = 1"),
    ]:
        print(f"{label}={fetch_one(q)['C']}")


if __name__ == "__main__":
    main()
