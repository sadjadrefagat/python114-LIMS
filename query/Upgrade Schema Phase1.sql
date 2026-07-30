/*
  مهم: این فایل UTF-8 (با BOM) است.
  برای sqlcmd حتماً از -f 65001 استفاده کنید، وگرنه فارسی خراب می‌شود:
    sqlcmd ... -d LIMDB -f 65001 -i "Upgrade Schema Phase1.sql"
  یا از SSMS با Encoding = UTF-8 اجرا کنید.
*/

/*
  ارتقای اسکیمای LIMDB مطابق فاز ۱ سند SRS v2
  Language → Level → Course → Class → Session
  + Enrollment، Payment، Attendance، Score، Branch، Soft Delete
  اسکریپت idempotent است و چندبار قابل اجراست.
*/
USE [LIMDB]
GO
SET NOCOUNT ON;
GO

/* ========== Branch ========== */
IF OBJECT_ID(N'dbo.Branch', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Branch](
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Name] NVARCHAR(100) NOT NULL,
        [Address] NVARCHAR(300) NULL,
        [Phone] VARCHAR(20) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT [DF_Branch_IsActive] DEFAULT (1),
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_Branch_CreatedAt] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_Branch] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [IX_Branch_Name] UNIQUE NONCLUSTERED ([Name])
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Branch)
BEGIN
    INSERT INTO dbo.Branch ([Name], [Address], [Phone])
    VALUES (N'شعبه مرکزی', N'تهران', N'02100000000');
END
GO

/* ========== Level (زبان → سطح) ========== */
IF OBJECT_ID(N'dbo.Level', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Level](
        [Id] INT IDENTITY(1,1) NOT NULL,
        [LanguageRef] INT NOT NULL,
        [Code] NVARCHAR(20) NOT NULL,
        [Name] NVARCHAR(50) NOT NULL,
        [SortOrder] INT NOT NULL CONSTRAINT [DF_Level_SortOrder] DEFAULT (0),
        [IsActive] BIT NOT NULL CONSTRAINT [DF_Level_IsActive] DEFAULT (1),
        CONSTRAINT [PK_Level] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_Level_Language] FOREIGN KEY ([LanguageRef]) REFERENCES [dbo].[Language]([Id]),
        CONSTRAINT [IX_Level_Language_Code] UNIQUE NONCLUSTERED ([LanguageRef], [Code])
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Level)
BEGIN
    DECLARE @LangId INT;
    DECLARE lang_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT Id FROM dbo.Language;
    OPEN lang_cursor;
    FETCH NEXT FROM lang_cursor INTO @LangId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO dbo.Level ([LanguageRef], [Code], [Name], [SortOrder]) VALUES
            (@LangId, N'A1', N'مبتدی ۱', 1),
            (@LangId, N'A2', N'مبتدی ۲', 2),
            (@LangId, N'B1', N'متوسط ۱', 3),
            (@LangId, N'B2', N'متوسط ۲', 4),
            (@LangId, N'C1', N'پیشرفته ۱', 5),
            (@LangId, N'C2', N'پیشرفته ۲', 6);
        FETCH NEXT FROM lang_cursor INTO @LangId;
    END
    CLOSE lang_cursor;
    DEALLOCATE lang_cursor;
END
GO

/* ========== Course — ستون‌های تکمیلی ========== */
IF COL_LENGTH('dbo.Course', 'LevelRef') IS NULL
    ALTER TABLE dbo.Course ADD [LevelRef] INT NULL;
GO
IF COL_LENGTH('dbo.Course', 'Description') IS NULL
    ALTER TABLE dbo.Course ADD [Description] NVARCHAR(1000) NULL;
GO
IF COL_LENGTH('dbo.Course', 'PrerequisiteCourseRef') IS NULL
    ALTER TABLE dbo.Course ADD [PrerequisiteCourseRef] INT NULL;
GO
IF COL_LENGTH('dbo.Course', 'DurationHours') IS NULL
    ALTER TABLE dbo.Course ADD [DurationHours] INT NULL;
GO
IF COL_LENGTH('dbo.Course', 'Syllabus') IS NULL
    ALTER TABLE dbo.Course ADD [Syllabus] NVARCHAR(MAX) NULL;
GO
IF COL_LENGTH('dbo.Course', 'TeachingMethod') IS NULL
    ALTER TABLE dbo.Course ADD [TeachingMethod] NVARCHAR(200) NULL;
