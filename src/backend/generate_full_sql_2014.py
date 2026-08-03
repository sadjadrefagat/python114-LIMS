# -*- coding: utf-8 -*-
"""
تولید اسکریپت کامل LIMDB سازگار با SQL Server 2014
خروجی: query/LIMDB_Full_Schema_And_Data_2014.sql
"""
from __future__ import annotations

import re
from datetime import date, datetime, time
from decimal import Decimal
from pathlib import Path

from database import fetch_all, fetch_one

OUT = Path(__file__).resolve().parents[2] / "query" / "LIMDB_Full_Schema_And_Data_2014.sql"

# ترتیب درج داده با رعایت وابستگی‌های FK
TABLE_ORDER = [
    "Role",
    "Language",
    "Branch",
    "SessionType",
    "Level",
    "Teacher",
    "Student",
    "Course",
    "Class",
    "Session",
    "SessionStudent",
    "Registration",
    "Payment",
    "Score",
    "CourseHistory",
    "AppUser",
    "UserSession",
    "ShopCategory",
    "ShopProduct",
    "ShopProductLike",
    "ShopProductBookmark",
    "ShopCartItem",
    "ShopOrder",
    "ShopOrderItem",
    "PlacementTestType",
    "PlacementQuestion",
    "PlacementLevelRule",
    "PlacementAttempt",
    "PlacementAttemptAnswer",
    "ActivityLog",
]

# جداول سیستمی/غیرکاربردی که نباید اسکریپت شوند
SKIP_TABLES = {"sysdiagrams"}
SKIP_FUNCTION_PREFIXES = ("fn_diagram",)
SKIP_TRIGGER_PREFIXES = ()
# جداول خیلی بزرگ یا باینری سنگین — داده را محدود یا رد کن
SKIP_DATA_TABLES = set()
# Photo های مدرس می‌توانند خیلی بزرگ باشند؛ فقط متادیتا نگه می‌داریم اگر حجم زیاد است
MAX_VARBINARY_INLINE = 64 * 1024  # 64KB


def sql_ident(name: str) -> str:
    return f"[{name}]"


def sql_str(value: str) -> str:
    return "N'" + value.replace("'", "''") + "'"


def sql_literal(value) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, (bytes, bytearray, memoryview)):
        b = bytes(value)
        if len(b) > MAX_VARBINARY_INLINE:
            return "NULL /* VARBINARY too large for inline seed */"
        return "0x" + b.hex().upper()
    if isinstance(value, Decimal):
        return format(value, "f")
    if isinstance(value, datetime):
        return f"'{value.strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]}'"
    if isinstance(value, date):
        return f"'{value.strftime('%Y-%m-%d')}'"
    if isinstance(value, time):
        return f"'{value.strftime('%H:%M:%S')}'"
    if isinstance(value, (int, float)):
        return str(value)
    # pyodbc may return datetime as str already
    return sql_str(str(value))


def get_tables() -> list[str]:
    rows = fetch_all(
        """
        SELECT TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_SCHEMA = 'dbo'
        ORDER BY TABLE_NAME
        """
    )
    names = [r["TABLE_NAME"] for r in rows if r["TABLE_NAME"] not in SKIP_TABLES]
    ordered = [t for t in TABLE_ORDER if t in names]
    rest = [t for t in names if t not in ordered]
    return ordered + rest


def get_columns(table: str) -> list[dict]:
    return fetch_all(
        """
        SELECT
            c.COLUMN_NAME,
            c.ORDINAL_POSITION,
            c.DATA_TYPE,
            c.CHARACTER_MAXIMUM_LENGTH,
            c.NUMERIC_PRECISION,
            c.NUMERIC_SCALE,
            c.DATETIME_PRECISION,
            c.IS_NULLABLE,
            c.COLUMN_DEFAULT,
            COLUMNPROPERTY(OBJECT_ID(QUOTENAME(c.TABLE_SCHEMA)+'.'+QUOTENAME(c.TABLE_NAME)), c.COLUMN_NAME, 'IsIdentity') AS IsIdentity,
            COLUMNPROPERTY(OBJECT_ID(QUOTENAME(c.TABLE_SCHEMA)+'.'+QUOTENAME(c.TABLE_NAME)), c.COLUMN_NAME, 'IsComputed') AS IsComputed
        FROM INFORMATION_SCHEMA.COLUMNS c
        WHERE c.TABLE_SCHEMA = 'dbo' AND c.TABLE_NAME = ?
        ORDER BY c.ORDINAL_POSITION
        """,
        (table,),
    )


