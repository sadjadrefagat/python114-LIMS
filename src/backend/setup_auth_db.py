"""ایجاد جداول احراز هویت و کاربر ادمین اولیه"""
from __future__ import annotations

import pyodbc

from auth import hash_password
from database import get_connection_string

DDL_STATEMENTS = [
    """
    IF OBJECT_ID(N'dbo.Role', N'U') IS NULL
    CREATE TABLE dbo.Role (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Code NVARCHAR(30) NOT NULL UNIQUE,
        Name NVARCHAR(50) NOT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_Role_IsActive DEFAULT (1)
    )
    """,
    """
    IF OBJECT_ID(N'dbo.AppUser', N'U') IS NULL
    CREATE TABLE dbo.AppUser (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Username NVARCHAR(50) NOT NULL,
        Email NVARCHAR(100) NULL,
        PasswordHash NVARCHAR(200) NOT NULL,
        FullName NVARCHAR(100) NULL,
        RoleRef INT NOT NULL,
        StudentRef INT NULL,
        TeacherRef INT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_AppUser_IsActive DEFAULT (1),
        PreferredUILanguage NVARCHAR(5) NOT NULL CONSTRAINT DF_AppUser_UI DEFAULT (N'fa'),
        FailedLoginCount INT NOT NULL CONSTRAINT DF_AppUser_Fail DEFAULT (0),
        LockedUntil DATETIME2 NULL,
        LastLoginAt DATETIME2 NULL,
        CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_AppUser_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT UQ_AppUser_Username UNIQUE (Username),
        CONSTRAINT FK_AppUser_Role FOREIGN KEY (RoleRef) REFERENCES dbo.Role(Id),
        CONSTRAINT FK_AppUser_Student FOREIGN KEY (StudentRef) REFERENCES dbo.Student(Id),
        CONSTRAINT FK_AppUser_Teacher FOREIGN KEY (TeacherRef) REFERENCES dbo.Teacher(Id)
    )
    """,
    """
    IF OBJECT_ID(N'dbo.UserSession', N'U') IS NULL
    CREATE TABLE dbo.UserSession (
        Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserRef INT NOT NULL,
        TokenHash CHAR(64) NOT NULL,
        CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_UserSession_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ExpiresAt DATETIME2 NOT NULL,
        RevokedAt DATETIME2 NULL,
        CONSTRAINT FK_UserSession_User FOREIGN KEY (UserRef) REFERENCES dbo.AppUser(Id)
    )
    """,
    """
    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes WHERE name = N'IX_UserSession_TokenHash'
          AND object_id = OBJECT_ID(N'dbo.UserSession')
    )
    CREATE UNIQUE INDEX IX_UserSession_TokenHash ON dbo.UserSession(TokenHash)
    """,
]

ROLES = [
    ("admin", "مدیر سیستم"),
    ("finance", "کارشناس مالی"),
    ("secretary", "منشی"),
    ("education", "مسئول آموزش"),
    ("teacher", "مدرس"),
    ("student", "زبان‌آموز"),
    ("parent", "والدین"),
]


def main() -> None:
    conn = pyodbc.connect(get_connection_string())
    cur = conn.cursor()
    for ddl in DDL_STATEMENTS:
        cur.execute(ddl)
    conn.commit()

    for code, name in ROLES:
        cur.execute("SELECT Id FROM Role WHERE Code = ?", (code,))
        if cur.fetchone() is None:
            cur.execute("INSERT INTO Role (Code, Name) VALUES (?, ?)", (code, name))
    conn.commit()

    cur.execute("SELECT Id FROM Role WHERE Code = ?", ("admin",))
    admin_role_id = cur.fetchone()[0]

    cur.execute("SELECT Id FROM AppUser WHERE Username = ?", ("admin",))
    if cur.fetchone() is None:
        pwd_hash = hash_password("LimsAdmin@2026")
        cur.execute(
            """INSERT INTO AppUser
                (Username, Email, PasswordHash, FullName, RoleRef, PreferredUILanguage)
               VALUES (?, ?, ?, ?, ?, ?)""",
            ("admin", "admin@lims.local", pwd_hash, "مدیر سیستم", admin_role_id, "fa"),
        )
        conn.commit()
        print("Admin user created: admin / LimsAdmin@2026")
    else:
        print("Admin user already exists")

    # secretary seed (optional helper account)
    cur.execute("SELECT Id FROM Role WHERE Code = ?", ("secretary",))
    sec_role = cur.fetchone()[0]
    cur.execute("SELECT Id FROM AppUser WHERE Username = ?", ("secretary",))
    if cur.fetchone() is None:
        cur.execute(
            """INSERT INTO AppUser
                (Username, Email, PasswordHash, FullName, RoleRef)
               VALUES (?, ?, ?, ?, ?)""",
            ("secretary", "secretary@lims.local", hash_password("LimsSecret@2026"), "منشی آموزشگاه", sec_role),
        )
        conn.commit()
        print("Secretary user created: secretary / LimsSecret@2026")

    cur.execute("SELECT R.Code, R.Name FROM Role R ORDER BY Id")
    print("Roles:", [(r[0], r[1]) for r in cur.fetchall()])
    cur.close()
    conn.close()
    print("Auth schema ready.")


if __name__ == "__main__":
    main()
