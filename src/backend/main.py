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


def execute_query(query: str, params: tuple = ()):
    """اجرای یک کوئری SQL و بازگرداندن نتایج"""
    cursor = conn.cursor()
    cursor.execute(query, params)
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
    WHERE C.IsActive = 1 AND C.Name LIKE ?"""
    params = (f"%{search}%",) if search else ()
    return execute_query(query, params)


@app.get("/courses")
async def read_courses(search: str = None):
    """دریافت تمام دوره‌ها و بازگرداندن آن‌ها به صورت JSON"""
    courses = get_all_cources(search)
    return {"courses": [dict(zip([column[0] for column in courses[0].cursor_description], row)) for row in courses]}