def type_sql(col: dict) -> str:
    dt = (col["DATA_TYPE"] or "").lower()
    length = col["CHARACTER_MAXIMUM_LENGTH"]
    prec = col["NUMERIC_PRECISION"]
    scale = col["NUMERIC_SCALE"]
    dtp = col["DATETIME_PRECISION"]

    if dt in ("nvarchar", "varchar", "nchar", "char", "varbinary", "binary"):
        if length is None:
            return dt.upper()
        if int(length) < 0:
            return f"{dt.upper()}(MAX)"
        return f"{dt.upper()}({int(length)})"
    if dt in ("decimal", "numeric"):
        return f"{dt.upper()}({int(prec)},{int(scale or 0)})"
    if dt in ("datetime2", "time", "datetimeoffset"):
        if dtp is not None:
            return f"{dt.upper()}({int(dtp)})"
        return dt.upper()
    if dt == "float" and prec:
        return f"FLOAT({int(prec)})"
    return dt.upper()


def script_create_table(table: str) -> str:
    cols = get_columns(table)
    lines = []
    for c in cols:
        if int(c.get("IsComputed") or 0) == 1:
            continue
        parts = [f"    {sql_ident(c['COLUMN_NAME'])} {type_sql(c)}"]
        if int(c.get("IsIdentity") or 0) == 1:
            # seed/increment
            seed = fetch_one(
                """
                SELECT CONVERT(varchar(30), seed_value) AS SeedVal,
                       CONVERT(varchar(30), increment_value) AS IncVal
                FROM sys.identity_columns
                WHERE object_id = OBJECT_ID(?) AND name = ?
                """,
                (f"dbo.{table}", c["COLUMN_NAME"]),
            )
            s = (seed or {}).get("SeedVal") or "1"
            i = (seed or {}).get("IncVal") or "1"
            parts.append(f"IDENTITY({s},{i})")
        if (c["IS_NULLABLE"] or "").upper() == "NO":
            parts.append("NOT NULL")
        else:
            parts.append("NULL")
        # defaults handled separately via constraints for cleanliness
        lines.append(" ".join(parts))
    body = ",\n".join(lines)
    return f"IF OBJECT_ID(N'dbo.{table}', N'U') IS NULL\nBEGIN\nCREATE TABLE dbo.{sql_ident(table)} (\n{body}\n);\nEND\nGO\n"


def script_primary_keys() -> str:
    rows = fetch_all(
        """
        SELECT
            t.name AS TableName,
            kc.name AS ConstraintName,
            STUFF((
                SELECT N', ' + QUOTENAME(c2.name)
                FROM sys.index_columns ic2
                JOIN sys.columns c2 ON c2.object_id = ic2.object_id AND c2.column_id = ic2.column_id
                WHERE ic2.object_id = i.object_id AND ic2.index_id = i.index_id AND ic2.is_included_column = 0
                ORDER BY ic2.key_ordinal
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'), 1, 2, N'') AS Cols
        FROM sys.key_constraints kc
        JOIN sys.tables t ON t.object_id = kc.parent_object_id
        JOIN sys.indexes i ON i.object_id = kc.parent_object_id AND i.index_id = kc.unique_index_id
        WHERE kc.type = 'PK' AND SCHEMA_NAME(t.schema_id) = 'dbo'
        ORDER BY t.name
        """
    )
    out = []
    for r in rows:
        if r["TableName"] in SKIP_TABLES:
            continue
        out.append(
            f"""IF OBJECT_ID(N'dbo.{r['ConstraintName']}', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.{r['TableName']}', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.{sql_ident(r['TableName'])}
      ADD CONSTRAINT {sql_ident(r['ConstraintName'])} PRIMARY KEY CLUSTERED ({r['Cols']});
END
GO
"""
        )
    return "\n".join(out)


