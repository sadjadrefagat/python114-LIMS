# فایل اصلی بک اند پروژه
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import pyodbc


# ایجاد یک نمونه از برنامه FastAPI
app = FastAPI()

# تنظیمات CORS برای اجازه دادن به درخواست‌ها از هر منبع
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def read_root():
    """تست API با یک پیام ساده"""
    return {"message": "Hello, World!"}


conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=(local)\\SQLEXPRESS2019;"
    "DATABASE=LIMDB;"
    "UID=limdbadmin;"
    "PWD=123@123!"
)


# مناسب برای اجرای کوئری‌های INSERT، UPDATE و DELETE بدون بازگرداندن نتایج
def execute_nonequery_with_params(query: str, params: tuple = ()):
    """اجرای یک کوئری SQL بدون بازگرداندن نتایج"""
    print(query)
    print(params)
    cursor = conn.cursor()
    cursor.execute(query, params)
    cursor.commit() # خیلی مهم: برای اعمال تغییرات در پایگاه داده باید تثبیت شود
    cursor.close()


#مناسب برای اجرای کوئری‌های SELECT با پارامترها و بازگرداندن نتایج
def execute_query_with_params(query: str, params: tuple = ()):
    """اجرای یک کوئری SQL و بازگرداندن نتایج"""
    print(query)
    print(params)
    cursor = conn.cursor()
    cursor.execute(query, params)
    results = cursor.fetchall()
    cursor.close()
    return results


#مناسب برای اجرای کوئری‌های SELECT بدون پارامترها و بازگرداندن نتایج
def execute_query(query: str):
    """اجرای یک کوئری SQL بدون پارامتر و بازگرداندن نتایج"""
    cursor = conn.cursor()
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()
    return results


def get_all_cources(search: str = None):
    """دریافت تمام دوره‌ها از جدول Course"""
    query = """SELECT
        C.Id,
        C.Name,
        L.Name AS LanguageName
    FROM Course C
        JOIN Language L ON C.LanguageRef = L.Id
    WHERE C.IsActive = 1"""
    if search:
        query += " AND C.Name LIKE ?"
        return execute_query_with_params(query, (f"%{search}%",))
    else:
        return execute_query(query)


@app.get("/courses")
async def read_courses(search: str = None):
    """دریافت تمام دوره‌ها و بازگرداندن آن‌ها به صورت JSON"""
    courses = get_all_cources(search)
    return {"courses": [dict(zip([column[0] for column in courses[0].cursor_description], row)) for row in courses]}


@app.get("/courses/{course_id}")
async def read_course(course_id: int):
    """دریافت یک دوره خاص بر اساس شناسه آن"""
    query = """SELECT
        C.Id,
        C.Name,
        L.Name AS LanguageName
    FROM Course C
        JOIN Language L ON C.LanguageRef = L.Id
    WHERE C.IsActive = 1 AND C.Id = ?"""
    course = execute_query_with_params(query, (course_id,))
    if course:
        return {"course": dict(zip([column[0] for column in course[0].cursor_description], course[0]))}
    else:
        return {"error": "Course not found"}


@app.post("/courses")
async def create_course(course: dict):
    """ایجاد یک دوره جدید"""
    query = """INSERT INTO Course ([Name], [LanguageRef], [SessionsCount], [Cost])
               VALUES (?, ?, ?, ?)"""
    execute_nonequery_with_params(
        query, (course["name"], course["language_ref"], course["sessions_count"], course["cost"]))
    return {"message": "Course created successfully"}


def get_all_languages(search: str = None):
    """دریافت تمام زبان‌ها از جدول Language"""
    query = """SELECT
        L.Id,
        L.Name
    FROM Language L"""
    if search:
        query += " AND L.Name LIKE ?"
        return execute_query_with_params(query, (f"%{search}%",))
    else:
        return execute_query(query)

    
@app.get("/languages")
async def read_languages(search: str = None):
    """دریافت تمام زبان‌ها و بازگرداندن آن‌ها به صورت JSON"""
    languages = get_all_languages(search)
    return {"languages": [dict(zip([column[0] for column in languages[0].cursor_description], row)) for row in languages]}
