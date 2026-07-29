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

@app.post("/languages")
async def create_language(language: dict):
    """ایجاد یک زبان جدید"""
    query = """INSERT INTO Language ([Name])
               VALUES (?)"""
    execute_nonequery_with_params(
        query, (language["name"],))
    return {"message": "Language created successfully"}

def get_all_students(search: str = None):
    """دریافت تمام زبان آموزان از جدول Student"""
    query = """SELECT
        S.Id,
        S.FirstName,
        S.LastName,
        S.FatherName,
        S.NationalCode,
        S.Gender,
        S.BirthDate,
        S.Mobile
    FROM Student S"""
    if search:
        query += " AND (S.FirstName LIKE ? OR S.LastName LIKE?)"
        return execute_query_with_params(query, (f"%{search}%",f"%{search}%"))
    else:
        return execute_query(query)

@app.get("/students")
async def read_students(search: str = None):
    """دریافت تمام زبان آموزان و بازگرداندن آن‌ها به صورت JSON"""
    students = get_all_students(search)
    return {"students": [dict(zip([column[0] for column in students[0].cursor_description], row)) for row in students]}

@app.post("/students")
async def create_student(student: dict):
    """ایجاد یک زبان آموز جدید"""
    query = """INSERT INTO Student ([FirstName],[LastName],[FatherName],[NationalCode],[Gender],[BirthDate],[Mobile])
               VALUES (?,?,?,?,?,?,?)"""
    execute_nonequery_with_params(
        query, (student["first_name"] , student["last_name"],student["father_name"],student["national_code"],student["gender"],student["birth_date"],student["mobile"]))
    return {"message": "Student created successfully"}\
    
def get_all_teachers(search: str = None):
    """دریافت تمام مدرسان از جدول Teacher"""
    query = """SELECT
        T.Id,
        T.FirstName,
        T.LastName,
        T.FatherName,
        T.NationalCode,
        T.Gender,
        T.BirthDate
    FROM Teacher T"""
    if search:
        query += " AND (T.FirstName LIKE ? OR T.LastName LIKE?)"
        return execute_query_with_params(query, (f"%{search}%",f"%{search}%"))
    else:
        return execute_query(query)

@app.get("/teachers")
async def read_teachers(search: str = None):
    """دریافت تمام مدرسان و بازگرداندن آن‌ها به صورت JSON"""
    teachers = get_all_teachers(search)
    return {"teachers": [dict(zip([column[0] for column in teachers[0].cursor_description], row)) for row in teachers]}

@app.post("/teachers")
async def create_teacher(teacher: dict):
    """ایجاد یک مدرس جدید"""
    query = """INSERT INTO Teacher ([FirstName],[LastName],[FatherName],[NationalCode],[Gender],[BirthDate])
               VALUES (?,?,?,?,?,?)"""
    execute_nonequery_with_params(
        query, (teacher["first_name"] ,teacher["last_name"],teacher["father_name"],teacher["national_code"],teacher["gender"],teacher["birth_date"]))
    return {"message": "Teacher created successfully"}\


def get_all_class(search: str = None):
    """دریافت تمام کلاس ها از جدول Class"""
    query = """SELECT
        C.Id
        C.CourseRef
        C.TeacherRef
        C.SessionType
    FROM Class C"""
    if search:
        query += " AND (C.CourseRef LIKE ? OR C.TeacherRef LIKE? OR C.SessionType LIKE?)"
        return execute_query_with_params(query, (f"%{search}%",f"%{search}%"))
    else:
        return execute_query(query)

@app.get("/class")
async def read_class(search: str = None):
    """دریافت تمام کلاس ها و بازگرداندن آن‌ها به صورت JSON"""
    class = get_all_class(search)
    return {"class": [dict(zip([column[0] for column in class[0].class_description], row)) for row in class]}

@app.post("/class")
async def create_class(class: dict):
    """ایجاد یک کلاس جدید"""
    query = """INSERT INTO class ([CourseRef],[TeacherRef],[SessionType])
               VALUES (?,?,?)"""
    execute_nonequery_with_params(
        query, (class["course_ref"] , class["teacher_ref"],class["session_type"]))
    return {"message": "class created successfully"}



def get_all_payment(search: str = None):
    """دریافت تمام پرداختی ها از جدول Payment"""
    query = """SELECT
        P.Id
        P.StudentRef
        P.Date
        P.Amount
        P.PaymentType
    FROM Payment P"""
    if search:
        query += " AND (P.StudentRef LIKE ? OR P.Date LIKE? OR P.Amount LIKE? OR P.PaymentType LIKE?)"
        return execute_query_with_params(query, (f"%{search}%",f"%{search}%"))
    else:
        return execute_query(query)

@app.get("/payment")
async def read_payment(search: str = None):
    """دریافت تمام پرداختی ها و بازگرداندن آن‌ها به صورت JSON"""
    payment = get_all_payment(search)
    return {"payment": [dict(zip([column[0] for column in payment[0].payment_description], row)) for row in payment]}

@app.post("/payment")
async def create_payment(payment: dict):
    """ایجاد یک پرداختی"""
    query = """INSERT INTO Payment ([StudentRef],[Date],[Amount],[PaymentType])
               VALUES (?,?,?,?)"""
    execute_nonequery_with_params(
        query, (payment["student_ref"], payment["date"],payment["amount"],payment["payment_type"]))
    return {"message": "payment created successfully"}


def get_all_registration(search: str = None):
    """دریافت تمام ثبت نام ها از جدول Registration"""
    query = """SELECT
        R.Id
        R.StudentRef
        R.CourseRef
        R.Date
        
    FROM Registration R"""
    if search:
        query += " AND (R.StudentRef LIKE ? OR R.CourseRef LIKE? OR R.Date LIKE?)"
        return execute_query_with_params(query, (f"%{search}%",f"%{search}%"))
    else:
        return execute_query(query)

@app.get("/registration")
async def read_registration(search: str = None):
    """دریافت تمام ثبت نام ها و بازگرداندن آن‌ها به صورت JSON"""
    registration = get_all_registration(search)
    return {"registration": [dict(zip([column[0] for column in registration[0].registration_description], row)) for row in registration]}

@app.post("/registration")
async def create_registration(registration: dict):
    """ایجاد یک ثبت نام جدید"""
    query = """INSERT INTO Registration ([StudentRef],[CourseRef],[Date])
               VALUES (?,?,?)"""
    execute_nonequery_with_params(
        query, (registration["student_ref"], registration["course_ref"],registration["date"]))
    return {"message": "registration created successfully"}


def get_all_Teacher(search: str = None):
    """دریافت تمام استاد ها از جدولTeacher"""
    query = """SELECT
        T.Id
        T.Name
        T.Family
        T.Phone
        
    FROM Teacher T"""
    if search:
        query += " AND (T.Name LIKE ? OR T.Family LIKE? OR T.Phone LIKE?)"
        return execute_query_with_params(query, (f"%{search}%",f"%{search}%"))
    else:
        return execute_query(query)

@app.post("/Teacher")
async def create_Teacher(Teacher: dict):
    """ایجاد یک استاد جدید"""
    query = """INSERT INTO Teacher ([name],[family],[phone])
               VALUES (?,?,?)"""
    execute_nonequery_with_params(
        query, (Teacher["name"], registration["family"],registration["phone"]))
    return {"message": "Teacher created successfully"}