def script_defaults() -> str:
    rows = fetch_all(
        """
        SELECT
            t.name AS TableName,
            c.name AS ColumnName,
            dc.name AS ConstraintName,
            dc.definition AS Definition
        FROM sys.default_constraints dc
        JOIN sys.tables t ON t.object_id = dc.parent_object_id
        JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
        WHERE SCHEMA_NAME(t.schema_id) = 'dbo'
        ORDER BY t.name, c.column_id
        """
    )
    out = []
    for r in rows:
        if r["TableName"] in SKIP_TABLES:
            continue
        out.append(
            f"""IF OBJECT_ID(N'dbo.{r['ConstraintName']}', N'D') IS NULL
   AND COL_LENGTH(N'dbo.{r['TableName']}', N'{r['ColumnName']}') IS NOT NULL
BEGIN
    ALTER TABLE dbo.{sql_ident(r['TableName'])}
      ADD CONSTRAINT {sql_ident(r['ConstraintName'])}
      DEFAULT {r['Definition']} FOR {sql_ident(r['ColumnName'])};
END
GO
"""
        )
    return "\n".join(out)


def script_checks() -> str:
    rows = fetch_all(
        """
        SELECT
            t.name AS TableName,
            cc.name AS ConstraintName,
            cc.definition AS Definition
        FROM sys.check_constraints cc
        JOIN sys.tables t ON t.object_id = cc.parent_object_id
        WHERE SCHEMA_NAME(t.schema_id) = 'dbo' AND cc.is_disabled = 0
        ORDER BY t.name, cc.name
        """
    )
    out = []
    for r in rows:
        if r["TableName"] in SKIP_TABLES:
            continue
        out.append(
            f"""IF OBJECT_ID(N'dbo.{r['ConstraintName']}', N'C') IS NULL
   AND OBJECT_ID(N'dbo.{r['TableName']}', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.{sql_ident(r['TableName'])} WITH NOCHECK
      ADD CONSTRAINT {sql_ident(r['ConstraintName'])} CHECK {r['Definition']};
    ALTER TABLE dbo.{sql_ident(r['TableName'])} CHECK CONSTRAINT {sql_ident(r['ConstraintName'])};
END
GO
"""
        )
    return "\n".join(out)


def script_foreign_keys() -> str:
    rows = fetch_all(
        """
        SELECT
            fk.name AS FkName,
            tp.name AS ParentTable,
            tr.name AS RefTable,
            fk.delete_referential_action_desc AS OnDelete,
            fk.update_referential_action_desc AS OnUpdate,
            STUFF((
                SELECT N', ' + QUOTENAME(cp.name)
                FROM sys.foreign_key_columns fkc
                JOIN sys.columns cp ON cp.object_id = fkc.parent_object_id AND cp.column_id = fkc.parent_column_id
                WHERE fkc.constraint_object_id = fk.object_id
                ORDER BY fkc.constraint_column_id
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'), 1, 2, N'') AS ParentCols,
            STUFF((
                SELECT N', ' + QUOTENAME(cr.name)
                FROM sys.foreign_key_columns fkc
                JOIN sys.columns cr ON cr.object_id = fkc.referenced_object_id AND cr.column_id = fkc.referenced_column_id
                WHERE fkc.constraint_object_id = fk.object_id
                ORDER BY fkc.constraint_column_id
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'), 1, 2, N'') AS RefCols
        FROM sys.foreign_keys fk
        JOIN sys.tables tp ON tp.object_id = fk.parent_object_id
        JOIN sys.tables tr ON tr.object_id = fk.referenced_object_id
        WHERE SCHEMA_NAME(tp.schema_id) = 'dbo'
        ORDER BY tp.name, fk.name
        """
    )
    out = []
    for r in rows:
        if r["ParentTable"] in SKIP_TABLES or r["RefTable"] in SKIP_TABLES:
            continue
        on_del = r["OnDelete"]
        on_upd = r["OnUpdate"]
        extra = ""
        if on_del and on_del != "NO_ACTION":
            extra += f" ON DELETE {on_del.replace('_', ' ')}"
        if on_upd and on_upd != "NO_ACTION":
            extra += f" ON UPDATE {on_upd.replace('_', ' ')}"
        out.append(
            f"""IF OBJECT_ID(N'dbo.{r['FkName']}', N'F') IS NULL
   AND OBJECT_ID(N'dbo.{r['ParentTable']}', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.{r['RefTable']}', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.{sql_ident(r['ParentTable'])} WITH NOCHECK
      ADD CONSTRAINT {sql_ident(r['FkName'])}
      FOREIGN KEY ({r['ParentCols']})
      REFERENCES dbo.{sql_ident(r['RefTable'])} ({r['RefCols']}){extra};
    ALTER TABLE dbo.{sql_ident(r['ParentTable'])} CHECK CONSTRAINT {sql_ident(r['FkName'])};
END
GO
"""
        )
    return "\n".join(out)