GO
IF COL_LENGTH('dbo.Course', 'AgeGroup') IS NULL
    ALTER TABLE dbo.Course ADD [AgeGroup] NVARCHAR(50) NULL;
GO
IF COL_LENGTH('dbo.Course', 'IsHighlighted') IS NULL
    ALTER TABLE dbo.Course ADD [IsHighlighted] BIT NOT NULL CONSTRAINT [DF_Course_IsHighlighted] DEFAULT (0);
GO
IF COL_LENGTH('dbo.Course', 'CreatedAt') IS NULL
    ALTER TABLE dbo.Course ADD [CreatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_Course_CreatedAt] DEFAULT (SYSUTCDATETIME());
GO
IF COL_LENGTH('dbo.Course', 'UpdatedAt') IS NULL
    ALTER TABLE dbo.Course ADD [UpdatedAt] DATETIME2 NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Course_Level')
    AND COL_LENGTH('dbo.Course', 'LevelRef') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Course WITH NOCHECK
    ADD CONSTRAINT [FK_Course_Level] FOREIGN KEY ([LevelRef]) REFERENCES [dbo].[Level]([Id]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Course_Prerequisite')
BEGIN
    ALTER TABLE dbo.Course WITH NOCHECK
    ADD CONSTRAINT [FK_Course_Prerequisite] FOREIGN KEY ([PrerequisiteCourseRef]) REFERENCES [dbo].[Course]([Id]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Course_Cost_NonNegative')
    ALTER TABLE dbo.Course ADD CONSTRAINT [CK_Course_Cost_NonNegative] CHECK ([Cost] >= 0);
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Course_SessionsCount_Positive')
    ALTER TABLE dbo.Course ADD CONSTRAINT [CK_Course_SessionsCount_Positive] CHECK ([SessionsCount] > 0);
GO

/* ========== Class — ظرفیت، وضعیت، نوع، شعبه ========== */
IF COL_LENGTH('dbo.Class', 'Capacity') IS NULL
    ALTER TABLE dbo.Class ADD [Capacity] INT NOT NULL CONSTRAINT [DF_Class_Capacity] DEFAULT (15);
GO
IF COL_LENGTH('dbo.Class', 'Status') IS NULL
    ALTER TABLE dbo.Class ADD [Status] NVARCHAR(20) NOT NULL CONSTRAINT [DF_Class_Status] DEFAULT (N'open');
GO
IF COL_LENGTH('dbo.Class', 'CancelReason') IS NULL
    ALTER TABLE dbo.Class ADD [CancelReason] NVARCHAR(300) NULL;
GO
IF COL_LENGTH('dbo.Class', 'ClassType') IS NULL
    ALTER TABLE dbo.Class ADD [ClassType] NVARCHAR(30) NOT NULL CONSTRAINT [DF_Class_ClassType] DEFAULT (N'group');
GO
IF COL_LENGTH('dbo.Class', 'BranchRef') IS NULL
    ALTER TABLE dbo.Class ADD [BranchRef] INT NULL;
GO
IF COL_LENGTH('dbo.Class', 'LocationAddress') IS NULL
    ALTER TABLE dbo.Class ADD [LocationAddress] NVARCHAR(300) NULL;
GO
IF COL_LENGTH('dbo.Class', 'MeetingLink') IS NULL
    ALTER TABLE dbo.Class ADD [MeetingLink] NVARCHAR(500) NULL;
GO
IF COL_LENGTH('dbo.Class', 'CreatedAt') IS NULL
    ALTER TABLE dbo.Class ADD [CreatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_Class_CreatedAt] DEFAULT (SYSUTCDATETIME());
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Class_Branch')
BEGIN
    ALTER TABLE dbo.Class WITH NOCHECK
    ADD CONSTRAINT [FK_Class_Branch] FOREIGN KEY ([BranchRef]) REFERENCES [dbo].[Branch]([Id]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Class_Capacity_NonNegative')
    ALTER TABLE dbo.Class ADD CONSTRAINT [CK_Class_Capacity_NonNegative] CHECK ([Capacity] >= 0);
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Class_Status')
    ALTER TABLE dbo.Class ADD CONSTRAINT [CK_Class_Status]
    CHECK ([Status] IN (N'draft', N'open', N'full', N'in_progress', N'finished', N'cancelled'));
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Class_ClassType')
    ALTER TABLE dbo.Class ADD CONSTRAINT [CK_Class_ClassType]
    CHECK ([ClassType] IN (N'group', N'semi_private', N'private', N'vip'));
GO

UPDATE dbo.Class SET BranchRef = (SELECT TOP 1 Id FROM dbo.Branch) WHERE BranchRef IS NULL;
GO

/* ========== Session — وضعیت و جبرانی ========== */
IF COL_LENGTH('dbo.Session', 'Status') IS NULL
    ALTER TABLE dbo.Session ADD [Status] NVARCHAR(20) NOT NULL CONSTRAINT [DF_Session_Status] DEFAULT (N'scheduled');
GO
IF COL_LENGTH('dbo.Session', 'CancelReason') IS NULL
    ALTER TABLE dbo.Session ADD [CancelReason] NVARCHAR(300) NULL;
GO
IF COL_LENGTH('dbo.Session', 'MeetingLink') IS NULL
    ALTER TABLE dbo.Session ADD [MeetingLink] NVARCHAR(500) NULL;
GO
IF COL_LENGTH('dbo.Session', 'LocationAddress') IS NULL
    ALTER TABLE dbo.Session ADD [LocationAddress] NVARCHAR(300) NULL;
GO
IF COL_LENGTH('dbo.Session', 'SubstituteTeacherRef') IS NULL
    ALTER TABLE dbo.Session ADD [SubstituteTeacherRef] INT NULL;
GO
IF COL_LENGTH('dbo.Session', 'IsMakeup') IS NULL
    ALTER TABLE dbo.Session ADD [IsMakeup] BIT NOT NULL CONSTRAINT [DF_Session_IsMakeup] DEFAULT (0);
GO
IF COL_LENGTH('dbo.Session', 'Notes') IS NULL
    ALTER TABLE dbo.Session ADD [Notes] NVARCHAR(500) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Session_SubstituteTeacher')
BEGIN
    ALTER TABLE dbo.Session WITH NOCHECK
    ADD CONSTRAINT [FK_Session_SubstituteTeacher]
    FOREIGN KEY ([SubstituteTeacherRef]) REFERENCES [dbo].[Teacher]([Id]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Session_Status')
    ALTER TABLE dbo.Session ADD CONSTRAINT [CK_Session_Status]
    CHECK ([Status] IN (N'scheduled', N'in_progress', N'completed', N'cancelled', N'rescheduled'));
GO

/* ========== SessionStudent → حضور و غیاب ========== */
IF COL_LENGTH('dbo.SessionStudent', 'AttendanceStatus') IS NULL
    ALTER TABLE dbo.SessionStudent ADD [AttendanceStatus] NVARCHAR(20) NOT NULL
        CONSTRAINT [DF_SessionStudent_AttendanceStatus] DEFAULT (N'present');
GO
IF COL_LENGTH('dbo.SessionStudent', 'RecordedAt') IS NULL
    ALTER TABLE dbo.SessionStudent ADD [RecordedAt] DATETIME2 NOT NULL
        CONSTRAINT [DF_SessionStudent_RecordedAt] DEFAULT (SYSUTCDATETIME());
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_SessionStudent_AttendanceStatus')
    ALTER TABLE dbo.SessionStudent ADD CONSTRAINT [CK_SessionStudent_AttendanceStatus]
    CHECK ([AttendanceStatus] IN (N'present', N'absent', N'late', N'leave'));
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes WHERE name = N'IX_SessionStudent_Unique' AND object_id = OBJECT_ID(N'dbo.SessionStudent')
)
    CREATE UNIQUE NONCLUSTERED INDEX [IX_SessionStudent_Unique]
    ON dbo.SessionStudent ([SessionRef], [StudentRef]);
GO

/* ========== Teacher ========== */
IF COL_LENGTH('dbo.Teacher', 'Mobile') IS NULL
    ALTER TABLE dbo.Teacher ADD [Mobile] VARCHAR(20) NULL;
GO
IF COL_LENGTH('dbo.Teacher', 'Email') IS NULL
    ALTER TABLE dbo.Teacher ADD [Email] NVARCHAR(100) NULL;
GO
IF COL_LENGTH('dbo.Teacher', 'Specialty') IS NULL
    ALTER TABLE dbo.Teacher ADD [Specialty] NVARCHAR(200) NULL;
GO
IF COL_LENGTH('dbo.Teacher', 'Bio') IS NULL
    ALTER TABLE dbo.Teacher ADD [Bio] NVARCHAR(1000) NULL;
GO
IF COL_LENGTH('dbo.Teacher', 'IsActive') IS NULL
    ALTER TABLE dbo.Teacher ADD [IsActive] BIT NOT NULL CONSTRAINT [DF_Teacher_IsActive] DEFAULT (1);
GO
IF COL_LENGTH('dbo.Teacher', 'CreatedAt') IS NULL
    ALTER TABLE dbo.Teacher ADD [CreatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_Teacher_CreatedAt] DEFAULT (SYSUTCDATETIME());
GO
IF COL_LENGTH('dbo.Teacher', 'Photo') IS NULL
    ALTER TABLE dbo.Teacher ADD [Photo] VARBINARY(MAX) NULL;
GO
IF COL_LENGTH('dbo.Teacher', 'PhotoMime') IS NULL
    ALTER TABLE dbo.Teacher ADD [PhotoMime] VARCHAR(100) NULL;
GO

IF OBJECT_ID(N'dbo.TRG_PreventDeleteTeacher', N'TR') IS NULL
BEGIN
    EXEC(N'
    CREATE TRIGGER [dbo].[TRG_PreventDeleteTeacher]
    ON [dbo].[Teacher]
    INSTEAD OF DELETE
    AS
    UPDATE Teacher SET IsActive = 0
    WHERE Id IN (SELECT Id FROM deleted);
    ');
END
GO

/* ========== Student ========== */
IF COL_LENGTH('dbo.Student', 'Email') IS NULL
    ALTER TABLE dbo.Student ADD [Email] NVARCHAR(100) NULL;
GO
IF COL_LENGTH('dbo.Student', 'TargetLanguageRef') IS NULL
    ALTER TABLE dbo.Student ADD [TargetLanguageRef] INT NULL;
GO
IF COL_LENGTH('dbo.Student', 'CurrentLevelRef') IS NULL
    ALTER TABLE dbo.Student ADD [CurrentLevelRef] INT NULL;
GO
IF COL_LENGTH('dbo.Student', 'PreferredUILanguage') IS NULL
    ALTER TABLE dbo.Student ADD [PreferredUILanguage] NVARCHAR(5) NOT NULL
        CONSTRAINT [DF_Student_PreferredUILanguage] DEFAULT (N'fa');
GO
IF COL_LENGTH('dbo.Student', 'NotificationsEnabled') IS NULL
    ALTER TABLE dbo.Student ADD [NotificationsEnabled] BIT NOT NULL
        CONSTRAINT [DF_Student_NotificationsEnabled] DEFAULT (1);
GO
IF COL_LENGTH('dbo.Student', 'IsActive') IS NULL
    ALTER TABLE dbo.Student ADD [IsActive] BIT NOT NULL CONSTRAINT [DF_Student_IsActive] DEFAULT (1);
GO
IF COL_LENGTH('dbo.Student', 'CreatedAt') IS NULL
    ALTER TABLE dbo.Student ADD [CreatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_Student_CreatedAt] DEFAULT (SYSUTCDATETIME());
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Student_TargetLanguage')
BEGIN
    ALTER TABLE dbo.Student WITH NOCHECK
    ADD CONSTRAINT [FK_Student_TargetLanguage] FOREIGN KEY ([TargetLanguageRef]) REFERENCES [dbo].[Language]([Id]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Student_CurrentLevel')
BEGIN
    ALTER TABLE dbo.Student WITH NOCHECK
    ADD CONSTRAINT [FK_Student_CurrentLevel] FOREIGN KEY ([CurrentLevelRef]) REFERENCES [dbo].[Level]([Id]);
END
GO

/* ========== Registration / Enrollment ========== */
IF COL_LENGTH('dbo.Registration', 'ClassRef') IS NULL
    ALTER TABLE dbo.Registration ADD [ClassRef] INT NULL;
GO
IF COL_LENGTH('dbo.Registration', 'Status') IS NULL
    ALTER TABLE dbo.Registration ADD [Status] NVARCHAR(30) NOT NULL
        CONSTRAINT [DF_Registration_Status] DEFAULT (N'active');
GO
IF COL_LENGTH('dbo.Registration', 'WithdrawReason') IS NULL
    ALTER TABLE dbo.Registration ADD [WithdrawReason] NVARCHAR(300) NULL;
GO
IF COL_LENGTH('dbo.Registration', 'FinancialStatus') IS NULL
    ALTER TABLE dbo.Registration ADD [FinancialStatus] NVARCHAR(20) NOT NULL
        CONSTRAINT [DF_Registration_FinancialStatus] DEFAULT (N'debtor');
GO
IF COL_LENGTH('dbo.Registration', 'CreatedAt') IS NULL
    ALTER TABLE dbo.Registration ADD [CreatedAt] DATETIME2 NOT NULL
        CONSTRAINT [DF_Registration_CreatedAt] DEFAULT (SYSUTCDATETIME());
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Registration_Class')
BEGIN
    ALTER TABLE dbo.Registration WITH NOCHECK
    ADD CONSTRAINT [FK_Registration_Class] FOREIGN KEY ([ClassRef]) REFERENCES [dbo].[Class]([Id]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Registration_Status')
    ALTER TABLE dbo.Registration ADD CONSTRAINT [CK_Registration_Status]
    CHECK ([Status] IN (N'pending_payment', N'pending_approval', N'active', N'frozen', N'completed', N'withdrawn', N'transferred'));
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Registration_FinancialStatus')
    ALTER TABLE dbo.Registration ADD CONSTRAINT [CK_Registration_FinancialStatus]
    CHECK ([FinancialStatus] IN (N'debtor', N'creditor', N'settled'));
GO
/* مهاجرت وضعیت جزئی → بدهکار و افزودن بستانکار */
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Registration_FinancialStatus')
BEGIN
    UPDATE dbo.Registration SET FinancialStatus = N'debtor' WHERE FinancialStatus = N'partial';
END
GO

/* ========== Payment ========== */
IF COL_LENGTH('dbo.Payment', 'Status') IS NULL
    ALTER TABLE dbo.Payment ADD [Status] NVARCHAR(20) NOT NULL
        CONSTRAINT [DF_Payment_Status] DEFAULT (N'paid');
GO
IF COL_LENGTH('dbo.Payment', 'PaymentMethod') IS NULL
    ALTER TABLE dbo.Payment ADD [PaymentMethod] NVARCHAR(20) NULL;
GO
IF COL_LENGTH('dbo.Payment', 'RegistrationRef') IS NULL
    ALTER TABLE dbo.Payment ADD [RegistrationRef] INT NULL;
GO
IF COL_LENGTH('dbo.Payment', 'Description') IS NULL
    ALTER TABLE dbo.Payment ADD [Description] NVARCHAR(300) NULL;
GO
IF COL_LENGTH('dbo.Payment', 'CreatedAt') IS NULL
    ALTER TABLE dbo.Payment ADD [CreatedAt] DATETIME2 NOT NULL
        CONSTRAINT [DF_Payment_CreatedAt] DEFAULT (SYSUTCDATETIME());
GO

/* همگام‌سازی روش پرداخت از PaymentType عددی قدیمی */
UPDATE dbo.Payment
SET PaymentMethod = CASE PaymentType
    WHEN 1 THEN N'cash'
    WHEN 2 THEN N'card'
    WHEN 3 THEN N'online'
    WHEN 4 THEN N'installment'
    ELSE N'other'
END
WHERE PaymentMethod IS NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Payment_Registration')
BEGIN
    ALTER TABLE dbo.Payment WITH NOCHECK
    ADD CONSTRAINT [FK_Payment_Registration] FOREIGN KEY ([RegistrationRef]) REFERENCES [dbo].[Registration]([Id]);
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Payment_Amount_NonNegative')
    ALTER TABLE dbo.Payment ADD CONSTRAINT [CK_Payment_Amount_NonNegative] CHECK ([Amount] >= 0);
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Payment_Status')
    ALTER TABLE dbo.Payment ADD CONSTRAINT [CK_Payment_Status]
    CHECK ([Status] IN (N'draft', N'pending', N'paid', N'failed', N'refunded', N'partially_paid', N'overdue'));
GO
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Payment_Method')
    ALTER TABLE dbo.Payment ADD CONSTRAINT [CK_Payment_Method]
    CHECK ([PaymentMethod] IS NULL OR [PaymentMethod] IN (N'cash', N'card', N'online', N'installment', N'other'));
GO

/* ========== Score ========== */
IF OBJECT_ID(N'dbo.Score', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[Score](
        [Id] INT IDENTITY(1,1) NOT NULL,
        [RegistrationRef] INT NOT NULL,
        [ExamType] NVARCHAR(30) NOT NULL,
        [ScoreValue] DECIMAL(6,2) NOT NULL,
        [MaxScore] DECIMAL(6,2) NOT NULL CONSTRAINT [DF_Score_MaxScore] DEFAULT (100),
        [Notes] NVARCHAR(500) NULL,
        [ExamDate] CHAR(10) NULL,
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_Score_CreatedAt] DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT [PK_Score] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_Score_Registration] FOREIGN KEY ([RegistrationRef]) REFERENCES [dbo].[Registration]([Id]),
        CONSTRAINT [CK_Score_ExamType] CHECK ([ExamType] IN (N'placement', N'midterm', N'final', N'quiz', N'assignment')),
        CONSTRAINT [CK_Score_Range] CHECK ([ScoreValue] >= 0 AND [ScoreValue] <= [MaxScore])
    );
END
GO

/* ========== CourseHistory (تاریخچه تغییرات دوره — BR / FR-025) ========== */
IF OBJECT_ID(N'dbo.CourseHistory', N'U') IS NULL
BEGIN
    CREATE TABLE [dbo].[CourseHistory](
        [Id] INT IDENTITY(1,1) NOT NULL,
        [CourseRef] INT NOT NULL,
        [ChangedBy] NVARCHAR(50) NOT NULL CONSTRAINT [DF_CourseHistory_ChangedBy] DEFAULT (ORIGINAL_LOGIN()),
        [ChangedAt] DATETIME2 NOT NULL CONSTRAINT [DF_CourseHistory_ChangedAt] DEFAULT (SYSUTCDATETIME()),
        [FieldName] NVARCHAR(50) NOT NULL,
        [OldValue] NVARCHAR(500) NULL,
        [NewValue] NVARCHAR(500) NULL,
        CONSTRAINT [PK_CourseHistory] PRIMARY KEY CLUSTERED ([Id]),
        CONSTRAINT [FK_CourseHistory_Course] FOREIGN KEY ([CourseRef]) REFERENCES [dbo].[Course]([Id])
    );
END
GO

IF OBJECT_ID(N'dbo.TRG_Course_History', N'TR') IS NULL
BEGIN
    EXEC(N'
    CREATE TRIGGER [dbo].[TRG_Course_History]
    ON [dbo].[Course]
    AFTER UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;
        INSERT INTO dbo.CourseHistory (CourseRef, FieldName, OldValue, NewValue)
        SELECT i.Id, N''Name'', CAST(d.Name AS NVARCHAR(500)), CAST(i.Name AS NVARCHAR(500))
        FROM inserted i JOIN deleted d ON i.Id = d.Id WHERE ISNULL(d.Name, N'''') <> ISNULL(i.Name, N'''');

        INSERT INTO dbo.CourseHistory (CourseRef, FieldName, OldValue, NewValue)
        SELECT i.Id, N''Cost'', CAST(d.Cost AS NVARCHAR(500)), CAST(i.Cost AS NVARCHAR(500))
        FROM inserted i JOIN deleted d ON i.Id = d.Id WHERE d.Cost <> i.Cost;

        INSERT INTO dbo.CourseHistory (CourseRef, FieldName, OldValue, NewValue)
        SELECT i.Id, N''SessionsCount'', CAST(d.SessionsCount AS NVARCHAR(500)), CAST(i.SessionsCount AS NVARCHAR(500))
        FROM inserted i JOIN deleted d ON i.Id = d.Id WHERE d.SessionsCount <> i.SessionsCount;

        INSERT INTO dbo.CourseHistory (CourseRef, FieldName, OldValue, NewValue)
        SELECT i.Id, N''IsActive'', CAST(d.IsActive AS NVARCHAR(500)), CAST(i.IsActive AS NVARCHAR(500))
        FROM inserted i JOIN deleted d ON i.Id = d.Id WHERE d.IsActive <> i.IsActive;

        UPDATE c SET UpdatedAt = SYSUTCDATETIME()
        FROM dbo.Course c
        INNER JOIN inserted i ON c.Id = i.Id;
    END
    ');
END
GO

PRINT N'Upgrade Schema Phase1 completed.';
GO
