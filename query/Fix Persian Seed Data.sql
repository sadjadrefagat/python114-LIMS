/*
  اصلاح متون فارسی Seed جداول Branch و Level
  این فایل را از SSMS با Encoding = UTF-8 اجرا کنید،
  یا با sqlcmd به این شکل:
    sqlcmd -S "(local)\SQLEXPRESS2019" -U limdbadmin -P "..." -d LIMDB -f 65001 -i "Fix Persian Seed Data.sql"
*/
USE [LIMDB]
GO

UPDATE dbo.Branch
SET [Name] = N'شعبه مرکزی',
    [Address] = N'تهران'
WHERE Id = 1;
GO

UPDATE dbo.Level SET [Name] = N'مبتدی ۱' WHERE [Code] = N'A1';
UPDATE dbo.Level SET [Name] = N'مبتدی ۲' WHERE [Code] = N'A2';
UPDATE dbo.Level SET [Name] = N'متوسط ۱' WHERE [Code] = N'B1';
UPDATE dbo.Level SET [Name] = N'متوسط ۲' WHERE [Code] = N'B2';
UPDATE dbo.Level SET [Name] = N'پیشرفته ۱' WHERE [Code] = N'C1';
UPDATE dbo.Level SET [Name] = N'پیشرفته ۲' WHERE [Code] = N'C2';
GO

PRINT N'Persian seed data fixed.';
GO