def script_indexes() -> str:
    rows = fetch_all(
        """
        SELECT
            t.name AS TableName,
            i.name AS IndexName,
            i.is_unique AS IsUnique,
            i.type_desc AS TypeDesc,
            STUFF((
                SELECT N', ' + QUOTENAME(c.name)
                    + CASE WHEN ic.is_descending_key = 1 THEN N' DESC' ELSE N' ASC' END
                FROM sys.index_columns ic
                JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                  AND ic.is_included_column = 0
                ORDER BY ic.key_ordinal
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'), 1, 2, N'') AS KeyCols,
            STUFF((
                SELECT N', ' + QUOTENAME(c.name)
                FROM sys.index_columns ic
                JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                  AND ic.is_included_column = 1
                ORDER BY ic.index_column_id
                FOR XML PATH(''), TYPE
            ).value('.', 'nvarchar(max)'), 1, 2, N'') AS InclCols
        FROM sys.indexes i
        JOIN sys.tables t ON t.object_id = i.object_id
        WHERE i.is_primary_key = 0
          AND i.is_unique_constraint = 0
          AND i.type > 0
          AND i.name IS NOT NULL
          AND SCHEMA_NAME(t.schema_id) = 'dbo'
        ORDER BY t.name, i.name
        """
    )
    out = []
    for r in rows:
        if r["TableName"] in SKIP_TABLES:
            continue
        if not r["KeyCols"]:
            continue
        uniq = "UNIQUE " if r["IsUnique"] else ""
        typ = "CLUSTERED" if r["TypeDesc"] == "CLUSTERED" else "NONCLUSTERED"
        incl = f" INCLUDE ({r['InclCols']})" if r["InclCols"] else ""
        out.append(
            f"""IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'{r['IndexName']}' AND object_id = OBJECT_ID(N'dbo.{r['TableName']}')
)
BEGIN
    CREATE {uniq}{typ} INDEX {sql_ident(r['IndexName'])}
      ON dbo.{sql_ident(r['TableName'])} ({r['KeyCols']}){incl};
END
GO
"""
        )
    return "\n".join(out)


def script_functions() -> str:
    rows = fetch_all(
        """
        SELECT o.name AS Name, m.definition AS Definition
        FROM sys.sql_modules m
        JOIN sys.objects o ON o.object_id = m.object_id
        WHERE o.type IN ('FN', 'IF', 'TF') AND SCHEMA_NAME(o.schema_id) = 'dbo'
        ORDER BY o.name
        """
    )
    out = []
    for r in rows:
        name = r["Name"] or ""
        if any(name.lower().startswith(p.lower()) for p in SKIP_FUNCTION_PREFIXES):
            continue
        if "diagram" in name.lower():
            continue
        defn = (r["Definition"] or "").strip()
        # remove CREATE OR ALTER if any
        defn = re.sub(r"(?i)create\s+or\s+alter", "CREATE", defn)
        # ensure schema-qualified CREATE FUNCTION dbo.Name
        defn = re.sub(
            r"(?i)^CREATE\s+FUNCTION\s+(?!dbo\.)(\[?[A-Za-z_][\w]*\]?)",
            r"CREATE FUNCTION dbo.\1",
            defn,
            count=1,
        )
        out.append(
            f"""IF OBJECT_ID(N'dbo.{name}', N'FN') IS NOT NULL
    DROP FUNCTION dbo.{sql_ident(name)};
IF OBJECT_ID(N'dbo.{name}', N'IF') IS NOT NULL
    DROP FUNCTION dbo.{sql_ident(name)};
IF OBJECT_ID(N'dbo.{name}', N'TF') IS NOT NULL
    DROP FUNCTION dbo.{sql_ident(name)};
GO
{defn}
GO
"""
        )
    return "\n".join(out)


def script_triggers() -> str:
    rows = fetch_all(
        """
        SELECT o.name AS TriggerName, t.name AS TableName, m.definition AS Definition
        FROM sys.triggers o
        JOIN sys.tables t ON t.object_id = o.parent_id
        JOIN sys.sql_modules m ON m.object_id = o.object_id
        WHERE o.parent_class = 1 AND SCHEMA_NAME(t.schema_id) = 'dbo'
        ORDER BY t.name, o.name
        """
    )
    out = []
    for r in rows:
        if r["TableName"] in SKIP_TABLES:
            continue
        defn = (r["Definition"] or "").strip()
        defn = re.sub(r"(?i)create\s+or\s+alter", "CREATE", defn)
        out.append(
            f"""IF OBJECT_ID(N'dbo.{r['TriggerName']}', N'TR') IS NOT NULL
    DROP TRIGGER dbo.{sql_ident(r['TriggerName'])};
GO
{defn}
GO
"""
        )
    return "\n".join(out)


def script_data(table: str) -> str:
    if table in SKIP_DATA_TABLES:
        return f"-- skipped data for {table}\nGO\n"

    cols = [c for c in get_columns(table) if int(c.get("IsComputed") or 0) == 0]
    # skip huge photo columns in seed for size; keep schema
    data_cols = []
    for c in cols:
        if c["DATA_TYPE"].lower() in ("varbinary", "image") and c["COLUMN_NAME"].lower() in (
            "photo",
            "image",
            "filedata",
        ):
            continue
        data_cols.append(c)

    if not data_cols:
        return ""

    col_names = [c["COLUMN_NAME"] for c in data_cols]
    select_list = ", ".join(sql_ident(n) for n in col_names)
    rows = fetch_all(f"SELECT {select_list} FROM dbo.{sql_ident(table)}")
    if not rows:
        return f"-- no rows in {table}\nGO\n"

    has_identity = any(int(c.get("IsIdentity") or 0) == 1 for c in cols)
    out = [f"-- ===== DATA: {table} ({len(rows)} rows) ====="]
    if has_identity:
        out.append(f"SET IDENTITY_INSERT dbo.{sql_ident(table)} ON;")
        out.append("GO")

    # batch inserts of ~50 rows
    batch_size = 40
    quoted_cols = ", ".join(sql_ident(n) for n in col_names)
    for i in range(0, len(rows), batch_size):
        chunk = rows[i : i + batch_size]
        values = []
        for row in chunk:
            vals = ", ".join(sql_literal(row.get(n)) for n in col_names)
            values.append(f"({vals})")
        out.append(
            f"INSERT INTO dbo.{sql_ident(table)} ({quoted_cols})\nVALUES\n"
            + ",\n".join(values)
            + ";"
        )
        out.append("GO")

    if has_identity:
        out.append(f"SET IDENTITY_INSERT dbo.{sql_ident(table)} OFF;")
        out.append("GO")
    return "\n".join(out) + "\n"


def header() -> str:
    return """/*
================================================================================
  LIMDB — Full Schema + Seed Data
  Compatible with: Microsoft SQL Server 2014 (COMPATIBILITY_LEVEL = 120)
                   and later (2016 / 2017 / 2019 / 2022)

  Generated from live LIMDB instance for LIMS (Language Institute Management System)

  How to use:
    1) Open in SSMS / Azure Data Studio
    2) Adjust FILENAME paths below if needed
    3) Execute the whole script (SQLCMD mode optional)
    4) After restore, start the API once so runtime ensure_* can patch anything missing

    Notes for SQL Server 2014:
    - No DROP IF EXISTS / CREATE OR ALTER / CATALOG_COLLATION
    - Uses IF OBJECT_ID / COL_LENGTH / sys.indexes checks instead
    - Large Teacher.Photo binaries are omitted from seed (NULL) to keep script size reasonable
    - Default logins (if present in seed): admin / LimsAdmin@2026 , secretary / LimsSecret@2026
================================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE [master];
GO

IF DB_ID(N'LIMDB') IS NULL
BEGIN
    DECLARE @data nvarchar(260) = CONVERT(nvarchar(260), SERVERPROPERTY('InstanceDefaultDataPath'));
    DECLARE @log  nvarchar(260) = CONVERT(nvarchar(260), SERVERPROPERTY('InstanceDefaultLogPath'));
    IF @data IS NULL SET @data = N'C:\\Program Files\\Microsoft SQL Server\\MSSQL12.MSSQLSERVER\\MSSQL\\DATA\\';
    IF @log  IS NULL SET @log  = @data;
    IF RIGHT(@data,1) <> N'\\' SET @data = @data + N'\\';
    IF RIGHT(@log,1)  <> N'\\' SET @log  = @log  + N'\\';

    DECLARE @sql nvarchar(max) =
        N'CREATE DATABASE [LIMDB] ON PRIMARY '
        + N'( NAME = N''LIMDB'', FILENAME = N''' + @data + N'LIMDB.mdf'', '
        + N'SIZE = 64MB, MAXSIZE = UNLIMITED, FILEGROWTH = 64MB ) '
        + N'LOG ON '
        + N'( NAME = N''LIMDB_log'', FILENAME = N''' + @log + N'LIMDB_log.ldf'', '
        + N'SIZE = 64MB, MAXSIZE = 2048GB, FILEGROWTH = 64MB );';
    EXEC(@sql);
END
GO

ALTER DATABASE [LIMDB] SET COMPATIBILITY_LEVEL = 120;  -- SQL Server 2014
GO
ALTER DATABASE [LIMDB] SET RECOVERY SIMPLE;
GO
ALTER DATABASE [LIMDB] SET READ_COMMITTED_SNAPSHOT OFF;
GO

USE [LIMDB];
GO

"""


def main() -> None:
    parts = [header()]
    tables = get_tables()
    print("tables:", tables)

    parts.append("/* ===================== FUNCTIONS ===================== */\nGO\n")
    parts.append(script_functions())

    parts.append("/* ===================== TABLES ===================== */\nGO\n")
    for t in tables:
        print("  table", t)
        parts.append(script_create_table(t))

    parts.append("/* ===================== PRIMARY KEYS ===================== */\nGO\n")
    parts.append(script_primary_keys())

    parts.append("/* ===================== DEFAULTS ===================== */\nGO\n")
    parts.append(script_defaults())

    parts.append("/* ===================== CHECK CONSTRAINTS ===================== */\nGO\n")
    parts.append(script_checks())

    parts.append("/* ===================== INDEXES ===================== */\nGO\n")
    parts.append(script_indexes())

    parts.append("/* ===================== FOREIGN KEYS ===================== */\nGO\n")
    parts.append(script_foreign_keys())

    parts.append("/* ===================== DATA ===================== */\nGO\n")
    # disable FKs temporarily for simpler load order safety
    parts.append(
        """
-- Temporarily disable FK checks for data load
DECLARE @sql nvarchar(max) = N'';
SELECT @sql = @sql + N'ALTER TABLE dbo.' + QUOTENAME(OBJECT_NAME(parent_object_id))
             + N' NOCHECK CONSTRAINT ' + QUOTENAME(name) + N';' + CHAR(10)
FROM sys.foreign_keys;
EXEC sp_executesql @sql;
GO
"""
    )
    for t in tables:
        print("  data", t)
        parts.append(script_data(t))

    parts.append(
        """
-- Re-enable FK checks
DECLARE @sql nvarchar(max) = N'';
SELECT @sql = @sql + N'ALTER TABLE dbo.' + QUOTENAME(OBJECT_NAME(parent_object_id))
             + N' WITH CHECK CHECK CONSTRAINT ' + QUOTENAME(name) + N';' + CHAR(10)
FROM sys.foreign_keys;
EXEC sp_executesql @sql;
GO
"""
    )

    parts.append("/* ===================== TRIGGERS ===================== */\nGO\n")
    parts.append(script_triggers())

    parts.append(
        """
PRINT N'LIMDB schema + data script completed (SQL Server 2014 compatible).';
GO
"""
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    text = "\n".join(parts)
    # SQL Server 2014: FOR XML PATH is fine. Avoid any CREATE OR ALTER leftovers.
    text = re.sub(r"(?i)create\s+or\s+alter", "CREATE", text)
    OUT.write_text(text, encoding="utf-8-sig")
    print("wrote", OUT, "bytes", OUT.stat().st_size)


if __name__ == "__main__":
    main()
