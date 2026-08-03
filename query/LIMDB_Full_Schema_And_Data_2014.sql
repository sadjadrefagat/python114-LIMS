/*
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
    IF @data IS NULL SET @data = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\';
    IF @log  IS NULL SET @log  = @data;
    IF RIGHT(@data,1) <> N'\' SET @data = @data + N'\';
    IF RIGHT(@log,1)  <> N'\' SET @log  = @log  + N'\';

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


/* ===================== FUNCTIONS ===================== */
GO

IF OBJECT_ID(N'dbo.CheckNationalCode', N'FN') IS NOT NULL
    DROP FUNCTION dbo.[CheckNationalCode];
IF OBJECT_ID(N'dbo.CheckNationalCode', N'IF') IS NOT NULL
    DROP FUNCTION dbo.[CheckNationalCode];
IF OBJECT_ID(N'dbo.CheckNationalCode', N'TF') IS NOT NULL
    DROP FUNCTION dbo.[CheckNationalCode];
GO
/*اعتبار سنجی کد ملی

10   9    8    7    6    5    4    3    2
1    3    7    7    3    9    2    7    5  |  9
10   27   56   49   18   45   8    21   10 = 244
r     0, 1
11-r  > 2
*/
CREATE FUNCTION dbo.CheckNationalCode(@NationalCode VARCHAR(10)) RETURNS BIT
BEGIN
	DECLARE @Result BIT = 0
	IF LEN(@NationalCode) = 10
	BEGIN
		DECLARE @I INT = 10, @Sum INT = 0
		WHILE @I > 1
		BEGIN
			SET @Sum = @Sum + @I * CAST(SUBSTRING(@NationalCode, 11-@I, 1) AS INT)
			SET @I = @I - 1
		END
		DECLARE @R INT = @Sum % 11
		IF @R >= 2
			SET @R = 11 - @R
		IF CAST(SUBSTRING(@NationalCode, 10, 1) AS INT) = @R
			SET @Result = 1
	END
	RETURN @Result
END
GO

/* ===================== TABLES ===================== */
GO

IF OBJECT_ID(N'dbo.Role', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[Role] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Code] NVARCHAR(30) NOT NULL,
    [Name] NVARCHAR(50) NOT NULL,
    [IsActive] BIT NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.Language', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[Language] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(50) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.Branch', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[Branch] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    [Address] NVARCHAR(300) NULL,
    [Phone] VARCHAR(20) NULL,
    [IsActive] BIT NOT NULL,
    [CreatedAt] DATETIME2(7) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.SessionType', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[SessionType] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(50) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.Level', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[Level] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [LanguageRef] INT NOT NULL,
    [Code] NVARCHAR(20) NOT NULL,
    [Name] NVARCHAR(50) NOT NULL,
    [SortOrder] INT NOT NULL,
    [IsActive] BIT NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.Teacher', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[Teacher] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [FirstName] NVARCHAR(50) NOT NULL,
    [LastName] NVARCHAR(50) NOT NULL,
    [FatherName] NVARCHAR(50) NULL,
    [NationalCode] VARCHAR(10) NOT NULL,
    [Gender] INT NOT NULL,
    [BirthDate] CHAR(10) NULL,
    [Creator] NVARCHAR(50) NOT NULL,
    [Mobile] VARCHAR(20) NULL,
    [Email] NVARCHAR(100) NULL,
    [Specialty] NVARCHAR(200) NULL,
    [Bio] NVARCHAR(1000) NULL,
    [IsActive] BIT NOT NULL,
    [CreatedAt] DATETIME2(7) NOT NULL,
    [Photo] VARBINARY(MAX) NULL,
    [PhotoMime] VARCHAR(100) NULL
);
END
GO

IF OBJECT_ID(N'dbo.Student', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[Student] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [FirstName] NVARCHAR(50) NOT NULL,
    [LastName] NVARCHAR(50) NOT NULL,
    [FatherName] NVARCHAR(50) NOT NULL,
    [NationalCode] VARCHAR(10) NOT NULL,
    [Gender] INT NOT NULL,
    [BirthDate] CHAR(10) NOT NULL,
    [Mobile] VARCHAR(50) NOT NULL,
    [Creator] NVARCHAR(50) NOT NULL,
    [Email] NVARCHAR(100) NULL,
    [TargetLanguageRef] INT NULL,
    [CurrentLevelRef] INT NULL,
    [PreferredUILanguage] NVARCHAR(5) NOT NULL,
    [NotificationsEnabled] BIT NOT NULL,
    [IsActive] BIT NOT NULL,
    [CreatedAt] DATETIME2(7) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.Course', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[Course] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [LanguageRef] INT NOT NULL,
    [Name] NVARCHAR(50) NOT NULL,
    [SessionsCount] INT NOT NULL,
    [Cost] INT NOT NULL,
    [Creator] NVARCHAR(50) NOT NULL,
    [IsActive] BIT NOT NULL,
    [LevelRef] INT NULL,
    [Description] NVARCHAR(1000) NULL,
    [PrerequisiteCourseRef] INT NULL,
    [DurationHours] INT NULL,
    [Syllabus] NVARCHAR(MAX) NULL,
    [TeachingMethod] NVARCHAR(200) NULL,
    [AgeGroup] NVARCHAR(50) NULL,
    [IsHighlighted] BIT NOT NULL,
    [CreatedAt] DATETIME2(7) NOT NULL,
    [UpdatedAt] DATETIME2(7) NULL
);
END
GO

IF OBJECT_ID(N'dbo.Class', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[Class] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [CourseRef] INT NOT NULL,
    [TeacherRef] INT NOT NULL,
    [SessionTypeRef] INT NOT NULL,
    [StartDate] CHAR(10) NULL,
    [EndDate] CHAR(10) NULL,
    [Capacity] INT NOT NULL,
    [Status] NVARCHAR(20) NOT NULL,
    [CancelReason] NVARCHAR(300) NULL,
    [ClassType] NVARCHAR(30) NOT NULL,
    [BranchRef] INT NULL,
    [LocationAddress] NVARCHAR(300) NULL,
    [MeetingLink] NVARCHAR(500) NULL,
    [CreatedAt] DATETIME2(7) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.Session', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[Session] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ClassRef] INT NOT NULL,
    [Date] CHAR(10) NOT NULL,
    [StartTime] CHAR(5) NOT NULL,
    [EndTime] CHAR(5) NOT NULL,
    [SessionTypeRef] INT NOT NULL,
    [Status] NVARCHAR(20) NOT NULL,
    [CancelReason] NVARCHAR(300) NULL,
    [MeetingLink] NVARCHAR(500) NULL,
    [LocationAddress] NVARCHAR(300) NULL,
    [SubstituteTeacherRef] INT NULL,
    [IsMakeup] BIT NOT NULL,
    [Notes] NVARCHAR(500) NULL
);
END
GO

IF OBJECT_ID(N'dbo.SessionStudent', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[SessionStudent] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [SessionRef] INT NOT NULL,
    [StudentRef] INT NOT NULL,
    [AttendanceStatus] NVARCHAR(20) NOT NULL,
    [RecordedAt] DATETIME2(7) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.Registration', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[Registration] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Studentref] INT NOT NULL,
    [CourseRef] INT NOT NULL,
    [Date] CHAR(10) NOT NULL,
    [ClassRef] INT NULL,
    [Status] NVARCHAR(30) NOT NULL,
    [WithdrawReason] NVARCHAR(300) NULL,
    [FinancialStatus] NVARCHAR(20) NOT NULL,
    [CreatedAt] DATETIME2(7) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.Payment', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[Payment] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [StudentRef] INT NOT NULL,
    [Date] CHAR(10) NOT NULL,
    [Amount] INT NOT NULL,
    [PaymentType] INT NOT NULL,
    [Status] NVARCHAR(20) NOT NULL,
    [PaymentMethod] NVARCHAR(20) NULL,
    [RegistrationRef] INT NULL,
    [Description] NVARCHAR(300) NULL,
    [CreatedAt] DATETIME2(7) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.Score', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[Score] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [RegistrationRef] INT NULL,
    [ExamType] NVARCHAR(30) NOT NULL,
    [ScoreValue] DECIMAL(6,2) NOT NULL,
    [MaxScore] DECIMAL(6,2) NOT NULL,
    [Notes] NVARCHAR(500) NULL,
    [ExamDate] CHAR(10) NULL,
    [CreatedAt] DATETIME2(7) NOT NULL,
    [StudentRef] INT NULL,
    [SuggestedLevelRef] INT NULL
);
END
GO

IF OBJECT_ID(N'dbo.CourseHistory', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[CourseHistory] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [CourseRef] INT NOT NULL,
    [ChangedBy] NVARCHAR(50) NOT NULL,
    [ChangedAt] DATETIME2(7) NOT NULL,
    [FieldName] NVARCHAR(50) NOT NULL,
    [OldValue] NVARCHAR(500) NULL,
    [NewValue] NVARCHAR(500) NULL
);
END
GO

IF OBJECT_ID(N'dbo.AppUser', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[AppUser] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Username] NVARCHAR(50) NOT NULL,
    [Email] NVARCHAR(100) NULL,
    [PasswordHash] NVARCHAR(200) NOT NULL,
    [FullName] NVARCHAR(100) NULL,
    [RoleRef] INT NOT NULL,
    [StudentRef] INT NULL,
    [TeacherRef] INT NULL,
    [IsActive] BIT NOT NULL,
    [PreferredUILanguage] NVARCHAR(5) NOT NULL,
    [FailedLoginCount] INT NOT NULL,
    [LockedUntil] DATETIME2(7) NULL,
    [LastLoginAt] DATETIME2(7) NULL,
    [CreatedAt] DATETIME2(7) NOT NULL,
    [UiTheme] NVARCHAR(30) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.UserSession', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[UserSession] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserRef] INT NOT NULL,
    [TokenHash] CHAR(64) NOT NULL,
    [CreatedAt] DATETIME2(7) NOT NULL,
    [ExpiresAt] DATETIME2(7) NOT NULL,
    [RevokedAt] DATETIME2(7) NULL
);
END
GO

IF OBJECT_ID(N'dbo.ShopCategory', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[ShopCategory] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    [SortOrder] INT NOT NULL,
    [IsActive] BIT NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.ShopProduct', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[ShopProduct] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [CategoryRef] INT NULL,
    [Name] NVARCHAR(200) NOT NULL,
    [Sku] NVARCHAR(50) NULL,
    [Description] NVARCHAR(MAX) NULL,
    [Price] INT NOT NULL,
    [Stock] INT NOT NULL,
    [ProductType] NVARCHAR(20) NOT NULL,
    [ImageUrl] NVARCHAR(500) NULL,
    [IsActive] BIT NOT NULL,
    [IsFeatured] BIT NOT NULL,
    [CreatedAt] DATETIME2(7) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.ShopProductLike', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[ShopProductLike] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserRef] INT NOT NULL,
    [ProductRef] INT NOT NULL,
    [CreatedAt] DATETIME2(7) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.ShopProductBookmark', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[ShopProductBookmark] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserRef] INT NOT NULL,
    [ProductRef] INT NOT NULL,
    [CreatedAt] DATETIME2(7) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.ShopCartItem', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[ShopCartItem] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserRef] INT NULL,
    [SessionKey] NVARCHAR(64) NULL,
    [ProductRef] INT NOT NULL,
    [Qty] INT NOT NULL,
    [UpdatedAt] DATETIME2(7) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.ShopOrder', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[ShopOrder] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserRef] INT NULL,
    [SessionKey] NVARCHAR(64) NULL,
    [Status] NVARCHAR(20) NOT NULL,
    [TotalAmount] INT NOT NULL,
    [Note] NVARCHAR(500) NULL,
    [CreatedAt] DATETIME2(7) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.ShopOrderItem', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[ShopOrderItem] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [OrderRef] INT NOT NULL,
    [ProductRef] INT NOT NULL,
    [Qty] INT NOT NULL,
    [UnitPrice] INT NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.PlacementTestType', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[PlacementTestType] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Code] NVARCHAR(40) NOT NULL,
    [Name] NVARCHAR(200) NOT NULL,
    [LanguageRef] INT NOT NULL,
    [Description] NVARCHAR(MAX) NULL,
    [DurationMinutes] INT NOT NULL,
    [QuestionsToAsk] INT NOT NULL,
    [IsActive] BIT NOT NULL,
    [CreatedAt] DATETIME2(7) NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.PlacementQuestion', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[PlacementQuestion] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [TestTypeRef] INT NOT NULL,
    [Skill] NVARCHAR(20) NOT NULL,
    [Difficulty] INT NOT NULL,
    [Prompt] NVARCHAR(MAX) NOT NULL,
    [OptionA] NVARCHAR(500) NOT NULL,
    [OptionB] NVARCHAR(500) NOT NULL,
    [OptionC] NVARCHAR(500) NOT NULL,
    [OptionD] NVARCHAR(500) NOT NULL,
    [CorrectOption] CHAR(1) NOT NULL,
    [Points] FLOAT(53) NOT NULL,
    [Explanation] NVARCHAR(MAX) NULL,
    [IsActive] BIT NOT NULL,
    [Creator] NVARCHAR(100) NULL,
    [CreatedAt] DATETIME2(7) NOT NULL,
    [UpdatedAt] DATETIME2(7) NULL
);
END
GO

IF OBJECT_ID(N'dbo.PlacementLevelRule', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[PlacementLevelRule] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [TestTypeRef] INT NOT NULL,
    [MinPercent] FLOAT(53) NOT NULL,
    [MaxPercent] FLOAT(53) NOT NULL,
    [LevelRef] INT NOT NULL,
    [Label] NVARCHAR(200) NULL
);
END
GO

IF OBJECT_ID(N'dbo.PlacementAttempt', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[PlacementAttempt] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [TestTypeRef] INT NOT NULL,
    [StudentRef] INT NOT NULL,
    [Status] NVARCHAR(20) NOT NULL,
    [StartedAt] DATETIME2(7) NOT NULL,
    [FinishedAt] DATETIME2(7) NULL,
    [ScoreValue] FLOAT(53) NULL,
    [MaxScore] FLOAT(53) NULL,
    [PercentScore] FLOAT(53) NULL,
    [SuggestedLevelRef] INT NULL,
    [ScoreRecordRef] INT NULL
);
END
GO

IF OBJECT_ID(N'dbo.PlacementAttemptAnswer', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[PlacementAttemptAnswer] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [AttemptRef] INT NOT NULL,
    [QuestionRef] INT NOT NULL,
    [SelectedOption] CHAR(1) NULL,
    [IsCorrect] BIT NULL,
    [PointsAwarded] FLOAT(53) NULL,
    [SortOrder] INT NOT NULL
);
END
GO

IF OBJECT_ID(N'dbo.ActivityLog', N'U') IS NULL
BEGIN
CREATE TABLE dbo.[ActivityLog] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserRef] INT NULL,
    [Username] NVARCHAR(100) NULL,
    [ActionCode] NVARCHAR(40) NOT NULL,
    [EntityType] NVARCHAR(40) NULL,
    [EntityId] INT NULL,
    [Message] NVARCHAR(500) NOT NULL,
    [DetailJson] NVARCHAR(MAX) NULL,
    [Method] NVARCHAR(10) NULL,
    [Path] NVARCHAR(300) NULL,
    [StatusCode] INT NULL,
    [IpAddress] NVARCHAR(64) NULL,
    [CreatedAt] DATETIME2(7) NOT NULL
);
END
GO

/* ===================== PRIMARY KEYS ===================== */
GO

IF OBJECT_ID(N'dbo.PK__Activity__3214EC072F268180', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.ActivityLog', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ActivityLog]
      ADD CONSTRAINT [PK__Activity__3214EC072F268180] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__AppUser__3214EC0755AC99AE', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.AppUser', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[AppUser]
      ADD CONSTRAINT [PK__AppUser__3214EC0755AC99AE] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK_Branch', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.Branch', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Branch]
      ADD CONSTRAINT [PK_Branch] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK_Class', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.Class', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Class]
      ADD CONSTRAINT [PK_Class] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK_Course', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.Course', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Course]
      ADD CONSTRAINT [PK_Course] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK_CourseHistory', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.CourseHistory', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[CourseHistory]
      ADD CONSTRAINT [PK_CourseHistory] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK_Language', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.Language', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Language]
      ADD CONSTRAINT [PK_Language] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK_Level', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.Level', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Level]
      ADD CONSTRAINT [PK_Level] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK_Payment', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.Payment', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Payment]
      ADD CONSTRAINT [PK_Payment] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__Placemen__3214EC078C9BDF9A', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.PlacementAttempt', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementAttempt]
      ADD CONSTRAINT [PK__Placemen__3214EC078C9BDF9A] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__Placemen__3214EC07B3CD8E08', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.PlacementAttemptAnswer', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementAttemptAnswer]
      ADD CONSTRAINT [PK__Placemen__3214EC07B3CD8E08] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__Placemen__3214EC07763639B1', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.PlacementLevelRule', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementLevelRule]
      ADD CONSTRAINT [PK__Placemen__3214EC07763639B1] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__Placemen__3214EC078E009E44', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.PlacementQuestion', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementQuestion]
      ADD CONSTRAINT [PK__Placemen__3214EC078E009E44] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__Placemen__3214EC072B03EA88', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.PlacementTestType', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementTestType]
      ADD CONSTRAINT [PK__Placemen__3214EC072B03EA88] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK_Registration', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.Registration', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Registration]
      ADD CONSTRAINT [PK_Registration] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__Role__3214EC07345C37C4', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.Role', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Role]
      ADD CONSTRAINT [PK__Role__3214EC07345C37C4] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK_Score', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.Score', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Score]
      ADD CONSTRAINT [PK_Score] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK_Session', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.Session', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Session]
      ADD CONSTRAINT [PK_Session] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK_SessionStudent', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.SessionStudent', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[SessionStudent]
      ADD CONSTRAINT [PK_SessionStudent] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK_SessionType', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.SessionType', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[SessionType]
      ADD CONSTRAINT [PK_SessionType] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__ShopCart__3214EC076D58A234', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.ShopCartItem', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopCartItem]
      ADD CONSTRAINT [PK__ShopCart__3214EC076D58A234] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__ShopCate__3214EC07BF40E370', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.ShopCategory', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopCategory]
      ADD CONSTRAINT [PK__ShopCate__3214EC07BF40E370] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__ShopOrde__3214EC078BB6169D', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.ShopOrder', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopOrder]
      ADD CONSTRAINT [PK__ShopOrde__3214EC078BB6169D] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__ShopOrde__3214EC079DA77CB8', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.ShopOrderItem', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopOrderItem]
      ADD CONSTRAINT [PK__ShopOrde__3214EC079DA77CB8] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__ShopProd__3214EC07952774DB', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.ShopProduct', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProduct]
      ADD CONSTRAINT [PK__ShopProd__3214EC07952774DB] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__ShopProd__3214EC07448BA7A9', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.ShopProductBookmark', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProductBookmark]
      ADD CONSTRAINT [PK__ShopProd__3214EC07448BA7A9] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__ShopProd__3214EC07F759A610', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.ShopProductLike', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProductLike]
      ADD CONSTRAINT [PK__ShopProd__3214EC07F759A610] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK_Student', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.Student', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Student]
      ADD CONSTRAINT [PK_Student] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK_Teacher', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.Teacher', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Teacher]
      ADD CONSTRAINT [PK_Teacher] PRIMARY KEY CLUSTERED ([Id]);
END
GO

IF OBJECT_ID(N'dbo.PK__UserSess__3214EC07622548DE', N'PK') IS NULL
   AND OBJECT_ID(N'dbo.UserSession', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[UserSession]
      ADD CONSTRAINT [PK__UserSess__3214EC07622548DE] PRIMARY KEY CLUSTERED ([Id]);
END
GO

/* ===================== DEFAULTS ===================== */
GO

IF OBJECT_ID(N'dbo.DF_ActivityLog_Created', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ActivityLog', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ActivityLog]
      ADD CONSTRAINT [DF_ActivityLog_Created]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_AppUser_IsActive', N'D') IS NULL
   AND COL_LENGTH(N'dbo.AppUser', N'IsActive') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[AppUser]
      ADD CONSTRAINT [DF_AppUser_IsActive]
      DEFAULT ((1)) FOR [IsActive];
END
GO

IF OBJECT_ID(N'dbo.DF_AppUser_UI', N'D') IS NULL
   AND COL_LENGTH(N'dbo.AppUser', N'PreferredUILanguage') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[AppUser]
      ADD CONSTRAINT [DF_AppUser_UI]
      DEFAULT (N'fa') FOR [PreferredUILanguage];
END
GO

IF OBJECT_ID(N'dbo.DF_AppUser_Fail', N'D') IS NULL
   AND COL_LENGTH(N'dbo.AppUser', N'FailedLoginCount') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[AppUser]
      ADD CONSTRAINT [DF_AppUser_Fail]
      DEFAULT ((0)) FOR [FailedLoginCount];
END
GO

IF OBJECT_ID(N'dbo.DF_AppUser_CreatedAt', N'D') IS NULL
   AND COL_LENGTH(N'dbo.AppUser', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[AppUser]
      ADD CONSTRAINT [DF_AppUser_CreatedAt]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_AppUser_UiTheme', N'D') IS NULL
   AND COL_LENGTH(N'dbo.AppUser', N'UiTheme') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[AppUser]
      ADD CONSTRAINT [DF_AppUser_UiTheme]
      DEFAULT (N'light') FOR [UiTheme];
END
GO

IF OBJECT_ID(N'dbo.DF_Branch_IsActive', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Branch', N'IsActive') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Branch]
      ADD CONSTRAINT [DF_Branch_IsActive]
      DEFAULT ((1)) FOR [IsActive];
END
GO

IF OBJECT_ID(N'dbo.DF_Branch_CreatedAt', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Branch', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Branch]
      ADD CONSTRAINT [DF_Branch_CreatedAt]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_Class_Capacity', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Class', N'Capacity') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Class]
      ADD CONSTRAINT [DF_Class_Capacity]
      DEFAULT ((15)) FOR [Capacity];
END
GO

IF OBJECT_ID(N'dbo.DF_Class_Status', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Class', N'Status') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Class]
      ADD CONSTRAINT [DF_Class_Status]
      DEFAULT (N'open') FOR [Status];
END
GO

IF OBJECT_ID(N'dbo.DF_Class_ClassType', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Class', N'ClassType') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Class]
      ADD CONSTRAINT [DF_Class_ClassType]
      DEFAULT (N'group') FOR [ClassType];
END
GO

IF OBJECT_ID(N'dbo.DF_Class_CreatedAt', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Class', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Class]
      ADD CONSTRAINT [DF_Class_CreatedAt]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_Course_Creator', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Course', N'Creator') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Course]
      ADD CONSTRAINT [DF_Course_Creator]
      DEFAULT (original_login()) FOR [Creator];
END
GO

IF OBJECT_ID(N'dbo.DF_Course_IsActive', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Course', N'IsActive') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Course]
      ADD CONSTRAINT [DF_Course_IsActive]
      DEFAULT ((1)) FOR [IsActive];
END
GO

IF OBJECT_ID(N'dbo.DF_Course_IsHighlighted', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Course', N'IsHighlighted') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Course]
      ADD CONSTRAINT [DF_Course_IsHighlighted]
      DEFAULT ((0)) FOR [IsHighlighted];
END
GO

IF OBJECT_ID(N'dbo.DF_Course_CreatedAt', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Course', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Course]
      ADD CONSTRAINT [DF_Course_CreatedAt]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_CourseHistory_ChangedBy', N'D') IS NULL
   AND COL_LENGTH(N'dbo.CourseHistory', N'ChangedBy') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[CourseHistory]
      ADD CONSTRAINT [DF_CourseHistory_ChangedBy]
      DEFAULT (original_login()) FOR [ChangedBy];
END
GO

IF OBJECT_ID(N'dbo.DF_CourseHistory_ChangedAt', N'D') IS NULL
   AND COL_LENGTH(N'dbo.CourseHistory', N'ChangedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[CourseHistory]
      ADD CONSTRAINT [DF_CourseHistory_ChangedAt]
      DEFAULT (sysutcdatetime()) FOR [ChangedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_Level_SortOrder', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Level', N'SortOrder') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Level]
      ADD CONSTRAINT [DF_Level_SortOrder]
      DEFAULT ((0)) FOR [SortOrder];
END
GO

IF OBJECT_ID(N'dbo.DF_Level_IsActive', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Level', N'IsActive') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Level]
      ADD CONSTRAINT [DF_Level_IsActive]
      DEFAULT ((1)) FOR [IsActive];
END
GO

IF OBJECT_ID(N'dbo.DF_Payment_Status', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Payment', N'Status') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Payment]
      ADD CONSTRAINT [DF_Payment_Status]
      DEFAULT (N'paid') FOR [Status];
END
GO

IF OBJECT_ID(N'dbo.DF_Payment_CreatedAt', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Payment', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Payment]
      ADD CONSTRAINT [DF_Payment_CreatedAt]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_PA_Status', N'D') IS NULL
   AND COL_LENGTH(N'dbo.PlacementAttempt', N'Status') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementAttempt]
      ADD CONSTRAINT [DF_PA_Status]
      DEFAULT (N'in_progress') FOR [Status];
END
GO

IF OBJECT_ID(N'dbo.DF_PA_Started', N'D') IS NULL
   AND COL_LENGTH(N'dbo.PlacementAttempt', N'StartedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementAttempt]
      ADD CONSTRAINT [DF_PA_Started]
      DEFAULT (sysutcdatetime()) FOR [StartedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_PAA_Sort', N'D') IS NULL
   AND COL_LENGTH(N'dbo.PlacementAttemptAnswer', N'SortOrder') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementAttemptAnswer]
      ADD CONSTRAINT [DF_PAA_Sort]
      DEFAULT ((0)) FOR [SortOrder];
END
GO

IF OBJECT_ID(N'dbo.DF_PQ_Skill', N'D') IS NULL
   AND COL_LENGTH(N'dbo.PlacementQuestion', N'Skill') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementQuestion]
      ADD CONSTRAINT [DF_PQ_Skill]
      DEFAULT (N'general') FOR [Skill];
END
GO

IF OBJECT_ID(N'dbo.DF_PQ_Diff', N'D') IS NULL
   AND COL_LENGTH(N'dbo.PlacementQuestion', N'Difficulty') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementQuestion]
      ADD CONSTRAINT [DF_PQ_Diff]
      DEFAULT ((1)) FOR [Difficulty];
END
GO

IF OBJECT_ID(N'dbo.DF_PQ_Pts', N'D') IS NULL
   AND COL_LENGTH(N'dbo.PlacementQuestion', N'Points') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementQuestion]
      ADD CONSTRAINT [DF_PQ_Pts]
      DEFAULT ((1)) FOR [Points];
END
GO

IF OBJECT_ID(N'dbo.DF_PQ_Active', N'D') IS NULL
   AND COL_LENGTH(N'dbo.PlacementQuestion', N'IsActive') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementQuestion]
      ADD CONSTRAINT [DF_PQ_Active]
      DEFAULT ((1)) FOR [IsActive];
END
GO

IF OBJECT_ID(N'dbo.DF_PQ_Created', N'D') IS NULL
   AND COL_LENGTH(N'dbo.PlacementQuestion', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementQuestion]
      ADD CONSTRAINT [DF_PQ_Created]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_PTT_Dur', N'D') IS NULL
   AND COL_LENGTH(N'dbo.PlacementTestType', N'DurationMinutes') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementTestType]
      ADD CONSTRAINT [DF_PTT_Dur]
      DEFAULT ((30)) FOR [DurationMinutes];
END
GO

IF OBJECT_ID(N'dbo.DF_PTT_Q', N'D') IS NULL
   AND COL_LENGTH(N'dbo.PlacementTestType', N'QuestionsToAsk') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementTestType]
      ADD CONSTRAINT [DF_PTT_Q]
      DEFAULT ((10)) FOR [QuestionsToAsk];
END
GO

IF OBJECT_ID(N'dbo.DF_PTT_Active', N'D') IS NULL
   AND COL_LENGTH(N'dbo.PlacementTestType', N'IsActive') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementTestType]
      ADD CONSTRAINT [DF_PTT_Active]
      DEFAULT ((1)) FOR [IsActive];
END
GO

IF OBJECT_ID(N'dbo.DF_PTT_Created', N'D') IS NULL
   AND COL_LENGTH(N'dbo.PlacementTestType', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementTestType]
      ADD CONSTRAINT [DF_PTT_Created]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_Registration_Status', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Registration', N'Status') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Registration]
      ADD CONSTRAINT [DF_Registration_Status]
      DEFAULT (N'active') FOR [Status];
END
GO

IF OBJECT_ID(N'dbo.DF_Registration_FinancialStatus', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Registration', N'FinancialStatus') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Registration]
      ADD CONSTRAINT [DF_Registration_FinancialStatus]
      DEFAULT (N'debtor') FOR [FinancialStatus];
END
GO

IF OBJECT_ID(N'dbo.DF_Registration_CreatedAt', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Registration', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Registration]
      ADD CONSTRAINT [DF_Registration_CreatedAt]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_Role_IsActive', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Role', N'IsActive') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Role]
      ADD CONSTRAINT [DF_Role_IsActive]
      DEFAULT ((1)) FOR [IsActive];
END
GO

IF OBJECT_ID(N'dbo.DF_Score_MaxScore', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Score', N'MaxScore') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Score]
      ADD CONSTRAINT [DF_Score_MaxScore]
      DEFAULT ((100)) FOR [MaxScore];
END
GO

IF OBJECT_ID(N'dbo.DF_Score_CreatedAt', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Score', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Score]
      ADD CONSTRAINT [DF_Score_CreatedAt]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_Session_Status', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Session', N'Status') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Session]
      ADD CONSTRAINT [DF_Session_Status]
      DEFAULT (N'scheduled') FOR [Status];
END
GO

IF OBJECT_ID(N'dbo.DF_Session_IsMakeup', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Session', N'IsMakeup') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Session]
      ADD CONSTRAINT [DF_Session_IsMakeup]
      DEFAULT ((0)) FOR [IsMakeup];
END
GO

IF OBJECT_ID(N'dbo.DF_SessionStudent_AttendanceStatus', N'D') IS NULL
   AND COL_LENGTH(N'dbo.SessionStudent', N'AttendanceStatus') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[SessionStudent]
      ADD CONSTRAINT [DF_SessionStudent_AttendanceStatus]
      DEFAULT (N'present') FOR [AttendanceStatus];
END
GO

IF OBJECT_ID(N'dbo.DF_SessionStudent_RecordedAt', N'D') IS NULL
   AND COL_LENGTH(N'dbo.SessionStudent', N'RecordedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[SessionStudent]
      ADD CONSTRAINT [DF_SessionStudent_RecordedAt]
      DEFAULT (sysutcdatetime()) FOR [RecordedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopCart_Qty', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopCartItem', N'Qty') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopCartItem]
      ADD CONSTRAINT [DF_ShopCart_Qty]
      DEFAULT ((1)) FOR [Qty];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopCart_Updated', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopCartItem', N'UpdatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopCartItem]
      ADD CONSTRAINT [DF_ShopCart_Updated]
      DEFAULT (sysutcdatetime()) FOR [UpdatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopCategory_Sort', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopCategory', N'SortOrder') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopCategory]
      ADD CONSTRAINT [DF_ShopCategory_Sort]
      DEFAULT ((0)) FOR [SortOrder];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopCategory_Active', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopCategory', N'IsActive') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopCategory]
      ADD CONSTRAINT [DF_ShopCategory_Active]
      DEFAULT ((1)) FOR [IsActive];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopOrder_Status', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopOrder', N'Status') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopOrder]
      ADD CONSTRAINT [DF_ShopOrder_Status]
      DEFAULT (N'pending') FOR [Status];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopOrder_Total', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopOrder', N'TotalAmount') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopOrder]
      ADD CONSTRAINT [DF_ShopOrder_Total]
      DEFAULT ((0)) FOR [TotalAmount];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopOrder_Created', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopOrder', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopOrder]
      ADD CONSTRAINT [DF_ShopOrder_Created]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopProduct_Price', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopProduct', N'Price') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProduct]
      ADD CONSTRAINT [DF_ShopProduct_Price]
      DEFAULT ((0)) FOR [Price];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopProduct_Stock', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopProduct', N'Stock') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProduct]
      ADD CONSTRAINT [DF_ShopProduct_Stock]
      DEFAULT ((0)) FOR [Stock];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopProduct_Type', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopProduct', N'ProductType') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProduct]
      ADD CONSTRAINT [DF_ShopProduct_Type]
      DEFAULT (N'other') FOR [ProductType];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopProduct_Active', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopProduct', N'IsActive') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProduct]
      ADD CONSTRAINT [DF_ShopProduct_Active]
      DEFAULT ((1)) FOR [IsActive];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopProduct_Feat', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopProduct', N'IsFeatured') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProduct]
      ADD CONSTRAINT [DF_ShopProduct_Feat]
      DEFAULT ((0)) FOR [IsFeatured];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopProduct_Created', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopProduct', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProduct]
      ADD CONSTRAINT [DF_ShopProduct_Created]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopBookmark_Created', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopProductBookmark', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProductBookmark]
      ADD CONSTRAINT [DF_ShopBookmark_Created]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_ShopLike_Created', N'D') IS NULL
   AND COL_LENGTH(N'dbo.ShopProductLike', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProductLike]
      ADD CONSTRAINT [DF_ShopLike_Created]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_Student_Creator', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Student', N'Creator') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Student]
      ADD CONSTRAINT [DF_Student_Creator]
      DEFAULT (original_login()) FOR [Creator];
END
GO

IF OBJECT_ID(N'dbo.DF_Student_PreferredUILanguage', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Student', N'PreferredUILanguage') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Student]
      ADD CONSTRAINT [DF_Student_PreferredUILanguage]
      DEFAULT (N'fa') FOR [PreferredUILanguage];
END
GO

IF OBJECT_ID(N'dbo.DF_Student_NotificationsEnabled', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Student', N'NotificationsEnabled') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Student]
      ADD CONSTRAINT [DF_Student_NotificationsEnabled]
      DEFAULT ((1)) FOR [NotificationsEnabled];
END
GO

IF OBJECT_ID(N'dbo.DF_Student_IsActive', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Student', N'IsActive') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Student]
      ADD CONSTRAINT [DF_Student_IsActive]
      DEFAULT ((1)) FOR [IsActive];
END
GO

IF OBJECT_ID(N'dbo.DF_Student_CreatedAt', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Student', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Student]
      ADD CONSTRAINT [DF_Student_CreatedAt]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_Teacher_Creator', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Teacher', N'Creator') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Teacher]
      ADD CONSTRAINT [DF_Teacher_Creator]
      DEFAULT (original_login()) FOR [Creator];
END
GO

IF OBJECT_ID(N'dbo.DF_Teacher_IsActive', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Teacher', N'IsActive') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Teacher]
      ADD CONSTRAINT [DF_Teacher_IsActive]
      DEFAULT ((1)) FOR [IsActive];
END
GO

IF OBJECT_ID(N'dbo.DF_Teacher_CreatedAt', N'D') IS NULL
   AND COL_LENGTH(N'dbo.Teacher', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Teacher]
      ADD CONSTRAINT [DF_Teacher_CreatedAt]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

IF OBJECT_ID(N'dbo.DF_UserSession_CreatedAt', N'D') IS NULL
   AND COL_LENGTH(N'dbo.UserSession', N'CreatedAt') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[UserSession]
      ADD CONSTRAINT [DF_UserSession_CreatedAt]
      DEFAULT (sysutcdatetime()) FOR [CreatedAt];
END
GO

/* ===================== CHECK CONSTRAINTS ===================== */
GO

IF OBJECT_ID(N'dbo.CK_Class_Capacity_NonNegative', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Class', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Class] WITH NOCHECK
      ADD CONSTRAINT [CK_Class_Capacity_NonNegative] CHECK ([Capacity]>=(0));
    ALTER TABLE dbo.[Class] CHECK CONSTRAINT [CK_Class_Capacity_NonNegative];
END
GO

IF OBJECT_ID(N'dbo.CK_Class_ClassType', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Class', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Class] WITH NOCHECK
      ADD CONSTRAINT [CK_Class_ClassType] CHECK ([ClassType]=N'vip' OR [ClassType]=N'private' OR [ClassType]=N'semi_private' OR [ClassType]=N'group');
    ALTER TABLE dbo.[Class] CHECK CONSTRAINT [CK_Class_ClassType];
END
GO

IF OBJECT_ID(N'dbo.CK_Class_Status', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Class', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Class] WITH NOCHECK
      ADD CONSTRAINT [CK_Class_Status] CHECK ([Status]=N'cancelled' OR [Status]=N'finished' OR [Status]=N'in_progress' OR [Status]=N'full' OR [Status]=N'open' OR [Status]=N'draft');
    ALTER TABLE dbo.[Class] CHECK CONSTRAINT [CK_Class_Status];
END
GO

IF OBJECT_ID(N'dbo.CK_Course_Cost_NonNegative', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Course', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Course] WITH NOCHECK
      ADD CONSTRAINT [CK_Course_Cost_NonNegative] CHECK ([Cost]>=(0));
    ALTER TABLE dbo.[Course] CHECK CONSTRAINT [CK_Course_Cost_NonNegative];
END
GO

IF OBJECT_ID(N'dbo.CK_Course_SessionsCount_Positive', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Course', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Course] WITH NOCHECK
      ADD CONSTRAINT [CK_Course_SessionsCount_Positive] CHECK ([SessionsCount]>(0));
    ALTER TABLE dbo.[Course] CHECK CONSTRAINT [CK_Course_SessionsCount_Positive];
END
GO

IF OBJECT_ID(N'dbo.CK_Payment_Amount_NonNegative', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Payment', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Payment] WITH NOCHECK
      ADD CONSTRAINT [CK_Payment_Amount_NonNegative] CHECK ([Amount]>=(0));
    ALTER TABLE dbo.[Payment] CHECK CONSTRAINT [CK_Payment_Amount_NonNegative];
END
GO

IF OBJECT_ID(N'dbo.CK_Payment_Method', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Payment', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Payment] WITH NOCHECK
      ADD CONSTRAINT [CK_Payment_Method] CHECK ([PaymentMethod] IS NULL OR ([PaymentMethod]=N'other' OR [PaymentMethod]=N'installment' OR [PaymentMethod]=N'online' OR [PaymentMethod]=N'card' OR [PaymentMethod]=N'cash'));
    ALTER TABLE dbo.[Payment] CHECK CONSTRAINT [CK_Payment_Method];
END
GO

IF OBJECT_ID(N'dbo.CK_Payment_Status', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Payment', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Payment] WITH NOCHECK
      ADD CONSTRAINT [CK_Payment_Status] CHECK ([Status]=N'overdue' OR [Status]=N'partially_paid' OR [Status]=N'refunded' OR [Status]=N'failed' OR [Status]=N'paid' OR [Status]=N'pending' OR [Status]=N'draft');
    ALTER TABLE dbo.[Payment] CHECK CONSTRAINT [CK_Payment_Status];
END
GO

IF OBJECT_ID(N'dbo.CK_PA_Status', N'C') IS NULL
   AND OBJECT_ID(N'dbo.PlacementAttempt', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementAttempt] WITH NOCHECK
      ADD CONSTRAINT [CK_PA_Status] CHECK ([Status]=N'abandoned' OR [Status]=N'completed' OR [Status]=N'in_progress');
    ALTER TABLE dbo.[PlacementAttempt] CHECK CONSTRAINT [CK_PA_Status];
END
GO

IF OBJECT_ID(N'dbo.CK_PAA_Opt', N'C') IS NULL
   AND OBJECT_ID(N'dbo.PlacementAttemptAnswer', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementAttemptAnswer] WITH NOCHECK
      ADD CONSTRAINT [CK_PAA_Opt] CHECK ([SelectedOption] IS NULL OR ([SelectedOption]='D' OR [SelectedOption]='C' OR [SelectedOption]='B' OR [SelectedOption]='A'));
    ALTER TABLE dbo.[PlacementAttemptAnswer] CHECK CONSTRAINT [CK_PAA_Opt];
END
GO

IF OBJECT_ID(N'dbo.CK_PLR_Range', N'C') IS NULL
   AND OBJECT_ID(N'dbo.PlacementLevelRule', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementLevelRule] WITH NOCHECK
      ADD CONSTRAINT [CK_PLR_Range] CHECK ([MinPercent]>=(0) AND [MaxPercent]<=(100) AND [MaxPercent]>=[MinPercent]);
    ALTER TABLE dbo.[PlacementLevelRule] CHECK CONSTRAINT [CK_PLR_Range];
END
GO

IF OBJECT_ID(N'dbo.CK_PQ_Correct', N'C') IS NULL
   AND OBJECT_ID(N'dbo.PlacementQuestion', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementQuestion] WITH NOCHECK
      ADD CONSTRAINT [CK_PQ_Correct] CHECK ([CorrectOption]='D' OR [CorrectOption]='C' OR [CorrectOption]='B' OR [CorrectOption]='A');
    ALTER TABLE dbo.[PlacementQuestion] CHECK CONSTRAINT [CK_PQ_Correct];
END
GO

IF OBJECT_ID(N'dbo.CK_PQ_Diff', N'C') IS NULL
   AND OBJECT_ID(N'dbo.PlacementQuestion', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementQuestion] WITH NOCHECK
      ADD CONSTRAINT [CK_PQ_Diff] CHECK ([Difficulty]>=(1) AND [Difficulty]<=(5));
    ALTER TABLE dbo.[PlacementQuestion] CHECK CONSTRAINT [CK_PQ_Diff];
END
GO

IF OBJECT_ID(N'dbo.CK_PQ_Pts', N'C') IS NULL
   AND OBJECT_ID(N'dbo.PlacementQuestion', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementQuestion] WITH NOCHECK
      ADD CONSTRAINT [CK_PQ_Pts] CHECK ([Points]>(0));
    ALTER TABLE dbo.[PlacementQuestion] CHECK CONSTRAINT [CK_PQ_Pts];
END
GO

IF OBJECT_ID(N'dbo.CK_PQ_Skill', N'C') IS NULL
   AND OBJECT_ID(N'dbo.PlacementQuestion', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementQuestion] WITH NOCHECK
      ADD CONSTRAINT [CK_PQ_Skill] CHECK ([Skill]=N'general' OR [Skill]=N'listening' OR [Skill]=N'reading' OR [Skill]=N'vocabulary' OR [Skill]=N'grammar');
    ALTER TABLE dbo.[PlacementQuestion] CHECK CONSTRAINT [CK_PQ_Skill];
END
GO

IF OBJECT_ID(N'dbo.CK_PTT_Dur', N'C') IS NULL
   AND OBJECT_ID(N'dbo.PlacementTestType', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementTestType] WITH NOCHECK
      ADD CONSTRAINT [CK_PTT_Dur] CHECK ([DurationMinutes]>=(5) AND [DurationMinutes]<=(180));
    ALTER TABLE dbo.[PlacementTestType] CHECK CONSTRAINT [CK_PTT_Dur];
END
GO

IF OBJECT_ID(N'dbo.CK_PTT_Q', N'C') IS NULL
   AND OBJECT_ID(N'dbo.PlacementTestType', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementTestType] WITH NOCHECK
      ADD CONSTRAINT [CK_PTT_Q] CHECK ([QuestionsToAsk]>=(1) AND [QuestionsToAsk]<=(100));
    ALTER TABLE dbo.[PlacementTestType] CHECK CONSTRAINT [CK_PTT_Q];
END
GO

IF OBJECT_ID(N'dbo.CK_Registration_FinancialStatus', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Registration', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Registration] WITH NOCHECK
      ADD CONSTRAINT [CK_Registration_FinancialStatus] CHECK ([FinancialStatus]=N'settled' OR [FinancialStatus]=N'creditor' OR [FinancialStatus]=N'debtor');
    ALTER TABLE dbo.[Registration] CHECK CONSTRAINT [CK_Registration_FinancialStatus];
END
GO

IF OBJECT_ID(N'dbo.CK_Registration_Status', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Registration', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Registration] WITH NOCHECK
      ADD CONSTRAINT [CK_Registration_Status] CHECK ([Status]=N'transferred' OR [Status]=N'withdrawn' OR [Status]=N'completed' OR [Status]=N'frozen' OR [Status]=N'active' OR [Status]=N'pending_approval' OR [Status]=N'pending_payment');
    ALTER TABLE dbo.[Registration] CHECK CONSTRAINT [CK_Registration_Status];
END
GO

IF OBJECT_ID(N'dbo.CK_Score_ExamType', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Score', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Score] WITH NOCHECK
      ADD CONSTRAINT [CK_Score_ExamType] CHECK ([ExamType]=N'assignment' OR [ExamType]=N'quiz' OR [ExamType]=N'final' OR [ExamType]=N'midterm' OR [ExamType]=N'placement');
    ALTER TABLE dbo.[Score] CHECK CONSTRAINT [CK_Score_ExamType];
END
GO

IF OBJECT_ID(N'dbo.CK_Score_Range', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Score', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Score] WITH NOCHECK
      ADD CONSTRAINT [CK_Score_Range] CHECK ([ScoreValue]>=(0) AND [ScoreValue]<=[MaxScore]);
    ALTER TABLE dbo.[Score] CHECK CONSTRAINT [CK_Score_Range];
END
GO

IF OBJECT_ID(N'dbo.CK_Session_Status', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Session', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Session] WITH NOCHECK
      ADD CONSTRAINT [CK_Session_Status] CHECK ([Status]=N'rescheduled' OR [Status]=N'cancelled' OR [Status]=N'completed' OR [Status]=N'in_progress' OR [Status]=N'scheduled');
    ALTER TABLE dbo.[Session] CHECK CONSTRAINT [CK_Session_Status];
END
GO

IF OBJECT_ID(N'dbo.CK_SessionStudent_AttendanceStatus', N'C') IS NULL
   AND OBJECT_ID(N'dbo.SessionStudent', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[SessionStudent] WITH NOCHECK
      ADD CONSTRAINT [CK_SessionStudent_AttendanceStatus] CHECK ([AttendanceStatus]=N'leave' OR [AttendanceStatus]=N'late' OR [AttendanceStatus]=N'absent' OR [AttendanceStatus]=N'present');
    ALTER TABLE dbo.[SessionStudent] CHECK CONSTRAINT [CK_SessionStudent_AttendanceStatus];
END
GO

IF OBJECT_ID(N'dbo.CK_ShopCart_Owner', N'C') IS NULL
   AND OBJECT_ID(N'dbo.ShopCartItem', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopCartItem] WITH NOCHECK
      ADD CONSTRAINT [CK_ShopCart_Owner] CHECK ([UserRef] IS NOT NULL OR [SessionKey] IS NOT NULL);
    ALTER TABLE dbo.[ShopCartItem] CHECK CONSTRAINT [CK_ShopCart_Owner];
END
GO

IF OBJECT_ID(N'dbo.CK_ShopCart_Qty', N'C') IS NULL
   AND OBJECT_ID(N'dbo.ShopCartItem', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopCartItem] WITH NOCHECK
      ADD CONSTRAINT [CK_ShopCart_Qty] CHECK ([Qty]>=(0));
    ALTER TABLE dbo.[ShopCartItem] CHECK CONSTRAINT [CK_ShopCart_Qty];
END
GO

IF OBJECT_ID(N'dbo.CK_ShopOrder_Status', N'C') IS NULL
   AND OBJECT_ID(N'dbo.ShopOrder', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopOrder] WITH NOCHECK
      ADD CONSTRAINT [CK_ShopOrder_Status] CHECK ([Status]=N'delivered' OR [Status]=N'shipped' OR [Status]=N'cancelled' OR [Status]=N'paid' OR [Status]=N'pending');
    ALTER TABLE dbo.[ShopOrder] CHECK CONSTRAINT [CK_ShopOrder_Status];
END
GO

IF OBJECT_ID(N'dbo.CK_ShopOrderItem_Qty', N'C') IS NULL
   AND OBJECT_ID(N'dbo.ShopOrderItem', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopOrderItem] WITH NOCHECK
      ADD CONSTRAINT [CK_ShopOrderItem_Qty] CHECK ([Qty]>(0));
    ALTER TABLE dbo.[ShopOrderItem] CHECK CONSTRAINT [CK_ShopOrderItem_Qty];
END
GO

IF OBJECT_ID(N'dbo.CK_ShopProduct_Price', N'C') IS NULL
   AND OBJECT_ID(N'dbo.ShopProduct', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProduct] WITH NOCHECK
      ADD CONSTRAINT [CK_ShopProduct_Price] CHECK ([Price]>=(0));
    ALTER TABLE dbo.[ShopProduct] CHECK CONSTRAINT [CK_ShopProduct_Price];
END
GO

IF OBJECT_ID(N'dbo.CK_ShopProduct_Stock', N'C') IS NULL
   AND OBJECT_ID(N'dbo.ShopProduct', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProduct] WITH NOCHECK
      ADD CONSTRAINT [CK_ShopProduct_Stock] CHECK ([Stock]>=(0));
    ALTER TABLE dbo.[ShopProduct] CHECK CONSTRAINT [CK_ShopProduct_Stock];
END
GO

IF OBJECT_ID(N'dbo.CK_ShopProduct_Type', N'C') IS NULL
   AND OBJECT_ID(N'dbo.ShopProduct', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProduct] WITH NOCHECK
      ADD CONSTRAINT [CK_ShopProduct_Type] CHECK ([ProductType]=N'other' OR [ProductType]=N'course_pack' OR [ProductType]=N'stationery' OR [ProductType]=N'file' OR [ProductType]=N'book');
    ALTER TABLE dbo.[ShopProduct] CHECK CONSTRAINT [CK_ShopProduct_Type];
END
GO

IF OBJECT_ID(N'dbo.جنسیت دانشجو نامعتبر است', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Student', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Student] WITH NOCHECK
      ADD CONSTRAINT [جنسیت دانشجو نامعتبر است] CHECK ([Gender]=(2) OR [Gender]=(1));
    ALTER TABLE dbo.[Student] CHECK CONSTRAINT [جنسیت دانشجو نامعتبر است];
END
GO

IF OBJECT_ID(N'dbo.کد ملی دانشجو نامعتبر است', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Student', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Student] WITH NOCHECK
      ADD CONSTRAINT [کد ملی دانشجو نامعتبر است] CHECK ([dbo].[CheckNationalCode]([NationalCode])=(1));
    ALTER TABLE dbo.[Student] CHECK CONSTRAINT [کد ملی دانشجو نامعتبر است];
END
GO

IF OBJECT_ID(N'dbo.جنسیت مدرس نامعتبر است', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Teacher', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Teacher] WITH NOCHECK
      ADD CONSTRAINT [جنسیت مدرس نامعتبر است] CHECK ([Gender]=(2) OR [Gender]=(1));
    ALTER TABLE dbo.[Teacher] CHECK CONSTRAINT [جنسیت مدرس نامعتبر است];
END
GO

IF OBJECT_ID(N'dbo.کد ملی مدرس نامعتبر است', N'C') IS NULL
   AND OBJECT_ID(N'dbo.Teacher', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Teacher] WITH NOCHECK
      ADD CONSTRAINT [کد ملی مدرس نامعتبر است] CHECK ([dbo].[CheckNationalCode]([NationalCode])=(1));
    ALTER TABLE dbo.[Teacher] CHECK CONSTRAINT [کد ملی مدرس نامعتبر است];
END
GO

/* ===================== INDEXES ===================== */
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_ActivityLog_Created' AND object_id = OBJECT_ID(N'dbo.ActivityLog')
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ActivityLog_Created]
      ON dbo.[ActivityLog] ([CreatedAt] DESC);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_SessionStudent_Unique' AND object_id = OBJECT_ID(N'dbo.SessionStudent')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [IX_SessionStudent_Unique]
      ON dbo.[SessionStudent] ([SessionRef] ASC, [StudentRef] ASC);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_UserSession_TokenHash' AND object_id = OBJECT_ID(N'dbo.UserSession')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX [IX_UserSession_TokenHash]
      ON dbo.[UserSession] ([TokenHash] ASC);
END
GO

/* ===================== FOREIGN KEYS ===================== */
GO

IF OBJECT_ID(N'dbo.FK_AppUser_Role', N'F') IS NULL
   AND OBJECT_ID(N'dbo.AppUser', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Role', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[AppUser] WITH NOCHECK
      ADD CONSTRAINT [FK_AppUser_Role]
      FOREIGN KEY ([RoleRef])
      REFERENCES dbo.[Role] ([Id]);
    ALTER TABLE dbo.[AppUser] CHECK CONSTRAINT [FK_AppUser_Role];
END
GO

IF OBJECT_ID(N'dbo.FK_AppUser_Student', N'F') IS NULL
   AND OBJECT_ID(N'dbo.AppUser', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Student', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[AppUser] WITH NOCHECK
      ADD CONSTRAINT [FK_AppUser_Student]
      FOREIGN KEY ([StudentRef])
      REFERENCES dbo.[Student] ([Id]);
    ALTER TABLE dbo.[AppUser] CHECK CONSTRAINT [FK_AppUser_Student];
END
GO

IF OBJECT_ID(N'dbo.FK_AppUser_Teacher', N'F') IS NULL
   AND OBJECT_ID(N'dbo.AppUser', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Teacher', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[AppUser] WITH NOCHECK
      ADD CONSTRAINT [FK_AppUser_Teacher]
      FOREIGN KEY ([TeacherRef])
      REFERENCES dbo.[Teacher] ([Id]);
    ALTER TABLE dbo.[AppUser] CHECK CONSTRAINT [FK_AppUser_Teacher];
END
GO

IF OBJECT_ID(N'dbo.FK_Class_Branch', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Class', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Branch', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Class] WITH NOCHECK
      ADD CONSTRAINT [FK_Class_Branch]
      FOREIGN KEY ([BranchRef])
      REFERENCES dbo.[Branch] ([Id]);
    ALTER TABLE dbo.[Class] CHECK CONSTRAINT [FK_Class_Branch];
END
GO

IF OBJECT_ID(N'dbo.FK_Class_Course', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Class', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Course', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Class] WITH NOCHECK
      ADD CONSTRAINT [FK_Class_Course]
      FOREIGN KEY ([CourseRef])
      REFERENCES dbo.[Course] ([Id]);
    ALTER TABLE dbo.[Class] CHECK CONSTRAINT [FK_Class_Course];
END
GO

IF OBJECT_ID(N'dbo.FK_Class_SessionType', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Class', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.SessionType', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Class] WITH NOCHECK
      ADD CONSTRAINT [FK_Class_SessionType]
      FOREIGN KEY ([SessionTypeRef])
      REFERENCES dbo.[SessionType] ([Id]);
    ALTER TABLE dbo.[Class] CHECK CONSTRAINT [FK_Class_SessionType];
END
GO

IF OBJECT_ID(N'dbo.FK_Class_Teacher', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Class', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Teacher', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Class] WITH NOCHECK
      ADD CONSTRAINT [FK_Class_Teacher]
      FOREIGN KEY ([TeacherRef])
      REFERENCES dbo.[Teacher] ([Id]);
    ALTER TABLE dbo.[Class] CHECK CONSTRAINT [FK_Class_Teacher];
END
GO

IF OBJECT_ID(N'dbo.FK_Course_Language', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Course', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Language', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Course] WITH NOCHECK
      ADD CONSTRAINT [FK_Course_Language]
      FOREIGN KEY ([LanguageRef])
      REFERENCES dbo.[Language] ([Id]);
    ALTER TABLE dbo.[Course] CHECK CONSTRAINT [FK_Course_Language];
END
GO

IF OBJECT_ID(N'dbo.FK_Course_Level', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Course', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Level', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Course] WITH NOCHECK
      ADD CONSTRAINT [FK_Course_Level]
      FOREIGN KEY ([LevelRef])
      REFERENCES dbo.[Level] ([Id]);
    ALTER TABLE dbo.[Course] CHECK CONSTRAINT [FK_Course_Level];
END
GO

IF OBJECT_ID(N'dbo.FK_Course_Prerequisite', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Course', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Course', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Course] WITH NOCHECK
      ADD CONSTRAINT [FK_Course_Prerequisite]
      FOREIGN KEY ([PrerequisiteCourseRef])
      REFERENCES dbo.[Course] ([Id]);
    ALTER TABLE dbo.[Course] CHECK CONSTRAINT [FK_Course_Prerequisite];
END
GO

IF OBJECT_ID(N'dbo.FK_CourseHistory_Course', N'F') IS NULL
   AND OBJECT_ID(N'dbo.CourseHistory', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Course', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[CourseHistory] WITH NOCHECK
      ADD CONSTRAINT [FK_CourseHistory_Course]
      FOREIGN KEY ([CourseRef])
      REFERENCES dbo.[Course] ([Id]);
    ALTER TABLE dbo.[CourseHistory] CHECK CONSTRAINT [FK_CourseHistory_Course];
END
GO

IF OBJECT_ID(N'dbo.FK_Level_Language', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Level', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Language', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Level] WITH NOCHECK
      ADD CONSTRAINT [FK_Level_Language]
      FOREIGN KEY ([LanguageRef])
      REFERENCES dbo.[Language] ([Id]);
    ALTER TABLE dbo.[Level] CHECK CONSTRAINT [FK_Level_Language];
END
GO

IF OBJECT_ID(N'dbo.FK_Payment_Registration', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Payment', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Registration', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Payment] WITH NOCHECK
      ADD CONSTRAINT [FK_Payment_Registration]
      FOREIGN KEY ([RegistrationRef])
      REFERENCES dbo.[Registration] ([Id]);
    ALTER TABLE dbo.[Payment] CHECK CONSTRAINT [FK_Payment_Registration];
END
GO

IF OBJECT_ID(N'dbo.FK_Payment_Student', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Payment', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Student', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Payment] WITH NOCHECK
      ADD CONSTRAINT [FK_Payment_Student]
      FOREIGN KEY ([StudentRef])
      REFERENCES dbo.[Student] ([Id]);
    ALTER TABLE dbo.[Payment] CHECK CONSTRAINT [FK_Payment_Student];
END
GO

IF OBJECT_ID(N'dbo.FK_PA_Level', N'F') IS NULL
   AND OBJECT_ID(N'dbo.PlacementAttempt', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Level', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementAttempt] WITH NOCHECK
      ADD CONSTRAINT [FK_PA_Level]
      FOREIGN KEY ([SuggestedLevelRef])
      REFERENCES dbo.[Level] ([Id]);
    ALTER TABLE dbo.[PlacementAttempt] CHECK CONSTRAINT [FK_PA_Level];
END
GO

IF OBJECT_ID(N'dbo.FK_PA_Student', N'F') IS NULL
   AND OBJECT_ID(N'dbo.PlacementAttempt', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Student', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementAttempt] WITH NOCHECK
      ADD CONSTRAINT [FK_PA_Student]
      FOREIGN KEY ([StudentRef])
      REFERENCES dbo.[Student] ([Id]);
    ALTER TABLE dbo.[PlacementAttempt] CHECK CONSTRAINT [FK_PA_Student];
END
GO

IF OBJECT_ID(N'dbo.FK_PA_TestType', N'F') IS NULL
   AND OBJECT_ID(N'dbo.PlacementAttempt', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.PlacementTestType', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementAttempt] WITH NOCHECK
      ADD CONSTRAINT [FK_PA_TestType]
      FOREIGN KEY ([TestTypeRef])
      REFERENCES dbo.[PlacementTestType] ([Id]);
    ALTER TABLE dbo.[PlacementAttempt] CHECK CONSTRAINT [FK_PA_TestType];
END
GO

IF OBJECT_ID(N'dbo.FK_PAA_Attempt', N'F') IS NULL
   AND OBJECT_ID(N'dbo.PlacementAttemptAnswer', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.PlacementAttempt', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementAttemptAnswer] WITH NOCHECK
      ADD CONSTRAINT [FK_PAA_Attempt]
      FOREIGN KEY ([AttemptRef])
      REFERENCES dbo.[PlacementAttempt] ([Id]);
    ALTER TABLE dbo.[PlacementAttemptAnswer] CHECK CONSTRAINT [FK_PAA_Attempt];
END
GO

IF OBJECT_ID(N'dbo.FK_PAA_Question', N'F') IS NULL
   AND OBJECT_ID(N'dbo.PlacementAttemptAnswer', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.PlacementQuestion', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementAttemptAnswer] WITH NOCHECK
      ADD CONSTRAINT [FK_PAA_Question]
      FOREIGN KEY ([QuestionRef])
      REFERENCES dbo.[PlacementQuestion] ([Id]);
    ALTER TABLE dbo.[PlacementAttemptAnswer] CHECK CONSTRAINT [FK_PAA_Question];
END
GO

IF OBJECT_ID(N'dbo.FK_PLR_Level', N'F') IS NULL
   AND OBJECT_ID(N'dbo.PlacementLevelRule', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Level', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementLevelRule] WITH NOCHECK
      ADD CONSTRAINT [FK_PLR_Level]
      FOREIGN KEY ([LevelRef])
      REFERENCES dbo.[Level] ([Id]);
    ALTER TABLE dbo.[PlacementLevelRule] CHECK CONSTRAINT [FK_PLR_Level];
END
GO

IF OBJECT_ID(N'dbo.FK_PLR_TestType', N'F') IS NULL
   AND OBJECT_ID(N'dbo.PlacementLevelRule', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.PlacementTestType', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementLevelRule] WITH NOCHECK
      ADD CONSTRAINT [FK_PLR_TestType]
      FOREIGN KEY ([TestTypeRef])
      REFERENCES dbo.[PlacementTestType] ([Id]);
    ALTER TABLE dbo.[PlacementLevelRule] CHECK CONSTRAINT [FK_PLR_TestType];
END
GO

IF OBJECT_ID(N'dbo.FK_PQ_TestType', N'F') IS NULL
   AND OBJECT_ID(N'dbo.PlacementQuestion', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.PlacementTestType', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementQuestion] WITH NOCHECK
      ADD CONSTRAINT [FK_PQ_TestType]
      FOREIGN KEY ([TestTypeRef])
      REFERENCES dbo.[PlacementTestType] ([Id]);
    ALTER TABLE dbo.[PlacementQuestion] CHECK CONSTRAINT [FK_PQ_TestType];
END
GO

IF OBJECT_ID(N'dbo.FK_PTT_Language', N'F') IS NULL
   AND OBJECT_ID(N'dbo.PlacementTestType', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Language', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[PlacementTestType] WITH NOCHECK
      ADD CONSTRAINT [FK_PTT_Language]
      FOREIGN KEY ([LanguageRef])
      REFERENCES dbo.[Language] ([Id]);
    ALTER TABLE dbo.[PlacementTestType] CHECK CONSTRAINT [FK_PTT_Language];
END
GO

IF OBJECT_ID(N'dbo.FK_Registration_Class', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Registration', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Class', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Registration] WITH NOCHECK
      ADD CONSTRAINT [FK_Registration_Class]
      FOREIGN KEY ([ClassRef])
      REFERENCES dbo.[Class] ([Id]);
    ALTER TABLE dbo.[Registration] CHECK CONSTRAINT [FK_Registration_Class];
END
GO

IF OBJECT_ID(N'dbo.FK_Registration_Course', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Registration', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Course', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Registration] WITH NOCHECK
      ADD CONSTRAINT [FK_Registration_Course]
      FOREIGN KEY ([CourseRef])
      REFERENCES dbo.[Course] ([Id]);
    ALTER TABLE dbo.[Registration] CHECK CONSTRAINT [FK_Registration_Course];
END
GO

IF OBJECT_ID(N'dbo.FK_Registration_Student', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Registration', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Student', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Registration] WITH NOCHECK
      ADD CONSTRAINT [FK_Registration_Student]
      FOREIGN KEY ([Studentref])
      REFERENCES dbo.[Student] ([Id]);
    ALTER TABLE dbo.[Registration] CHECK CONSTRAINT [FK_Registration_Student];
END
GO

IF OBJECT_ID(N'dbo.FK_Score_Registration', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Score', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Registration', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Score] WITH NOCHECK
      ADD CONSTRAINT [FK_Score_Registration]
      FOREIGN KEY ([RegistrationRef])
      REFERENCES dbo.[Registration] ([Id]);
    ALTER TABLE dbo.[Score] CHECK CONSTRAINT [FK_Score_Registration];
END
GO

IF OBJECT_ID(N'dbo.FK_Score_Student', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Score', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Student', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Score] WITH NOCHECK
      ADD CONSTRAINT [FK_Score_Student]
      FOREIGN KEY ([StudentRef])
      REFERENCES dbo.[Student] ([Id]);
    ALTER TABLE dbo.[Score] CHECK CONSTRAINT [FK_Score_Student];
END
GO

IF OBJECT_ID(N'dbo.FK_Score_SuggestedLevel', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Score', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Level', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Score] WITH NOCHECK
      ADD CONSTRAINT [FK_Score_SuggestedLevel]
      FOREIGN KEY ([SuggestedLevelRef])
      REFERENCES dbo.[Level] ([Id]);
    ALTER TABLE dbo.[Score] CHECK CONSTRAINT [FK_Score_SuggestedLevel];
END
GO

IF OBJECT_ID(N'dbo.FK_Session_Class', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Session', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Class', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Session] WITH NOCHECK
      ADD CONSTRAINT [FK_Session_Class]
      FOREIGN KEY ([ClassRef])
      REFERENCES dbo.[Class] ([Id]);
    ALTER TABLE dbo.[Session] CHECK CONSTRAINT [FK_Session_Class];
END
GO

IF OBJECT_ID(N'dbo.FK_Session_SessionType', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Session', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.SessionType', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Session] WITH NOCHECK
      ADD CONSTRAINT [FK_Session_SessionType]
      FOREIGN KEY ([SessionTypeRef])
      REFERENCES dbo.[SessionType] ([Id]);
    ALTER TABLE dbo.[Session] CHECK CONSTRAINT [FK_Session_SessionType];
END
GO

IF OBJECT_ID(N'dbo.FK_Session_SubstituteTeacher', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Session', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Teacher', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Session] WITH NOCHECK
      ADD CONSTRAINT [FK_Session_SubstituteTeacher]
      FOREIGN KEY ([SubstituteTeacherRef])
      REFERENCES dbo.[Teacher] ([Id]);
    ALTER TABLE dbo.[Session] CHECK CONSTRAINT [FK_Session_SubstituteTeacher];
END
GO

IF OBJECT_ID(N'dbo.FK_SessionStudent_Session', N'F') IS NULL
   AND OBJECT_ID(N'dbo.SessionStudent', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Session', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[SessionStudent] WITH NOCHECK
      ADD CONSTRAINT [FK_SessionStudent_Session]
      FOREIGN KEY ([SessionRef])
      REFERENCES dbo.[Session] ([Id]);
    ALTER TABLE dbo.[SessionStudent] CHECK CONSTRAINT [FK_SessionStudent_Session];
END
GO

IF OBJECT_ID(N'dbo.FK_SessionStudent_Student', N'F') IS NULL
   AND OBJECT_ID(N'dbo.SessionStudent', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Student', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[SessionStudent] WITH NOCHECK
      ADD CONSTRAINT [FK_SessionStudent_Student]
      FOREIGN KEY ([StudentRef])
      REFERENCES dbo.[Student] ([Id]);
    ALTER TABLE dbo.[SessionStudent] CHECK CONSTRAINT [FK_SessionStudent_Student];
END
GO

IF OBJECT_ID(N'dbo.FK_ShopCart_Product', N'F') IS NULL
   AND OBJECT_ID(N'dbo.ShopCartItem', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.ShopProduct', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopCartItem] WITH NOCHECK
      ADD CONSTRAINT [FK_ShopCart_Product]
      FOREIGN KEY ([ProductRef])
      REFERENCES dbo.[ShopProduct] ([Id]);
    ALTER TABLE dbo.[ShopCartItem] CHECK CONSTRAINT [FK_ShopCart_Product];
END
GO

IF OBJECT_ID(N'dbo.FK_ShopCart_User', N'F') IS NULL
   AND OBJECT_ID(N'dbo.ShopCartItem', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.AppUser', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopCartItem] WITH NOCHECK
      ADD CONSTRAINT [FK_ShopCart_User]
      FOREIGN KEY ([UserRef])
      REFERENCES dbo.[AppUser] ([Id]);
    ALTER TABLE dbo.[ShopCartItem] CHECK CONSTRAINT [FK_ShopCart_User];
END
GO

IF OBJECT_ID(N'dbo.FK_ShopOrder_User', N'F') IS NULL
   AND OBJECT_ID(N'dbo.ShopOrder', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.AppUser', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopOrder] WITH NOCHECK
      ADD CONSTRAINT [FK_ShopOrder_User]
      FOREIGN KEY ([UserRef])
      REFERENCES dbo.[AppUser] ([Id]);
    ALTER TABLE dbo.[ShopOrder] CHECK CONSTRAINT [FK_ShopOrder_User];
END
GO

IF OBJECT_ID(N'dbo.FK_ShopOrderItem_Order', N'F') IS NULL
   AND OBJECT_ID(N'dbo.ShopOrderItem', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.ShopOrder', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopOrderItem] WITH NOCHECK
      ADD CONSTRAINT [FK_ShopOrderItem_Order]
      FOREIGN KEY ([OrderRef])
      REFERENCES dbo.[ShopOrder] ([Id]);
    ALTER TABLE dbo.[ShopOrderItem] CHECK CONSTRAINT [FK_ShopOrderItem_Order];
END
GO

IF OBJECT_ID(N'dbo.FK_ShopOrderItem_Product', N'F') IS NULL
   AND OBJECT_ID(N'dbo.ShopOrderItem', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.ShopProduct', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopOrderItem] WITH NOCHECK
      ADD CONSTRAINT [FK_ShopOrderItem_Product]
      FOREIGN KEY ([ProductRef])
      REFERENCES dbo.[ShopProduct] ([Id]);
    ALTER TABLE dbo.[ShopOrderItem] CHECK CONSTRAINT [FK_ShopOrderItem_Product];
END
GO

IF OBJECT_ID(N'dbo.FK_ShopProduct_Category', N'F') IS NULL
   AND OBJECT_ID(N'dbo.ShopProduct', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.ShopCategory', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProduct] WITH NOCHECK
      ADD CONSTRAINT [FK_ShopProduct_Category]
      FOREIGN KEY ([CategoryRef])
      REFERENCES dbo.[ShopCategory] ([Id]);
    ALTER TABLE dbo.[ShopProduct] CHECK CONSTRAINT [FK_ShopProduct_Category];
END
GO

IF OBJECT_ID(N'dbo.FK_ShopBookmark_Product', N'F') IS NULL
   AND OBJECT_ID(N'dbo.ShopProductBookmark', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.ShopProduct', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProductBookmark] WITH NOCHECK
      ADD CONSTRAINT [FK_ShopBookmark_Product]
      FOREIGN KEY ([ProductRef])
      REFERENCES dbo.[ShopProduct] ([Id]);
    ALTER TABLE dbo.[ShopProductBookmark] CHECK CONSTRAINT [FK_ShopBookmark_Product];
END
GO

IF OBJECT_ID(N'dbo.FK_ShopBookmark_User', N'F') IS NULL
   AND OBJECT_ID(N'dbo.ShopProductBookmark', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.AppUser', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProductBookmark] WITH NOCHECK
      ADD CONSTRAINT [FK_ShopBookmark_User]
      FOREIGN KEY ([UserRef])
      REFERENCES dbo.[AppUser] ([Id]);
    ALTER TABLE dbo.[ShopProductBookmark] CHECK CONSTRAINT [FK_ShopBookmark_User];
END
GO

IF OBJECT_ID(N'dbo.FK_ShopLike_Product', N'F') IS NULL
   AND OBJECT_ID(N'dbo.ShopProductLike', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.ShopProduct', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProductLike] WITH NOCHECK
      ADD CONSTRAINT [FK_ShopLike_Product]
      FOREIGN KEY ([ProductRef])
      REFERENCES dbo.[ShopProduct] ([Id]);
    ALTER TABLE dbo.[ShopProductLike] CHECK CONSTRAINT [FK_ShopLike_Product];
END
GO

IF OBJECT_ID(N'dbo.FK_ShopLike_User', N'F') IS NULL
   AND OBJECT_ID(N'dbo.ShopProductLike', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.AppUser', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[ShopProductLike] WITH NOCHECK
      ADD CONSTRAINT [FK_ShopLike_User]
      FOREIGN KEY ([UserRef])
      REFERENCES dbo.[AppUser] ([Id]);
    ALTER TABLE dbo.[ShopProductLike] CHECK CONSTRAINT [FK_ShopLike_User];
END
GO

IF OBJECT_ID(N'dbo.FK_Student_CurrentLevel', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Student', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Level', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Student] WITH NOCHECK
      ADD CONSTRAINT [FK_Student_CurrentLevel]
      FOREIGN KEY ([CurrentLevelRef])
      REFERENCES dbo.[Level] ([Id]);
    ALTER TABLE dbo.[Student] CHECK CONSTRAINT [FK_Student_CurrentLevel];
END
GO

IF OBJECT_ID(N'dbo.FK_Student_TargetLanguage', N'F') IS NULL
   AND OBJECT_ID(N'dbo.Student', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.Language', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[Student] WITH NOCHECK
      ADD CONSTRAINT [FK_Student_TargetLanguage]
      FOREIGN KEY ([TargetLanguageRef])
      REFERENCES dbo.[Language] ([Id]);
    ALTER TABLE dbo.[Student] CHECK CONSTRAINT [FK_Student_TargetLanguage];
END
GO

IF OBJECT_ID(N'dbo.FK_UserSession_User', N'F') IS NULL
   AND OBJECT_ID(N'dbo.UserSession', N'U') IS NOT NULL
   AND OBJECT_ID(N'dbo.AppUser', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.[UserSession] WITH NOCHECK
      ADD CONSTRAINT [FK_UserSession_User]
      FOREIGN KEY ([UserRef])
      REFERENCES dbo.[AppUser] ([Id]);
    ALTER TABLE dbo.[UserSession] CHECK CONSTRAINT [FK_UserSession_User];
END
GO

/* ===================== DATA ===================== */
GO


-- Temporarily disable FK checks for data load
DECLARE @sql nvarchar(max) = N'';
SELECT @sql = @sql + N'ALTER TABLE dbo.' + QUOTENAME(OBJECT_NAME(parent_object_id))
             + N' NOCHECK CONSTRAINT ' + QUOTENAME(name) + N';' + CHAR(10)
FROM sys.foreign_keys;
EXEC sp_executesql @sql;
GO

-- ===== DATA: Role (7 rows) =====
SET IDENTITY_INSERT dbo.[Role] ON;
GO
INSERT INTO dbo.[Role] ([Id], [Code], [Name], [IsActive])
VALUES
(1, N'admin', N'مدیر سیستم', 1),
(2, N'finance', N'کارشناس مالی', 1),
(3, N'secretary', N'منشی', 1),
(4, N'teacher', N'مدرس', 1),
(5, N'student', N'زبان‌آموز', 1),
(6, N'parent', N'والدین', 1),
(7, N'education', N'مسئول آموزش', 1);
GO
SET IDENTITY_INSERT dbo.[Role] OFF;
GO

-- ===== DATA: Language (13 rows) =====
SET IDENTITY_INSERT dbo.[Language] ON;
GO
INSERT INTO dbo.[Language] ([Id], [Name])
VALUES
(4, N'آلمانی'),
(7, N'اسپانیایی'),
(1, N'انگلیسی'),
(3, N'ایتالیایی'),
(9, N'ترکی آذربایجانی'),
(8, N'چینی'),
(5, N'روسی'),
(6, N'ژاپنی'),
(10, N'عربی'),
(11, N'فارسی'),
(2, N'فرانسوی'),
(13, N'هلندی'),
(12, N'هندی');
GO
SET IDENTITY_INSERT dbo.[Language] OFF;
GO

-- ===== DATA: Branch (12 rows) =====
SET IDENTITY_INSERT dbo.[Branch] ON;
GO
INSERT INTO dbo.[Branch] ([Id], [Name], [Address], [Phone], [IsActive], [CreatedAt])
VALUES
(1, N'شعبه مرکزی', N'تهران', N'02100000000', 1, '2026-07-29 14:01:12.597'),
(3, N'دفتر مرکزی', N'تهران،خیابان جم', N'021-91070008', 1, '2026-07-29 14:14:00.261'),
(4, N'شعبه 2', N'تبریز', N'430245613', 1, '2026-07-29 14:14:01.275'),
(5, N'شعبه3', N'زنجان', N'430245613', 1, '2026-07-29 14:14:41.615'),
(7, N'شعبه شریعی', N'خیابان شریعی, کوی مهران', N'4134442828', 1, '2025-05-05 00:00:00.000'),
(10, N'شعبه4', N'اهواز', N'4308645297', 1, '2026-07-29 14:33:30.722'),
(11, N'شعبه5', N'مشهد', N'09967656554', 1, '2026-07-29 14:36:37.309'),
(13, N'شعبه7', N'مشهد', N'09967656554', 1, '2026-07-29 14:37:18.166'),
(16, N'شعب85', N'تهران', N'5984265', 1, '2026-07-29 14:38:58.666'),
(17, N'شعب8', N'تهران', N'5984265', 1, '2026-07-29 14:40:59.595'),
(18, N'شعبه دوم مرکزی', N'شیراز', N'04132589', 1, '2026-07-29 16:11:02.949'),
(19, N'شعبه آبرسان', N'آبرسان-ساختمان برج سفید', N'04136656968', 1, '2026-07-29 16:17:34.761');
GO
SET IDENTITY_INSERT dbo.[Branch] OFF;
GO

-- ===== DATA: SessionType (5 rows) =====
SET IDENTITY_INSERT dbo.[SessionType] ON;
GO
INSERT INTO dbo.[SessionType] ([Id], [Name])
VALUES
(1, N'حضوری'),
(2, N'آنلاین'),
(3, N'نیمه حضوری'),
(4, N'آفلاین'),
(5, N'حضوری 3');
GO
SET IDENTITY_INSERT dbo.[SessionType] OFF;
GO

-- ===== DATA: Level (30 rows) =====
SET IDENTITY_INSERT dbo.[Level] ON;
GO
INSERT INTO dbo.[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive])
VALUES
(1, 4, N'A1', N'مبتدی ۱', 1, 1),
(2, 4, N'A2', N'مبتدی ۲', 2, 1),
(3, 4, N'B1', N'متوسط ۱', 3, 1),
(4, 4, N'B2', N'متوسط ۲', 4, 1),
(5, 4, N'C1', N'پیشرفته ۱', 5, 1),
(6, 4, N'C2', N'پیشرفته ۲', 6, 1),
(7, 1, N'A1', N'مبتدی ۱', 1, 1),
(8, 1, N'A2', N'مبتدی ۲', 2, 1),
(9, 1, N'B1', N'متوسط ۱', 3, 1),
(10, 1, N'B2', N'متوسط ۲', 4, 1),
(11, 1, N'C1', N'پیشرفته ۱', 5, 1),
(12, 1, N'C2', N'پیشرفته ۲', 6, 1),
(13, 3, N'A1', N'مبتدی ۱', 1, 1),
(14, 3, N'A2', N'مبتدی ۲', 2, 1),
(15, 3, N'B1', N'متوسط ۱', 3, 1),
(16, 3, N'B2', N'متوسط ۲', 4, 1),
(17, 3, N'C1', N'پیشرفته ۱', 5, 1),
(18, 3, N'C2', N'پیشرفته ۲', 6, 1),
(19, 2, N'A1', N'مبتدی ۱', 1, 1),
(20, 2, N'A2', N'مبتدی ۲', 2, 1),
(21, 2, N'B1', N'متوسط ۱', 3, 1),
(22, 2, N'B2', N'متوسط ۲', 4, 1),
(23, 2, N'C1', N'پیشرفته ۱', 5, 1),
(24, 2, N'C2', N'پیشرفته ۲', 6, 1),
(26, 1, N'C3', N'متوسط 2', 4, 1),
(27, 7, N'c10', N'پیشرفته', 3, 0),
(28, 4, N'َشئبنثیئ', N'سثقفا', 1, 0),
(30, 7, N'صقفاتصقفاصشقفاصشفقتا', N'ف4تاثقفافاقاقفاقفا', 112312323, 0),
(31, 7, N'c2', N'پیشرفته', 1, 1),
(32, 7, N'jkhuop[45', N'uo', 1, 0);
GO
SET IDENTITY_INSERT dbo.[Level] OFF;
GO

-- ===== DATA: Teacher (21 rows) =====
SET IDENTITY_INSERT dbo.[Teacher] ON;
GO
INSERT INTO dbo.[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [PhotoMime])
VALUES
(1, N'سجاد', N'رفاقت', N'اکبر', N'1377392759', 2, N'1359/09/16', N'Sadjad-PC\Sadjad', N'09145041648', NULL, N'متخصص برنامه نویس و...', NULL, 1, '2026-07-29 14:01:12.843', N'image/jpeg'),
(8, N'اسما', N'نوری', N'احد', N'3200110015', 1, N'1358/02/16', N'elyar', NULL, NULL, NULL, NULL, 1, '2026-07-29 14:01:12.843', NULL),
(9, N'زهرا', N'حبیبی', NULL, N'5254754109', 1, N'1379/12/22', N'saba', N'09124578965', NULL, N'زبان انگلیسی', NULL, 1, '2026-07-29 14:01:12.843', NULL),
(13, N'حامد', N'صمدی', N'محمد', N'7696488724', 2, N'1370/11/30', N'vahideh', NULL, NULL, NULL, NULL, 1, '2026-07-29 14:01:12.843', NULL),
(16, N'سارا', N'رحیمی', N'اشکان', N'1364932032', 1, N'1368/06/26', N'asra', N'09584568563', NULL, N'عضلات پشت بازو', NULL, 1, '2026-07-29 14:01:12.843', N'image/webp'),
(18, N'اسما', N'نوری', N'احد', N'6702220847', 1, N'1369/07/15', N'elyar', NULL, NULL, NULL, NULL, 1, '2026-07-29 14:01:12.843', NULL),
(19, N'احمد', N'اصغری', N'علی', N'6100001111', 2, N'1369/08/26', N'elyar', N'09956526556', NULL, N'تخصص دارد در تنبیه بدنی', NULL, 1, '2026-07-29 14:01:12.843', NULL),
(21, N'فاطمه', N'سیفی', N'حمید', N'1083143786', 1, N'1367/10/28', N'vahideh', NULL, NULL, NULL, NULL, 1, '2026-07-29 14:01:12.843', NULL),
(23, N'مینا', N'محبی', N'رسول', N'8920522693', 1, N'1359/10/15', N'vahideh', NULL, NULL, NULL, NULL, 1, '2026-07-29 14:01:12.843', NULL),
(27, N'صابر', N'معصومی', N'صمد', N'4952913961', 2, N'1383/08/18', N'vahideh', NULL, NULL, NULL, NULL, 1, '2026-07-29 14:01:12.843', NULL),
(28, N'محمد', N'قاسمی', N'میثم', N'8506687640', 2, N'1368/03/25', N'saba', NULL, NULL, NULL, NULL, 1, '2026-07-29 14:01:12.843', NULL),
(31, N'سعید', N'علیون', N'رضا', N'1365091600', 2, N'1360/11/15', N'amirreza', NULL, NULL, NULL, NULL, 1, '2026-07-29 14:01:12.843', NULL),
(38, N'اصغر', N'نوریان', N'رضا', N'1111010013', 2, N'1381/10/15', N'elyar', N'09124563201', NULL, N'.', NULL, 1, '2026-07-29 14:01:12.843', N'image/webp'),
(39, N'اسما', N'نوری', N'احد', N'7181590073', 1, N'1382/06/20', N'elyar', NULL, NULL, NULL, NULL, 1, '2026-07-29 14:01:12.843', NULL),
(42, N'هلیا', N'حیدری', N'علی', N'5456769123', 1, N'1381/06/26', N'saba', N'09144021112', NULL, N'مدرس', NULL, 0, '2026-07-29 14:01:12.843', N'image/webp'),
(80, N'الیار', N'نورنواز', N'احمد', N'6065232912', 2, NULL, N'limdbadmin', N'09148064585', NULL, N'آلمانی', NULL, 1, '2026-07-29 15:23:14.868', NULL),
(81, N'سینا', N'مرجانی', NULL, N'7104273255', 2, NULL, N'limdbadmin', N'09145852014', NULL, N'مغز اعصاب', N'یکی از بهترین جراه های دنیا', 1, '2026-07-29 15:31:26.021', NULL),
(82, N'امیر', N'کاظم لو', N'علی', N'3508824799', 2, N'1410/01/02', N'limdbadmin', N'09143512272', NULL, N'انگلیسی', NULL, 1, '2026-07-29 15:35:07.025', NULL),
(83, N'الیار', N'نورنواز', NULL, N'5243680966', 2, NULL, N'limdbadmin', N'09148257645555', NULL, N'انگلیسی', NULL, 0, '2026-07-29 15:39:59.271', NULL),
(88, N'محمد', N'علیزاده', N'حمید', N'6666715837', 2, NULL, N'limdbadmin', N'09587412589', NULL, N'پای چپ', NULL, 1, '2026-08-01 15:04:21.198', NULL),
(89, N'مختار', N'ثقفی', N'ابوبید ثقفی', N'2076455787', 2, N'1404/02/02', N'limdbadmin', N'09962154484', N'mokhtar.com', N'شمشیر زنی', NULL, 0, '2026-08-01 15:45:19.039', N'image/jpeg');
GO
SET IDENTITY_INSERT dbo.[Teacher] OFF;
GO

-- ===== DATA: Student (91 rows) =====
SET IDENTITY_INSERT dbo.[Student] ON;
GO
INSERT INTO dbo.[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt])
VALUES
(1, N'سجاد', N'رفاقت', N'اکبر', N'1377392759', 2, N'1359/09/16', N'09145041648', N'Sadjad-PC\Sadjad', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(2, N'علی', N'احمدی', N'رضا', N'3259124411', 2, N'1390/02/20', N'09123456781', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(3, N'علی', N'فیروزی', N'جعفر', N'1365091600', 2, N'1388/12/30', N'09204917841', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(4, N'آیلار', N'محمدی', N'صمد', N'4444943191', 1, N'1380/1/24 ', N'09145879642', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(6, N'سمانه', N'علیار', N'جواد', N'9246272951', 1, N'1385/12/06', N'09145875798', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(7, N'مریم', N'حسینی', N'رضا', N'5462722109', 1, N'1391/02/20', N'09351246789', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(8, N'یاسین', N'پورنصر', N'بهزاد', N'1898415978', 2, N'1390/10/16', N'09146247798', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(10, N'زهرا', N'محمدی', N'بابک', N'7458834323', 1, N'1395/03/20', N'09901234567', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(11, N'امیرمحمد', N'رضایی', N'احمد', N'4816927999', 1, N'1388/07/29', N'09146201587', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(12, N'اسرا', N'رهبران', N'سعید', N'1364932032', 1, N'1388/01/11', N'09928698775', N'asra', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(13, N'سینا', N'کاظمی', N'کریم', N'3405377821', 2, N'1393/06/20', N'09187654321', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(21, N'سمانه', N'رسولی', N'علی', N'1487479700', 1, N'1358/06/31', N'09928776554', N'asra', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(22, N'احمد', N'نوری', N'اصغر', N'9731378286', 2, N'1390/08/28', N'09145024965', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(23, N'اسما', N'اصغری', N'احد', N'3970357403', 1, N'1385/11/22', N'09148347294', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(24, N'احد', N'باقری', N'علی', N'0704041261', 2, N'1380/05/15', N'09147294885', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(25, N'رها', N'نوریان', N'احمد', N'5141202054', 1, N'1350/11/30', N'09935817556', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(26, N'رضا', N'باقر زاده', N'باقر', N'5577380911', 2, N'1359/02/15', N'03995841557', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(27, N'آرش', N'شریفی', N'محمد علی', N'8749702165', 2, N'1387/11/23', N'09141141382', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(44, N'آرتین', N'وصلی', N'حبیب', N'4342010658', 2, N'1388/07/29', N'09146254587', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(45, N'ایلیا', N'رسولیان', N'علیرضا', N'2678458725', 2, N'1320/07/01', N'09934567676', N'asra', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(46, N'بابک', N'بدری', N'رسول', N'2699165069', 2, N'1392/01/13', N'09146249187', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(50, N'عطا', N'ذوقی', N'عبادالله', N'8711550066', 2, N'1389/03/23', N'09146244127', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(59, N'امیر', N'ذوقی', N'عبادالله', N'5073699440', 2, N'1374/10/07', N'09146243636', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(60, N'احمد', N'نوری', N'اصغر', N'2495334962', 2, N'1390/08/28', N'09145024965', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(61, N'اسما', N'اصغری', N'احد', N'0421584505', 1, N'1385/11/22', N'09148347294', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(62, N'احد', N'باقری', N'علی', N'7129761717', 2, N'1380/05/15', N'09147294885', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(63, N'رها', N'نوریان', N'احمد', N'5289595211', 1, N'1350/11/30', N'09935817556', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(64, N'رضا', N'باقر زاده', N'باقر', N'2111000019', 2, N'1359/02/15', N'03995841557', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(65, N'سعید', N'باقر زاده', N'رضا', N'5265895061', 2, N'1368/05/31', N'09335842515', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(66, N'ماهان', N'رضایی', N'بهرام', N'5465621885', 2, N'1388/10/07', N'09146212636', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(67, N'اشکان', N'رنجبر', N'ارش', N'7887961505', 2, N'1368/05/08', N'09144444994', N'asra', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(70, N'پارسا', N'رنجبری', N'جعفر', N'4760230696', 2, N'1384/04/04', N'09123455454', N'asra', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(72, N'مهیا', N'حسینی', N'سجاد', N'4546324741', 1, N'1389/11/04', N'09144391467', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(73, N'پارسایی', N'رنجبریان', N'جعفری', N'9504625681', 2, N'1311/11/11', N'09145674332', N'asra', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(74, N'اسماء', N'واحد', N'محمد', N'3203156148', 1, N'1394/08/08', N'09146791467', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(76, N'علی', N'داداش زاده', N'قاسم', N'0319929991', 2, N'1377/11/12', N'09146661551', N'arshya', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(79, N'علی', N'فیروزی', N'جعفر', N'0111010004', 2, N'1388/12/30', N'09204917841', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(80, N'جعفر', N'دلریش', N'قاسم', N'0000011101', 2, N'1365/12/30', N'03855454545', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(84, N'نیما', N'خدایی', N'احمد', N'0741753456', 2, N'1380/06/12', N'09923456565', N'asra', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(85, N'یسنا', N'راد', N'علی', N'4001366053', 1, N'1389/07/27', N'09146791467', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869');
GO
INSERT INTO dbo.[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt])
VALUES
(86, N'مسعود', N'میر سیدی', N'عزیز', N'3453998065', 2, N'1387/01/02', N'09046361641', N'arshya', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(87, N'سودا', N'عبادی', N'مرسل', N'0010934391', 1, N'1387/10/18', N'09938767667', N'asra', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(89, N'سونیا', N'عبادیان', N'سجاد', N'8295846094', 1, N'1347/10/28', N'09989878777', N'asra', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(92, N'سالار', N'مدنی', N'اکبر', N'5405674508', 2, N'1381/03/12', N'09308031129', N'arshya', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(95, N'جولیا', N'عبادیان', N'حمید', N'1639751602', 1, N'1367/04/08', N'09928786565', N'asra', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(96, N'مبین', N'بهینه', N'مهدی', N'8131608921', 2, N'1382/06/11', N'09308031129', N'arshya', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(98, N'بهار', N'راهور', N'آرش', N'2859673709', 1, N'1350/03/14', N'9364978521', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(101, N'الهام', N'علی پور', N'مرتضی', N'8931479093', 1, N'1389/10/30', N'09369901213', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(112, N'لیلا', N'قانونی', N'مرتضی', N'2504205899', 1, N'1389/10/10', N'09369903313', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(113, N'عبدل مالک', N'فاقدی', N'کاظم', N'2652926373', 2, N'1369/08/01', N'09145481453', N'arshya', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(115, N'علی', N'فیروزی', N'جعفر', N'9011111109', 2, N'1388/12/30', N'09204917841', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(116, N'جعفر', N'دلریش', N'قاسم', N'2001001010', 2, N'1365/12/30', N'03855454545', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(124, N'نادر', N'محمدی', N'ناصر', N'0011110015', 2, N'1380/7/2  ', N'092887845123', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(128, N'ماهان', N'زارعی', N'مجتبی', N'9459402577', 2, N'1389/09/10', N'09142502253', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(132, N'میلاد', N'بابایی', N'حسین', N'8407229202', 2, N'1386/08/12', N'09143802253', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(133, N'صمیرا', N'صمیرایی', N'مکس', N'4690197717', 1, N'1359/01/01', N'09928798776', N'asra', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(134, N'محنا', N'معارفی', N'امیر', N'9143077862', 1, N'1386/08/12', N'09363802253', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(135, N'دریا', N'دیرباز', N'حسن', N'2053348658', 1, N'1375/12/14', N'9364912321', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(138, N'ثنا', N'کرمانی', N'رضا', N'4296905521', 1, N'1386/08/21', N'09384002253', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(139, N'کامران', N'شاهد', N'حسین', N'1394557442', 2, N'1386/05/01', N'9364912321', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(141, N'نگار', N'یوسفی', N'شایان', N'9510228745', 1, N'1385/08/21', N'09384009998', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(143, N'احمد', N'زارع', N'محمدعلی', N'7318415549', 2, N'1368/06/21', N'9363568321', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(145, N'حمیده', N'زارع', N'محمدعلی', N'2665190710', 1, N'1368/06/21', N'9363567521', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(146, N'هانیه', N'زمانی', N'احسان', N'5203472203', 1, N'1385/06/21', N'09141189298', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(148, N'زهرا', N'امینی', N'علی', N'9680241904', 1, N'1384/05/21', N'09141182768', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(149, N'معصومه', N'علیزاده', N'امیر', N'1981742182', 1, N'1384/08/28', N'9363567521', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(155, N'پریسا', N'باقرپور', N'سعید', N'9407995089', 1, N'1384/05/28', N'09141912768', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(156, N'ناصر', N'ملکی', N'محمد', N'8402251951', 2, N'1393/02/03', N'9363154821', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(161, N'زینب', N'ابراهیم زاده', N'سعید', N'8028551637', 1, N'1375/03/28', N'09141915768', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(162, N'رویا', N'مکسولی', N'جک', N'6807361882', 1, N'1379/11/01', N'09988768776', N'asra', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(163, N'جواد', N'ناصری', N'جلال', N'5826044111', 2, N'1395/11/26', N'9353154821', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(164, N'بایرامعلی', N'سرخی ', N'مرقوب', N'1554357640', 2, N'1376/01/05', N'09142738772', N'arshya', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(165, N'ناردین', N'کریمی', N'مهدی', N'6405922715', 1, N'1378/04/09', N'09121915768', N'saba', NULL, NULL, 7, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(166, N'رها', N'زند', N'سیروس', N'2094321401', 1, N'1390/09/09', N'9903154821', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(173, N'نرگس', N'مرتضوی', N'مهدی', N'8260527103', 1, N'1372/04/09', N'09371916668', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(188, N'پویا', N'مرادی', N'محمدرضا', N'3664257340', 2, N'1382/04/09', N'09379122272', N'saba', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 14:01:12.869'),
(1213, N'سجاد', N'رفاقت', N'اکبر', N'4444444444', 2, N'1359/09/16', N'09145041648', N'limdbadmin', NULL, 1, NULL, N'fa', 1, 1, '2026-07-29 14:57:50.411'),
(1214, N'وحید', N'مجیدی', N'محمد', N'0192585002', 2, N'1370/10/26', N'09199185467', N'limdbadmin', NULL, 1, 9, N'fa', 1, 1, '2026-07-29 14:59:07.491'),
(1226, N'المیرا', N'کرمانی', N'امیر', N'1322454647', 1, N'1378/02/30', N'09141156575', N'limdbadmin', NULL, 3, NULL, N'fa', 1, 1, '2026-07-29 15:01:10.981'),
(1229, N'مریم', N'مرادپور', N'کریم', N'5310146962', 1, N'1405/12/03', N'09369082272', N'limdbadmin', NULL, 4, NULL, N'fa', 1, 1, '2026-07-29 15:38:03.649');
GO
INSERT INTO dbo.[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt])
VALUES
(1234, N'هلما', N'کاظمی', N'علی', N'6970060276', 1, N'1391/02/04', N'09141201212', N'limdbadmin', NULL, 4, 8, N'fa', 1, 1, '2026-07-29 15:58:52.259'),
(1235, N'احمد', N'نوری زادثیان', N'احد', N'3269485212', 1, N'1402/04/06', N'???????????????', N'limdbadmin', NULL, NULL, NULL, N'fa', 1, 1, '2026-07-29 16:00:11.571'),
(1237, N'صمد', N'صمدی', N'صادق', N'0462604047', 2, N'1384/01/18', N'09141234567', N'limdbadmin', NULL, 7, 7, N'fa', 1, 1, '2026-07-29 16:08:33.099'),
(1244, N'الیار', N'حاج باباپور', N'احد', N'1811213634', 1, N'1392/01/06', N'09956854558', N'limdbadmin', NULL, NULL, NULL, N'fa', 1, 1, '2026-08-01 13:59:01.045'),
(1245, N'احد', N'احدی', N'احمد', N'4708378270', 2, N'1393/03/01', N'09158425698', N'limdbadmin', NULL, NULL, 7, N'fa', 1, 1, '2026-08-01 14:13:09.786'),
(1246, N'امیر', N'کاظمی', N'علی', N'2060728789', 2, N'1405/05/10', N'09141141370', N'limdbadmin', NULL, 7, NULL, N'fa', 1, 1, '2026-08-01 14:13:28.359'),
(1247, N'احمد', N'احدی', N'علی', N'6010001110', 2, N'1369/09/08', N'09148254765', N'limdbadmin', NULL, 8, NULL, N'fa', 1, 1, '2026-08-01 14:18:03.338'),
(1248, N'سما', N'عبادی', N'ارسلان', N'5759989030', 1, N'1384/02/06', N'09983212555', N'limdbadmin', NULL, 1, 7, N'fa', 1, 1, '2026-08-01 14:33:08.150'),
(1252, N'علی', N'کریم لو', N'محمد', N'3216162885', 2, N'1405/05/09', N'09369082777', N'limdbadmin', NULL, NULL, NULL, N'fa', 1, 1, '2026-08-01 15:21:21.104'),
(1253, N'مسعود', N'مهندسیان', N'مسافر', N'6666715837', 2, N'1405/05/04', N'09145236987', N'limdbadmin', NULL, 4, 9, N'fa', 1, 1, '2026-08-01 15:50:31.888'),
(1254, N'مریم', N'حسینی', N'کاظم', N'9435260721', 1, N'1405/05/04', N'09369082777', N'limdbadmin', NULL, NULL, 10, N'fa', 1, 1, '2026-08-01 15:54:42.272');
GO
SET IDENTITY_INSERT dbo.[Student] OFF;
GO

-- ===== DATA: Course (44 rows) =====
SET IDENTITY_INSERT dbo.[Course] ON;
GO
INSERT INTO dbo.[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt])
VALUES
(1, 1, N'دوره فشرده انگلیسی برای کارمندان', 30, 50000000, N'Sadjad-PC\Sadjad', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(8, 1, N'دوره فشرده تافل برای بزرگسالان', 25, 35000000, N'saba', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(9, 1, N'دوره زبان انگلیسی برای نونهالان', 20, 20000000, N'saba', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(10, 2, N'دوره فشورده فرانسوی برای کارمندان', 30, 50000000, N'arshya', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(11, 1, N'دوره فشرده انگلیسی', 40, 900000, N'elyar', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(12, 2, N'دوره فشرده فرانسوی', 40, 1200000, N'elyar', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(17, 2, N'دوره زبان فرانسه برای کارمندان', 30, 50000000, N'asra', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(18, 1, N'دوره فشرده تافل برای کودکان', 30, 50000000, N'asra', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(32, 1, N'دوره نیمه فشرده انگلیسی', 40, 900000, N'elyar', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(33, 2, N'دوره نیمه فشرده فرانسوی', 40, 1200000, N'elyar', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(37, 3, N'دوره ی آموزش زبان ایتالیایی', 30, 42000000, N'vahideh', 1, NULL, N'قفقفقفقفغاخحصثهخ', NULL, NULL, NULL, N'حضوری', N'کودک', 0, '2026-07-29 14:01:12.645', '2026-07-29 16:13:54.292'),
(38, 4, N'دوره ی آموزش زبان آلمانی', 30, 42000000, N'vahideh', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(39, 2, N'دوره زبان فرانسوی برای بانوان خانه دار', 30, 45000000, N'saba', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(43, 1, N'دوره نیمه فشرده 90 جلسه ای انگلیسی', 40, 900000, N'elyar', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(44, 2, N'دوره نیمه فشرده80  جلسه ای فرانسوی', 40, 1200000, N'elyar', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(45, 2, N'ترم یک  فرانسوی', 20, 1000000, N'elyar', 1, 20, N'دوره45 دوره 45', NULL, NULL, NULL, N'ترکیبی', N'جوان', 0, '2026-07-29 14:01:12.645', '2026-08-01 14:05:41.344'),
(46, 1, N'دوره آموزش رایتینگ تافل', 20, 3000000, N'amirreza', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, '2026-07-29 14:01:12.645', NULL),
(53, 1, N'دوره 6 ماهه زبان انگلیسی', 100, 350000000, N'limdbadmin', 1, 10, N'دوره 6 ماهه زبان انگلیسی', NULL, NULL, NULL, N'حضوری', N'10-20', 0, '2026-07-29 15:41:34.056', NULL),
(60, 4, N'دوره فرانسه', 24, 1000000000, N'limdbadmin', 1, 4, N'با متد های جدید بین المللی', NULL, NULL, NULL, N'گرامرمحور', N'جوان', 0, '2026-07-29 15:49:54.692', '2026-07-29 16:06:32.442'),
(64, 11, N'دوره نمایشی فارسی #20', 16, 15000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'ترکیبی', N'کودک', 0, '2026-07-30 04:10:00.799', NULL),
(65, 5, N'دوره نمایشی روسی #21', 30, 25000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'حضوری', N'نوجوان', 0, '2026-07-30 04:10:00.808', NULL),
(68, 5, N'دوره نمایشی روسی #24', 20, 12000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آنلاین', N'کودک', 0, '2026-07-30 04:10:00.820', NULL),
(69, 5, N'دوره نمایشی روسی #25', 16, 20000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آزمون‌محور', N'بزرگسال', 0, '2026-07-30 04:10:00.823', NULL),
(70, 6, N'دوره نمایشی ژاپنی #26', 12, 45000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'مهارت‌محور', N'کودک', 0, '2026-07-30 04:10:00.828', NULL),
(71, 1, N'دوره نمایشی انگلیسی #27', 16, 15000000, N'seed', 1, 9, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'مهارت‌محور', N'همه سنین', 0, '2026-07-30 04:10:00.832', NULL),
(72, 1, N'دوره نمایشی انگلیسی #28', 12, 15000000, N'seed', 1, 9, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آنلاین', N'بزرگسال', 0, '2026-07-30 04:10:00.835', NULL),
(73, 2, N'دوره نمایشی فرانسوی #29', 24, 8000000, N'seed', 1, 24, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'مهارت‌محور', N'جوان', 0, '2026-07-30 04:10:00.835', NULL),
(74, 5, N'دوره نمایشی روسی #30', 20, 12000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آزمون‌محور', N'کودک', 0, '2026-07-30 04:10:00.842', NULL),
(75, 11, N'دوره نمایشی فارسی #31', 20, 15000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آزمون‌محور', N'نوجوان', 0, '2026-07-30 04:10:00.842', NULL),
(76, 10, N'دوره نمایشی عربی #32', 24, 12000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'گرامرمحور', N'بزرگسال', 0, '2026-07-30 04:10:00.849', NULL),
(77, 2, N'دوره نمایشی فرانسوی #33', 24, 8000000, N'seed', 1, 21, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'ترکیبی', N'کودک', 0, '2026-07-30 04:10:00.855', NULL),
(78, 7, N'دوره نمایشی اسپانیایی #34', 24, 45000000, N'seed', 1, 27, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آنلاین', N'کودک', 0, '2026-07-30 04:10:00.858', NULL),
(79, 1, N'دوره نمایشی انگلیسی #35', 30, 20000000, N'seed', 1, 11, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'حضوری', N'جوان', 0, '2026-07-30 04:10:00.863', NULL),
(80, 9, N'دوره نمایشی ترکی(آذری) #36', 12, 20000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'فشرده', N'بزرگسال', 0, '2026-07-30 04:10:00.869', NULL),
(81, 3, N'دوره نمایشی ایتالیایی #37', 20, 15000000, N'seed', 1, 18, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آزمون‌محور', N'نوجوان', 0, '2026-07-30 04:10:00.874', NULL),
(82, 6, N'دوره نمایشی ژاپنی #38', 24, 25000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'گرامرمحور', N'کودک', 0, '2026-07-30 04:10:00.876', NULL),
(83, 7, N'دوره نمایشی اسپانیایی #39', 30, 8000000, N'seed', 1, 27, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آنلاین', N'بزرگسال', 0, '2026-07-30 04:10:00.881', NULL),
(84, 8, N'دوره نمایشی چینی #40', 12, 12000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آنلاین', N'جوان', 0, '2026-07-30 04:10:00.883', NULL),
(85, 8, N'دوره نمایشی چینی #41', 12, 15000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آنلاین', N'نوجوان', 0, '2026-07-30 04:10:00.883', NULL),
(86, 2, N'دوره نمایشی فرانسوی #42', 16, 35000000, N'seed', 1, 19, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'حضوری', N'همه سنین', 0, '2026-07-30 04:10:00.890', NULL);
GO
INSERT INTO dbo.[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt])
VALUES
(87, 2, N'دوره نمایشی فرانسوی #43', 12, 20000000, N'seed', 1, 23, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'ترکیبی', N'جوان', 0, '2026-07-30 04:10:00.892', NULL),
(88, 3, N'دوره نمایشی ایتالیایی #44', 16, 15000000, N'seed', 1, 13, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آزمون‌محور', N'کودک', 0, '2026-07-30 04:10:00.892', NULL),
(89, 11, N'دوره نمایشی فارسی #45', 30, 15000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'حضوری', N'کودک', 0, '2026-07-30 04:10:00.898', NULL),
(90, 12, N'دوره فشرده هندی', 20, 900000000, N'limdbadmin', 1, NULL, N'دوره فشرده هندی', NULL, NULL, NULL, N'گرامرمحور', N'بزرگسال', 0, '2026-08-01 14:09:11.090', NULL);
GO
SET IDENTITY_INSERT dbo.[Course] OFF;
GO

-- ===== DATA: Class (76 rows) =====
SET IDENTITY_INSERT dbo.[Class] ON;
GO
INSERT INTO dbo.[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt])
VALUES
(2, 1, 1, 1, N'1405/03/20', NULL, 15, N'open', NULL, N'group', 1, NULL, NULL, '2026-07-29 14:01:12.720'),
(1003, 1, 1, 1, N'1405/06/01', NULL, 10, N'open', NULL, N'group', NULL, N'تهران - کلاس ۱۰۱', NULL, '2026-07-29 14:04:43.679'),
(1005, 9, 21, 1, N'????/??/??', N'????/??/??', 15, N'open', NULL, N'private', 1, N'شعبه مرکزی', NULL, '2026-07-29 15:09:50.058'),
(1006, 45, 1, 1, N'????/??/??', N'????/??/??', 15, N'open', NULL, N'group', 3, N'تهران', NULL, '2026-07-29 15:10:16.371'),
(1007, 46, 42, 3, N'1405/05/07', N'1405/05/07', 15, N'open', NULL, N'group', 11, N'تهران', NULL, '2026-07-29 15:25:32.702'),
(1010, 45, 42, 3, N'1404/08/13', N'1404/08/22', 15, N'open', NULL, N'group', NULL, NULL, NULL, '2026-07-29 15:44:12.963'),
(1014, 38, 28, 3, N'1404/09/07', N'1404/12/14', 12, N'finished', NULL, N'vip', 16, NULL, NULL, '2026-07-30 04:10:00.913'),
(1015, 33, 81, 2, N'1404/06/06', N'1404/07/20', 10, N'open', NULL, N'semi_private', 11, NULL, N'https://meet.demo.lims/class', '2026-07-30 04:10:00.918'),
(1016, 82, 38, 3, N'1403/03/19', N'1403/04/12', 15, N'finished', NULL, N'semi_private', 10, NULL, NULL, '2026-07-30 04:10:00.925'),
(1017, 32, 39, 4, N'1403/09/03', N'1403/11/15', 12, N'finished', NULL, N'vip', 10, NULL, NULL, '2026-07-30 04:10:00.925'),
(1018, 64, 1, 5, N'1405/06/13', N'1405/07/10', 8, N'open', NULL, N'semi_private', 3, NULL, NULL, '2026-07-30 04:10:00.934'),
(1019, 9, 9, 2, N'1403/04/02', N'1403/06/13', 12, N'in_progress', NULL, N'vip', 5, NULL, N'https://meet.demo.lims/class', '2026-07-30 04:10:00.939'),
(1020, 39, 39, 3, N'1405/01/13', N'1405/04/22', 12, N'open', NULL, N'vip', 13, NULL, NULL, '2026-07-30 04:10:00.946'),
(1021, 80, 83, 2, N'1403/07/19', N'1403/09/17', 15, N'finished', NULL, N'group', 3, NULL, N'https://meet.demo.lims/class', '2026-07-30 04:10:00.946'),
(1022, 71, 28, 5, N'1405/07/13', N'1405/10/12', 20, N'open', NULL, N'group', NULL, NULL, NULL, '2026-07-30 04:10:00.953'),
(1023, 39, 23, 3, N'1403/07/04', N'1403/09/27', 12, N'open', NULL, N'vip', 4, NULL, NULL, '2026-07-30 04:10:00.953'),
(1025, 75, 42, 2, N'1404/02/11', N'1404/04/23', 10, N'in_progress', NULL, N'semi_private', 11, NULL, N'https://meet.demo.lims/class', '2026-07-30 04:10:00.960'),
(1029, 72, 9, 3, N'1405/02/04', N'1405/03/10', 18, N'open', NULL, N'vip', 11, NULL, NULL, '2026-07-30 04:10:00.980'),
(1030, 33, 83, 5, N'1403/05/13', N'1403/06/22', 12, N'open', NULL, N'group', 1, NULL, NULL, '2026-07-30 04:10:00.980'),
(1031, 60, 38, 4, N'1404/06/15', N'1404/09/22', 8, N'draft', NULL, N'semi_private', 11, NULL, NULL, '2026-07-30 04:10:00.987'),
(1032, 64, 23, 1, N'1405/09/13', N'1405/11/22', 10, N'finished', NULL, N'semi_private', 18, N'کلاس نمایشی طبقه ۲', NULL, '2026-07-30 04:10:00.994'),
(1034, 8, 38, 2, N'1405/10/08', N'1405/12/14', 18, N'full', NULL, N'vip', NULL, NULL, N'https://meet.demo.lims/class', '2026-07-30 04:10:01.004'),
(1035, 87, 16, 1, N'1404/06/13', N'1404/08/17', 18, N'open', NULL, N'group', 3, N'کلاس نمایشی طبقه ۲', NULL, '2026-07-30 04:10:01.008'),
(1036, 68, 42, 1, N'1405/01/11', N'1405/04/22', 18, N'finished', NULL, N'private', 1, N'کلاس نمایشی طبقه ۲', NULL, '2026-07-30 04:10:01.019'),
(1040, 69, 27, 2, N'1405/06/11', N'1405/08/13', 12, N'open', NULL, N'private', 18, NULL, N'https://meet.demo.lims/class', '2026-07-30 04:10:01.041'),
(1041, 38, 28, 4, N'1404/02/07', N'1404/03/18', 20, N'finished', NULL, N'vip', 3, NULL, NULL, '2026-07-30 04:10:01.043'),
(1042, 45, 42, 4, N'1403/01/19', N'1403/03/10', 12, N'in_progress', NULL, N'group', 13, NULL, NULL, '2026-07-30 04:10:01.045'),
(1043, 78, 31, 5, N'1403/07/19', N'1403/08/24', 12, N'open', NULL, N'semi_private', 4, NULL, NULL, '2026-07-30 04:10:01.045'),
(1046, 80, 16, 1, N'1403/04/11', N'1403/06/15', 12, N'in_progress', NULL, N'semi_private', 4, N'کلاس نمایشی طبقه ۲', NULL, '2026-07-30 04:10:01.053'),
(1047, 39, 39, 1, N'1405/10/03', N'1405/11/10', 15, N'open', NULL, N'private', 13, N'کلاس نمایشی طبقه ۲', NULL, '2026-07-30 04:10:01.059'),
(1048, 86, 21, 5, N'1404/09/03', N'1404/12/23', 18, N'open', NULL, N'vip', 17, NULL, NULL, '2026-07-30 04:10:01.063'),
(1049, 10, 19, 1, N'1403/01/18', N'1403/03/21', 18, N'finished', NULL, N'semi_private', 10, N'کلاس نمایشی طبقه ۲', NULL, '2026-07-30 04:10:01.064'),
(1052, 76, 1, 5, N'1405/02/04', N'1405/03/27', 20, N'in_progress', NULL, N'vip', 17, NULL, NULL, '2026-07-30 04:10:01.077'),
(1054, 83, 16, 3, N'1405/04/17', N'1405/05/10', 10, N'open', NULL, N'semi_private', 19, NULL, NULL, '2026-07-30 04:10:01.079'),
(1058, 89, 83, 3, N'1403/01/11', N'1403/02/17', 12, N'open', NULL, N'private', NULL, NULL, NULL, '2026-07-30 04:10:01.095'),
(1059, 72, 81, 4, N'1405/09/19', N'1405/10/24', 20, N'open', NULL, N'private', 3, NULL, NULL, '2026-07-30 04:10:01.097'),
(1061, 85, 9, 4, N'1405/06/12', N'1405/08/20', 20, N'in_progress', NULL, N'group', 10, NULL, NULL, '2026-07-30 04:10:01.099'),
(1063, 10, 38, 2, N'1404/06/11', N'1404/09/27', 10, N'open', NULL, N'group', 3, NULL, N'https://meet.demo.lims/class', '2026-07-30 04:10:01.105'),
(1067, 46, 23, 1, N'1403/08/11', N'1403/09/22', 15, N'open', NULL, N'group', 18, N'کلاس نمایشی طبقه ۲', NULL, '2026-07-30 04:10:01.114'),
(1068, 8, 81, 5, N'1405/04/04', N'1405/05/17', 8, N'draft', NULL, N'semi_private', 18, NULL, NULL, '2026-07-30 04:10:01.116');
GO
INSERT INTO dbo.[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt])
VALUES
(1071, 70, 39, 4, N'1403/03/02', N'1403/06/24', 12, N'draft', NULL, N'vip', 4, NULL, NULL, '2026-07-30 04:10:01.124'),
(1072, 87, 9, 2, N'1403/01/12', N'1403/04/24', 20, N'full', NULL, N'private', NULL, NULL, N'https://meet.demo.lims/class', '2026-07-30 04:10:01.126'),
(1073, 17, 82, 2, N'1405/05/07', N'1405/06/15', 20, N'finished', NULL, N'vip', 7, NULL, N'https://meet.demo.lims/class', '2026-07-30 04:10:01.130'),
(1075, 45, 9, 5, N'1403/07/03', N'1403/10/28', 18, N'in_progress', NULL, N'semi_private', 3, NULL, NULL, '2026-07-30 04:10:01.135'),
(1077, 10, 38, 1, N'1403/09/12', N'1403/10/17', 8, N'in_progress', NULL, N'semi_private', 3, N'کلاس نمایشی طبقه ۲', NULL, '2026-07-30 04:10:01.138'),
(1078, 83, 9, 3, N'1405/03/15', N'1405/04/14', 8, N'open', NULL, N'private', 5, NULL, NULL, '2026-07-30 04:10:01.140'),
(1079, 38, 18, 3, N'1404/08/15', N'1404/10/22', 20, N'full', NULL, N'semi_private', 7, NULL, NULL, '2026-07-30 04:10:01.140'),
(1082, 77, 31, 2, N'1404/09/19', N'1404/12/21', 10, N'finished', NULL, N'vip', 18, NULL, N'https://meet.demo.lims/class', '2026-07-30 04:10:01.144'),
(1083, 74, 81, 1, N'1404/03/18', N'1404/05/19', 12, N'in_progress', NULL, N'private', 1, N'کلاس نمایشی طبقه ۲', NULL, '2026-07-30 04:10:01.150'),
(1084, 64, 19, 4, N'1403/01/03', N'1403/04/22', 15, N'in_progress', NULL, N'private', 18, NULL, NULL, '2026-07-30 04:10:01.151'),
(1086, 8, 27, 5, N'1405/02/08', N'1405/03/23', 12, N'draft', NULL, N'vip', NULL, NULL, NULL, '2026-07-30 04:10:01.157'),
(1088, 72, 80, 1, N'1403/01/11', N'1403/02/23', 10, N'finished', NULL, N'private', 11, N'کلاس نمایشی طبقه ۲', NULL, '2026-07-30 04:10:01.160'),
(1089, 65, 82, 4, N'1405/09/19', N'1405/10/17', 15, N'open', NULL, N'semi_private', 19, NULL, NULL, '2026-07-30 04:10:01.162'),
(1093, 9, 27, 1, N'1405/06/17', N'1405/08/18', 15, N'finished', NULL, N'group', 17, N'کلاس نمایشی طبقه ۲', NULL, '2026-07-30 04:10:01.171'),
(1095, 68, 81, 1, N'1405/09/05', N'1405/12/16', 10, N'open', NULL, N'group', NULL, N'کلاس نمایشی طبقه ۲', NULL, '2026-07-30 04:10:01.175'),
(1096, 74, 21, 5, N'1405/06/04', N'1405/08/27', 20, N'full', NULL, N'semi_private', 10, NULL, NULL, '2026-07-30 04:10:01.176'),
(1100, 79, 19, 4, N'1404/03/09', N'1404/06/20', 18, N'finished', NULL, N'group', 10, NULL, NULL, '2026-07-30 04:10:01.187'),
(1101, 12, 21, 1, N'1405/09/03', N'1405/10/20', 8, N'open', NULL, N'group', 10, N'کلاس نمایشی طبقه ۲', NULL, '2026-07-30 04:10:01.188'),
(1102, 79, 1, 4, N'1404/07/16', N'1404/08/25', 8, N'full', NULL, N'semi_private', 18, NULL, NULL, '2026-07-30 04:10:01.191'),
(1103, 75, 39, 3, N'1404/01/09', N'1404/02/17', 10, N'open', NULL, N'private', 3, NULL, NULL, '2026-07-30 04:10:01.192'),
(1107, 8, 18, 3, N'1403/04/19', N'1403/07/23', 12, N'in_progress', NULL, N'private', 11, NULL, NULL, '2026-07-30 04:10:01.198'),
(1108, 86, 16, 2, N'1405/05/10', N'1405/06/11', 18, N'open', NULL, N'vip', 7, NULL, N'https://meet.demo.lims/class', '2026-07-30 04:10:01.198'),
(1112, 12, 18, 2, N'1404/07/15', N'1404/09/19', 18, N'draft', NULL, N'group', 4, NULL, N'https://meet.demo.lims/class', '2026-07-30 04:10:01.211'),
(1113, 33, 83, 5, N'1404/02/07', N'1404/03/14', 10, N'in_progress', NULL, N'semi_private', 4, NULL, NULL, '2026-07-30 04:10:01.211'),
(1114, 83, 19, 5, N'1403/09/12', N'1403/10/18', 12, N'in_progress', NULL, N'vip', 3, NULL, NULL, '2026-07-30 04:10:01.217'),
(1121, 86, 8, 3, N'1405/10/04', N'1405/12/10', 8, N'open', NULL, N'group', 7, NULL, NULL, '2026-07-30 04:10:01.231'),
(1123, 82, 16, 2, N'1404/06/02', N'1404/09/11', 12, N'open', NULL, N'vip', 18, NULL, N'https://meet.demo.lims/class', '2026-07-30 04:10:01.237'),
(1124, 39, 13, 5, N'1404/03/15', N'1404/05/23', 10, N'finished', NULL, N'vip', 4, NULL, NULL, '2026-07-30 04:10:01.237'),
(1125, 64, 1, 4, N'1404/07/01', N'1404/09/21', 10, N'open', NULL, N'group', 1, NULL, NULL, '2026-07-30 04:10:01.237'),
(1127, 78, 1, 3, N'1403/09/15', N'1403/12/25', 15, N'open', NULL, N'semi_private', 3, NULL, NULL, '2026-07-30 04:10:01.244'),
(1130, 83, 27, 5, N'1405/05/14', N'1405/06/24', 15, N'open', NULL, N'semi_private', 16, NULL, NULL, '2026-07-30 04:10:01.248'),
(1131, 45, 9, 2, N'1405/09/18', N'1405/12/18', 20, N'open', NULL, N'private', 5, NULL, N'https://meet.demo.lims/class', '2026-07-30 04:10:01.250'),
(1132, 72, 19, 4, N'1403/02/03', N'1403/05/20', 15, N'in_progress', NULL, N'group', 18, NULL, NULL, '2026-07-30 04:10:01.251'),
(1133, 64, 80, 2, N'1405/05/15', N'1405/05/28', 15, N'open', NULL, N'group', 3, NULL, N'r7i7tfuytyrt', '2026-08-01 13:39:43.473'),
(1134, 44, 9, 3, N'1405/05/21', N'1412/01/04', 15, N'open', NULL, N'semi_private', 17, NULL, NULL, '2026-08-01 14:02:17.836'),
(1135, 45, 19, 2, N'1405/05/12', N'1405/05/12', 15, N'open', NULL, N'group', 19, N'شعبه ابرسان', N';lkkjmkmjff', '2026-08-01 14:06:36.352');
GO
SET IDENTITY_INSERT dbo.[Class] OFF;
GO

-- ===== DATA: Session (94 rows) =====
SET IDENTITY_INSERT dbo.[Session] ON;
GO
INSERT INTO dbo.[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes])
VALUES
(1, 2, N'1405/04/01', N'17:00', N'20:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, NULL),
(2, 2, N'1405/04/02', N'17:00', N'18:30', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, NULL),
(3, 2, N'1405/04/03', N'17:00', N'20:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, NULL),
(1003, 1005, N'1395/02/02', N'10:00', N'11:30', 1, N'scheduled', NULL, NULL, N'شعبه مرکزی', NULL, 0, NULL),
(1005, 1006, N'1405/05/07', N'10:00', N'11:30', 1, N'scheduled', NULL, NULL, N'تهران', NULL, 0, NULL),
(1006, 1006, N'1405/05/01', N'10:00', N'11:30', 1, N'scheduled', NULL, NULL, N'تهران', NULL, 0, NULL),
(1009, 1006, N'1405/05/28', N'10:00', N'11:30', 1, N'scheduled', NULL, NULL, N'تهران', NULL, 0, NULL),
(1010, 1007, N'1409/02/03', N'10:00', N'25:30', 4, N'scheduled', NULL, NULL, N'تهران', NULL, 1, NULL),
(1011, 1006, N'1405/05/31', N'10:00', N'11:30', 1, N'scheduled', NULL, NULL, N'تهران', NULL, 0, NULL),
(1013, 1042, N'1405/05/16', N'12:00', N'14:00', 3, N'completed', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد'),
(1016, 1113, N'1405/10/25', N'14:00', N'16:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1018, 1054, N'1404/01/11', N'15:00', N'17:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1019, 1006, N'1404/07/24', N'18:00', N'20:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1020, 1075, N'1404/03/20', N'18:00', N'20:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1022, 1114, N'1405/02/17', N'12:00', N'14:00', 1, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1025, 1018, N'1404/11/28', N'15:00', N'17:00', 1, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1029, 1021, N'1404/04/04', N'16:00', N'18:00', 2, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1030, 1049, N'1404/03/28', N'12:00', N'14:00', 1, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1036, 1016, N'1405/07/23', N'17:00', N'19:00', 2, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1037, 1089, N'1404/08/20', N'11:00', N'13:00', 1, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1038, 1083, N'1404/05/12', N'10:00', N'12:00', 1, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1040, 1132, N'1405/10/28', N'08:00', N'10:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1043, 1107, N'1404/02/14', N'10:00', N'12:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1044, 1121, N'1404/12/17', N'17:00', N'19:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1045, 1047, N'1404/02/19', N'12:00', N'14:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1050, 1078, N'1405/01/16', N'09:00', N'11:00', 3, N'completed', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد'),
(1052, 1058, N'1404/12/22', N'17:00', N'19:00', 2, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1053, 1124, N'1405/01/06', N'16:00', N'18:00', 3, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1055, 1042, N'1404/05/11', N'11:00', N'13:00', 2, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1059, 1112, N'1404/12/23', N'18:00', N'20:00', 1, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1061, 1007, N'1404/12/03', N'15:00', N'17:00', 4, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1062, 2, N'1404/10/21', N'18:00', N'20:00', 2, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1063, 1107, N'1404/02/13', N'11:00', N'13:00', 3, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1064, 1124, N'1404/09/01', N'14:00', N'16:00', 5, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1066, 1073, N'1405/03/20', N'16:00', N'18:00', 1, N'completed', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد'),
(1067, 1043, N'1404/05/18', N'12:00', N'14:00', 5, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1069, 1127, N'1405/11/27', N'12:00', N'14:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1071, 1100, N'1404/07/05', N'08:00', N'10:00', 4, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1073, 1041, N'1404/11/07', N'08:00', N'10:00', 4, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1074, 1063, N'1404/12/15', N'09:00', N'11:00', 1, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد');
GO
INSERT INTO dbo.[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes])
VALUES
(1075, 2, N'1405/06/22', N'14:00', N'16:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد'),
(1077, 1108, N'1404/09/28', N'14:00', N'16:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1078, 1019, N'1405/05/05', N'08:00', N'10:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1079, 1023, N'1404/04/17', N'11:00', N'13:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1085, 1095, N'1405/10/18', N'16:00', N'18:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1086, 1047, N'1405/02/05', N'12:00', N'14:00', 2, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1088, 1021, N'1404/04/17', N'12:00', N'14:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1090, 1063, N'1405/09/08', N'12:00', N'14:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1091, 1036, N'1404/01/21', N'08:00', N'10:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1094, 1079, N'1404/05/10', N'12:00', N'14:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1095, 1040, N'1405/12/24', N'16:00', N'18:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1100, 1124, N'1405/07/26', N'08:00', N'10:00', 2, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1103, 1103, N'1405/06/24', N'13:00', N'15:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1104, 1127, N'1405/01/07', N'15:00', N'17:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1112, 1072, N'1404/06/20', N'08:00', N'10:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1113, 1061, N'1405/06/14', N'13:00', N'15:00', 3, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1114, 1078, N'1405/06/10', N'18:00', N'20:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1115, 1059, N'1404/09/03', N'08:00', N'10:00', 5, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1116, 1030, N'1405/01/14', N'16:00', N'18:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1117, 1049, N'1405/11/09', N'11:00', N'13:00', 2, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1118, 1042, N'1405/03/07', N'09:00', N'11:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1119, 1123, N'1404/04/10', N'16:00', N'18:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد'),
(1122, 1047, N'1404/03/08', N'13:00', N'15:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1123, 1023, N'1404/11/25', N'10:00', N'12:00', 4, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1125, 1041, N'1404/05/12', N'09:00', N'11:00', 2, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1126, 1019, N'1404/11/23', N'08:00', N'10:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1128, 1010, N'1404/03/16', N'18:00', N'20:00', 1, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1129, 1041, N'1404/12/04', N'11:00', N'13:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1130, 1046, N'1404/07/13', N'12:00', N'14:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1131, 1059, N'1405/04/04', N'18:00', N'20:00', 3, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1132, 1082, N'1405/06/09', N'12:00', N'14:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1136, 1130, N'1404/07/10', N'13:00', N'15:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1137, 1123, N'1405/12/18', N'18:00', N'20:00', 3, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1140, 1003, N'1405/10/18', N'11:00', N'13:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1144, 1068, N'1405/04/03', N'14:00', N'16:00', 2, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1145, 1073, N'1404/10/21', N'08:00', N'10:00', 2, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1146, 1083, N'1405/10/17', N'14:00', N'16:00', 4, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1147, 1078, N'1404/07/17', N'16:00', N'18:00', 1, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1148, 1103, N'1405/11/07', N'16:00', N'18:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1149, 1052, N'1405/01/13', N'18:00', N'20:00', 2, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد');
GO
INSERT INTO dbo.[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes])
VALUES
(1150, 1058, N'1404/09/27', N'17:00', N'19:00', 2, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1155, 1035, N'1405/06/26', N'17:00', N'19:00', 4, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1156, 1096, N'1405/05/21', N'18:00', N'20:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1157, 1049, N'1405/06/25', N'16:00', N'18:00', 3, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1158, 1014, N'1404/10/19', N'16:00', N'18:00', 2, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1159, 1058, N'1404/01/09', N'18:00', N'20:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1160, 1005, N'1404/07/22', N'15:00', N'17:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1164, 1040, N'1404/03/18', N'18:00', N'20:00', 2, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1169, 1052, N'1405/09/02', N'15:00', N'17:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1171, 1130, N'1404/03/03', N'17:00', N'19:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد'),
(1173, 1131, N'1405/05/12', N'10:00', N'10:02', 2, N'scheduled', NULL, N'https://meet.demo.lims/class', NULL, NULL, 0, NULL),
(1174, 1132, N'1405/05/10', N'10:00', N'10:05', 2, N'scheduled', NULL, NULL, NULL, NULL, 0, NULL),
(1175, 1135, N'1405/05/12', N'17:00', N'20:00', 1, N'scheduled', NULL, N';lkkjmkmjff', N'شعبه نف راه', NULL, 0, NULL),
(1176, 1134, N'1405/05/14', N'10:00', N'19:08', 4, N'scheduled', NULL, N'hfgiulukg', N'شعبه مرکزی', NULL, 1, NULL);
GO
SET IDENTITY_INSERT dbo.[Session] OFF;
GO

-- ===== DATA: SessionStudent (26 rows) =====
SET IDENTITY_INSERT dbo.[SessionStudent] ON;
GO
INSERT INTO dbo.[SessionStudent] ([Id], [SessionRef], [StudentRef], [AttendanceStatus], [RecordedAt])
VALUES
(1, 1, 1, N'present', '2026-07-29 14:01:12.803'),
(2, 1, 2, N'present', '2026-07-29 14:01:12.803'),
(3, 1, 3, N'present', '2026-07-29 14:01:12.803'),
(4, 1, 4, N'present', '2026-07-29 14:01:12.803'),
(6, 1, 6, N'present', '2026-07-29 14:01:12.803'),
(7, 2, 1, N'present', '2026-07-29 14:01:12.803'),
(8, 2, 2, N'present', '2026-07-29 14:01:12.803'),
(9, 2, 4, N'present', '2026-07-29 14:01:12.803'),
(10, 2, 6, N'present', '2026-07-29 14:01:12.803'),
(11, 3, 1, N'present', '2026-07-29 14:01:12.803'),
(12, 3, 2, N'present', '2026-07-29 14:01:12.803'),
(13, 3, 10, N'present', '2026-07-29 14:01:12.803'),
(1008, 1003, 98, N'absent', '2026-08-01 14:02:34.702'),
(1009, 1020, 74, N'late', '2026-08-01 16:19:04.453'),
(1011, 1112, 60, N'absent', '2026-08-01 14:23:10.191'),
(1012, 1112, 63, N'absent', '2026-08-01 14:23:10.197'),
(1017, 1173, 1246, N'leave', '2026-08-01 15:34:24.819'),
(1019, 1066, 141, N'present', '2026-08-01 15:21:55.177'),
(1020, 1071, 163, N'present', '2026-08-01 15:39:33.241'),
(1021, 1114, 6, N'late', '2026-08-01 15:34:13.932'),
(1022, 1114, 26, N'absent', '2026-08-01 15:34:13.936'),
(1023, 1114, 163, N'leave', '2026-08-01 15:34:13.939'),
(1024, 1147, 6, N'absent', '2026-08-01 15:34:36.433'),
(1025, 1147, 26, N'absent', '2026-08-01 15:34:36.437'),
(1026, 1147, 163, N'absent', '2026-08-01 15:34:36.438'),
(1027, 1022, 1254, N'present', '2026-08-01 16:06:43.903');
GO
SET IDENTITY_INSERT dbo.[SessionStudent] OFF;
GO

-- ===== DATA: Registration (79 rows) =====
SET IDENTITY_INSERT dbo.[Registration] ON;
GO
INSERT INTO dbo.[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt])
VALUES
(1, 1, 1, N'1405/04/31', NULL, N'active', NULL, N'debtor', '2026-07-29 14:01:12.896'),
(2, 2, 1, N'1405/04/30', NULL, N'active', NULL, N'debtor', '2026-07-29 14:01:12.896'),
(1014, 84, 79, N'1405/06/01', 1102, N'completed', NULL, N'debtor', '2026-07-30 04:10:01.501'),
(1016, 1214, 79, N'1405/05/01', 1102, N'pending_payment', NULL, N'debtor', '2026-07-30 04:10:01.515'),
(1017, 70, 86, N'1405/01/05', 1121, N'pending_payment', NULL, N'debtor', '2026-07-30 04:10:01.515'),
(1018, 98, 75, N'1405/06/12', 1103, N'completed', NULL, N'debtor', '2026-07-30 04:10:01.522'),
(1021, 59, 74, N'1405/07/17', 1096, N'transferred', NULL, N'debtor', '2026-07-30 04:10:01.536'),
(1022, 27, 75, N'1405/03/12', 1025, N'active', NULL, N'creditor', '2026-07-30 04:10:01.536'),
(1023, 76, 68, N'1405/06/02', 1095, N'active', NULL, N'creditor', '2026-07-30 04:10:01.536'),
(1030, 84, 87, N'1405/02/16', 1035, N'active', NULL, N'debtor', '2026-07-30 04:10:01.557'),
(1034, 74, 45, N'1405/02/03', 1075, N'pending_approval', NULL, N'debtor', '2026-07-30 04:10:01.564'),
(1035, 145, 75, N'1405/01/16', 1025, N'active', NULL, N'debtor', '2026-07-30 04:10:01.564'),
(1038, 149, 64, N'1405/01/01', 1125, N'active', NULL, N'debtor', '2026-07-30 04:10:01.570'),
(1039, 156, 38, N'1405/02/19', 1079, N'active', NULL, N'debtor', '2026-07-30 04:10:01.571'),
(1041, 72, 8, N'1405/04/07', 1107, N'pending_approval', NULL, N'debtor', '2026-07-30 04:10:01.578'),
(1042, 65, 64, N'1405/03/27', 1084, N'transferred', NULL, N'creditor', '2026-07-30 04:10:01.578'),
(1048, 24, 38, N'1405/04/10', 1014, N'pending_approval', NULL, N'debtor', '2026-07-30 04:10:01.585'),
(1050, 87, 10, N'1405/04/04', 1077, N'active', NULL, N'debtor', '2026-07-30 04:10:01.585'),
(1051, 149, 10, N'1405/01/12', 1077, N'frozen', NULL, N'debtor', '2026-07-30 04:10:01.592'),
(1055, 134, 45, N'1405/03/06', 1010, N'pending_payment', NULL, N'debtor', '2026-07-30 04:10:01.598'),
(1058, 134, 10, N'1405/05/12', 1063, N'active', NULL, N'debtor', '2026-07-30 04:10:01.605'),
(1061, 72, 72, N'1405/02/23', 1029, N'pending_approval', NULL, N'debtor', '2026-07-30 04:10:01.612'),
(1063, 25, 8, N'1405/03/13', 1107, N'active', NULL, N'debtor', '2026-07-30 04:10:01.612'),
(1064, 2, 10, N'1405/06/09', 1077, N'pending_approval', NULL, N'debtor', '2026-07-30 04:10:01.612'),
(1066, 163, 79, N'1405/05/15', 1100, N'active', NULL, N'debtor', '2026-07-30 04:10:01.619'),
(1069, 143, 75, N'1405/04/21', 1103, N'active', NULL, N'debtor', '2026-07-30 04:10:01.619'),
(1070, 2, 46, N'1405/06/23', 1067, N'completed', NULL, N'debtor', '2026-07-30 04:10:01.626'),
(1071, 148, 8, N'1405/01/05', 1086, N'completed', NULL, N'debtor', '2026-07-30 04:10:01.626'),
(1072, 22, 64, N'1405/07/27', 1084, N'active', NULL, N'debtor', '2026-07-30 04:10:01.626'),
(1074, 66, 76, N'1405/05/02', 1052, N'transferred', NULL, N'creditor', '2026-07-30 04:10:01.633'),
(1077, 155, 46, N'1405/03/22', 1067, N'pending_approval', NULL, N'debtor', '2026-07-30 04:10:01.634'),
(1080, 155, 89, N'1405/01/02', 1058, N'pending_payment', NULL, N'creditor', '2026-07-30 04:10:01.640'),
(1084, 145, 78, N'1405/05/19', 1127, N'active', NULL, N'debtor', '2026-07-30 04:10:01.643'),
(1085, 44, 72, N'1405/04/07', 1059, N'pending_payment', NULL, N'debtor', '2026-07-30 04:10:01.647'),
(1094, 96, 82, N'1405/02/07', 1123, N'active', NULL, N'debtor', '2026-07-30 04:10:01.663'),
(1097, 173, 8, N'1405/07/23', 1107, N'active', NULL, N'debtor', '2026-07-30 04:10:01.668'),
(1101, 63, 87, N'1405/04/12', 1072, N'frozen', NULL, N'debtor', '2026-07-30 04:10:01.675'),
(1102, 163, 83, N'1405/05/04', 1078, N'active', NULL, N'debtor', '2026-07-30 04:10:01.675'),
(1104, 141, 64, N'1405/02/07', 1018, N'completed', NULL, N'debtor', '2026-07-30 04:10:01.675'),
(1105, 60, 87, N'1405/05/10', 1072, N'pending_payment', NULL, N'settled', '2026-07-30 04:10:01.682');
GO
INSERT INTO dbo.[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt])
VALUES
(1109, 134, 75, N'1405/06/15', 1025, N'active', NULL, N'debtor', '2026-07-30 04:10:01.682'),
(1114, 1237, 83, N'1405/03/04', 1078, N'transferred', NULL, N'debtor', '2026-07-30 04:10:01.696'),
(1119, 73, 12, N'1405/05/24', 1112, N'transferred', NULL, N'creditor', '2026-07-30 04:10:01.703'),
(1123, 4, 60, N'1405/05/16', 1031, N'pending_payment', NULL, N'debtor', '2026-07-30 04:10:01.710'),
(1128, 79, 70, N'1405/05/28', 1071, N'active', NULL, N'debtor', '2026-07-30 04:10:01.715'),
(1129, 79, 87, N'1405/03/18', 1035, N'active', NULL, N'creditor', '2026-07-30 04:10:01.717'),
(1137, 79, 9, N'1405/06/26', 1093, N'active', NULL, N'debtor', '2026-07-30 04:10:01.730'),
(1139, 67, 77, N'1405/04/17', 1082, N'active', NULL, N'debtor', '2026-07-30 04:10:01.730'),
(1142, 74, 38, N'1405/03/07', 1041, N'active', NULL, N'debtor', '2026-07-30 04:10:01.735'),
(1148, 139, 33, N'1405/05/10', 1030, N'completed', NULL, N'creditor', '2026-07-30 04:10:01.739'),
(1157, 141, 17, N'1405/01/22', 1073, N'pending_payment', NULL, N'debtor', '2026-07-30 04:10:01.752'),
(1158, 26, 83, N'1405/05/27', 1078, N'active', NULL, N'debtor', '2026-07-30 04:10:01.752'),
(1164, 98, 9, N'1405/05/10', 1005, N'pending_payment', NULL, N'debtor', '2026-07-30 04:10:01.758'),
(1165, 70, 78, N'1405/03/08', 1043, N'active', NULL, N'debtor', '2026-07-30 04:10:01.765'),
(1168, 173, 1, N'1405/04/11', 2, N'active', NULL, N'debtor', '2026-07-30 04:10:01.765'),
(1170, 124, 72, N'1405/02/16', 1059, N'completed', NULL, N'debtor', '2026-07-30 04:10:01.773'),
(1171, 148, 64, N'1405/04/17', 1018, N'completed', NULL, N'debtor', '2026-07-30 04:10:01.773'),
(1172, 164, 1, N'1405/05/04', 1003, N'active', NULL, N'debtor', '2026-07-30 04:10:01.775'),
(1176, 133, 38, N'1405/02/07', 1041, N'active', NULL, N'debtor', '2026-07-30 04:10:01.779'),
(1180, 96, 68, N'1405/01/07', 1036, N'pending_payment', NULL, N'debtor', '2026-07-30 04:10:01.786'),
(1181, 1229, 12, N'1405/02/25', 1112, N'active', NULL, N'debtor', '2026-07-30 04:10:01.789'),
(1188, 1226, 39, N'1405/01/16', 1023, N'pending_payment', NULL, N'debtor', '2026-07-30 04:10:01.793'),
(1195, 66, 45, N'1405/03/11', 1010, N'active', NULL, N'debtor', '2026-07-30 04:10:01.807'),
(1197, 96, 45, N'1405/02/18', 1010, N'active', NULL, N'debtor', '2026-07-30 04:10:01.807'),
(1202, 166, 10, N'1405/05/03', 1077, N'active', NULL, N'debtor', '2026-07-30 04:10:01.814'),
(1204, 115, 69, N'1405/05/15', 1040, N'active', NULL, N'debtor', '2026-07-30 04:10:01.821'),
(1209, 138, 39, N'1405/05/16', 1020, N'active', NULL, N'debtor', '2026-07-30 04:10:01.828'),
(1210, 188, 83, N'1405/03/09', 1054, N'active', NULL, N'debtor', '2026-07-30 04:10:01.828'),
(1212, 27, 71, N'1405/02/05', 1022, N'pending_payment', NULL, N'creditor', '2026-07-30 04:10:01.828'),
(1216, 6, 83, N'1405/07/12', 1078, N'pending_payment', NULL, N'debtor', '2026-07-30 04:10:01.835'),
(1218, 188, 9, N'1405/07/02', 1019, N'pending_approval', NULL, N'debtor', '2026-07-30 04:10:01.841'),
(1224, 76, 1, N'1405/01/05', 2, N'active', NULL, N'debtor', '2026-07-30 04:10:01.850'),
(1237, 1246, 45, N'1405/05/10', 1131, N'pending_payment', NULL, N'debtor', '2026-08-01 14:16:12.257'),
(1239, 1246, 1, N'1405/05/10', 1003, N'pending_payment', NULL, N'debtor', '2026-08-01 14:21:07.732'),
(1240, 1246, 12, N'1405/05/10', 1101, N'pending_payment', NULL, N'debtor', '2026-08-01 14:22:02.944'),
(1242, 1246, 39, N'1405/05/10', 1023, N'pending_payment', NULL, N'debtor', '2026-08-01 14:22:40.646'),
(1243, 1246, 9, N'1405/05/10', 1005, N'pending_payment', NULL, N'debtor', '2026-08-01 14:23:06.305'),
(1250, 1254, 83, N'1405/05/10', 1114, N'pending_payment', NULL, N'debtor', '2026-08-01 16:04:27.098'),
(2250, 161, 46, N'1405/05/12', 1067, N'pending_payment', NULL, N'debtor', '2026-08-03 15:26:53.289');
GO
SET IDENTITY_INSERT dbo.[Registration] OFF;
GO

-- ===== DATA: Payment (60 rows) =====
SET IDENTITY_INSERT dbo.[Payment] ON;
GO
INSERT INTO dbo.[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt])
VALUES
(2, 2, N'1405/06/26', 20000000, 3, N'failed', N'cash', 1070, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.869'),
(3, 133, N'1405/02/03', 15000000, 2, N'paid', N'online', 1176, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.876'),
(8, 141, N'1405/06/14', 12000000, 2, N'failed', N'online', 1104, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.892'),
(10, 173, N'1405/04/04', 30000000, 2, N'draft', N'cash', 1168, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.899'),
(24, 148, N'1405/05/13', 5000000, 2, N'draft', N'other', 1171, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.925'),
(27, 155, N'1405/03/02', 20000000, 2, N'paid', N'online', 1080, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.925'),
(30, 96, N'1405/04/20', 10000000, 2, N'paid', N'installment', 1180, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.932'),
(33, 65, N'1405/05/25', 12000000, 1, N'paid', N'online', 1042, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.940'),
(34, 65, N'1405/05/17', 30000000, 1, N'paid', N'cash', 1042, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.942'),
(37, 87, N'1405/05/04', 30000000, 2, N'overdue', N'other', 1050, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.946'),
(38, 95, N'1405/05/08', 10000000, 1, N'draft', N'online', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.946'),
(40, 45, N'1405/05/18', 15000000, 2, N'paid', N'cash', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.953'),
(45, 73, N'1405/04/27', 8000000, 1, N'paid', N'cash', 1119, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.953'),
(46, 66, N'1405/03/13', 12000000, 2, N'paid', N'installment', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.959'),
(54, 59, N'1405/05/25', 30000000, 3, N'failed', N'installment', 1021, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.978'),
(56, 113, N'1405/02/27', 30000000, 2, N'paid', N'card', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.980'),
(58, 23, N'1405/01/21', 5000000, 2, N'partially_paid', N'other', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.987'),
(59, 1229, N'1405/05/12', 25000000, 1, N'partially_paid', N'cash', 1181, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:01.987'),
(68, 27, N'1405/05/06', 8000000, 3, N'paid', N'installment', 1022, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.003'),
(69, 164, N'1405/07/01', 15000000, 2, N'failed', N'other', 1172, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.003'),
(71, 76, N'1405/07/14', 30000000, 3, N'paid', N'installment', 1023, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.009'),
(75, 70, N'1405/03/19', 12000000, 1, N'refunded', N'online', 1165, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.015'),
(77, 96, N'1405/02/04', 30000000, 2, N'partially_paid', N'online', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.023'),
(79, 72, N'1405/02/04', 30000000, 1, N'partially_paid', N'cash', 1061, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.024'),
(82, 27, N'1405/05/13', 30000000, 1, N'partially_paid', N'online', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.026'),
(85, 96, N'1405/01/27', 10000000, 3, N'overdue', N'installment', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.029'),
(87, 27, N'1405/07/14', 30000000, 1, N'paid', N'installment', 1022, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.029'),
(95, 27, N'1405/06/03', 30000000, 1, N'paid', N'card', 1212, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.043'),
(97, 79, N'1405/05/05', 25000000, 2, N'paid', N'online', 1129, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.043'),
(98, 4, N'1405/05/06', 15000000, 3, N'partially_paid', N'installment', 1123, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.043'),
(104, 23, N'1405/01/08', 10000000, 3, N'paid', N'installment', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.050'),
(106, 50, N'1405/06/09', 5000000, 3, N'pending', N'card', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.050'),
(107, 156, N'1405/07/07', 15000000, 3, N'paid', N'cash', 1039, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.050'),
(108, 74, N'1405/02/08', 15000000, 3, N'overdue', N'other', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.057'),
(111, 1229, N'1405/07/23', 30000000, 1, N'overdue', N'card', 1181, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.057'),
(112, 27, N'1405/05/06', 20000000, 1, N'pending', N'installment', 1212, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.057'),
(117, 155, N'1405/02/08', 10000000, 3, N'pending', N'card', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.065'),
(118, 148, N'1405/03/25', 12000000, 2, N'refunded', N'card', 1171, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.066'),
(125, 63, N'1405/03/19', 15000000, 2, N'refunded', N'installment', 1101, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.071'),
(130, 4, N'1405/02/20', 30000000, 1, N'pending', N'online', 1123, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.071');
GO
INSERT INTO dbo.[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt])
VALUES
(132, 72, N'1405/02/04', 20000000, 2, N'pending', N'card', 1061, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.077'),
(137, 60, N'1405/04/04', 20000000, 1, N'paid', N'cash', 1105, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.077'),
(138, 173, N'1405/01/10', 15000000, 3, N'paid', N'online', 1168, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.077'),
(139, 2, N'1405/06/12', 15000000, 2, N'failed', N'installment', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.084'),
(141, 148, N'1405/01/05', 15000000, 1, N'draft', N'card', 1171, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.084'),
(142, 66, N'1405/04/18', 30000000, 1, N'paid', N'online', 1074, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.084'),
(144, 24, N'1405/05/12', 25000000, 2, N'pending', N'other', 1048, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.084'),
(145, 24, N'1405/01/14', 15000000, 3, N'paid', N'card', 1048, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.084'),
(146, 79, N'1405/01/26', 10000000, 1, N'paid', N'other', 1128, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.084'),
(148, 1229, N'1405/05/11', 10000000, 3, N'partially_paid', N'cash', 1181, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.092'),
(149, 155, N'1405/07/01', 30000000, 2, N'paid', N'card', 1080, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.092'),
(151, 112, N'1405/06/07', 20000000, 2, N'pending', N'cash', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.092'),
(159, 4, N'1405/05/05', 30000000, 3, N'pending', N'other', 1123, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.099'),
(162, 84, N'1405/04/24', 8000000, 1, N'paid', N'cash', 1030, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.099'),
(163, 148, N'1405/03/13', 15000000, 1, N'paid', N'card', NULL, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.099'),
(168, 139, N'1405/07/26', 8000000, 1, N'paid', N'installment', 1148, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.106'),
(171, 98, N'1405/04/24', 12000000, 2, N'overdue', N'cash', 1164, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.106'),
(174, 163, N'1405/02/16', 30000000, 2, N'refunded', N'cash', 1102, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.112'),
(178, 2, N'1405/04/09', 5000000, 1, N'overdue', N'installment', 1064, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.112'),
(181, 173, N'1405/07/24', 300, 4, N'paid', N'installment', 1097, N'پرداخت نمایشی داشبورد', '2026-07-30 04:10:02.119');
GO
SET IDENTITY_INSERT dbo.[Payment] OFF;
GO

-- ===== DATA: Score (15 rows) =====
SET IDENTITY_INSERT dbo.[Score] ON;
GO
INSERT INTO dbo.[Score] ([Id], [RegistrationRef], [ExamType], [ScoreValue], [MaxScore], [Notes], [ExamDate], [CreatedAt], [StudentRef], [SuggestedLevelRef])
VALUES
(4, 1048, N'placement', 100.00, 120.00, NULL, N'1405/05/10', '2026-08-01 15:34:26.270', 24, NULL),
(5, NULL, N'placement', 8.00, 8.00, N'آزمون آنلاین تعیین سطح #1 — پیشنهاد: متوسط ۲', N'0431/05/09', '2026-08-01 15:48:25.497', 165, 10),
(6, NULL, N'placement', 8.00, 8.00, N'آزمون آنلاین تعیین سطح #3 — پیشنهاد: متوسط ۲', N'0431/05/09', '2026-08-01 15:55:44.724', 1254, 10),
(7, NULL, N'placement', 8.00, 8.00, N'آزمون آنلاین تعیین سطح #4 — پیشنهاد: متوسط ۲', N'0431/05/09', '2026-08-01 15:58:39.524', 1254, 10),
(8, NULL, N'placement', 7.00, 8.00, N'آزمون آنلاین تعیین سطح #6 — پیشنهاد: متوسط ۲', N'0431/05/09', '2026-08-01 15:58:58.454', 1248, 10),
(9, NULL, N'placement', 2.00, 8.00, N'آزمون آنلاین تعیین سطح #7 — پیشنهاد: مبتدی ۱', N'0431/05/09', '2026-08-01 15:59:10.810', 1237, 7),
(10, NULL, N'placement', 1.00, 8.00, N'آزمون آنلاین تعیین سطح #5 — پیشنهاد: مبتدی ۱', N'0431/05/09', '2026-08-01 16:00:57.097', 1245, 7),
(11, NULL, N'placement', 8.00, 8.00, N'آزمون آنلاین تعیین سطح #9 — پیشنهاد: متوسط ۲', N'0431/05/09', '2026-08-01 16:01:28.371', 1254, 10),
(12, NULL, N'placement', 0.00, 8.00, N'آزمون آنلاین تعیین سطح #11 — پیشنهاد: مبتدی ۱', N'0431/05/09', '2026-08-01 16:09:27.512', 1248, 7),
(13, NULL, N'placement', 10.00, 100.00, N'عالی', N'1236/01/01', '2026-08-01 16:10:00.642', 1245, 27),
(14, NULL, N'placement', 4.00, 8.00, N'آزمون آنلاین تعیین سطح #12 — پیشنهاد: مبتدی ۲', N'0431/05/09', '2026-08-01 16:12:17.554', 1234, 8),
(15, NULL, N'placement', 2.00, 8.00, N'آزمون آنلاین تعیین سطح #8 — پیشنهاد: مبتدی ۱', N'0431/05/09', '2026-08-01 16:13:11.781', 165, 7),
(19, NULL, N'placement', 7.00, 9.00, N'آزمون آنلاین تعیین سطح #15 — پیشنهاد: متوسط ۱', N'0431/05/09', '2026-08-01 16:17:04.100', 1253, 9),
(20, NULL, N'placement', 1.00, 1.00, N'آزمون آنلاین تعیین سطح #16', N'0431/05/09', '2026-08-01 16:20:51.256', 1254, NULL),
(1005, NULL, N'placement', 7.00, 9.00, N'آزمون آنلاین تعیین سطح #1002 — پیشنهاد: متوسط ۱', N'0431/05/11', '2026-08-03 15:01:53.017', 1214, 9);
GO
SET IDENTITY_INSERT dbo.[Score] OFF;
GO

-- ===== DATA: CourseHistory (2 rows) =====
SET IDENTITY_INSERT dbo.[CourseHistory] ON;
GO
INSERT INTO dbo.[CourseHistory] ([Id], [CourseRef], [ChangedBy], [ChangedAt], [FieldName], [OldValue], [NewValue])
VALUES
(7, 60, N'limdbadmin', '2026-07-29 16:06:32.440', N'Name', N'تست سایت', N'دوره فرانسه'),
(8, 60, N'limdbadmin', '2026-07-29 16:06:32.442', N'SessionsCount', N'1', N'24');
GO
SET IDENTITY_INSERT dbo.[CourseHistory] OFF;
GO

-- ===== DATA: AppUser (27 rows) =====
SET IDENTITY_INSERT dbo.[AppUser] ON;
GO
INSERT INTO dbo.[AppUser] ([Id], [Username], [Email], [PasswordHash], [FullName], [RoleRef], [StudentRef], [TeacherRef], [IsActive], [PreferredUILanguage], [FailedLoginCount], [LockedUntil], [LastLoginAt], [CreatedAt], [UiTheme])
VALUES
(1, N'admin', N'admin@lims.local', N'$2b$12$0xWSrEAPGlCkW/h5CLIB.uy6nZhwV2.cCzWh5OCPNHReEJEXef4em', N'مدیر سیستم', 1, NULL, NULL, 1, N'fa', 0, NULL, '2026-08-03 15:02:18.798', '2026-07-29 14:19:35.537', N'ocean'),
(2, N'secretary', N'secretary@lims.local', N'$2b$12$RV9jLmtTJhNjr/sNkQ64hu675SXe4c8fomO4DIcYBqlYB0D0ocbEm', N'منشی آموزشگاه', 3, NULL, NULL, 1, N'fa', 0, NULL, '2026-08-01 15:51:03.041', '2026-07-29 14:19:35.755', N'light'),
(3, N'user80375', NULL, N'$2b$12$Jeqejmg3sr6UXpx73y6T0eMMg6KJGHCnzork2QMQM67jyJvr/n1u2', N'آزمایش ثبت‌نام', 5, NULL, NULL, 1, N'fa', 0, NULL, NULL, '2026-07-29 14:54:21.987', N'light'),
(4, N'sref', NULL, N'$2b$12$OuqUZC6/TaYRIum1ggc0.u1cFz4jyikrIPXc2i3X2wot4r4MVNoZq', N'سجاد رفاقت', 5, 1213, NULL, 1, N'fa', 0, NULL, '2026-07-29 15:02:44.955', '2026-07-29 14:57:50.810', N'light'),
(5, N'وحید', NULL, N'$2b$12$g.EObASFJkXJ71AMVsKXJ.Auk9AyeXTSJAgTMPLqyiN5mcKdAw.4i', N'وحید مجیدی', 5, 1214, NULL, 1, N'fa', 0, NULL, '2026-08-03 14:55:36.314', '2026-07-29 14:59:07.704', N'midnight'),
(6, N'Ely78', NULL, N'$2b$12$WBgPLABGZMiKvPoZojNPaOGXF/DBlPWqAl86qCuMz8kTuOV0IEEJO', N'المیرا کرمانی', 5, 1226, NULL, 1, N'fa', 0, NULL, NULL, '2026-07-29 15:01:11.196', N'light'),
(7, N'مختار', NULL, N'$2b$12$U2hNAE4gZFlvdKs.Np3IM.v5NqsMkB63SXDNAFvt8uyIznrPMJypW', N'مختار ثقفی', 5, NULL, NULL, 1, N'fa', 0, NULL, NULL, '2026-07-29 15:23:33.521', N'light'),
(8, N'ELYAR', NULL, N'$2b$12$aSNvgMuSoDmS7JfY1cFIBOtniJUQ/tTGml8hvDPItabgI95J3MV1K', N'الیار نورنواز', 6, NULL, NULL, 1, N'fa', 0, NULL, '2026-07-29 16:01:51.827', '2026-07-29 15:50:42.397', N'light'),
(9, N'فردوسی', NULL, N'$2b$12$SiNGtw.F6U/tcg9GeY9T3ebn72DUEBjFaGl3xjtqppJnfObavwe7.', N'ابوالقاسم فردوسی', 5, NULL, NULL, 1, N'fa', 0, NULL, NULL, '2026-07-29 15:55:20.061', N'light'),
(10, N'Heli', NULL, N'$2b$12$JiPXEmoQ2jL7vjOT0AVV6Oxc7DVInjU8ldPk5iJbFV88JIC9GHy2.', N'هلما کاظمی', 5, 1234, NULL, 1, N'fa', 0, NULL, '2026-08-01 16:11:45.172', '2026-07-29 15:58:52.475', N'ocean'),
(11, N'arshya', N'arshyafraji1388@gmail.com', N'$2b$12$BwkCWaJPj2Bs1qcTSDiP0OMI.ne3XLWGntYKP9/A8azils.iKHKPe', N'arshya', 1, NULL, NULL, 1, N'fa', 0, NULL, '2026-08-01 16:17:49.097', '2026-07-29 16:16:22.206', N'dark'),
(12, N'ely@r', NULL, N'$2b$12$w2dWZxUBnPyTyMmu2bQG6eQMyvn2YlBwln6i.9rxEQOZ6iPPrefty', N'احمد نوری', 5, NULL, NULL, 1, N'fa', 0, NULL, NULL, '2026-08-01 13:48:55.473', N'light'),
(13, N'ابراهیم رئیسی', NULL, N'$2b$12$SdJvN0D7c96mugefxtw8z.x1t1beB.Zc3qYdkSeVL6MucXNOEcP9O', N'ابراهیم احمدی', 5, 165, NULL, 1, N'fa', 0, NULL, '2026-08-01 16:17:05.472', '2026-08-01 13:49:50.645', N'sunny'),
(14, N'ثمغ@ق', NULL, N'$2b$12$sbEgEG9Ninqc8MuxCC/eMOB8QyEYXtdcN7tREC73fKP10lik0THyy', N'الیار نورنواز', 5, 2, NULL, 1, N'fa', 0, NULL, NULL, '2026-08-01 14:04:44.574', N'light'),
(15, N'ely@r123', NULL, N'$2b$12$UWzEL1e3QkZ0EQWv2G9LJuljkBVGOAZFGQCxvQT/502ErJFXeGPYu', N'احد احدی', 2, NULL, NULL, 1, N'fa', 0, NULL, NULL, '2026-08-01 14:13:10.002', N'light'),
(16, N'Amir05', NULL, N'$2b$12$1a4bZoaNhObwD.MsByHui.YUzxYKTQ7mHMfqHvm4dhboTC1eRC0dW', N'امیر کاظمی', 3, NULL, NULL, 1, N'fa', 0, NULL, '2026-08-01 14:24:54.288', '2026-08-01 14:13:28.578', N'light'),
(17, N'arshya1', NULL, N'$2b$12$xgglMvI3CwsK.1sa4LO4neruRYmJdRBpZip5HRsBGzVYOge8aYX9C', N'تستa1', 5, 1237, NULL, 1, N'fa', 0, NULL, '2026-08-01 15:21:45.197', '2026-08-01 14:17:14.908', N'dark'),
(18, N'elyar1390', NULL, N'$2b$12$HiInauuvSBM8Pm5AohmwIucI4XGkYdwSID4F1/7VQtiyQKh.a5dDu', N'احمد احدی', 5, 161, NULL, 1, N'fa', 0, NULL, '2026-08-03 15:26:13.247', '2026-08-01 14:18:03.553', N'midnight'),
(19, N'zahra', NULL, N'$2b$12$CyHoBU6IbilnsPUtdBSlJ.3RWl6IOQ6bRLq00.LUbCicwwbAGebiS', N'Zahra Habibi', 4, NULL, 9, 1, N'fa', 0, NULL, '2026-08-01 16:18:47.529', '2026-08-01 14:21:44.671', N'rose'),
(20, N'sama', NULL, N'$2b$12$1oBLfNJ6pD2WxPtGFnAQoObDuL1LUzddyxkOhRMH70dAJa2Fgyyyi', N'سما عبادی', 5, 1248, NULL, 1, N'fa', 0, NULL, '2026-08-01 15:57:26.972', '2026-08-01 14:33:08.365', N'light'),
(21, N'مسئول امور مالی آموزشگاه', NULL, N'$2b$12$6TDSQ84pj3zgcoXPjVCq6u9Q3qTj6X/NaJ9GRd88gBsXiNMVe2z2C', N'ناشناس', 2, NULL, NULL, 1, N'fa', 0, NULL, '2026-08-01 15:58:03.145', '2026-08-01 14:40:49.315', N'dark'),
(22, N'Eli', NULL, N'$2b$12$50IVuIj7sX/2S84aqu4M1.db64MkCFH8lwi5mBf2ObZCVcMY550k6', N'الهام حبیبی', 4, NULL, 1, 1, N'fa', 0, NULL, '2026-08-01 14:50:08.177', '2026-08-01 14:44:04.932', N'light'),
(23, N'finance_test', NULL, N'$2b$12$sH3wMiJeWy3fzRzll/4OCey2pTRtlU9Tlba8vVlbrTxXdM.C4iBdW', N'تست مالی', 2, NULL, NULL, 1, N'fa', 0, NULL, '2026-08-01 14:54:52.445', '2026-08-01 14:54:52.223', N'light'),
(24, N'teacher_demo', NULL, N'$2b$12$WtQIW7ConZKD.lkaDaa0YOmDArMgPtWRbSmk8iH./E//FJl0/kaUy', N'مدرس دمو', 4, NULL, 9, 1, N'fa', 0, NULL, '2026-08-01 15:04:29.677', '2026-08-01 15:04:29.454', N'light'),
(25, N'Ali', NULL, N'$2b$12$HOt1sJswvdz3bAV5i.HGTuS5B8X773D2tTZ3QzdJn1IY3DUF60YzO', N'علی کریم لو', 4, NULL, 19, 1, N'fa', 0, NULL, '2026-08-01 16:06:14.706', '2026-08-01 15:21:21.310', N'ocean'),
(26, N'مسعود هستم', NULL, N'$2b$12$KczKSp1/XZ5TRZe1z/HbYOgO9t52wsRURRRj1PgKurXJMtGeZ9iaa', N'مسعود مهندسیان', 5, 1253, NULL, 1, N'fa', 0, NULL, '2026-08-01 16:12:41.519', '2026-08-01 15:50:32.099', N'midnight'),
(27, N'Mee', NULL, N'$2b$12$xt0mnD5Y7iENdq74Yqx2keENuDDIcwji31JNogvaT7v/VcgGcLJQu', N'مریم حسینی', 5, 1254, NULL, 1, N'fa', 0, NULL, '2026-08-01 16:20:43.342', '2026-08-01 15:54:42.481', N'ocean');
GO
SET IDENTITY_INSERT dbo.[AppUser] OFF;
GO

-- ===== DATA: UserSession (272 rows) =====
SET IDENTITY_INSERT dbo.[UserSession] ON;
GO
INSERT INTO dbo.[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt])
VALUES
(1, 1, N'a8cc4a950dd2ce1ef6b8f3c03977475ecbd9a062412c281c5391ff971ee9993d', '2026-07-29 14:33:13.411', '2026-08-12 14:33:13.410', NULL),
(2, 1, N'25225cc6aa688c1593cb17f6152db3c3d1f94b4099b5e221a81d927213196a04', '2026-07-29 14:42:23.574', '2026-08-12 14:42:23.572', '2026-07-29 15:06:18.171'),
(3, 1, N'8d47568a02b95b6cfd10ff8af13979a8ef07f2bcd86a42a67afa0d2595d76b62', '2026-07-29 14:42:55.475', '2026-08-12 14:42:55.475', '2026-07-29 14:50:02.901'),
(4, 1, N'c763c8b6c338782c8017d8bab5b3a4c9406a1785ae11c183e72477b631de64ae', '2026-07-29 14:43:47.820', '2026-08-12 14:43:47.818', '2026-07-29 14:44:15.262'),
(5, 1, N'42c783cae389d0c30dad21ad75bde546c0260f602f226fe2c3487c77c31449ac', '2026-07-29 14:43:58.565', '2026-08-12 14:43:58.564', '2026-07-29 14:50:16.877'),
(6, 1, N'139a869403637c944996aa038f1d09a67f8f4b664044f4a514a759bcfb4c8508', '2026-07-29 14:44:05.501', '2026-08-12 14:44:05.501', '2026-07-29 14:49:03.332'),
(7, 1, N'55d39fdf2fe35e162dabee1a6458fb8531c7a883a2a29610ad4edff8ff756229', '2026-07-29 14:44:25.379', '2026-08-12 14:44:25.379', '2026-07-29 14:50:13.516'),
(8, 1, N'b5a83864c17569bc01829cb10a31119bc3e2a21515e3bbe58f2243146c53917c', '2026-07-29 14:44:28.228', '2026-08-12 14:44:28.220', '2026-07-29 14:50:01.324'),
(9, 1, N'ea08b2aca419a4193e1b84b7d28891215182cd62d0ee7149e347e3e98dd16e0c', '2026-07-29 14:44:39.338', '2026-08-12 14:44:39.338', '2026-07-29 14:44:47.604'),
(10, 3, N'5bfd56f70a7b567e741f83b303133d42dc4cb9dff6b58cc38f6f1b179b172eb4', '2026-07-29 14:54:21.997', '2026-08-12 14:54:21.996', NULL),
(11, 1, N'9040bcf0e4df523c1d6d77db9785c587c8ed565074a326cb26f47e30d4c8e95f', '2026-07-29 14:55:44.856', '2026-08-12 14:55:44.856', '2026-07-29 14:58:19.108'),
(12, 1, N'12af6817185f965b2cce88c731c1e6a6e23c5d68049f41a620e1f014590e94a2', '2026-07-29 14:56:14.898', '2026-08-12 14:56:14.898', '2026-07-29 14:58:23.020'),
(13, 4, N'de69a4a0492ee0f7b02fc395e429719f16bf569f2e6789cb5015671bb73a8473', '2026-07-29 14:57:50.810', '2026-08-12 14:57:50.810', '2026-07-29 15:01:19.518'),
(14, 5, N'bd8733d7ae31d317461248cd9e7584646afea2da711e995698ec32675bb6e9ae', '2026-07-29 14:59:07.710', '2026-08-12 14:59:07.710', '2026-07-29 15:01:29.185'),
(15, 6, N'06dd18cfe9d7f2c59324873f7bcedcc281f7bc681ef7015b9fc035f3ec46b259', '2026-07-29 15:01:11.196', '2026-08-12 15:01:11.196', '2026-07-29 15:04:30.008'),
(16, 5, N'3a74d6fffe32f2d570eda848db715954b5689a5b408ea981c9e09c98fc9cd9eb', '2026-07-29 15:01:31.208', '2026-08-12 15:01:31.208', '2026-07-29 15:04:43.302'),
(17, 4, N'b371cdbe2f1fb14351fa51d4c6023fe025bfc9b956e14a024f5f4ddd85a57a07', '2026-07-29 15:02:44.959', '2026-08-12 15:02:44.957', '2026-07-29 15:04:18.414'),
(18, 1, N'fd030ea39823adcfbe70732c797f23a4cb4e64625e7acaf4eff72944b7c5002f', '2026-07-29 15:03:12.081', '2026-08-12 15:03:12.079', '2026-07-29 15:03:32.528'),
(19, 1, N'34b2717f409712494d6e025d0e01ad61b99d84bc4b084380cb8488da0ce0b728', '2026-07-29 15:06:15.690', '2026-08-12 15:06:15.690', '2026-07-29 15:48:57.323'),
(20, 1, N'cf7083f357e010c17fb67c45662e13ffbd9d85b74ae803d46dbd2370f02e2282', '2026-07-29 15:06:16.271', '2026-08-12 15:06:16.265', '2026-07-29 15:53:08.183'),
(21, 1, N'6c3e9314a4fe3c07bdffd034ef8c1b7cd0d87edd17e2ef945fcbc48b74402b1f', '2026-07-29 15:06:44.881', '2026-08-12 15:06:44.877', '2026-07-29 15:54:08.081'),
(22, 1, N'292f4a03b8435aba9077158f63a273a9b69f9ca9752a6d8bd1decc2549c47900', '2026-07-29 15:07:28.198', '2026-08-12 15:07:28.189', '2026-07-29 15:13:24.763'),
(23, 1, N'0f906ddb6d5fdfd5ced61e3fc5cbb5332865594b52f4ad859ea1242b09d1c34f', '2026-07-29 15:07:36.694', '2026-08-12 15:07:36.692', '2026-07-29 15:50:17.696'),
(24, 1, N'45291f11af269768c0bfc9c075d1c3d8c53ce74dac8a73fa68035ae7af946649', '2026-07-29 15:15:04.037', '2026-08-12 15:15:04.037', NULL),
(25, 1, N'6aafaef68267cc1c040e75a1a708ce572e04861a92afdf0371d0bbeb1295af63', '2026-07-29 15:15:18.452', '2026-08-12 15:15:18.450', NULL),
(26, 1, N'6d6c036e53981df535866a23d3a5dad84a22c86101a08fab4901441f6bae9338', '2026-07-29 15:15:42.865', '2026-08-12 15:15:42.865', NULL),
(27, 1, N'cc233de76500e954978c35bb23b7df2658f5f3ba90be8f3eaf9de2ec2524ece9', '2026-07-29 15:16:19.991', '2026-08-12 15:16:19.986', NULL),
(28, 1, N'0f8673f78f962124be4cf82228a46c5dfcabef6965aa8ac24495597c4ff7a893', '2026-07-29 15:16:49.186', '2026-08-12 15:16:49.186', NULL),
(29, 1, N'02450ef0612294ce6badabc4518bde62b0e3014c03f64c40fc534fd097917b5c', '2026-07-29 15:18:16.908', '2026-08-12 15:18:16.908', NULL),
(30, 1, N'567ccbcb4718b8f65f39ae4700b836fa3865226535d55604b9f51dd4ab13687c', '2026-07-29 15:19:36.804', '2026-08-12 15:19:36.804', NULL),
(31, 1, N'018d36e11a08e0adbeda43c41d1335be4a2384dd728e27d242ba9a51a6491d71', '2026-07-29 15:20:10.738', '2026-08-12 15:20:10.738', NULL),
(32, 1, N'84e3ecd6c14997c74692e10f871779ab2d1c3b84787ce88de4113cacfb676626', '2026-07-29 15:20:11.201', '2026-08-12 15:20:11.200', NULL),
(33, 1, N'a212c8e154afb218667226eb4db07fb7034e1662025c745e73bf079c568417f5', '2026-07-29 15:22:12.443', '2026-08-12 15:22:12.442', '2026-07-29 15:27:18.910'),
(34, 7, N'bfc1cf98832fb55c08cbd5fae2d0a963207143aac36311789b8700d5d32f3311', '2026-07-29 15:23:33.525', '2026-08-12 15:23:33.523', '2026-07-29 15:24:20.223'),
(35, 1, N'1232ef5e5dcd875912fb12527859f563832c07e9d988e92e742f3906412a5468', '2026-07-29 15:24:22.447', '2026-08-12 15:24:22.447', '2026-07-29 15:53:00.893'),
(36, 5, N'87747b17d56aa6babd2bda1d2767439d498f9f5cc0c40784d1eb66d10c03ed4b', '2026-07-29 15:27:27.526', '2026-08-12 15:27:27.523', '2026-07-29 15:30:50.636'),
(37, 1, N'80dafbb75ee3e2cce166dbc5e41eeb8262b262abe4453cc03e09eb54437b35ce', '2026-07-29 15:33:13.482', '2026-08-12 15:33:13.482', '2026-07-29 15:53:06.859'),
(38, 1, N'16ccce054e56683a91f049f0e6da129a290377b4112aa71f1d445e969c26a03a', '2026-07-29 15:34:07.497', '2026-08-12 15:34:07.497', NULL),
(39, 8, N'9d4c7d355034999d93c66edecf36831c1dc7b8c351cab306e552beb6531bf00c', '2026-07-29 15:50:42.401', '2026-08-12 15:50:42.401', '2026-07-29 15:51:51.746'),
(40, 1, N'0442d60003ff0ad7b44d2196d16437229d6ab677f5b8c385aee51dd412319dd2', '2026-07-29 15:52:48.072', '2026-08-12 15:52:48.068', '2026-07-29 16:01:36.800');
GO
INSERT INTO dbo.[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt])
VALUES
(41, 1, N'dabd1af4edff9fd91bec5d84a7438d23e5fce2682cecf43a60eb02ee1f35b9c6', '2026-07-29 15:53:47.184', '2026-08-12 15:53:47.183', '2026-07-29 16:15:43.096'),
(42, 1, N'2134041a7ed1afa1442e5544bf92936e816338ed3b24ce9d6ebe754def2d23a7', '2026-07-29 15:54:05.935', '2026-08-12 15:54:05.935', NULL),
(43, 1, N'e4828af6d649eeb2d4d4a1989874a9eaa484d85babfeb4cfd409e0c50e88a9d9', '2026-07-29 15:54:24.852', '2026-08-12 15:54:24.852', '2026-07-29 15:56:22.961'),
(44, 9, N'98bd90051012c04e9fa6f26c0d9565556ff505565cea12a2902ece7c96d69dc3', '2026-07-29 15:55:20.066', '2026-08-12 15:55:20.063', '2026-07-29 15:56:21.088'),
(45, 1, N'e3e7f202b6aea004f37d1c6852238f1dcf6e3329fe6b0cdb269935e52fd0110d', '2026-07-29 15:55:30.360', '2026-08-12 15:55:30.360', NULL),
(46, 1, N'8a412d264be74fa6d18ae2f3d2469f259881de18564cec767c5623edbdff1b64', '2026-07-29 15:56:22.787', '2026-08-12 15:56:22.783', NULL),
(47, 10, N'7d5ee298cd63613594eb6c2aa7202e87291e775570cb94bd1c85de534cd9483f', '2026-07-29 15:58:52.487', '2026-08-12 15:58:52.483', '2026-07-29 16:01:35.202'),
(48, 8, N'f544c12862c57a40b3ea18918e920f43cec80514dc15a714415bb412a41430a0', '2026-07-29 16:01:51.832', '2026-08-12 16:01:51.829', '2026-07-29 16:02:31.004'),
(49, 1, N'153b00cb27e87615faa28f9eda178a22a6b8610a55a8b3aa58a7a88396a58176', '2026-07-29 16:02:22.641', '2026-08-12 16:02:22.637', NULL),
(50, 1, N'4b70121aa1e4565bc82bfc4e76e0e66e979c38f5cd11fc895684d4d5a22e70ef', '2026-07-29 16:02:36.614', '2026-08-12 16:02:36.612', '2026-07-29 16:07:13.881'),
(51, 1, N'3f22312473197017c25beed509d6b668119b930ed697a9a115c0668f87f463a4', '2026-07-29 16:09:04.396', '2026-08-12 16:09:04.396', '2026-07-29 16:15:13.408'),
(52, 11, N'a61015c290d64d47270c2de4b6632bbd2dfaab57b0f99d8b0e1413aa4ccd6ecf', '2026-07-29 16:16:22.212', '2026-08-12 16:16:22.206', '2026-07-29 16:16:27.492'),
(53, 11, N'782d8765d2f0881164cf927ab438563888f423190a2ed03d6a6a4245d97b6f72', '2026-07-29 16:16:42.872', '2026-08-12 16:16:42.869', '2026-07-29 16:16:48.945'),
(54, 11, N'9cf9ba1e37f9c4b4fa0d7c5299bef7c8aa07461dc55aacfcc8cd979fe52005f5', '2026-07-29 16:17:14.524', '2026-08-12 16:17:14.524', '2026-08-01 13:58:02.684'),
(55, 1, N'eed6bc05b4756ebac0c10187802766f1bfdf8d57c0dc60b0a70b5bc6bb1f468d', '2026-07-29 16:22:53.043', '2026-08-12 16:22:53.041', NULL),
(56, 1, N'3b08fb1d335d3532c8322efa18ebab87510111b949544777817a15c6adf06485', '2026-07-29 16:24:11.278', '2026-08-12 16:24:11.278', NULL),
(57, 1, N'8625c7a1a3ef9ef5bb44bf76a9eab95f955750ff1f349ad23e6b2190d76194a9', '2026-07-30 03:53:38.610', '2026-08-13 03:53:38.610', NULL),
(58, 1, N'3ef25cdaf57c25753d9fd0dc3a55204dc8c21f9ee42fa983892bf18709ef33d9', '2026-07-30 03:54:24.271', '2026-08-13 03:54:24.268', NULL),
(59, 1, N'cbed74825631f53de5e55613f6251ee37dd736c501c90ccaa01387aed1905c14', '2026-07-30 04:10:16.982', '2026-08-13 04:10:16.980', NULL),
(60, 1, N'84905b8ad167ec60a49be1d6d0a8c1f8f3f770d3df89351fa4c34d3158621152', '2026-07-30 04:10:48.066', '2026-08-13 04:10:48.064', NULL),
(61, 1, N'926c380e00ee1a85ce7a778f23a4fa5dd8dd39151de091ca6d5920e70f435851', '2026-07-30 04:11:03.714', '2026-08-13 04:11:03.714', NULL),
(62, 1, N'912a17280d0a6df7b3ec19b17917af3bfcf5e3e6ae2515cb15c6e6a05092bf07', '2026-07-30 04:12:05.520', '2026-08-13 04:12:05.514', NULL),
(63, 1, N'a5dc879c155a8cd13d403e6e51515076039860894d26e7d8075ab35d5f97a70b', '2026-07-30 04:12:37.857', '2026-08-13 04:12:37.857', NULL),
(64, 1, N'cc1f425425b740c5237f816da50ef8c4deccd030585b1c204196db2d284b1d3e', '2026-07-30 04:12:53.606', '2026-08-13 04:12:53.600', NULL),
(65, 1, N'e205ff5be66ab699bafa8ff2b66e4c7b4ee33ca64aeb03f4afe62efa8ccd54fc', '2026-07-30 04:14:06.516', '2026-08-13 04:14:06.516', NULL),
(66, 1, N'75668e8850fe34e2d129d70be4bc866f1db9685b592630ea539e8e8f0f2b088f', '2026-07-30 04:54:54.911', '2026-08-13 04:54:54.911', NULL),
(67, 1, N'9dd33d557667310e700b580f4f946daece3af19c69ff1e5f3eee9d059ecb3c30', '2026-07-30 04:55:30.977', '2026-08-13 04:55:30.977', NULL),
(68, 1, N'f6d2e4ccf7b185739cc7213e14660613ff7da73df3cebdf1d48f151d04707c5e', '2026-07-30 04:56:00.332', '2026-08-13 04:56:00.329', NULL),
(69, 1, N'253778a7fac5b77a3088e97450cd91ce6554c14c6d7c2c846faa7b48239ba394', '2026-07-30 04:56:28.848', '2026-08-13 04:56:28.848', NULL),
(70, 1, N'7adfc43b10369df4d47b1beefc5bc9bec57d9f94221c56f0c6ce8185ea36d42d', '2026-07-30 04:56:55.537', '2026-08-13 04:56:55.533', NULL),
(71, 1, N'291594f8d87ce264843f27431fad140fa3cb292563f0f4046c25e8b256eed779', '2026-07-30 04:59:52.591', '2026-08-13 04:59:52.585', NULL),
(72, 1, N'345de72ad0fb4de061c7c00bcf8dd730062d147647dab992fd388a94b9e69c28', '2026-07-30 05:00:20.787', '2026-08-13 05:00:20.780', NULL),
(73, 1, N'3e4527dcb4666cdc192dbde1da6b9052d525f62591f852d2cd9d1527fe58f373', '2026-07-30 05:00:45.032', '2026-08-13 05:00:45.032', NULL),
(74, 1, N'31b620a3443095ddc18ce188c047418a8268a77a5c45cc748b8f2e0dfc8ae337', '2026-07-30 05:04:01.994', '2026-08-13 05:04:01.991', NULL),
(75, 1, N'9c8e8652f027661976206920b6f5e90e6bac9f4cd05a7a67c78acee808a06309', '2026-07-30 05:04:47.580', '2026-08-13 05:04:47.577', NULL),
(76, 1, N'7811991d42ed98e20f9f1b910b6f0333288b6fff7b98440675dec569054b45ff', '2026-07-30 06:04:07.760', '2026-08-13 06:04:07.757', NULL),
(77, 1, N'857dbb5c557ed48ed062a2b729e3d436e23412142a846a866cb79b55ff66b2a3', '2026-07-30 09:48:32.614', '2026-08-13 09:48:32.614', NULL),
(78, 1, N'fcf8fdb334f3fc07068f465a6c8e8755b5cdaebb845b6fb3f71e5b5a73cade1e', '2026-08-01 13:35:19.782', '2026-08-15 13:35:19.781', NULL),
(79, 1, N'26e9214dd1da9f45d8422f337f16a37c354a9eea61d00a063e00b01867f314a1', '2026-08-01 13:38:13.885', '2026-08-15 13:38:13.885', '2026-08-01 14:09:19.557'),
(80, 1, N'b465e4fbd4d1a6d4b173db65d5c53a1f0bec1113d2a8f1541ffc39f49d48a6c5', '2026-08-01 13:38:16.977', '2026-08-15 13:38:16.977', '2026-08-01 13:45:31.513');
GO
INSERT INTO dbo.[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt])
VALUES
(81, 1, N'324780754bbf8ce310a323205b02a6eba59f83f5e2393285b0f27f2b92c4beca', '2026-08-01 13:38:55.105', '2026-08-15 13:38:55.105', '2026-08-01 13:58:29.638'),
(82, 1, N'e0b5e802d2d19e1c62aeed9ae785af6b9ebbd44f5bcd8b207e879c16b70de4f4', '2026-08-01 13:42:24.972', '2026-08-15 13:42:24.967', '2026-08-01 13:46:33.596'),
(83, 1, N'626236fcfa4b25d28a2b3d94c6db7c44464e71051d3b2b721790d05fccf73c59', '2026-08-01 13:46:24.397', '2026-08-15 13:46:24.397', NULL),
(84, 12, N'821259a921fd14f2378f753cbf0cef80d6b262d8a0e16eb33c797e4d654b51a9', '2026-08-01 13:48:55.481', '2026-08-15 13:48:55.478', '2026-08-01 13:50:55.441'),
(85, 13, N'119a20917436ac16fc006fd64bd825d19621c01417fb36a0e99890f026c0c962', '2026-08-01 13:49:50.649', '2026-08-15 13:49:50.649', '2026-08-01 13:56:08.570'),
(86, 1, N'7367a440720a7692f6099e3ab960024ea2e17a0f7dd299734a381fecabbfe293', '2026-08-01 13:51:44.390', '2026-08-15 13:51:44.388', '2026-08-01 14:02:00.260'),
(87, 1, N'2b7e80e3dbd7c81830d93ca6245955e74e2bf3cadaccb72e604d9ce3389652ec', '2026-08-01 13:55:10.401', '2026-08-15 13:55:10.397', '2026-08-01 14:20:47.304'),
(88, 1, N'1bbbf9279b94ada882ee2bf7df8ced8fab02c1c077c572ac720ce6b933b34f18', '2026-08-01 13:56:31.528', '2026-08-15 13:56:31.526', NULL),
(89, 11, N'37fb3c3b4050baeb58a21793a8fbe95b4d76a476d930514c5d3927503e41c661', '2026-08-01 13:58:41.806', '2026-08-15 13:58:41.806', NULL),
(90, 1, N'e14614fa783e19d85862f260f726fecb586e2cfead850d142177f5ac233d1817', '2026-08-01 13:59:25.106', '2026-08-15 13:59:25.106', NULL),
(91, 1, N'76a18fd83d450b75f8cbd3ab4156aab2ff8431888d978dac825a066bc967e486', '2026-08-01 14:00:22.548', '2026-08-15 14:00:22.546', NULL),
(92, 11, N'99239691c30742ca49f3f8f565f02f3bfb6df8fe84066073a1673690820c81c1', '2026-08-01 14:00:22.759', '2026-08-15 14:00:22.759', '2026-08-01 14:23:41.917'),
(93, 1, N'b76a08f965c320e7c9fb55d4103873054bbaee5310facae4b1412fc8134725cf', '2026-08-01 14:00:52.114', '2026-08-15 14:00:52.110', NULL),
(94, 1, N'eff07a54b8d1ea7d4597d52109db007bf97f3bf35e34fd6cb5fafe7f5b183d78', '2026-08-01 14:01:21.248', '2026-08-15 14:01:21.246', '2026-08-01 14:05:44.484'),
(95, 1, N'dc0b1daeb2e220680d71abdd9d9c66e6027d809cce4fbedbaafe4584b00b3724', '2026-08-01 14:01:26.323', '2026-08-15 14:01:26.322', NULL),
(96, 11, N'9dc3b1038e55440ef7b935da9c0845d50609d67ed539e74cbce1ddcc76aa87d5', '2026-08-01 14:01:46.091', '2026-08-15 14:01:46.091', '2026-08-01 14:08:40.584'),
(97, 1, N'207db1a5f1748122d4f368652e55b59416119641bb0a76edfef4b30d768ae6bf', '2026-08-01 14:03:33.115', '2026-08-15 14:03:33.112', '2026-08-01 14:11:53.517'),
(98, 13, N'45acc87088a7791156b79fbcb45e78b9d1bfd4c9244a53c132c6d4feab2c0aa1', '2026-08-01 14:06:14.616', '2026-08-15 14:06:14.616', '2026-08-01 14:09:01.125'),
(99, 1, N'0a06756ff9e77fe579a1e43996a2b711092b5cb2155d92dddccf2cbd4291539c', '2026-08-01 14:09:04.791', '2026-08-15 14:09:04.791', '2026-08-01 14:15:27.856'),
(100, 1, N'e6e8403e59a532dd9dabd86eff733307f56efbcdcbf263531a736e2d1295f800', '2026-08-01 14:10:23.438', '2026-08-15 14:10:23.437', NULL),
(101, 11, N'3fba14d3887bcd9e7cf216eec9d2e4753a6a3e7497f0e6992e38ebef925ac87b', '2026-08-01 14:11:20.013', '2026-08-15 14:11:20.012', '2026-08-01 14:20:53.017'),
(102, 15, N'4e46ee294d48f7a0a63de3fee6f695bef61aac519136f89ca9a5ff81ae18d563', '2026-08-01 14:13:10.008', '2026-08-15 14:13:10.002', '2026-08-01 14:15:16.812'),
(103, 1, N'01fa72e6b8b639d562834b521c6e7b9c9bf78868650f2defff5c2b1e2c8d158f', '2026-08-01 14:13:25.227', '2026-08-15 14:13:25.223', NULL),
(104, 16, N'a78d21bfc25b9ae94b47c2c4ca409415264c9629915ec52c0e39e2f65be190ff', '2026-08-01 14:13:28.581', '2026-08-15 14:13:28.581', '2026-08-01 14:24:33.999'),
(105, 1, N'3d4fd50c9ea9a99b3b62c0161eb8920306bfa103f9a53bece680dc37b681afe5', '2026-08-01 14:13:34.955', '2026-08-15 14:13:34.955', NULL),
(106, 1, N'4356a4f378f7f237c0190a699b77dddcdd266e7bc2bca1bdb7443fc6e0a264a1', '2026-08-01 14:14:25.192', '2026-08-15 14:14:25.192', NULL),
(107, 1, N'2cb22fbfbfba0eb33bb4bcb57987358a7e89a63cc9f91997753d50c0d48c34c6', '2026-08-01 14:14:38.239', '2026-08-15 14:14:38.239', NULL),
(108, 1, N'c67d5f35cb7cfd17efc7c82da68d59943f4e96d06c174ad87b3ef355a18a00aa', '2026-08-01 14:15:05.839', '2026-08-15 14:15:05.834', NULL),
(109, 13, N'50f32f1596fbd2d6a48881cdf9efd51a71696c00a29b60aed334cd84fef300f8', '2026-08-01 14:15:30.779', '2026-08-15 14:15:30.777', '2026-08-01 14:22:27.162'),
(110, 18, N'20c2ef64695bf08e46548375191bc3530c458442b83f799e8b655e0ad9b0049a', '2026-08-01 14:18:03.563', '2026-08-15 14:18:03.560', '2026-08-01 14:19:49.796'),
(111, 1, N'5de8e92657d8b27cda24c1553796ed8f887213d39d3b257d32a53122ec37de99', '2026-08-01 14:18:49.483', '2026-08-15 14:18:49.482', NULL),
(112, 1, N'1d49c9c7fda968c3a5533b7f77535ad5fdd4f82685d5e9a53d6c820a53f47dfc', '2026-08-01 14:19:53.748', '2026-08-15 14:19:53.748', '2026-08-01 14:20:07.287'),
(113, 18, N'096c66fe8f62e97187d4bcd2d7092c61cee2a4d49fb79e5d0abed0b7f7df74c9', '2026-08-01 14:20:11.442', '2026-08-15 14:20:11.442', '2026-08-01 14:20:17.582'),
(114, 1, N'6d4bf83e95e6780fd15f7c4ac8d17c201fc8cd05adcaecc82eb8b8086e5c98ab', '2026-08-01 14:20:21.329', '2026-08-15 14:20:21.329', '2026-08-01 14:21:12.063'),
(115, 17, N'6f6b5929ea7626ac0cf4e2bf95f4a493eabe901ada5661475aa6498e5ee781c1', '2026-08-01 14:20:59.030', '2026-08-15 14:20:59.030', NULL),
(116, 18, N'25f659911dcc69f47639c6a71a1fe4f39b85bba6f5018621ee5eb3640f8ab464', '2026-08-01 14:21:15.644', '2026-08-15 14:21:15.644', '2026-08-01 14:21:20.991'),
(117, 1, N'ba16c43264c3ffc01a5386cf90d00260dc0b3a8231163a9eea2b13d611312c66', '2026-08-01 14:21:24.617', '2026-08-15 14:21:24.617', '2026-08-01 14:21:38.790'),
(118, 18, N'8ac364f147728f09b30dc8301a3c6aa9884284acc083c4cba7857bbe0723dbfe', '2026-08-01 14:21:44.117', '2026-08-15 14:21:44.117', '2026-08-01 14:21:58.973'),
(119, 1, N'2b372900098bde49c2c749a5ab60b115fc5ea9ba42c9fb59733f8ddf0ae9eb11', '2026-08-01 14:22:02.784', '2026-08-15 14:22:02.784', '2026-08-01 14:22:25.069'),
(120, 18, N'6498693aa9f07e9000ce1639079f30f6b5fd7c286d5089431409324a9f361c2a', '2026-08-01 14:22:28.375', '2026-08-15 14:22:28.375', '2026-08-01 14:23:12.265');
GO
INSERT INTO dbo.[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt])
VALUES
(121, 1, N'8ed0792c4ff48f4c266b69f85c7d892d2655d9f21d55f923c40426a54affb947', '2026-08-01 14:22:30.661', '2026-08-15 14:22:30.661', '2026-08-01 14:23:15.264'),
(122, 19, N'7b886b8fccc8935a1fca73b9e51fa6a49aa69404b6266dfc008acbff7e05c252', '2026-08-01 14:22:37.168', '2026-08-15 14:22:37.168', '2026-08-01 14:30:24.560'),
(123, 1, N'f52c607bbcdbc65bef024f39b592da891b575aa740442e05baf946863fa992b7', '2026-08-01 14:23:15.264', '2026-08-15 14:23:15.264', '2026-08-01 14:24:32.433'),
(124, 13, N'7ac334de20f11c64fd1e5b21c60634583f7d6e190246207dd0ce51893cc1eda2', '2026-08-01 14:23:18.482', '2026-08-15 14:23:18.482', '2026-08-01 14:37:15.090'),
(125, 18, N'6dbd55fe8bdd0638d307d4a23388d18c6d171d1d4d2634e580a137283dbcc70c', '2026-08-01 14:24:35.503', '2026-08-15 14:24:35.503', '2026-08-01 14:25:11.116'),
(126, 16, N'4bac29f81e48c6511b93f06891e42aa90a07bc2ce7101ea0122812da5714522a', '2026-08-01 14:24:54.288', '2026-08-15 14:24:54.288', '2026-08-01 15:16:20.627'),
(127, 1, N'1fc4a2b35f8fe4e790a22623d7d26a0d2aed65994489a5fb4d4125e6e39d57f5', '2026-08-01 14:25:14.110', '2026-08-15 14:25:14.105', '2026-08-01 14:26:11.678'),
(128, 18, N'e2635fabacac64f38352c8497b82fd4800f083bce48c6eb50ccfe28ee8166905', '2026-08-01 14:26:17.969', '2026-08-15 14:26:17.968', '2026-08-01 14:27:22.964'),
(129, 1, N'52ac322b4f0a5048fea73177f4ca9f6b5e3abe4fd36a10e1a3baa5d8f0f04549', '2026-08-01 14:26:49.006', '2026-08-15 14:26:49.006', NULL),
(130, 1, N'6379d62005c8c25e616da145184abc91ee88680d5cd54c9bdfc0967bc02b8afe', '2026-08-01 14:27:26.325', '2026-08-15 14:27:26.323', '2026-08-01 14:30:39.960'),
(131, 17, N'f41ae89c0f91eaeebd2cabd03dd7ef456c9ab82e572d9e0a23a6f0d6322941a2', '2026-08-01 14:28:26.206', '2026-08-15 14:28:26.206', '2026-08-01 14:28:33.504'),
(132, 11, N'ef94ca37340947127406a2033b21f247841a02f34cf37c8802087d939b95bc89', '2026-08-01 14:28:36.925', '2026-08-15 14:28:36.925', '2026-08-01 15:03:00.139'),
(133, 1, N'3b7cdb820c372b04f6ad6d0fd1d176cf011e52cb2ab28f0cf0a4002e7df5a5b6', '2026-08-01 14:28:50.186', '2026-08-15 14:28:50.186', NULL),
(134, 18, N'9ccb012ec43eee1c57d09599815a511ac819c3a390048084096ac7ca3bcc239c', '2026-08-01 14:30:44.459', '2026-08-15 14:30:44.452', '2026-08-01 14:31:42.058'),
(135, 1, N'99b4f718d258930329d86b7dc3b5e1eaa7b083607a312ee78bb603994090da61', '2026-08-01 14:31:45.118', '2026-08-15 14:31:45.111', '2026-08-01 14:32:46.736'),
(136, 18, N'03b525e2799fa32507a0e89e136a2790e055cf85071350d6fcf2c50437ff65f1', '2026-08-01 14:32:49.349', '2026-08-15 14:32:49.349', '2026-08-01 14:32:57.883'),
(137, 1, N'c6683ad6efe9c50bc1cb8d0734a4452011259bdf4f49a0caf2e621b1794dade7', '2026-08-01 14:33:01.284', '2026-08-15 14:33:01.284', '2026-08-01 14:33:32.521'),
(138, 20, N'afe65b7f30ff29d6e5bdfb117a1cc2fa187b2b2addebb3515b6e38e0907bdb47', '2026-08-01 14:33:08.368', '2026-08-15 14:33:08.368', '2026-08-01 14:37:41.128'),
(139, 18, N'a43ffbf17ba1e4b5b7507cbc50a93743f04e01acc02dcacd893da0771cd2820e', '2026-08-01 14:33:46.931', '2026-08-15 14:33:46.931', '2026-08-01 14:34:20.043'),
(140, 1, N'28bf62c18f2e7e564c05c091514db39e6c145529e2296b3d4cef7f7c49e44098', '2026-08-01 14:34:24.320', '2026-08-15 14:34:24.320', '2026-08-01 14:37:09.288'),
(141, 1, N'a75a0d1484234828916cbcd2e5021bcf4409473b14464765ba61ca4c2489d5cb', '2026-08-01 14:37:19.357', '2026-08-15 14:37:19.353', '2026-08-01 14:42:41.935'),
(142, 1, N'e1e775ac9f10a4bf08ac6b85386dc8680188ee3e5f1b04bbad485743756e46f6', '2026-08-01 14:37:23.656', '2026-08-15 14:37:23.656', '2026-08-01 14:40:53.359'),
(143, 1, N'a7888d67e1e5b90bb5cd38202bc70aa10a723299cc4a49887742966aa6602fe6', '2026-08-01 14:37:48.780', '2026-08-15 14:37:48.780', '2026-08-01 14:41:22.125'),
(144, 20, N'f7affb6d91a92e2cebaf30d5ac3497b50f290c26d6d59fb8ea936c03a1167ff6', '2026-08-01 14:38:04.747', '2026-08-15 14:38:04.747', '2026-08-01 14:42:40.350'),
(145, 1, N'8dc161c7f86315eed06dffd417900be614eb8936fbcf8071601632f3a7cdc33e', '2026-08-01 14:39:56.024', '2026-08-15 14:39:56.020', NULL),
(146, 21, N'7d7131a29054579cd1e7d75f26ed438f2af7a07f8d752aa138b6535f167c4ab8', '2026-08-01 14:40:57.008', '2026-08-15 14:40:57.005', '2026-08-01 14:41:31.586'),
(147, 1, N'c6086c1a7612e7cd7ce0d06f1a52f148b8e9969eb95c177e6f9d6fd3f86b4e2a', '2026-08-01 14:41:35.358', '2026-08-15 14:41:35.356', '2026-08-01 14:42:40.709'),
(148, 1, N'969f7f896f86a8f04ef235ff168c79b5f0fb51f39a28643a742bb565b1d87d24', '2026-08-01 14:42:51.356', '2026-08-15 14:42:51.353', '2026-08-01 14:47:41.908'),
(149, 1, N'be3da392e42f71e569bcbb26907708d67773ed6b070dfcd1ff365458d846f5dd', '2026-08-01 14:42:56.984', '2026-08-15 14:42:56.983', '2026-08-01 14:45:30.904'),
(150, 1, N'c23d57a27e10c648c46f8ad986e0d4ecf08d110d2532690067da4959663f6f86', '2026-08-01 14:42:58.038', '2026-08-15 14:42:58.038', '2026-08-01 14:46:20.549'),
(151, 22, N'f0b308b04b7e41ae93cad004f55d1259c45250eb482006b357fd70e8175a75ec', '2026-08-01 14:44:04.938', '2026-08-15 14:44:04.934', '2026-08-01 14:44:14.400'),
(152, 1, N'22e86abfaaf3e96a8a14aa473b6ea324694cad7d4248554702581719fcea6120', '2026-08-01 14:44:37.009', '2026-08-15 14:44:37.009', '2026-08-01 14:45:03.604'),
(153, 22, N'82630fc0bc9448debd4887827e7646c9a010609c08da320defc4c90515c9ce86', '2026-08-01 14:45:13.875', '2026-08-15 14:45:13.871', '2026-08-01 14:46:48.059'),
(154, 18, N'1f0a2974faa073d8ad772b148d06f34d8c71023b59c950e5f97392140c331802', '2026-08-01 14:45:34.113', '2026-08-15 14:45:34.111', '2026-08-01 14:46:38.806'),
(155, 1, N'a4d3825e35338546418933d6d31485c324149bf26cfb1ce12672e10f257f14bf', '2026-08-01 14:46:36.088', '2026-08-15 14:46:36.086', '2026-08-01 14:49:51.219'),
(156, 1, N'0ac0203dfec4405e3fc9cedf1114c95da461bb27146402bcb22afd999be7436b', '2026-08-01 14:46:43.907', '2026-08-15 14:46:43.907', '2026-08-01 14:54:15.152'),
(157, 1, N'411df5606bf132b6c574d17509dec26921d70c59dc29387c7abf1ee292f6aa0b', '2026-08-01 14:47:22.510', '2026-08-15 14:47:22.509', '2026-08-01 14:47:47.708'),
(158, 22, N'b5738cb8b441e4f57b42d75e67b479b7295196b84fffab150c19c951143a5f05', '2026-08-01 14:47:59.186', '2026-08-15 14:47:59.186', '2026-08-01 14:49:18.074'),
(159, 20, N'3255cbb95af701d35db88ec749fee3022ccd2324ff3b65070a7a7b62b107fb3f', '2026-08-01 14:48:18.784', '2026-08-15 14:48:18.782', '2026-08-01 14:52:56.690'),
(160, 1, N'6b41b82c9c02db5926ac2ce6df4f974994f53275cab8e5c5da947e3e28fd38ba', '2026-08-01 14:48:40.757', '2026-08-15 14:48:40.757', NULL);
GO
INSERT INTO dbo.[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt])
VALUES
(161, 1, N'2c6d7dcc41dff1af6b165f7e481a92b421ec0a184ca7d1cdfcc237b30c11665f', '2026-08-01 14:49:22.637', '2026-08-15 14:49:22.637', NULL),
(162, 1, N'a77e1c86dfc7b03ff663d07449802c11bb5afd9807c3820001d336f159738bb0', '2026-08-01 14:49:32.899', '2026-08-15 14:49:32.899', '2026-08-01 14:49:57.634'),
(163, 1, N'b60cb22f2c2450fc096ae98be73fdfcb161f2ba6073411e1485f7fe52a092397', '2026-08-01 14:49:58.902', '2026-08-15 14:49:58.902', NULL),
(164, 22, N'ede8df4843fbcc7c01aef7b0bd60f73ef6c91f7c39f1b412cd4e9311e9391974', '2026-08-01 14:50:08.179', '2026-08-15 14:50:08.179', '2026-08-01 14:52:55.100'),
(165, 19, N'67311f09dbb6d4207bc3d4e5df0af8a5a86234f91215d302df5b1840aa1170a4', '2026-08-01 14:50:19.259', '2026-08-15 14:50:19.259', '2026-08-01 14:52:17.364'),
(166, 1, N'49f4cc9600be528cd39dbea0335a45e87d91b2802a002f6bfed28a618c2c6bad', '2026-08-01 14:51:50.739', '2026-08-15 14:51:50.737', NULL),
(167, 1, N'1858ebc4340174b78993597e44a4a8fa29b573a2fbb17e96400d2df828908d2f', '2026-08-01 14:52:20.454', '2026-08-15 14:52:20.454', '2026-08-01 15:16:25.875'),
(168, 1, N'a54982f067c353ce795c250870a3d281c04e81b80bc630945aa80f390a68f05c', '2026-08-01 14:52:34.606', '2026-08-15 14:52:34.603', NULL),
(169, 1, N'c70af4ebeb277659d84ef3856e4bb34131221920ebd0908f1fd296748636c932', '2026-08-01 14:52:59.767', '2026-08-15 14:52:59.766', '2026-08-01 15:16:11.459'),
(170, 1, N'a962ae9b4e472e73cba2716fb8f826b9b3d8308e80e4cd3f82c78a235f2de3a7', '2026-08-01 14:53:36.214', '2026-08-15 14:53:36.211', '2026-08-01 15:18:15.160'),
(171, 18, N'837adf3891e55ea4d5479f1dba51b8db619e6f9b8f39dce980a5b5820e0f2255', '2026-08-01 14:54:18.286', '2026-08-15 14:54:18.286', '2026-08-01 14:54:44.642'),
(172, 1, N'87808fbb125ef4aee17c47f38d787acf33e8415da039ecb6fbc1810b8c185e52', '2026-08-01 14:54:47.797', '2026-08-15 14:54:47.794', '2026-08-01 15:16:31.182'),
(173, 1, N'23f641118efe7de56fa03a67256cf3666cfd872a2e6a2ad2a89050e3555a88dd', '2026-08-01 14:54:52.009', '2026-08-15 14:54:52.009', NULL),
(174, 23, N'95c0bca03d3f4ae3235534f3dcdaffa196420e5907c9b28ec5f4de694290ee14', '2026-08-01 14:54:52.449', '2026-08-15 14:54:52.449', NULL),
(175, 1, N'fc23d53f65a1bb5e6e1b84c52bcf62d88aedaa3a0af041e167dbe2d79487f826', '2026-08-01 14:58:07.055', '2026-08-15 14:58:07.054', NULL),
(176, 1, N'13522d4fd3825595dc0a3badb138946e33a7a36fa54def98f942b42103819cd4', '2026-08-01 15:00:44.160', '2026-08-15 15:00:44.158', NULL),
(177, 17, N'86be1af3e578d26dd7309a72da45465b3a178f1c0545195ffb6a98952820c080', '2026-08-01 15:03:13.019', '2026-08-15 15:03:13.019', '2026-08-01 15:21:39.190'),
(178, 1, N'fd8e1d978aade8fdeac554abc778a44a83b9c5c09d4c3f961d2cf9e68159c1b2', '2026-08-01 15:04:29.234', '2026-08-15 15:04:29.231', NULL),
(179, 24, N'62b80897e35a0c03a906c1d6079eb9a3c16c7cd85db957114a1a4215b7df75a1', '2026-08-01 15:04:29.684', '2026-08-15 15:04:29.681', NULL),
(180, 18, N'1fed9a5b62b5b7069e5dd5a4896d10745da48936d4f78dc6246729f6849a6b22', '2026-08-01 15:16:34.049', '2026-08-15 15:16:34.046', '2026-08-01 15:19:16.638'),
(181, 19, N'0c3df5e273c45e89773ba69356489768e68dcb0cd0bd6b1bf77c0e7b3e98ffee', '2026-08-01 15:16:36.192', '2026-08-15 15:16:36.189', '2026-08-01 15:41:34.957'),
(182, 1, N'f554fc41a3b827dc7f7da52354caf2559dd513e4e52a394645193bff55170d70', '2026-08-01 15:16:43.658', '2026-08-15 15:16:43.658', NULL),
(183, 19, N'48640d61c1dd6f0dc78621017e2b90bc31c0435fe7612caf12a66c1b27159fee', '2026-08-01 15:16:44.192', '2026-08-15 15:16:44.191', '2026-08-01 15:56:09.274'),
(184, 19, N'47b52ce290eb4b67ae28409e40c496197e1b447dea16ef1bf2adb7f748ffac98', '2026-08-01 15:17:06.402', '2026-08-15 15:17:06.402', '2026-08-01 15:19:45.667'),
(185, 1, N'25b1b830339cccd515ba95c07091d39feec8bb137bfe531c0ed2716c56ab6a29', '2026-08-01 15:19:19.785', '2026-08-15 15:19:19.785', '2026-08-01 15:31:43.079'),
(186, 13, N'4478a83b83f83d3756c50f2ede9ea07d365cd1661ab970cc3ff6780e3766e5a4', '2026-08-01 15:19:49.540', '2026-08-15 15:19:49.538', '2026-08-01 15:22:14.412'),
(187, 25, N'49ebade927d2ba791dbf15fbaf6f4aa09bb9c503fd2398e6f4364efb24ebdc87', '2026-08-01 15:21:21.315', '2026-08-15 15:21:21.314', '2026-08-01 15:21:34.371'),
(188, 17, N'764929513baed4226b981801a823ec585a67684428d1f2155643320d4d309bf2', '2026-08-01 15:21:45.200', '2026-08-15 15:21:45.200', NULL),
(189, 1, N'06d05803a92bb3d377cfd3ecedc3f79bba24c9bd6f48da958dcdd371db6d81ef', '2026-08-01 15:21:58.491', '2026-08-15 15:21:58.491', '2026-08-01 15:27:26.698'),
(190, 19, N'7e7b32ce7adf8355e04f732c640779bbe62cfad06ab58f79a12cacb9c268fc95', '2026-08-01 15:22:34.284', '2026-08-15 15:22:34.283', '2026-08-01 15:24:56.225'),
(191, 13, N'd47d3bde6f032c0c7c808f1c6c926bf93d87e12a935885b2592c51d5c92028b3', '2026-08-01 15:25:00.144', '2026-08-15 15:25:00.144', '2026-08-01 15:25:58.702'),
(192, 1, N'e9c9a293c61b9a23bbce340925efb566ba789616589afbb50c8b1bb6c2d1ad0c', '2026-08-01 15:26:01.901', '2026-08-15 15:26:01.900', '2026-08-01 15:32:40.557'),
(193, 25, N'964875c4ce7ddebe550c95eec9cbba6e2acb0b5705720c63649aa21d6b891b4c', '2026-08-01 15:28:00.221', '2026-08-15 15:28:00.221', NULL),
(194, 18, N'e999d520389bb9e113b5b6fc256580bcace2124f155f76f633167413d232c838', '2026-08-01 15:31:46.802', '2026-08-15 15:31:46.802', '2026-08-01 15:44:53.983'),
(195, 19, N'002f80b4e66f3849d297320a64f57e4a4539d5df3be3974851d795baa9f9b93a', '2026-08-01 15:32:44.380', '2026-08-15 15:32:44.380', '2026-08-01 15:33:15.687'),
(196, 1, N'0eaf7df13bee63ab2c44f8223c770552b9814588262cf3a184dba0e98954b4bb', '2026-08-01 15:33:24.493', '2026-08-15 15:33:24.489', '2026-08-01 15:36:53.170'),
(197, 13, N'cef145f0fec83280261f6a1fc28909afb8f9db6d19a3b722681854a47d85fca5', '2026-08-01 15:36:56.299', '2026-08-15 15:36:56.298', '2026-08-01 15:38:10.524'),
(198, 13, N'b44f5eac7d6ec1141e6c83fbbc0daf9d129ec675d881bcde251ba44f818c0001', '2026-08-01 15:38:13.762', '2026-08-15 15:38:13.761', '2026-08-01 15:39:11.096'),
(199, 1, N'5dd1d2ff4b536a696463abe81b1069358f47107ef2f7476946b98287b743c373', '2026-08-01 15:39:51.285', '2026-08-15 15:39:51.282', '2026-08-01 15:43:10.738'),
(200, 19, N'6b715108c3fb91d0e1b8d7516059a516f4ee8cd6690df9efddbb2434ab02daf0', '2026-08-01 15:41:38.328', '2026-08-15 15:41:38.321', '2026-08-01 15:45:07.765');
GO
INSERT INTO dbo.[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt])
VALUES
(201, 19, N'5664ae1ee4d5f15817b7308bf91ecc0aef7f04323c0f3dbfeae6e50e762bbac4', '2026-08-01 15:42:12.410', '2026-08-15 15:42:12.407', '2026-08-01 16:08:47.487'),
(202, 19, N'019ef873bc6b2c0643717e1bc938cf5d82948fbee959b600db1561d9e9f2f109', '2026-08-01 15:43:40.092', '2026-08-15 15:43:40.090', '2026-08-01 16:08:47.487'),
(203, 25, N'938b68559a6884f13d9de94bd673408defefd4536b7415de2e883ab36a355de5', '2026-08-01 15:43:42.266', '2026-08-15 15:43:42.266', '2026-08-01 15:50:04.448'),
(204, 1, N'146e136a31d3f62e9ecc247c3cba0e1dce0a32d8501fca182cc1ec1f8268bc91', '2026-08-01 15:44:31.227', '2026-08-15 15:44:31.226', '2026-08-01 15:46:13.452'),
(205, 19, N'fb46507c60b009fee641867f669cc66edfc51475202888eab82425e0f601d58a', '2026-08-01 15:44:38.567', '2026-08-15 15:44:38.567', '2026-08-01 16:08:47.487'),
(206, 19, N'8ebbfb65a1f7f8e35db24ff8d9caa97796583c9c7383b012ab5f7576de0d9699', '2026-08-01 15:44:57.208', '2026-08-15 15:44:57.208', '2026-08-01 16:08:47.487'),
(207, 18, N'dece9d9c55d022379b4af0508629aa42b13f3d24ce75552a824d2d45e14d4267', '2026-08-01 15:45:39.404', '2026-08-15 15:45:39.401', '2026-08-01 15:46:29.252'),
(208, 13, N'7e5742d2572789b72bcfcf8698557ab80e32cbd104e65aeac4c4f560a9bc9f79', '2026-08-01 15:46:18.702', '2026-08-15 15:46:18.702', '2026-08-01 15:48:55.553'),
(209, 18, N'dfd3aa2ea7aea36333ba103a23318069f93990ceede349a1d115a53c843fe1b2', '2026-08-01 15:46:58.481', '2026-08-15 15:46:58.481', '2026-08-01 15:47:45.325'),
(210, 18, N'46e1d67c5817754bc723bbf267a0961bf5663674c37ebca46fa6238215d41a73', '2026-08-01 15:48:28.232', '2026-08-15 15:48:28.229', '2026-08-01 15:53:28.329'),
(211, 25, N'01526e299606b1d5715e1fa1425949bfd6e86bf77b77fd274375796446635021', '2026-08-01 15:50:21.054', '2026-08-15 15:50:21.051', '2026-08-01 15:52:26.082'),
(212, 26, N'746c6bab024c23017478a569f76628ec7a1b46c3b5b0eabc7e9d3ddf8cc2136c', '2026-08-01 15:50:32.102', '2026-08-15 15:50:32.102', '2026-08-01 15:53:15.928'),
(213, 1, N'8ea558221bdb7c91390a0f4fe164f571291c2a04aaf5feaabbde3facd4ce536b', '2026-08-01 15:50:36.390', '2026-08-15 15:50:36.386', NULL),
(214, 19, N'dde5b10387999066b49d1088e866db9973648bbdfa506af9d0aaccbb867c2c02', '2026-08-01 15:50:36.895', '2026-08-15 15:50:36.890', '2026-08-01 16:08:47.487'),
(215, 1, N'32d3f2c49380ead35ffa7d4a4d7168596ca98d42fd70fac7ed7ab1f746e2d495', '2026-08-01 15:51:02.609', '2026-08-15 15:51:02.608', NULL),
(216, 19, N'f41e25cd154824593a8069b5e80d78e21b17c3028086ddc19247eb1787812cf6', '2026-08-01 15:51:02.831', '2026-08-15 15:51:02.831', '2026-08-01 16:08:47.487'),
(217, 2, N'7d0786063e48a6ce58e641e654deb17def6b83314f855cbc2ec74daa60929724', '2026-08-01 15:51:03.043', '2026-08-15 15:51:03.043', NULL),
(218, 25, N'd1de88e314fbea23ea7c2e656f38769b528b18ceba9b21c3176aa70e17b2db83', '2026-08-01 15:52:43.183', '2026-08-15 15:52:43.183', '2026-08-01 15:53:10.387'),
(219, 1, N'43e82eeba3641bade3b6fb57b0f87b395524117b62d360254079a686089a4c8b', '2026-08-01 15:53:18.209', '2026-08-15 15:53:18.206', '2026-08-01 16:04:07.373'),
(220, 1, N'88dd4117a22745fd097bb4991c07c36e93a841201cba9ff541ea8a5d8222822c', '2026-08-01 15:53:19.908', '2026-08-15 15:53:19.903', '2026-08-01 15:54:15.711'),
(221, 1, N'17d1aa4a3b3d2a4d30e3ef2c0e1bc0db8a833305057b72c6979f68d08f8eda6f', '2026-08-01 15:53:31.594', '2026-08-15 15:53:31.588', '2026-08-01 15:56:54.182'),
(222, 26, N'16b7299f60ba5660c835369c2cd7aa604a1b89f2424eef90bdf52ddd0d070243', '2026-08-01 15:54:19.908', '2026-08-15 15:54:19.906', '2026-08-01 15:57:58.805'),
(223, 27, N'ac26a9635dd6ca0a0510f1d7bc2e2794af47012f33a493c9573328305042b096', '2026-08-01 15:54:42.488', '2026-08-15 15:54:42.485', '2026-08-01 16:06:03.767'),
(224, 1, N'5e8b762a2d1d2409517f54292e66bb0cd8794a090ca6e5736bd49181456de3d5', '2026-08-01 15:56:11.581', '2026-08-15 15:56:11.581', '2026-08-01 15:57:05.719'),
(225, 1, N'28189d87971752a1bf06714cef97b45784b5770a2e3e1531bdc9e0b6c51443b5', '2026-08-01 15:57:04.073', '2026-08-15 15:57:04.070', '2026-08-01 15:57:18.501'),
(226, 18, N'89d466afc848de78082627fb621799ecc868d5e22adf7ad58fcf519969ae86b6', '2026-08-01 15:57:21.371', '2026-08-15 15:57:21.370', '2026-08-01 16:04:36.896'),
(227, 20, N'3ee23529f8bb7e1655fbfdd7617c7bb015ef6c004e1ca90609a8f0e89fba995e', '2026-08-01 15:57:26.972', '2026-08-15 15:57:26.972', '2026-08-01 16:10:47.045'),
(228, 21, N'28eb9d086368bfe4f8e0a69c158f26b9830e6b67b67d430bfce03e238ce3973d', '2026-08-01 15:58:03.145', '2026-08-15 15:58:03.145', '2026-08-01 15:58:18.273'),
(229, 1, N'2a5ee11b6976f47b591827faf5ddbb0e456cce11507a35d98847f3a097af0880', '2026-08-01 15:58:22.950', '2026-08-15 15:58:22.946', '2026-08-01 16:00:18.120'),
(230, 13, N'96ed6d261576dbb2fbeb1bf0ae2dcb55a7708a04d0a7a241a0ad5b468ed9386c', '2026-08-01 16:00:23.212', '2026-08-15 16:00:23.210', '2026-08-01 16:05:18.167'),
(231, 1, N'6206d5edb36a4a3a9f5aacc242e16a72eff392de615a8d18a7908ffc2955992e', '2026-08-01 16:04:09.830', '2026-08-15 16:04:09.830', '2026-08-01 16:04:13.050'),
(232, 1, N'54fe3cd74dcc9235b0eeb1f60311fc092d5ce6896403ef295c776e528cebf064', '2026-08-01 16:04:40.949', '2026-08-15 16:04:40.947', '2026-08-01 16:06:34.014'),
(233, 1, N'0d4461a997a06043d37caa05c1100219f971b62c50ea19759945656892dab586', '2026-08-01 16:04:44.330', '2026-08-15 16:04:44.330', NULL),
(234, 1, N'db02ab731b0cc3b3067188819e29679e8477dec744eade28f37ca0da38c647e2', '2026-08-01 16:05:21.578', '2026-08-15 16:05:21.575', '2026-08-01 16:06:04.984'),
(235, 26, N'75a6b2826c5ed1a8165d01d17dff1e3680bb77b9a26509854a985b75c45309fc', '2026-08-01 16:06:09.411', '2026-08-15 16:06:09.404', '2026-08-01 16:07:29.792'),
(236, 25, N'826b51e064d1c068730fd98acfaacd58c0d4a8329b4d4722a36185cfe4bf907f', '2026-08-01 16:06:14.708', '2026-08-15 16:06:14.708', '2026-08-01 16:20:27.663'),
(237, 18, N'2923f4101a8da1aa914d98c6ae7a6e1a601507154dbc0e51161b20aef4eadd13', '2026-08-01 16:06:37.356', '2026-08-15 16:06:37.355', '2026-08-01 16:10:22.363'),
(238, 1, N'9d6c9f0576ea7298d5bbb5d8d979a15e309b1148c6e8e99f92de8a93a641b546', '2026-08-01 16:07:02.943', '2026-08-15 16:07:02.943', NULL),
(239, 1, N'49565c6972b51c2e28ceab8658a7c138f901dd88cd1b868510f657a096841153', '2026-08-01 16:07:53.652', '2026-08-15 16:07:53.652', NULL),
(240, 1, N'f07ab52906b0acec097f2f348fc48975fd4fe5ba8a668ac072bc2bfd055fe0ba', '2026-08-01 16:08:01.246', '2026-08-15 16:08:01.246', '2026-08-01 16:09:46.873');
GO
INSERT INTO dbo.[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt])
VALUES
(241, 1, N'a10790c02539dcfbc35a38b7c71baf9cb8a3e17f39c1526aeca93f5cee17d016', '2026-08-01 16:08:47.253', '2026-08-15 16:08:47.250', NULL),
(242, 19, N'917241923600e7eec596e14f03b551a9d1f59c52c4dcd5093e10f153c4724163', '2026-08-01 16:09:43.084', '2026-08-15 16:09:43.078', '2026-08-01 16:10:26.664'),
(243, 19, N'10f8cd187346f133991060b91e4ab845654695f730559b31d98cf74886ffb7da', '2026-08-01 16:09:50.201', '2026-08-15 16:09:50.192', '2026-08-01 16:12:34.456'),
(244, 1, N'ad2121133eec8c7ed2f071492620947a52e9eb4d7397b05c33da920fb0da763e', '2026-08-01 16:10:25.652', '2026-08-15 16:10:25.650', '2026-08-01 16:12:37.755'),
(245, 1, N'52c15a615b2c57f1b038d71e81b3cb7dfbc1940489094b0f1d650bef65645a2a', '2026-08-01 16:10:49.143', '2026-08-15 16:10:49.139', NULL),
(246, 10, N'5732fa78ba86f2dd2d393ee3294bb5034e9ce7038cc43bfdc1e5219397bd4645', '2026-08-01 16:11:45.179', '2026-08-15 16:11:45.178', NULL),
(247, 13, N'535b9aa247320dca5738a8e1f133095c3d071bdac5f461c0d40a34a3e5eb4ed1', '2026-08-01 16:12:38.971', '2026-08-15 16:12:38.968', '2026-08-01 16:13:23.720'),
(248, 26, N'5e1167c35157c65493c0499b614e20b16dbbdbade52f70cea54db950d88f3aa8', '2026-08-01 16:12:41.524', '2026-08-15 16:12:41.522', '2026-08-01 16:17:52.016'),
(249, 19, N'8bdca4b52218a54b3c12edf70d33e365b5a5ea8cb422bbe9d3e032270bfd67eb', '2026-08-01 16:13:29.836', '2026-08-15 16:13:29.836', '2026-08-01 16:14:01.498'),
(250, 1, N'b0ede1fd580eb9d2c206dd19cf788c11a8ef570164a74cfc88d155504d605ddb', '2026-08-01 16:14:06.381', '2026-08-15 16:14:06.380', '2026-08-01 16:16:52.898'),
(251, 13, N'3a6c2aef31fa3448e66531e92f08120a471a769f0e77ade11bfd58a075ee7a22', '2026-08-01 16:17:05.485', '2026-08-15 16:17:05.481', '2026-08-01 16:18:39.797'),
(252, 11, N'b4a4234036aa558c5264eb1531ba7b6aa0404c99be0074c54a1aa9dbfeaac99b', '2026-08-01 16:17:49.101', '2026-08-15 16:17:49.100', NULL),
(253, 1, N'67914f833a606b4c65842edfc181bd89c5a599d514bb3a916ccb0d0b54c8eaed', '2026-08-01 16:17:57.020', '2026-08-15 16:17:57.020', NULL),
(254, 19, N'ebc5306ca406720c4d5e4f457da35f43f9662758c531be08822eb5c200b94e20', '2026-08-01 16:18:47.534', '2026-08-15 16:18:47.534', '2026-08-01 16:19:09.988'),
(255, 1, N'35b2e35ecbd3438dc406d1745dcd2d7247a668122ec83b97028d3340ab0ac620', '2026-08-01 16:19:14.195', '2026-08-15 16:19:14.195', NULL),
(256, 27, N'a907256dc3b4400a9c917d4913e94a3ce8cda9801f10ff3f0b6e7163e4e8b63c', '2026-08-01 16:20:43.347', '2026-08-15 16:20:43.347', '2026-08-01 16:21:13.888'),
(257, 1, N'ed6fe2ca14af20b789ba31df1b12fa6787dc5a0c56955bb451b72ccabaa76106', '2026-08-01 16:21:29.900', '2026-08-15 16:21:29.898', NULL),
(1207, 1, N'586352fb42f4d2364aa2a5627bbae66e3eb0da90a008e5ac0dc8b1d437554797', '2026-08-03 13:48:32.256', '2026-08-17 13:48:32.256', '2026-08-03 14:34:39.377'),
(1208, 1, N'0a66db9d0ec2a4c83654b429c780afbda082881c935a9898463f43c338809373', '2026-08-03 13:50:06.172', '2026-08-17 13:50:06.172', NULL),
(1209, 1, N'2c5550af3b1d7eabe7b43d0040cc83ad72add56a8f6dd8065f3864d2712c0eff', '2026-08-03 13:50:08.299', '2026-08-17 13:50:08.299', '2026-08-03 14:35:55.344'),
(1210, 1, N'a3ee009acb6ec2dc947fc7ff9ce2680a2cd28ece4533d6983b6aa3183273f57d', '2026-08-03 13:50:45.678', '2026-08-17 13:50:45.678', NULL),
(1211, 1, N'9f535c6642561bc88ca7ba6258fffbf2cde8fb76c647b69a459b7b18419adc1e', '2026-08-03 13:50:54.947', '2026-08-17 13:50:54.947', NULL),
(1212, 1, N'ffeaf06274fffa6a4b8bead401db75654c83db6d37d8a191492bae9d2e3b158d', '2026-08-03 14:34:28.664', '2026-08-17 14:34:28.664', '2026-08-03 14:35:26.234'),
(1213, 18, N'54bba5d8dff3c78334f84eae647c9986d924cf3b36d856bde0daad64bf62af32', '2026-08-03 14:34:43.472', '2026-08-17 14:34:43.471', '2026-08-03 14:35:30.731'),
(1214, 1, N'd89962e425f6b49f5b2a63ff91279b39beebd194027ffe01c165e3b2508ce44c', '2026-08-03 14:35:38.145', '2026-08-17 14:35:38.140', '2026-08-03 15:26:09.795'),
(1215, 1, N'1e48c1b45662c46d91adb564f5a73e344d9216b32c8c200ab468508beba53796', '2026-08-03 14:36:18.886', '2026-08-17 14:36:18.886', NULL),
(1216, 1, N'c1783610c87c403654bb3e6c8ebfe80de74f4f733c84a2b7415d37efe66ff245', '2026-08-03 14:36:50.755', '2026-08-17 14:36:50.753', NULL),
(1217, 1, N'd28d0de5f29ddfa52b98574807ed74e1ef8d9d6c4698b7eadcba02bb7450dc4f', '2026-08-03 14:53:30.798', '2026-08-17 14:53:30.798', '2026-08-03 14:55:22.627'),
(1218, 5, N'b87ffc2a6899f62af1744646ab417cbf26297fb65453b39321815120647d4704', '2026-08-03 14:55:36.322', '2026-08-17 14:55:36.319', '2026-08-03 15:02:12.471'),
(1219, 1, N'218d750cbb5b2ec2e36d8452f125d55225fd7d4d88da8d154cd723848aa44c80', '2026-08-03 14:59:23.628', '2026-08-17 14:59:23.628', NULL),
(1220, 1, N'84682b49235d9f107e2dd60117d621c8a40e578a2e429ca55a0a9a4b6884296e', '2026-08-03 15:02:18.798', '2026-08-17 15:02:18.798', NULL),
(1221, 18, N'07b6c73bb2030ecb2cfe8295c8c86efb1c31ed4a2a341c3b133d851601462fa5', '2026-08-03 15:26:13.260', '2026-08-17 15:26:13.247', NULL);
GO
SET IDENTITY_INSERT dbo.[UserSession] OFF;
GO

-- ===== DATA: ShopCategory (4 rows) =====
SET IDENTITY_INSERT dbo.[ShopCategory] ON;
GO
INSERT INTO dbo.[ShopCategory] ([Id], [Name], [SortOrder], [IsActive])
VALUES
(1, N'کتاب و منابع', 1, 1),
(2, N'فایل و محتوای دیجیتال', 2, 1),
(3, N'لوازم التحریر آموزشی', 3, 1),
(4, N'پکیج‌های آمادگی آزمون', 4, 1);
GO
SET IDENTITY_INSERT dbo.[ShopCategory] OFF;
GO

-- ===== DATA: ShopProduct (13 rows) =====
SET IDENTITY_INSERT dbo.[ShopProduct] ON;
GO
INSERT INTO dbo.[ShopProduct] ([Id], [CategoryRef], [Name], [Sku], [Description], [Price], [Stock], [ProductType], [ImageUrl], [IsActive], [IsFeatured], [CreatedAt])
VALUES
(1, 1, N'کتاب گرامر انگلیسی سطح متوسط', N'BK-EN-GRAM-01', N'مرجع کامل گرامر با تمرین', 850000, 39, N'book', NULL, 1, 1, '2026-08-01 14:08:57.840'),
(2, 1, N'واژه‌نامه موضوعی آلمانی', N'BK-DE-VOC-02', N'۵۰۰ واژه پرتکرار با مثال', 620000, 25, N'book', NULL, 1, 0, '2026-08-01 14:08:57.844'),
(3, 2, N'پکیج صوتی مکالمه اسپانیایی', N'FL-ES-AUD-01', N'۳۰ درس صوتی قابل دانلود', 450000, 999, N'file', NULL, 1, 1, '2026-08-01 14:08:57.848'),
(4, 2, N'نمونه سوالات IELTS Reading', N'FL-IELTS-RD-03', N'PDF + پاسخ‌نامه', 390000, 991, N'file', NULL, 1, 1, '2026-08-01 14:08:57.851'),
(5, 3, N'دفترچه تمرین زبان‌آموز', N'ST-NOTE-01', N'۱۲۰ برگ خط‌دار ویژه کلاس', 180000, 119, N'stationery', NULL, 1, 0, '2026-08-01 14:08:57.854'),
(6, 3, N'فلش‌کارت واژگان رنگی', N'ST-FLASH-05', N'بسته ۲۰۰ کارت دو رو', 275000, 51, N'stationery', NULL, 1, 1, '2026-08-01 14:08:57.858'),
(7, 4, N'پکیج آمادگی آزمون YOS', N'PK-YOS-01', N'کتاب + فایل تمرین + راهنما', 1250000, 6, N'course_pack', NULL, 0, 1, '2026-08-01 14:08:57.859'),
(8, 4, N'پکیج مکالمه فشرده فرانسه', N'PK-FR-CONV', N'بسته ۴ هفته‌ای خودآموز', 980000, 19, N'course_pack', NULL, 1, 0, '2026-08-01 14:08:57.863'),
(9, 1, N'basic grammer', N'45', N'grammer for beginners', 5000000, 6, N'book', NULL, 1, 1, '2026-08-01 14:11:24.290'),
(10, 1, N'مجله های انگلیسی', N'26', N'سری مجلات English maters منبعی فوق العاده برای تمرین مهارت خوانداری زبان آموزان است', 2500000, 9, N'other', NULL, 1, 0, '2026-08-01 14:14:19.276'),
(11, 1, N'کتاب دوره فشرده انگلیسی', N'#11111', NULL, 150000000, 0, N'book', NULL, 1, 0, '2026-08-01 14:48:53.374'),
(22, 1, N'listening tactics [Basic,extanded,developer]', N'1235400', N'if you wanna experience an beneficial improvement in your listening skill? It''s for you.', 152630, 130, N'book', NULL, 1, 1, '2026-08-01 16:23:30.267'),
(1022, 1, N'English alphabet for begginers', N'-1', NULL, 550000, 20, N'book', NULL, 1, 0, '2026-08-03 14:34:56.844');
GO
SET IDENTITY_INSERT dbo.[ShopProduct] OFF;
GO

-- ===== DATA: ShopProductLike (13 rows) =====
SET IDENTITY_INSERT dbo.[ShopProductLike] ON;
GO
INSERT INTO dbo.[ShopProductLike] ([Id], [UserRef], [ProductRef], [CreatedAt])
VALUES
(2, 16, 6, '2026-08-01 14:14:33.856'),
(3, 13, 9, '2026-08-01 14:15:36.370'),
(4, 16, 5, '2026-08-01 14:29:56.952'),
(5, 16, 3, '2026-08-01 14:29:59.230'),
(6, 16, 1, '2026-08-01 14:30:01.542'),
(7, 16, 4, '2026-08-01 14:30:26.026'),
(8, 18, 6, '2026-08-01 14:30:50.869'),
(10, 18, 3, '2026-08-01 14:31:06.811'),
(11, 20, 8, '2026-08-01 14:38:41.429'),
(12, 13, 11, '2026-08-01 15:25:07.940'),
(13, 1, 1, '2026-08-01 15:45:36.797'),
(14, 27, 9, '2026-08-01 15:58:27.673'),
(1013, 1, 22, '2026-08-03 14:14:04.301');
GO
SET IDENTITY_INSERT dbo.[ShopProductLike] OFF;
GO

-- ===== DATA: ShopProductBookmark (9 rows) =====
SET IDENTITY_INSERT dbo.[ShopProductBookmark] ON;
GO
INSERT INTO dbo.[ShopProductBookmark] ([Id], [UserRef], [ProductRef], [CreatedAt])
VALUES
(2, 15, 9, '2026-08-01 14:14:45.338'),
(3, 16, 9, '2026-08-01 14:14:46.053'),
(4, 13, 9, '2026-08-01 14:15:37.266'),
(5, 16, 4, '2026-08-01 14:30:03.456'),
(6, 18, 9, '2026-08-01 14:30:48.669'),
(7, 18, 4, '2026-08-01 14:30:52.104'),
(8, 18, 3, '2026-08-01 14:31:03.861'),
(9, 20, 9, '2026-08-01 14:36:29.603'),
(10, 13, 6, '2026-08-01 15:25:05.901');
GO
SET IDENTITY_INSERT dbo.[ShopProductBookmark] OFF;
GO

-- no rows in ShopCartItem
GO

-- ===== DATA: ShopOrder (22 rows) =====
SET IDENTITY_INSERT dbo.[ShopOrder] ON;
GO
INSERT INTO dbo.[ShopOrder] ([Id], [UserRef], [SessionKey], [Status], [TotalAmount], [Note], [CreatedAt])
VALUES
(1, NULL, N'a295bcdd7283feb6427601a3c2d1a624', N'pending', 180000, NULL, '2026-08-01 14:10:59.215'),
(2, 1, NULL, N'pending', 1125000, NULL, '2026-08-01 14:11:17.964'),
(3, 11, NULL, N'pending', 665000, NULL, '2026-08-01 14:12:02.663'),
(4, 1, NULL, N'pending', 275000, NULL, '2026-08-01 14:12:38.937'),
(5, 15, NULL, N'pending', 980000, NULL, '2026-08-01 14:13:52.641'),
(6, 15, NULL, N'pending', 5000000, NULL, '2026-08-01 14:14:37.608'),
(7, 16, NULL, N'pending', 5000000, NULL, '2026-08-01 14:15:27.402'),
(8, 13, NULL, N'pending', 15000000, NULL, '2026-08-01 14:16:15.637'),
(9, 16, NULL, N'pending', 275000, NULL, '2026-08-01 14:17:46.275'),
(10, 18, NULL, N'pending', 5000000, NULL, '2026-08-01 14:18:11.618'),
(11, 11, NULL, N'pending', 275000, NULL, '2026-08-01 14:18:39.866'),
(12, 13, NULL, N'pending', 5665000, N'تحویل درب منزل', '2026-08-01 14:19:26.912'),
(13, 16, NULL, N'pending', 1170000, NULL, '2026-08-01 14:19:51.553'),
(14, 16, NULL, N'pending', 390000, NULL, '2026-08-01 14:26:12.833'),
(15, 19, NULL, N'pending', 665000, NULL, '2026-08-01 14:29:03.681'),
(16, 20, NULL, N'pending', 275000, NULL, '2026-08-01 14:33:37.236'),
(17, 13, NULL, N'pending', 2500000, NULL, '2026-08-01 14:36:40.256'),
(18, NULL, N'a295bcdd7283feb6427601a3c2d1a624', N'pending', 390000, NULL, '2026-08-01 14:37:23.235'),
(19, 1, NULL, N'pending', 850000, NULL, '2026-08-01 14:38:07.795'),
(20, 18, NULL, N'pending', 5000000, N'دذنم', '2026-08-01 14:54:37.576'),
(21, 13, NULL, N'pending', 275000, NULL, '2026-08-01 15:25:47.683'),
(22, 25, NULL, N'pending', 275000, NULL, '2026-08-01 15:34:10.340');
GO
SET IDENTITY_INSERT dbo.[ShopOrder] OFF;
GO

-- ===== DATA: ShopOrderItem (26 rows) =====
SET IDENTITY_INSERT dbo.[ShopOrderItem] ON;
GO
INSERT INTO dbo.[ShopOrderItem] ([Id], [OrderRef], [ProductRef], [Qty], [UnitPrice])
VALUES
(1, 1, 5, 1, 180000),
(2, 2, 7, 9, 125000),
(3, 3, 4, 1, 390000),
(4, 3, 6, 1, 275000),
(5, 4, 6, 1, 275000),
(6, 5, 8, 1, 980000),
(7, 6, 9, 1, 5000000),
(8, 7, 9, 1, 5000000),
(9, 8, 9, 3, 5000000),
(10, 9, 6, 1, 275000),
(11, 10, 9, 1, 5000000),
(12, 11, 6, 1, 275000),
(13, 12, 9, 1, 5000000),
(14, 12, 6, 1, 275000),
(15, 12, 4, 1, 390000),
(16, 13, 4, 3, 390000),
(17, 14, 4, 1, 390000),
(18, 15, 6, 1, 275000),
(19, 15, 4, 1, 390000),
(20, 16, 6, 1, 275000),
(21, 17, 10, 1, 2500000),
(22, 18, 4, 1, 390000),
(23, 19, 1, 1, 850000),
(24, 20, 9, 1, 5000000),
(25, 21, 6, 1, 275000),
(26, 22, 6, 1, 275000);
GO
SET IDENTITY_INSERT dbo.[ShopOrderItem] OFF;
GO

-- ===== DATA: PlacementTestType (2 rows) =====
SET IDENTITY_INSERT dbo.[PlacementTestType] ON;
GO
INSERT INTO dbo.[PlacementTestType] ([Id], [Code], [Name], [LanguageRef], [Description], [DurationMinutes], [QuestionsToAsk], [IsActive], [CreatedAt])
VALUES
(1, N'EN-PLACEMENT', N'آزمون تعیین سطح عمومی انگلیسی', 1, N'آزمون چندگزینه‌ای برای پیشنهاد سطح مناسب. نتیجه بلافاصله پس از پایان اعلام می‌شود.', 20, 8, 1, '2026-08-01 15:34:50.128'),
(2, N'تعیین سطح', N'اسپانیایی', 7, NULL, 30, 10, 1, '2026-08-01 16:17:46.009');
GO
SET IDENTITY_INSERT dbo.[PlacementTestType] OFF;
GO

-- ===== DATA: PlacementQuestion (12 rows) =====
SET IDENTITY_INSERT dbo.[PlacementQuestion] ON;
GO
INSERT INTO dbo.[PlacementQuestion] ([Id], [TestTypeRef], [Skill], [Difficulty], [Prompt], [OptionA], [OptionB], [OptionC], [OptionD], [CorrectOption], [Points], [Explanation], [IsActive], [Creator], [CreatedAt], [UpdatedAt])
VALUES
(1, 1, N'grammar', 1, N'She _____ to school every day.', N'go', N'goes', N'going', N'gone', N'B', 1.0, N'فاعل سوم‌شخص مفرد → goes', 1, N'system', '2026-08-01 15:34:50.135', NULL),
(2, 1, N'grammar', 2, N'If it rains, we _____ at home.', N'stay', N'stayed', N'will stay', N'staying', N'C', 1.0, N'شرطی نوع اول', 1, N'system', '2026-08-01 15:34:50.136', NULL),
(3, 1, N'vocabulary', 1, N'A synonym of ''happy'' is:', N'sad', N'angry', N'glad', N'tired', N'C', 1.0, NULL, 1, N'system', '2026-08-01 15:34:50.140', NULL),
(4, 1, N'vocabulary', 2, N'Please _____ the door when you leave.', N'open', N'close', N'break', N'paint', N'B', 1.0, NULL, 1, N'system', '2026-08-01 15:34:50.143', NULL),
(5, 1, N'reading', 2, N'Tom has two cats. They are black. How many cats does Tom have?', N'One', N'Two', N'Three', N'None', N'B', 1.0, NULL, 1, N'system', '2026-08-01 15:34:50.149', NULL),
(6, 1, N'grammar', 3, N'I have _____ finished my homework.', N'yet', N'already', N'never', N'ever', N'B', 1.0, N'already برای عمل کامل‌شده', 1, N'system', '2026-08-01 15:34:50.151', NULL),
(7, 1, N'vocabulary', 3, N'The opposite of ''expensive'' is:', N'cheap', N'heavy', N'large', N'fast', N'A', 1.0, NULL, 1, N'system', '2026-08-01 15:34:50.156', NULL),
(8, 1, N'general', 2, N'_____ are you from?', N'What', N'Where', N'Who', N'Which', N'B', 1.0, NULL, 1, N'system', '2026-08-01 15:34:50.159', NULL),
(9, 1, N'grammar', 5, N'Neither John nor his friends _____ coming.', N'is', N'are', N'be', N'was', N'B', 1.0, NULL, 0, N'system', '2026-08-01 15:34:50.163', '2026-08-01 16:07:21.559'),
(10, 1, N'vocabulary', 4, N'To ''postpone'' means to:', N'cancel', N'delay', N'finish', N'start', N'B', 1.0, NULL, 0, N'system', '2026-08-01 15:34:50.165', '2026-08-01 16:07:18.060'),
(11, 1, N'general', 2, N'what is the singular of mice ?', N'mouses', N'music', N'mice', N'mouse', N'D', 2.0, NULL, 1, N'zahra', '2026-08-01 16:11:56.476', NULL),
(12, 2, N'vocabulary', 1, N'Agua', N'Water', N'Apple', N'man', N'woman', N'A', 1.0, NULL, 1, N'Ali', '2026-08-01 16:19:30.998', '2026-08-01 16:19:41.190');
GO
SET IDENTITY_INSERT dbo.[PlacementQuestion] OFF;
GO

-- ===== DATA: PlacementLevelRule (4 rows) =====
SET IDENTITY_INSERT dbo.[PlacementLevelRule] ON;
GO
INSERT INTO dbo.[PlacementLevelRule] ([Id], [TestTypeRef], [MinPercent], [MaxPercent], [LevelRef], [Label])
VALUES
(1, 1, 0.0, 39.0, 7, N'پیشنهاد: مبتدی ۱'),
(2, 1, 40.0, 59.0, 8, N'پیشنهاد: مبتدی ۲'),
(3, 1, 60.0, 79.0, 9, N'پیشنهاد: متوسط ۱'),
(4, 1, 80.0, 100.0, 10, N'پیشنهاد: متوسط ۲');
GO
SET IDENTITY_INSERT dbo.[PlacementLevelRule] OFF;
GO

-- ===== DATA: PlacementAttempt (17 rows) =====
SET IDENTITY_INSERT dbo.[PlacementAttempt] ON;
GO
INSERT INTO dbo.[PlacementAttempt] ([Id], [TestTypeRef], [StudentRef], [Status], [StartedAt], [FinishedAt], [ScoreValue], [MaxScore], [PercentScore], [SuggestedLevelRef], [ScoreRecordRef])
VALUES
(1, 1, 165, N'completed', '2026-08-01 15:46:33.792', '2026-08-01 15:48:25.500', 8.0, 8.0, 100.0, 10, 5),
(2, 1, 1253, N'completed', '2026-08-01 15:50:41.964', '2026-08-01 16:14:37.160', 1.0, 8.0, 12.5, 7, 16),
(3, 1, 1254, N'completed', '2026-08-01 15:54:47.075', '2026-08-01 15:55:44.727', 8.0, 8.0, 100.0, 10, 6),
(4, 1, 1254, N'completed', '2026-08-01 15:56:00.619', '2026-08-01 15:58:39.532', 8.0, 8.0, 100.0, 10, 7),
(5, 1, 1245, N'completed', '2026-08-01 15:57:26.437', '2026-08-01 16:00:57.100', 1.0, 8.0, 12.5, 7, 10),
(6, 1, 1248, N'completed', '2026-08-01 15:57:31.835', '2026-08-01 15:58:58.458', 7.0, 8.0, 87.5, 10, 8),
(7, 1, 1237, N'completed', '2026-08-01 15:57:51.091', '2026-08-01 15:59:10.810', 2.0, 8.0, 25.0, 7, 9),
(8, 1, 165, N'completed', '2026-08-01 16:00:28.026', '2026-08-01 16:13:11.783', 2.0, 8.0, 25.0, 7, 15),
(9, 1, 1254, N'completed', '2026-08-01 16:00:48.748', '2026-08-01 16:01:28.373', 8.0, 8.0, 100.0, 10, 11),
(10, 1, 1237, N'in_progress', '2026-08-01 16:00:55.691', NULL, NULL, NULL, NULL, NULL, NULL),
(11, 1, 1248, N'completed', '2026-08-01 16:02:31.994', '2026-08-01 16:09:27.516', 0.0, 8.0, 0.0, 7, 12),
(12, 1, 1234, N'completed', '2026-08-01 16:11:50.702', '2026-08-01 16:12:17.558', 4.0, 8.0, 50.0, 8, 14),
(13, 1, 1253, N'completed', '2026-08-01 16:14:56.921', '2026-08-01 16:15:04.610', 0.0, 9.0, 0.0, 7, 17),
(14, 1, 1253, N'completed', '2026-08-01 16:15:18.921', '2026-08-01 16:15:26.170', 1.0, 9.0, 11.11, 7, 18),
(15, 1, 1253, N'completed', '2026-08-01 16:15:32.318', '2026-08-01 16:17:04.104', 7.0, 9.0, 77.78, 9, 19),
(16, 2, 1254, N'completed', '2026-08-01 16:20:48.596', '2026-08-01 16:20:51.262', 1.0, 1.0, 100.0, NULL, 20),
(1002, 1, 1214, N'completed', '2026-08-03 14:56:12.924', '2026-08-03 15:01:53.025', 7.0, 9.0, 77.78, 9, 1005);
GO
SET IDENTITY_INSERT dbo.[PlacementAttempt] OFF;
GO

-- ===== DATA: PlacementAttemptAnswer (129 rows) =====
SET IDENTITY_INSERT dbo.[PlacementAttemptAnswer] ON;
GO
INSERT INTO dbo.[PlacementAttemptAnswer] ([Id], [AttemptRef], [QuestionRef], [SelectedOption], [IsCorrect], [PointsAwarded], [SortOrder])
VALUES
(1, 1, 4, N'B', 1, 1.0, 1),
(2, 1, 1, N'B', 1, 1.0, 2),
(3, 1, 8, N'B', 1, 1.0, 3),
(4, 1, 2, N'C', 1, 1.0, 4),
(5, 1, 7, N'A', 1, 1.0, 5),
(6, 1, 6, N'B', 1, 1.0, 6),
(7, 1, 5, N'B', 1, 1.0, 7),
(8, 1, 10, N'B', 1, 1.0, 8),
(9, 2, 6, NULL, 0, 0.0, 1),
(10, 2, 7, N'A', 1, 1.0, 2),
(11, 2, 2, N'D', 0, 0.0, 3),
(12, 2, 5, NULL, 0, 0.0, 4),
(13, 2, 10, NULL, 0, 0.0, 5),
(14, 2, 4, NULL, 0, 0.0, 6),
(15, 2, 8, NULL, 0, 0.0, 7),
(16, 2, 1, NULL, 0, 0.0, 8),
(17, 3, 6, N'B', 1, 1.0, 1),
(18, 3, 3, N'C', 1, 1.0, 2),
(19, 3, 10, N'B', 1, 1.0, 3),
(20, 3, 8, N'B', 1, 1.0, 4),
(21, 3, 1, N'B', 1, 1.0, 5),
(22, 3, 2, N'C', 1, 1.0, 6),
(23, 3, 5, N'B', 1, 1.0, 7),
(24, 3, 7, N'A', 1, 1.0, 8),
(25, 4, 10, N'B', 1, 1.0, 1),
(26, 4, 8, N'B', 1, 1.0, 2),
(27, 4, 7, N'A', 1, 1.0, 3),
(28, 4, 2, N'C', 1, 1.0, 4),
(29, 4, 6, N'B', 1, 1.0, 5),
(30, 4, 4, N'B', 1, 1.0, 6),
(31, 4, 1, N'B', 1, 1.0, 7),
(32, 4, 9, N'B', 1, 1.0, 8),
(33, 5, 4, N'B', 1, 1.0, 1),
(34, 5, 2, N'D', 0, 0.0, 2),
(35, 5, 7, N'D', 0, 0.0, 3),
(36, 5, 8, N'D', 0, 0.0, 4),
(37, 5, 5, N'C', 0, 0.0, 5),
(38, 5, 10, N'D', 0, 0.0, 6),
(39, 5, 3, N'D', 0, 0.0, 7),
(40, 5, 6, N'D', 0, 0.0, 8);
GO
INSERT INTO dbo.[PlacementAttemptAnswer] ([Id], [AttemptRef], [QuestionRef], [SelectedOption], [IsCorrect], [PointsAwarded], [SortOrder])
VALUES
(41, 6, 2, N'C', 1, 1.0, 1),
(42, 6, 10, N'B', 1, 1.0, 2),
(43, 6, 5, N'B', 1, 1.0, 3),
(44, 6, 4, N'B', 1, 1.0, 4),
(45, 6, 1, N'B', 1, 1.0, 5),
(46, 6, 8, N'C', 0, 0.0, 6),
(47, 6, 3, N'C', 1, 1.0, 7),
(48, 6, 9, N'B', 1, 1.0, 8),
(49, 7, 1, N'A', 0, 0.0, 1),
(50, 7, 3, N'A', 0, 0.0, 2),
(51, 7, 10, N'B', 1, 1.0, 3),
(52, 7, 9, N'A', 0, 0.0, 4),
(53, 7, 6, N'A', 0, 0.0, 5),
(54, 7, 4, N'B', 1, 1.0, 6),
(55, 7, 2, N'D', 0, 0.0, 7),
(56, 7, 5, N'C', 0, 0.0, 8),
(57, 8, 4, N'B', 1, 1.0, 1),
(58, 8, 9, NULL, 0, 0.0, 2),
(59, 8, 3, N'C', 1, 1.0, 3),
(60, 8, 8, N'C', 0, 0.0, 4),
(61, 8, 6, NULL, 0, 0.0, 5),
(62, 8, 7, N'B', 0, 0.0, 6),
(63, 8, 5, NULL, 0, 0.0, 7),
(64, 8, 2, NULL, 0, 0.0, 8),
(65, 9, 8, N'B', 1, 1.0, 1),
(66, 9, 10, N'B', 1, 1.0, 2),
(67, 9, 2, N'C', 1, 1.0, 3),
(68, 9, 1, N'B', 1, 1.0, 4),
(69, 9, 5, N'B', 1, 1.0, 5),
(70, 9, 4, N'B', 1, 1.0, 6),
(71, 9, 6, N'B', 1, 1.0, 7),
(72, 9, 9, N'B', 1, 1.0, 8),
(73, 10, 4, N'A', NULL, NULL, 1),
(74, 10, 9, N'A', NULL, NULL, 2),
(75, 10, 3, NULL, NULL, NULL, 3),
(76, 10, 10, N'C', NULL, NULL, 4),
(77, 10, 5, N'D', NULL, NULL, 5),
(78, 10, 8, NULL, NULL, NULL, 6),
(79, 10, 6, N'B', NULL, NULL, 7),
(80, 10, 7, N'D', NULL, NULL, 8);
GO
INSERT INTO dbo.[PlacementAttemptAnswer] ([Id], [AttemptRef], [QuestionRef], [SelectedOption], [IsCorrect], [PointsAwarded], [SortOrder])
VALUES
(81, 11, 6, N'C', 0, 0.0, 1),
(82, 11, 10, NULL, 0, 0.0, 2),
(83, 11, 7, NULL, 0, 0.0, 3),
(84, 11, 1, NULL, 0, 0.0, 4),
(85, 11, 8, NULL, 0, 0.0, 5),
(86, 11, 2, NULL, 0, 0.0, 6),
(87, 11, 3, NULL, 0, 0.0, 7),
(88, 11, 9, NULL, 0, 0.0, 8),
(89, 12, 7, NULL, 0, 0.0, 1),
(90, 12, 3, N'C', 1, 1.0, 2),
(91, 12, 5, N'A', 0, 0.0, 3),
(92, 12, 1, N'B', 1, 1.0, 4),
(93, 12, 2, N'C', 1, 1.0, 5),
(94, 12, 6, NULL, 0, 0.0, 6),
(95, 12, 4, N'B', 1, 1.0, 7),
(96, 12, 8, NULL, 0, 0.0, 8),
(97, 13, 2, N'A', 0, 0.0, 1),
(98, 13, 4, NULL, 0, 0.0, 2),
(99, 13, 8, NULL, 0, 0.0, 3),
(100, 13, 5, NULL, 0, 0.0, 4),
(101, 13, 7, NULL, 0, 0.0, 5),
(102, 13, 3, NULL, 0, 0.0, 6),
(103, 13, 1, NULL, 0, 0.0, 7),
(104, 13, 11, NULL, 0, 0.0, 8),
(105, 14, 7, N'A', 1, 1.0, 1),
(106, 14, 11, NULL, 0, 0.0, 2),
(107, 14, 6, NULL, 0, 0.0, 3),
(108, 14, 2, NULL, 0, 0.0, 4),
(109, 14, 1, NULL, 0, 0.0, 5),
(110, 14, 4, NULL, 0, 0.0, 6),
(111, 14, 5, NULL, 0, 0.0, 7),
(112, 14, 8, NULL, 0, 0.0, 8),
(113, 15, 4, N'B', 1, 1.0, 1),
(114, 15, 8, N'B', 1, 1.0, 2),
(115, 15, 7, N'A', 1, 1.0, 3),
(116, 15, 2, N'C', 1, 1.0, 4),
(117, 15, 1, N'B', 1, 1.0, 5),
(118, 15, 11, N'A', 0, 0.0, 6),
(119, 15, 6, N'B', 1, 1.0, 7),
(120, 15, 5, N'B', 1, 1.0, 8);
GO
INSERT INTO dbo.[PlacementAttemptAnswer] ([Id], [AttemptRef], [QuestionRef], [SelectedOption], [IsCorrect], [PointsAwarded], [SortOrder])
VALUES
(121, 16, 12, N'A', 1, 1.0, 1),
(1002, 1002, 3, N'C', 1, 1.0, 1),
(1003, 1002, 8, N'B', 1, 1.0, 2),
(1004, 1002, 11, N'B', 0, 0.0, 3),
(1005, 1002, 4, N'B', 1, 1.0, 4),
(1006, 1002, 2, N'C', 1, 1.0, 5),
(1007, 1002, 7, N'A', 1, 1.0, 6),
(1008, 1002, 1, N'B', 1, 1.0, 7),
(1009, 1002, 5, N'B', 1, 1.0, 8);
GO
SET IDENTITY_INSERT dbo.[PlacementAttemptAnswer] OFF;
GO

-- ===== DATA: ActivityLog (1835 rows) =====
SET IDENTITY_INSERT dbo.[ActivityLog] ON;
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1, NULL, NULL, N'event', N'system', NULL, N'تست لاگ', N'{"ok": true}', NULL, NULL, NULL, NULL, '2026-08-01 14:44:32.982'),
(2, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 14:47:41.913'),
(3, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/22', 200, N'127.0.0.1', '2026-08-01 14:47:43.654'),
(4, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 14:47:47.715'),
(5, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:47:59.188'),
(6, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:48:18.787'),
(7, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:48:40.759'),
(8, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1248', 200, N'127.0.0.1', '2026-08-01 14:48:40.804'),
(9, 1, N'admin', N'create', N'shop', NULL, N'ایجاد فروشگاه', N'{"query": null}', N'POST', N'/shop/products', 201, N'127.0.0.1', '2026-08-01 14:48:53.387'),
(10, 1, N'admin', N'create', N'teacher', NULL, N'ایجاد مدرس', N'{"query": null}', N'POST', N'/teachers', 201, N'127.0.0.1', '2026-08-01 14:49:00.880'),
(11, 1, N'admin', N'create', N'teacher', NULL, N'ایجاد مدرس', N'{"query": null}', N'POST', N'/teachers/87/photo', 200, N'127.0.0.1', '2026-08-01 14:49:01.010'),
(12, 22, N'Eli', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 14:49:18.082'),
(13, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:49:22.646'),
(14, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1247', 200, N'127.0.0.1', '2026-08-01 14:49:22.771'),
(15, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:49:32.901'),
(16, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 14:49:51.238'),
(17, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/22', 200, N'127.0.0.1', '2026-08-01 14:49:55.241'),
(18, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 14:49:57.639'),
(19, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:49:58.904'),
(20, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1246', 200, N'127.0.0.1', '2026-08-01 14:49:58.984'),
(21, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:50:08.180'),
(22, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:50:19.264'),
(23, 19, N'zahra', N'create', N'attendance', NULL, N'ایجاد attendance', N'{"query": null}', N'POST', N'/attendance/bulk', 201, N'127.0.0.1', '2026-08-01 14:50:40.596'),
(24, 22, N'Eli', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/69', 200, N'127.0.0.1', '2026-08-01 14:51:08.602'),
(25, 1, N'admin', N'update', N'shop', NULL, N'ناموفق: ویرایش فروشگاه (422)', N'{"query": null}', N'PUT', N'/shop/products/11', 422, N'127.0.0.1', '2026-08-01 14:51:09.143'),
(26, 19, N'zahra', N'create', N'attendance', NULL, N'ایجاد attendance', N'{"query": null}', N'POST', N'/attendance/bulk', 201, N'127.0.0.1', '2026-08-01 14:51:09.623'),
(27, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1248', 200, N'127.0.0.1', '2026-08-01 14:51:12.841'),
(28, 1, N'admin', N'update', N'shop', NULL, N'ویرایش فروشگاه', N'{"query": null}', N'PUT', N'/shop/products/11', 200, N'127.0.0.1', '2026-08-01 14:51:16.459'),
(29, 22, N'Eli', N'delete', N'teacher', NULL, N'حذف مدرس', N'{"query": null}', N'DELETE', N'/teachers/5', 200, N'127.0.0.1', '2026-08-01 14:51:16.925'),
(30, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1236', 200, N'127.0.0.1', '2026-08-01 14:51:18.352'),
(31, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1120', 200, N'127.0.0.1', '2026-08-01 14:51:28.061'),
(32, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1120', 200, N'127.0.0.1', '2026-08-01 14:51:28.065'),
(33, 20, N'sama', N'create', N'enrollment', NULL, N'ایجاد ثبت‌نام', N'{"query": null}', N'POST', N'/enrollments', 201, N'127.0.0.1', '2026-08-01 14:51:34.123'),
(34, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1245', 200, N'127.0.0.1', '2026-08-01 14:51:36.860'),
(35, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1241', 200, N'127.0.0.1', '2026-08-01 14:51:41.708'),
(36, 22, N'Eli', N'update', N'enrollment', NULL, N'ویرایش ثبت‌نام', N'{"query": null}', N'PUT', N'/enrollments/1238', 200, N'127.0.0.1', '2026-08-01 14:51:42.189'),
(37, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1235', 200, N'127.0.0.1', '2026-08-01 14:51:47.867'),
(38, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:51:50.744'),
(39, 1, N'admin', N'update', N'payment', NULL, N'ناموفق: ویرایش پرداخت (404)', N'{"query": null}', N'PUT', N'/payments/183', 404, N'127.0.0.1', '2026-08-01 14:51:50.763'),
(40, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1234', 200, N'127.0.0.1', '2026-08-01 14:51:52.204');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(41, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1229', 200, N'127.0.0.1', '2026-08-01 14:52:01.123'),
(42, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1226', 200, N'127.0.0.1', '2026-08-01 14:52:06.621'),
(43, 19, N'zahra', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 14:52:17.372'),
(44, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:52:20.457'),
(45, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/120', 200, N'127.0.0.1', '2026-08-01 14:52:20.849'),
(46, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/1249', 200, N'127.0.0.1', '2026-08-01 14:52:33.291'),
(47, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:52:34.609'),
(48, 1, N'admin', N'update', N'payment', NULL, N'ویرایش پرداخت', N'{"query": null}', N'PUT', N'/payments/183', 200, N'127.0.0.1', '2026-08-01 14:52:34.695'),
(49, 1, N'admin', N'create', N'payment', NULL, N'ایجاد پرداخت', N'{"query": null}', N'POST', N'/payments', 201, N'127.0.0.1', '2026-08-01 14:52:34.773'),
(50, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/184', 200, N'127.0.0.1', '2026-08-01 14:52:34.779'),
(51, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/1228', 200, N'127.0.0.1', '2026-08-01 14:52:42.069'),
(52, 22, N'Eli', N'update', N'enrollment', NULL, N'ویرایش ثبت‌نام', N'{"query": null}', N'PUT', N'/enrollments/1238', 200, N'127.0.0.1', '2026-08-01 14:52:43.752'),
(53, 22, N'Eli', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 14:52:55.107'),
(54, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/126', 200, N'127.0.0.1', '2026-08-01 14:52:55.329'),
(55, 20, N'sama', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 14:52:56.696'),
(56, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:52:59.768'),
(57, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 14:53:21.185'),
(58, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/147', 200, N'127.0.0.1', '2026-08-01 14:53:21.713'),
(59, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/122', 200, N'127.0.0.1', '2026-08-01 14:53:24.780'),
(60, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:53:36.217'),
(61, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1249', 200, N'127.0.0.1', '2026-08-01 14:53:41.762'),
(62, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/114', 200, N'127.0.0.1', '2026-08-01 14:53:42.365'),
(63, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/127', 200, N'127.0.0.1', '2026-08-01 14:53:53.207'),
(64, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/117', 200, N'127.0.0.1', '2026-08-01 14:53:57.892'),
(65, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/77', 200, N'127.0.0.1', '2026-08-01 14:53:59.141'),
(66, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/19', 200, N'127.0.0.1', '2026-08-01 14:54:01.247'),
(67, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/18', 200, N'127.0.0.1', '2026-08-01 14:54:02.059'),
(68, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/81', 200, N'127.0.0.1', '2026-08-01 14:54:08.205'),
(69, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 14:54:15.158'),
(70, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:54:18.289'),
(71, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/1242', 200, N'127.0.0.1', '2026-08-01 14:54:19.031'),
(72, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/1233', 200, N'127.0.0.1', '2026-08-01 14:54:27.294'),
(73, 18, N'elyar1390', N'create', N'shop', NULL, N'ایجاد فروشگاه', N'{"query": null}', N'POST', N'/shop/cart', 200, N'127.0.0.1', '2026-08-01 14:54:28.225'),
(74, 1, N'admin', N'delete', N'enrollment', NULL, N'حذف ثبت‌نام', N'{"query": null}', N'DELETE', N'/enrollments/1233', 200, N'127.0.0.1', '2026-08-01 14:54:28.437'),
(75, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/125', 200, N'127.0.0.1', '2026-08-01 14:54:32.662'),
(76, 18, N'elyar1390', N'create', N'shop', NULL, N'ایجاد فروشگاه', N'{"query": null}', N'POST', N'/shop/checkout', 201, N'127.0.0.1', '2026-08-01 14:54:37.602'),
(77, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 14:54:39.039'),
(78, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 14:54:39.250'),
(79, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 14:54:39.460'),
(80, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 14:54:39.676');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(81, 1, N'admin', N'update', N'enrollment', NULL, N'ویرایش ثبت‌نام', N'{"query": null}', N'PUT', N'/enrollments/1244', 200, N'127.0.0.1', '2026-08-01 14:54:43.169'),
(82, 18, N'elyar1390', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 14:54:44.647'),
(83, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/1238', 200, N'127.0.0.1', '2026-08-01 14:54:47.218'),
(84, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:54:47.800'),
(85, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:54:52.011'),
(86, 1, N'admin', N'create', N'user', NULL, N'ایجاد کاربر', N'{"query": null}', N'POST', N'/users', 201, N'127.0.0.1', '2026-08-01 14:54:52.235'),
(87, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:54:52.451'),
(88, 23, N'finance_test', N'create', N'enrollment', NULL, N'ناموفق: ایجاد ثبت‌نام (403)', N'{"query": null}', N'POST', N'/enrollments', 403, N'127.0.0.1', '2026-08-01 14:54:52.463'),
(89, 23, N'finance_test', N'create', N'enrollment', NULL, N'ناموفق: ایجاد ثبت‌نام (403)', N'{"query": null}', N'POST', N'/enrollments/bulk', 403, N'127.0.0.1', '2026-08-01 14:54:52.470'),
(90, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/123', 200, N'127.0.0.1', '2026-08-01 14:55:03.003'),
(91, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/150', 200, N'127.0.0.1', '2026-08-01 14:55:27.529'),
(92, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/82', 200, N'127.0.0.1', '2026-08-01 14:55:41.175'),
(93, 1, N'admin', N'delete', N'teacher', NULL, N'حذف مدرس', N'{"query": null}', N'DELETE', N'/teachers/11', 200, N'127.0.0.1', '2026-08-01 14:55:45.179'),
(94, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/118', 200, N'127.0.0.1', '2026-08-01 14:55:52.787'),
(95, 1, N'admin', N'update', N'teacher', NULL, N'ویرایش مدرس', N'{"query": null}', N'PUT', N'/teachers/42', 200, N'127.0.0.1', '2026-08-01 14:55:54.792'),
(96, 1, N'admin', N'delete', N'teacher', NULL, N'حذف مدرس', N'{"query": null}', N'DELETE', N'/teachers/85', 200, N'127.0.0.1', '2026-08-01 14:56:25.519'),
(97, 1, N'admin', N'delete', N'teacher', NULL, N'حذف مدرس', N'{"query": null}', N'DELETE', N'/teachers/87', 200, N'127.0.0.1', '2026-08-01 14:56:33.324'),
(98, 1, N'admin', N'delete', N'teacher', NULL, N'حذف مدرس', N'{"query": null}', N'DELETE', N'/teachers/40', 200, N'127.0.0.1', '2026-08-01 14:56:40.625'),
(99, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/177', 200, N'127.0.0.1', '2026-08-01 14:57:32.396'),
(100, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/183', 200, N'127.0.0.1', '2026-08-01 14:57:36.034'),
(101, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/180', 200, N'127.0.0.1', '2026-08-01 14:57:42.674'),
(102, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/167', 200, N'127.0.0.1', '2026-08-01 14:57:59.322'),
(103, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/179', 200, N'127.0.0.1', '2026-08-01 14:58:04.994'),
(104, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 14:58:07.059'),
(105, 1, N'admin', N'create', N'score', NULL, N'ایجاد score', N'{"query": null}', N'POST', N'/scores', 201, N'127.0.0.1', '2026-08-01 14:58:07.083'),
(106, 1, N'admin', N'update', N'score', NULL, N'ویرایش score', N'{"query": null}', N'PUT', N'/scores/2', 200, N'127.0.0.1', '2026-08-01 14:58:07.109'),
(107, 1, N'admin', N'delete', N'score', NULL, N'حذف score', N'{"query": null}', N'DELETE', N'/scores/2', 200, N'127.0.0.1', '2026-08-01 14:58:07.116'),
(108, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/176', 200, N'127.0.0.1', '2026-08-01 14:58:11.522'),
(109, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/173', 200, N'127.0.0.1', '2026-08-01 14:58:16.642'),
(110, 1, N'admin', N'delete', N'student', NULL, N'حذف زبان‌آموز', N'{"query": null}', N'DELETE', N'/students/9', 200, N'127.0.0.1', '2026-08-01 14:58:33.433'),
(111, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/153', 200, N'127.0.0.1', '2026-08-01 14:58:36.196'),
(112, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/155', 200, N'127.0.0.1', '2026-08-01 14:58:46.198'),
(113, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/21', 200, N'127.0.0.1', '2026-08-01 14:58:47.300'),
(114, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/154', 200, N'127.0.0.1', '2026-08-01 14:58:54.182'),
(115, 1, N'admin', N'delete', N'session-types', NULL, N'حذف session-types', N'{"query": null}', N'DELETE', N'/session-types/6', 200, N'127.0.0.1', '2026-08-01 14:58:57.745'),
(116, 1, N'admin', N'delete', N'branch', NULL, N'حذف شعبه', N'{"query": null}', N'DELETE', N'/branches/20', 200, N'127.0.0.1', '2026-08-01 14:59:02.406'),
(117, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/136', 200, N'127.0.0.1', '2026-08-01 14:59:04.071'),
(118, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/133', 200, N'127.0.0.1', '2026-08-01 14:59:40.340'),
(119, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/152', 200, N'127.0.0.1', '2026-08-01 14:59:50.862'),
(120, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/123', 200, N'127.0.0.1', '2026-08-01 15:00:04.782');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(121, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/127', 200, N'127.0.0.1', '2026-08-01 15:00:16.529'),
(122, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/126', 200, N'127.0.0.1', '2026-08-01 15:00:30.175'),
(123, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:00:44.163'),
(124, 1, N'admin', N'create', N'student', NULL, N'ایجاد زبان‌آموز', N'{"query": null}', N'POST', N'/students', 201, N'127.0.0.1', '2026-08-01 15:00:44.178'),
(125, 1, N'admin', N'create', N'student', NULL, N'ایجاد زبان‌آموز', N'{"query": null}', N'POST', N'/students', 201, N'127.0.0.1', '2026-08-01 15:00:44.186'),
(126, 1, N'admin', N'create', N'student', NULL, N'ایجاد زبان‌آموز', N'{"query": null}', N'POST', N'/students/bulk-delete', 200, N'127.0.0.1', '2026-08-01 15:00:44.203'),
(127, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/92', 200, N'127.0.0.1', '2026-08-01 15:00:47.490'),
(128, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/94', 200, N'127.0.0.1', '2026-08-01 15:00:58.243'),
(129, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/66', 200, N'127.0.0.1', '2026-08-01 15:01:19.473'),
(130, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/74', 200, N'127.0.0.1', '2026-08-01 15:01:36.160'),
(131, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/96', 200, N'127.0.0.1', '2026-08-01 15:01:49.164'),
(132, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/17', 200, N'127.0.0.1', '2026-08-01 15:02:45.879'),
(133, 11, N'arshya', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:03:00.145'),
(134, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:03:03.601'),
(135, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:03:13.019'),
(136, 1, N'admin', N'delete', N'payment', NULL, N'حذف پرداخت', N'{"query": null}', N'DELETE', N'/payments/182', 200, N'127.0.0.1', '2026-08-01 15:03:34.874'),
(137, 1, N'admin', N'update', N'payment', NULL, N'ویرایش پرداخت', N'{"query": null}', N'PUT', N'/payments/181', 200, N'127.0.0.1', '2026-08-01 15:03:43.684'),
(138, 1, N'admin', N'update', N'payment', NULL, N'ویرایش پرداخت', N'{"query": null}', N'PUT', N'/payments/172', 200, N'127.0.0.1', '2026-08-01 15:03:50.670'),
(139, 1, N'admin', N'create', N'teacher', NULL, N'ایجاد مدرس', N'{"query": null}', N'POST', N'/teachers', 201, N'127.0.0.1', '2026-08-01 15:04:21.205'),
(140, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:04:29.238'),
(141, 1, N'admin', N'create', N'user', NULL, N'ایجاد کاربر', N'{"query": null}', N'POST', N'/users', 201, N'127.0.0.1', '2026-08-01 15:04:29.462'),
(142, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:04:29.686'),
(143, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:16:11.465'),
(144, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:16:12.616'),
(145, 16, N'Amir05', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:16:20.632'),
(146, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:16:25.882'),
(147, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/18', 200, N'127.0.0.1', '2026-08-01 15:16:28.136'),
(148, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:16:31.188'),
(149, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:16:34.054'),
(150, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:16:36.196'),
(151, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:16:43.660'),
(152, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:16:44.193'),
(153, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:16:47.773'),
(154, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:17:06.404'),
(155, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/22', 200, N'127.0.0.1', '2026-08-01 15:18:12.130'),
(156, 19, N'zahra', N'create', N'attendance', NULL, N'ایجاد attendance', N'{"query": null}', N'POST', N'/attendance/bulk', 201, N'127.0.0.1', '2026-08-01 15:18:12.422'),
(157, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:18:15.176'),
(158, 1, N'admin', N'create', N'score', NULL, N'ایجاد score', N'{"query": null}', N'POST', N'/scores', 201, N'127.0.0.1', '2026-08-01 15:18:20.525'),
(159, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:18:34.171'),
(160, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:18:43.267');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(161, 18, N'elyar1390', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:19:16.644'),
(162, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:19:19.791'),
(163, 19, N'zahra', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:19:45.674'),
(164, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:19:49.543'),
(165, 19, N'zahra', N'create', N'attendance', NULL, N'ایجاد attendance', N'{"query": null}', N'POST', N'/attendance/bulk', 201, N'127.0.0.1', '2026-08-01 15:19:56.995'),
(166, NULL, NULL, N'register', N'auth', NULL, N'ناموفق: ثبت‌نام کاربری احراز هویت (400)', N'{"query": null}', N'POST', N'/auth/register', 400, N'127.0.0.1', '2026-08-01 15:20:24.881'),
(167, 19, N'zahra', N'update', N'score', NULL, N'ویرایش score', N'{"query": null}', N'PUT', N'/scores/1', 200, N'127.0.0.1', '2026-08-01 15:20:52.638'),
(168, NULL, NULL, N'register', N'auth', NULL, N'ثبت‌نام کاربری احراز هویت', N'{"query": null}', N'POST', N'/auth/register', 201, N'127.0.0.1', '2026-08-01 15:21:21.319'),
(169, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/17', 200, N'127.0.0.1', '2026-08-01 15:21:29.751'),
(170, 25, N'Ali', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:21:34.380'),
(171, 17, N'arshya1', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:21:39.194'),
(172, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:21:45.203'),
(173, 17, N'arshya1', N'create', N'attendance', NULL, N'ایجاد attendance', N'{"query": null}', N'POST', N'/attendance/bulk', 201, N'127.0.0.1', '2026-08-01 15:21:55.182'),
(174, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:21:58.493'),
(175, 13, N'ابراهیم رئیسی', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:22:14.420'),
(176, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:22:34.288'),
(177, 1, N'admin', N'update', N'shop', NULL, N'ویرایش فروشگاه', N'{"query": null}', N'PUT', N'/shop/products/7', 200, N'127.0.0.1', '2026-08-01 15:23:43.858'),
(178, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/25', 200, N'127.0.0.1', '2026-08-01 15:24:03.612'),
(179, 1, N'admin', N'update', N'shop', NULL, N'ویرایش فروشگاه', N'{"query": null}', N'PUT', N'/shop/products/7', 200, N'127.0.0.1', '2026-08-01 15:24:03.745'),
(180, 19, N'zahra', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:24:56.234'),
(181, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:25:00.156'),
(182, 13, N'ابراهیم رئیسی', N'create', N'shop', NULL, N'ایجاد فروشگاه', N'{"query": null}', N'POST', N'/shop/products/6/bookmark', 200, N'127.0.0.1', '2026-08-01 15:25:05.908'),
(183, 13, N'ابراهیم رئیسی', N'create', N'shop', NULL, N'ایجاد فروشگاه', N'{"query": null}', N'POST', N'/shop/products/11/like', 200, N'127.0.0.1', '2026-08-01 15:25:07.954'),
(184, 13, N'ابراهیم رئیسی', N'create', N'shop', NULL, N'ایجاد فروشگاه', N'{"query": null}', N'POST', N'/shop/cart', 200, N'127.0.0.1', '2026-08-01 15:25:21.064'),
(185, 13, N'ابراهیم رئیسی', N'create', N'shop', NULL, N'ایجاد فروشگاه', N'{"query": null}', N'POST', N'/shop/checkout', 201, N'127.0.0.1', '2026-08-01 15:25:47.696'),
(186, 13, N'ابراهیم رئیسی', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:25:58.709'),
(187, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:26:01.904'),
(188, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/13', 200, N'127.0.0.1', '2026-08-01 15:26:55.024'),
(189, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:27:26.704'),
(190, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:28:00.229'),
(191, 1, N'admin', N'update', N'teacher', NULL, N'ویرایش مدرس', N'{"query": null}', N'PUT', N'/teachers/9', 200, N'127.0.0.1', '2026-08-01 15:31:26.960'),
(192, 1, N'admin', N'create', N'teacher', NULL, N'ایجاد مدرس', N'{"query": null}', N'POST', N'/teachers/9/photo', 200, N'127.0.0.1', '2026-08-01 15:31:27.024'),
(193, 1, N'admin', N'update', N'teacher', NULL, N'ویرایش مدرس', N'{"query": null}', N'PUT', N'/teachers/1', 200, N'127.0.0.1', '2026-08-01 15:31:27.684'),
(194, 1, N'admin', N'create', N'teacher', NULL, N'ایجاد مدرس', N'{"query": null}', N'POST', N'/teachers/1/photo', 200, N'127.0.0.1', '2026-08-01 15:31:27.708'),
(195, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:31:43.086'),
(196, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:31:46.809'),
(197, 1, N'admin', N'update', N'teacher', NULL, N'ویرایش مدرس', N'{"query": null}', N'PUT', N'/teachers/9', 200, N'127.0.0.1', '2026-08-01 15:31:56.839'),
(198, 1, N'admin', N'delete', N'teacher', NULL, N'حذف مدرس', N'{"query": null}', N'DELETE', N'/teachers/9/photo', 200, N'127.0.0.1', '2026-08-01 15:31:56.863'),
(199, 19, N'zahra', N'create', N'attendance', NULL, N'ایجاد attendance', N'{"query": null}', N'POST', N'/attendance/bulk', 201, N'127.0.0.1', '2026-08-01 15:32:05.932'),
(200, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:32:40.564');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(201, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:32:44.384'),
(202, 19, N'zahra', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:33:15.695'),
(203, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:33:24.495'),
(204, 25, N'Ali', N'create', N'attendance', NULL, N'ایجاد attendance', N'{"query": null}', N'POST', N'/attendance/bulk', 201, N'127.0.0.1', '2026-08-01 15:33:35.642'),
(205, 18, N'elyar1390', N'create', N'attendance', NULL, N'ایجاد attendance', N'{"query": null}', N'POST', N'/attendance/bulk', 201, N'127.0.0.1', '2026-08-01 15:33:59.252'),
(206, 25, N'Ali', N'create', N'shop', NULL, N'ایجاد فروشگاه', N'{"query": null}', N'POST', N'/shop/cart', 200, N'127.0.0.1', '2026-08-01 15:34:07.528'),
(207, 25, N'Ali', N'create', N'shop', NULL, N'ایجاد فروشگاه', N'{"query": null}', N'POST', N'/shop/checkout', 201, N'127.0.0.1', '2026-08-01 15:34:10.349'),
(208, 19, N'zahra', N'create', N'attendance', NULL, N'ایجاد attendance', N'{"query": null}', N'POST', N'/attendance/bulk', 201, N'127.0.0.1', '2026-08-01 15:34:13.942'),
(209, 19, N'zahra', N'create', N'attendance', NULL, N'ایجاد attendance', N'{"query": null}', N'POST', N'/attendance/bulk', 201, N'127.0.0.1', '2026-08-01 15:34:24.822'),
(210, 1, N'admin', N'create', N'score', NULL, N'ایجاد score', N'{"query": null}', N'POST', N'/scores', 201, N'127.0.0.1', '2026-08-01 15:34:26.276'),
(211, 19, N'zahra', N'create', N'attendance', NULL, N'ایجاد attendance', N'{"query": null}', N'POST', N'/attendance/bulk', 201, N'127.0.0.1', '2026-08-01 15:34:36.440'),
(212, 1, N'admin', N'update', N'teacher', NULL, N'ویرایش مدرس', N'{"query": null}', N'PUT', N'/teachers/38', 200, N'127.0.0.1', '2026-08-01 15:35:06.582'),
(213, 1, N'admin', N'create', N'teacher', NULL, N'ایجاد مدرس', N'{"query": null}', N'POST', N'/teachers/38/photo', 200, N'127.0.0.1', '2026-08-01 15:35:06.628'),
(214, 19, N'zahra', N'update', N'score', NULL, N'ویرایش score', N'{"query": null}', N'PUT', N'/scores/4', 200, N'127.0.0.1', '2026-08-01 15:35:09.521'),
(215, 25, N'Ali', N'update', N'score', NULL, N'ویرایش score', N'{"query": null}', N'PUT', N'/scores/4', 200, N'127.0.0.1', '2026-08-01 15:36:36.165'),
(216, 1, N'admin', N'update', N'score', NULL, N'ویرایش score', N'{"query": null}', N'PUT', N'/scores/4', 200, N'127.0.0.1', '2026-08-01 15:36:38.115'),
(217, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:36:53.174'),
(218, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:36:56.303'),
(219, 13, N'ابراهیم رئیسی', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:38:10.531'),
(220, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:38:13.765'),
(221, 25, N'Ali', N'update', N'score', NULL, N'ویرایش score', N'{"query": null}', N'PUT', N'/scores/4', 200, N'127.0.0.1', '2026-08-01 15:38:26.604'),
(222, 13, N'ابراهیم رئیسی', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:39:11.104'),
(223, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:39:15.652'),
(224, 1, N'admin', N'create', N'teacher', NULL, N'ناموفق: ایجاد مدرس (422)', N'{"query": null}', N'POST', N'/teachers', 422, N'127.0.0.1', '2026-08-01 15:39:30.582'),
(225, 25, N'Ali', N'create', N'attendance', NULL, N'ایجاد attendance', N'{"query": null}', N'POST', N'/attendance/bulk', 201, N'127.0.0.1', '2026-08-01 15:39:33.248'),
(226, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:39:51.288'),
(227, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:43.726'),
(228, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:44.380'),
(229, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:44.439'),
(230, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:44.990'),
(231, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:45.502'),
(232, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:45.676'),
(233, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:45.987'),
(234, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:46.483'),
(235, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:46.928'),
(236, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:47.051'),
(237, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:47.151'),
(238, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:47.642'),
(239, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:48.145'),
(240, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:48.202');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(241, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:48.545'),
(242, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:48.680'),
(243, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:48.815'),
(244, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:48.848'),
(245, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:49.024'),
(246, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:49.241'),
(247, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:49.423'),
(248, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:49.454'),
(249, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:49.479'),
(250, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:49.737'),
(251, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:49.745'),
(252, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:49.952'),
(253, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:50.119'),
(254, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:50.137'),
(255, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:50.149'),
(256, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:50.794'),
(257, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:50.815'),
(258, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:50.983'),
(259, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:51.262'),
(260, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:51.422'),
(261, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:51.440'),
(262, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:51.479'),
(263, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:51.501'),
(264, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:51.520'),
(265, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:51.614'),
(266, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:52.061'),
(267, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:52.096'),
(268, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:52.100'),
(269, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:52.281'),
(270, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:53.199'),
(271, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:53.423'),
(272, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:53.605'),
(273, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:53.766'),
(274, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:53.800'),
(275, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:54.297'),
(276, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:54.406'),
(277, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:54.568'),
(278, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:54.703'),
(279, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:55.127'),
(280, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:55.310');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(281, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:55.430'),
(282, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:55.517'),
(283, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:55.531'),
(284, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:55.871'),
(285, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:55.899'),
(286, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:56.050'),
(287, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:56.238'),
(288, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:56.640'),
(289, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:56.666'),
(290, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:56.950'),
(291, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:57.026'),
(292, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:57.090'),
(293, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:57.287'),
(294, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:57.317'),
(295, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:57.466'),
(296, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:57.633'),
(297, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:57.730'),
(298, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:58.041'),
(299, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:58.100'),
(300, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:58.306'),
(301, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:58.328'),
(302, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:58.484'),
(303, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:58.666'),
(304, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:58.842'),
(305, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:58.869'),
(306, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:58.900'),
(307, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:58.991'),
(308, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:59.022'),
(309, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:59.254'),
(310, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:59.397'),
(311, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:59.423'),
(312, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:59.551'),
(313, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:59.567'),
(314, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:59.718'),
(315, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:59.760'),
(316, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:59.952'),
(317, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:40:59.970'),
(318, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:00.195'),
(319, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:00.417'),
(320, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:00.633');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(321, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:01.156'),
(322, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:01.590'),
(323, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:01.645'),
(324, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:01.806'),
(325, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:01.869'),
(326, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:01.927'),
(327, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:02.079'),
(328, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:02.082'),
(329, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:02.275'),
(330, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:02.304'),
(331, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:02.398'),
(332, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:02.566'),
(333, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:02.689'),
(334, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:03.184'),
(335, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:03.358'),
(336, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:03.423'),
(337, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:03.508'),
(338, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:03.827'),
(339, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:03.945'),
(340, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:03.967'),
(341, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:04.104'),
(342, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:04.583'),
(343, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:04.590'),
(344, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:04.764'),
(345, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:04.806'),
(346, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:05.024'),
(347, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:05.035'),
(348, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:05.238'),
(349, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:05.522'),
(350, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:05.752'),
(351, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:05.802'),
(352, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:05.815'),
(353, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:05.941'),
(354, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:05.961'),
(355, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:06.103'),
(356, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:06.257'),
(357, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:06.328'),
(358, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:06.431'),
(359, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:06.495'),
(360, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:06.623');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(361, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:06.630'),
(362, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:06.766'),
(363, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:07.016'),
(364, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:07.039'),
(365, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:07.201'),
(366, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:07.249'),
(367, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:07.359'),
(368, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:07.855'),
(369, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:08.039'),
(370, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:08.057'),
(371, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:08.079'),
(372, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:08.289'),
(373, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:08.408'),
(374, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:08.445'),
(375, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:08.587'),
(376, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:08.775'),
(377, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:08.936'),
(378, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:09.062'),
(379, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:09.104'),
(380, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:09.216'),
(381, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:09.383'),
(382, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:09.553'),
(383, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:09.616'),
(384, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:10.164'),
(385, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:11.216'),
(386, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:14.302'),
(387, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:14.919'),
(388, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:15.486'),
(389, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:22.618'),
(390, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:23.634'),
(391, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:23.967'),
(392, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:24.229'),
(393, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:24.442'),
(394, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:24.982'),
(395, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:28.256'),
(396, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:29.804'),
(397, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:30.642'),
(398, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:30.971'),
(399, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:31.226'),
(400, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:31.545');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(401, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:31.747'),
(402, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:31.968'),
(403, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:32.139'),
(404, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:32.315'),
(405, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:32.510'),
(406, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:32.742'),
(407, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:33.338'),
(408, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:33.608'),
(409, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:33.812'),
(410, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:34.405'),
(411, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:34.766'),
(412, 19, N'zahra', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:41:34.965'),
(413, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:34.972'),
(414, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:35.165'),
(415, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:35.348'),
(416, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:35.838'),
(417, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:36.988'),
(418, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:37.519'),
(419, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:41:38.328'),
(420, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:38.387'),
(421, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:39.273'),
(422, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:39.804'),
(423, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:40.149'),
(424, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:40.735'),
(425, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:40.991'),
(426, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:41.174'),
(427, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:41.404'),
(428, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:41.606'),
(429, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:41:41.900'),
(430, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:41:42.121'),
(431, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:41:42.371'),
(432, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:41:42.612'),
(433, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:42.619'),
(434, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:41:42.857'),
(435, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:42.876'),
(436, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:43.120'),
(437, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:43.587'),
(438, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:43.848'),
(439, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:44.093'),
(440, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:45.307');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(441, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:45.470'),
(442, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:45.897'),
(443, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:46.244'),
(444, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:46.812'),
(445, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:47.052'),
(446, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:47.341'),
(447, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:47.428'),
(448, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:47.574'),
(449, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:47.590'),
(450, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:48.445'),
(451, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:48.742'),
(452, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:48.940'),
(453, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:49.171'),
(454, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:49.403'),
(455, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:49.636'),
(456, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:49.867'),
(457, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:50.067'),
(458, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:50.313'),
(459, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:50.820'),
(460, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:51.051'),
(461, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:51.262'),
(462, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:51.479'),
(463, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:51.699'),
(464, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:51.899'),
(465, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:52.092'),
(466, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:52.339'),
(467, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:52.571'),
(468, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:52.750'),
(469, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:52.981'),
(470, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:53.190'),
(471, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:53.443'),
(472, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:53.665'),
(473, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:53.876'),
(474, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:54.127'),
(475, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:54.543'),
(476, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:55.160'),
(477, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:55.634'),
(478, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:56.088'),
(479, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:56.217'),
(480, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:56.459');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(481, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:56.836'),
(482, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:57.175'),
(483, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:57.476'),
(484, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:57.735'),
(485, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:57.951'),
(486, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:58.089'),
(487, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:58.156'),
(488, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 423, N'testclient', '2026-08-01 15:41:58.198'),
(489, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:58.356'),
(490, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:58.605'),
(491, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:58.634'),
(492, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:59.167'),
(493, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:41:59.245'),
(494, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:04.304'),
(495, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:05.199'),
(496, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:05.720'),
(497, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:05.930'),
(498, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:06.519'),
(499, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:06.833'),
(500, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:07.542'),
(501, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:08.223'),
(502, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:08.423'),
(503, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:08.615'),
(504, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:08.790'),
(505, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:08.974'),
(506, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:09.173'),
(507, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:09.343'),
(508, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:09.518'),
(509, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:09.711'),
(510, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:09.895'),
(511, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:10.064'),
(512, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:10.272'),
(513, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:10.696'),
(514, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:10.901'),
(515, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:11.178'),
(516, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:11.303'),
(517, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:11.446'),
(518, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:11.648'),
(519, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:11.782'),
(520, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:11.959');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(521, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:12.159'),
(522, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:12.352'),
(523, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:12.366'),
(524, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'testclient', '2026-08-01 15:42:12.414'),
(525, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:12.551'),
(526, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:12.744'),
(527, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:12.938'),
(528, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:13.137'),
(529, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:13.179'),
(530, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:13.413'),
(531, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:13.657'),
(532, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:13.810'),
(533, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:13.977'),
(534, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:14.147'),
(535, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:14.325'),
(536, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:14.506'),
(537, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:14.525'),
(538, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:14.666'),
(539, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:14.784'),
(540, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:14.841'),
(541, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:14.951'),
(542, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:15.012'),
(543, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:15.151'),
(544, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:15.179'),
(545, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:15.323'),
(546, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:15.369'),
(547, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:15.390'),
(548, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:15.512'),
(549, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:15.548'),
(550, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:15.688'),
(551, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:15.724'),
(552, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:15.883'),
(553, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:15.900'),
(554, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:16.072'),
(555, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:16.084'),
(556, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:16.243'),
(557, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:16.260'),
(558, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:16.423'),
(559, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:16.427'),
(560, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:16.610');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(561, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:16.623'),
(562, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:16.768'),
(563, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:16.837'),
(564, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:16.949'),
(565, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:16.954'),
(566, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:17.049'),
(567, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:17.123'),
(568, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:17.242'),
(569, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:17.300'),
(570, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:17.466'),
(571, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:17.473'),
(572, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:17.644'),
(573, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:17.665'),
(574, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:17.754'),
(575, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:17.827'),
(576, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:17.858'),
(577, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:18.003'),
(578, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:18.055'),
(579, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:18.178'),
(580, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:18.266'),
(581, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:18.346'),
(582, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:18.463'),
(583, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:18.515'),
(584, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:18.672'),
(585, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:18.679'),
(586, 19, N'zahra', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:18.844'),
(587, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:18.879'),
(588, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:19.087'),
(589, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:19.286'),
(590, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:19.460'),
(591, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:19.490'),
(592, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:19.696'),
(593, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:19.909'),
(594, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:20.084'),
(595, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:20.111'),
(596, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:20.307'),
(597, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:20.510'),
(598, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:20.688'),
(599, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:20.753'),
(600, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:20.921');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(601, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:20.966'),
(602, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:21.091'),
(603, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:21.176'),
(604, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:21.382'),
(605, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:21.586'),
(606, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:21.797'),
(607, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:21.914'),
(608, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:22.010'),
(609, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:22.208'),
(610, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:22.214'),
(611, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:22.332'),
(612, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:22.425'),
(613, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:22.584'),
(614, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:22.655'),
(615, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:22.718'),
(616, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:22.832'),
(617, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:22.911'),
(618, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:23.130'),
(619, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:23.152'),
(620, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:23.325'),
(621, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:23.384'),
(622, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:23.550'),
(623, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:23.598'),
(624, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:23.773'),
(625, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:23.808'),
(626, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:24.005'),
(627, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:24.049'),
(628, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:24.262'),
(629, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:24.506'),
(630, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:24.712'),
(631, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:24.936'),
(632, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:25.129'),
(633, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:25.310'),
(634, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:25.489'),
(635, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:25.648'),
(636, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:26.488'),
(637, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:26.680'),
(638, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:26.862'),
(639, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:27.047'),
(640, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:27.226');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(641, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:27.399'),
(642, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:28.617'),
(643, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:28.750'),
(644, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:28.886'),
(645, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:29.006'),
(646, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:29.153'),
(647, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:29.285'),
(648, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:29.439'),
(649, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:29.591'),
(650, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:29.727'),
(651, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:29.885'),
(652, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:30.030'),
(653, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:30.159'),
(654, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:30.189'),
(655, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:30.350'),
(656, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:30.512'),
(657, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:30.520'),
(658, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:30.562'),
(659, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:30.670'),
(660, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:30.719'),
(661, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:30.837'),
(662, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:30.845'),
(663, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:30.998'),
(664, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:31.014'),
(665, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:31.166'),
(666, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:31.172'),
(667, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:31.302'),
(668, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:31.328'),
(669, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:31.454'),
(670, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:31.493'),
(671, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:31.627'),
(672, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:31.783'),
(673, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:31.815'),
(674, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:31.943'),
(675, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:32.022'),
(676, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:32.103'),
(677, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:32.264'),
(678, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:32.314'),
(679, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:32.335'),
(680, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:32.431');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(681, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:32.616'),
(682, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:32.789'),
(683, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:32.963'),
(684, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:33.150'),
(685, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:33.320'),
(686, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:33.509'),
(687, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:33.712'),
(688, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:33.894'),
(689, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:34.069'),
(690, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:34.263'),
(691, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:34.436'),
(692, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:34.597'),
(693, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:34.783'),
(694, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:34.943'),
(695, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:35.119'),
(696, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:35.281'),
(697, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:35.325'),
(698, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:35.456'),
(699, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:35.503'),
(700, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:35.623'),
(701, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:35.684'),
(702, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:35.800'),
(703, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:35.863'),
(704, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:36.045'),
(705, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:36.208'),
(706, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:36.274'),
(707, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:36.380'),
(708, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:36.483'),
(709, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:36.558'),
(710, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:36.678'),
(711, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:36.692'),
(712, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:36.872'),
(713, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:36.909'),
(714, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:37.085'),
(715, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:37.090'),
(716, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:37.278'),
(717, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:37.347'),
(718, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:37.468'),
(719, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:37.673'),
(720, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:37.734');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(721, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:37.871'),
(722, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:37.919'),
(723, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:38.063'),
(724, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:38.222'),
(725, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:38.423'),
(726, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:38.805'),
(727, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:38.997'),
(728, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:39.173'),
(729, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:39.360'),
(730, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:39.533'),
(731, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:39.711'),
(732, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:39.902'),
(733, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:40.081'),
(734, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:40.255'),
(735, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:40.424'),
(736, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:40.588'),
(737, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:40.791'),
(738, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:40.959'),
(739, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:41.141'),
(740, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:41.278'),
(741, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:41.478'),
(742, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:41.740'),
(743, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:41.926'),
(744, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:42.118'),
(745, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:42.307'),
(746, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:42.486'),
(747, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:42.855'),
(748, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:43.045'),
(749, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:43.207'),
(750, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:43.425'),
(751, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:43.583'),
(752, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:43.823'),
(753, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:44.028'),
(754, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:44.200'),
(755, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:44.402'),
(756, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:44.586'),
(757, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:44.752'),
(758, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:44.918'),
(759, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.068'),
(760, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.094');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(761, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.172'),
(762, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.237'),
(763, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.264'),
(764, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.351'),
(765, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.424'),
(766, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.432'),
(767, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.548'),
(768, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.558'),
(769, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.569'),
(770, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.739'),
(771, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.750'),
(772, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.760'),
(773, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.854'),
(774, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:45.917'),
(775, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:46.095'),
(776, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:46.109'),
(777, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:46.189'),
(778, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:46.333'),
(779, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:46.442'),
(780, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:46.479'),
(781, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:46.513'),
(782, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:46.613'),
(783, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:46.642'),
(784, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:46.689'),
(785, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:46.769'),
(786, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:46.802'),
(787, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:46.897'),
(788, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:46.958'),
(789, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:47.086'),
(790, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:47.138'),
(791, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:47.262'),
(792, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:47.311'),
(793, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:47.488'),
(794, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:47.499'),
(795, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:47.499'),
(796, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:47.515'),
(797, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:47.659'),
(798, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:47.675'),
(799, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:47.677'),
(800, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:47.851');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(801, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:47.867'),
(802, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.059'),
(803, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.132'),
(804, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.211'),
(805, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.289'),
(806, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.304'),
(807, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.418'),
(808, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.490'),
(809, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.624'),
(810, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.650'),
(811, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.690'),
(812, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.792'),
(813, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.844'),
(814, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.872'),
(815, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.939'),
(816, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.956'),
(817, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:48.956'),
(818, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:49.017'),
(819, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:49.116'),
(820, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:49.186'),
(821, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:49.228'),
(822, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:49.387'),
(823, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:49.407'),
(824, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:49.553'),
(825, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:49.622'),
(826, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:49.824'),
(827, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:49.902'),
(828, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:50.016'),
(829, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:50.106'),
(830, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:50.205'),
(831, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:50.280'),
(832, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:50.382'),
(833, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:50.471'),
(834, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:50.566'),
(835, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:50.665'),
(836, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:50.741'),
(837, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:50.837'),
(838, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:50.877'),
(839, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:50.956'),
(840, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.077');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(841, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.109'),
(842, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.113'),
(843, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.127'),
(844, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.269'),
(845, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.312'),
(846, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.383'),
(847, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.469'),
(848, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.477'),
(849, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.557'),
(850, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.636'),
(851, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.679'),
(852, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.751'),
(853, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.838'),
(854, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:51.877'),
(855, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.023'),
(856, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.032'),
(857, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.072'),
(858, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.161'),
(859, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.189'),
(860, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.198'),
(861, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.248'),
(862, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.350'),
(863, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.388'),
(864, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.429'),
(865, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.511'),
(866, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.531'),
(867, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.592'),
(868, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.630'),
(869, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.797'),
(870, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.814'),
(871, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.981'),
(872, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:52.998'),
(873, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.005'),
(874, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.185'),
(875, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.203'),
(876, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.233'),
(877, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.360'),
(878, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.377'),
(879, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.392'),
(880, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.557');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(881, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.565'),
(882, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.572'),
(883, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.743'),
(884, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.753'),
(885, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.764'),
(886, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.960'),
(887, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:53.975'),
(888, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.117'),
(889, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.161'),
(890, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.173'),
(891, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.247'),
(892, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.267'),
(893, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.286'),
(894, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.311'),
(895, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.418'),
(896, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.477'),
(897, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.494'),
(898, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.503'),
(899, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.650'),
(900, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.678'),
(901, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.692'),
(902, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.854'),
(903, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.868'),
(904, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:54.994'),
(905, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.044'),
(906, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.071'),
(907, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.093'),
(908, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.226'),
(909, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.244'),
(910, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.258'),
(911, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.268'),
(912, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.287'),
(913, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.405'),
(914, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.417'),
(915, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.430'),
(916, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.572'),
(917, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.580'),
(918, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.586'),
(919, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.773'),
(920, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.783');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(921, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:55.942'),
(922, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.023'),
(923, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.039'),
(924, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.141'),
(925, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.187'),
(926, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.223'),
(927, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.328'),
(928, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.341'),
(929, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.459'),
(930, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.492'),
(931, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.520'),
(932, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.640'),
(933, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.691'),
(934, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.707'),
(935, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.838'),
(936, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.871'),
(937, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:56.913'),
(938, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.031'),
(939, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.064'),
(940, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.109'),
(941, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.211'),
(942, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.259'),
(943, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.300'),
(944, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.365'),
(945, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.432'),
(946, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.487'),
(947, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.614'),
(948, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.691'),
(949, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.751'),
(950, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.799'),
(951, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.894'),
(952, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:57.985'),
(953, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.050'),
(954, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.113'),
(955, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.149'),
(956, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.247'),
(957, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.334'),
(958, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.358'),
(959, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.438'),
(960, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.467');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(961, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.496'),
(962, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.534'),
(963, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.542'),
(964, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.554'),
(965, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.631'),
(966, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.749'),
(967, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.758'),
(968, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.809'),
(969, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.918'),
(970, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:58.971'),
(971, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:59.104'),
(972, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:59.152'),
(973, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:59.209'),
(974, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:59.253'),
(975, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:59.354'),
(976, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:59.391'),
(977, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:59.423'),
(978, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:59.549'),
(979, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:59.560'),
(980, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:59.768'),
(981, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:59.774'),
(982, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:59.945'),
(983, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:42:59.969'),
(984, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:00.103'),
(985, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:00.170'),
(986, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:00.317'),
(987, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:00.395'),
(988, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:00.428'),
(989, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:00.443'),
(990, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:00.466'),
(991, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:00.575'),
(992, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:00.606'),
(993, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:00.769'),
(994, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:00.896'),
(995, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:01.025'),
(996, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:01.062'),
(997, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:01.264'),
(998, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:01.299'),
(999, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:01.434'),
(1000, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:01.613');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1001, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:01.790'),
(1002, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:01.989'),
(1003, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:02.175'),
(1004, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:02.325'),
(1005, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:02.494'),
(1006, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:02.671'),
(1007, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:02.840'),
(1008, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:03.032'),
(1009, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:03.224'),
(1010, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:03.405'),
(1011, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:03.589'),
(1012, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:03.901'),
(1013, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:04.072'),
(1014, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:04.270'),
(1015, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:04.455'),
(1016, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:04.588'),
(1017, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:04.733'),
(1018, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:04.919'),
(1019, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:05.100'),
(1020, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:05.269'),
(1021, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:05.431'),
(1022, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:05.606'),
(1023, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:05.790'),
(1024, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:05.950'),
(1025, 25, N'Ali', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:06.125'),
(1026, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:06.133'),
(1027, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:06.312'),
(1028, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:06.496'),
(1029, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:06.855'),
(1030, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:07.006'),
(1031, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:07.109'),
(1032, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:07.256'),
(1033, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:07.438'),
(1034, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:07.607'),
(1035, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:07.734'),
(1036, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:07.823'),
(1037, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:07.995'),
(1038, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:08.019'),
(1039, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:08.198'),
(1040, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:08.233');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1041, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:08.407'),
(1042, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:08.521'),
(1043, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:08.580'),
(1044, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:08.766'),
(1045, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:08.958'),
(1046, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:08.975'),
(1047, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:09.137'),
(1048, 1, N'admin', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:09.152'),
(1049, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:09.316'),
(1050, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:09.546'),
(1051, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:09.703'),
(1052, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:09.912'),
(1053, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:10.093'),
(1054, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:10.262'),
(1055, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:10.462'),
(1056, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:10.663'),
(1057, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:43:10.745'),
(1058, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:10.798'),
(1059, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:11.013'),
(1060, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:11.431'),
(1061, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:11.610'),
(1062, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:11.780'),
(1063, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:11.957'),
(1064, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:12.134'),
(1065, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:13.029'),
(1066, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:13.870'),
(1067, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:14.111'),
(1068, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:14.278'),
(1069, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:14.449'),
(1070, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:14.798'),
(1071, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:14.999'),
(1072, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:15.172'),
(1073, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:15.359'),
(1074, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:15.533'),
(1075, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:15.710'),
(1076, 18, N'elyar1390', N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (404)', N'{"query": null}', N'PUT', N'/auth/theme', 404, N'127.0.0.1', '2026-08-01 15:43:15.910'),
(1077, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:43:40.095'),
(1078, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:43:42.266'),
(1079, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:43:47.719'),
(1080, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:43:52.306');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1081, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:43:53.776'),
(1082, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:43:55.093'),
(1083, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:43:57.615'),
(1084, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:43:57.869'),
(1085, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:43:59.572'),
(1086, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:03.734'),
(1087, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:04.923'),
(1088, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:05.106'),
(1089, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:06.224'),
(1090, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:09.215'),
(1091, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:11.267'),
(1092, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:11.678'),
(1093, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:44:14.701'),
(1094, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:20.859'),
(1095, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:44:21.253'),
(1096, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:21.839'),
(1097, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:25.794'),
(1098, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:25.834'),
(1099, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:30.531'),
(1100, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:44:31.231'),
(1101, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:31.788'),
(1102, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:32.282'),
(1103, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:33.435'),
(1104, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:33.755'),
(1105, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:34.907'),
(1106, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:35.568'),
(1107, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:36.563'),
(1108, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:37.326'),
(1109, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:37.708'),
(1110, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:38.256'),
(1111, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:44:38.569'),
(1112, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:39.146'),
(1113, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:39.643'),
(1114, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:42.922'),
(1115, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:43.709'),
(1116, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:44.207'),
(1117, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:46.123'),
(1118, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:46.824'),
(1119, 18, N'elyar1390', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:44:53.990'),
(1120, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:44:57.210');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1121, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:44:58.724'),
(1122, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:44:59.496'),
(1123, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:45:01.843'),
(1124, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:45:04.221'),
(1125, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:45:05.688'),
(1126, 19, N'zahra', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:45:07.784'),
(1127, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:45:08.856'),
(1128, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:45:16.113'),
(1129, 1, N'admin', N'create', N'teacher', NULL, N'ایجاد مدرس', N'{"query": null}', N'POST', N'/teachers', 201, N'127.0.0.1', '2026-08-01 15:45:19.046'),
(1130, 1, N'admin', N'create', N'teacher', NULL, N'ایجاد مدرس', N'{"query": null}', N'POST', N'/teachers/89/photo', 200, N'127.0.0.1', '2026-08-01 15:45:19.146'),
(1131, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:45:25.105'),
(1132, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:45:26.770'),
(1133, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:45:27.889'),
(1134, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:45:35.821'),
(1135, 1, N'admin', N'create', N'shop', NULL, N'ایجاد فروشگاه', N'{"query": null}', N'POST', N'/shop/products/1/like', 200, N'127.0.0.1', '2026-08-01 15:45:36.807'),
(1136, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:45:39.407'),
(1137, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:45:43.348'),
(1138, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:45:43.496'),
(1139, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:45:43.511'),
(1140, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:45:46.981'),
(1141, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:45:49.766'),
(1142, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:45:52.894'),
(1143, 1, N'admin', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/questions/9', 200, N'127.0.0.1', '2026-08-01 15:45:56.618'),
(1144, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 15:45:57.284'),
(1145, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 15:45:59.256'),
(1146, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:46:02.006'),
(1147, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:46:06.063'),
(1148, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:46:06.070'),
(1149, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:46:07.713'),
(1150, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:46:08.608'),
(1151, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:46:13.471'),
(1152, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:46:16.289'),
(1153, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:46:17.601'),
(1154, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:46:18.715'),
(1155, 13, N'ابراهیم رئیسی', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:46:23.646'),
(1156, 18, N'elyar1390', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:46:29.252'),
(1157, 13, N'ابراهیم رئیسی', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 15:46:33.856'),
(1158, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1/answer', 200, N'127.0.0.1', '2026-08-01 15:46:38.957'),
(1159, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:46:46.741'),
(1160, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1/answer', 200, N'127.0.0.1', '2026-08-01 15:46:49.409');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1161, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1/answer', 200, N'127.0.0.1', '2026-08-01 15:46:52.668'),
(1162, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:46:58.482'),
(1163, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1/answer', 200, N'127.0.0.1', '2026-08-01 15:47:02.868'),
(1164, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:47:04.041'),
(1165, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:47:10.057'),
(1166, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:47:10.223'),
(1167, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:47:20.409'),
(1168, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:47:23.679'),
(1169, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1/answer', 200, N'127.0.0.1', '2026-08-01 15:47:24.764'),
(1170, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:47:30.373'),
(1171, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1/answer', 200, N'127.0.0.1', '2026-08-01 15:47:36.205'),
(1172, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:47:36.988'),
(1173, 18, N'elyar1390', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:47:45.331'),
(1174, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1/answer', 200, N'127.0.0.1', '2026-08-01 15:47:46.646'),
(1175, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:47:48.939'),
(1176, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1/answer', 200, N'127.0.0.1', '2026-08-01 15:48:23.613'),
(1177, 13, N'ابراهیم رئیسی', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/1/submit', 200, N'127.0.0.1', '2026-08-01 15:48:25.534'),
(1178, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:48:28.234'),
(1179, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:48:44.917'),
(1180, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:48:47.117'),
(1181, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:48:48.137'),
(1182, 13, N'ابراهیم رئیسی', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:48:55.560'),
(1183, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:49:07.412'),
(1184, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:49:08.404'),
(1185, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:49:11.789'),
(1186, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:49:15.171'),
(1187, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/11', 200, N'127.0.0.1', '2026-08-01 15:49:33.213'),
(1188, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:49:49.472'),
(1189, 25, N'Ali', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:50:04.455'),
(1190, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:50:12.184'),
(1191, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:50:12.191'),
(1192, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:50:16.600'),
(1193, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:50:17.454'),
(1194, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:50:20.375'),
(1195, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:50:21.057'),
(1196, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:50:21.068'),
(1197, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:50:21.425'),
(1198, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:50:21.850'),
(1199, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:50:22.167'),
(1200, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:50:22.508');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1201, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:50:23.455'),
(1202, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:50:24.546'),
(1203, NULL, NULL, N'register', N'auth', NULL, N'ثبت‌نام کاربری احراز هویت', N'{"query": null}', N'POST', N'/auth/register', 201, N'127.0.0.1', '2026-08-01 15:50:32.107'),
(1204, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:50:36.395'),
(1205, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:50:36.640'),
(1206, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:50:36.900'),
(1207, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 15:50:41.982'),
(1208, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:50:44.340'),
(1209, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:50:47.027'),
(1210, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:50:48.894'),
(1211, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:50:49.647'),
(1212, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:50:49.943'),
(1213, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:50:53.974'),
(1214, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:50:56.143'),
(1215, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:51:02.612'),
(1216, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:51:02.618'),
(1217, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:51:02.833'),
(1218, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:51:03.045'),
(1219, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:51:08.695'),
(1220, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:51:11.038'),
(1221, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:51:17.373'),
(1222, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:51:23.529'),
(1223, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:51:25.208'),
(1224, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:51:26.020'),
(1225, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:51:27.479'),
(1226, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:51:29.586'),
(1227, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:51:39.692'),
(1228, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:51:41.838'),
(1229, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:51:44.429'),
(1230, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:51:44.933'),
(1231, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:51:45.759'),
(1232, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:51:46.013'),
(1233, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:51:48.515'),
(1234, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:51:49.603'),
(1235, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:51:52.085'),
(1236, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:04.587'),
(1237, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:12.778'),
(1238, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:15.195'),
(1239, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:17.508'),
(1240, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:21.039');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1241, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:22.794'),
(1242, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:25.645'),
(1243, 25, N'Ali', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:52:26.083'),
(1244, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:28.542'),
(1245, 26, N'مسعود هستم', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:30.364'),
(1246, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:30.877'),
(1247, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:34.804'),
(1248, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:36.543'),
(1249, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:37.927'),
(1250, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 15:52:39.434'),
(1251, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:40.245'),
(1252, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:52:43.183'),
(1253, 19, N'zahra', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:44.658'),
(1254, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:52:48.849'),
(1255, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 15:52:58.335'),
(1256, 25, N'Ali', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/questions/10', 200, N'127.0.0.1', '2026-08-01 15:53:02.612'),
(1257, 25, N'Ali', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:53:10.398'),
(1258, 26, N'مسعود هستم', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:53:15.934'),
(1259, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:53:18.215'),
(1260, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:53:19.916'),
(1261, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:53:21.813'),
(1262, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:53:25.554'),
(1263, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:53:27.091'),
(1264, 18, N'elyar1390', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:53:28.334'),
(1265, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:53:28.980'),
(1266, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:53:30.429'),
(1267, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:53:31.594'),
(1268, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:53:38.936'),
(1269, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:54:09.448'),
(1270, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:54:12.111'),
(1271, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:54:15.718'),
(1272, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:54:19.912'),
(1273, NULL, NULL, N'register', N'auth', NULL, N'ناموفق: ثبت‌نام کاربری احراز هویت (422)', N'{"query": null}', N'POST', N'/auth/register', 422, N'127.0.0.1', '2026-08-01 15:54:26.676'),
(1274, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 15:54:26.710'),
(1275, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/2/submit', 400, N'127.0.0.1', '2026-08-01 15:54:28.769'),
(1276, NULL, NULL, N'register', N'auth', NULL, N'ثبت‌نام کاربری احراز هویت', N'{"query": null}', N'POST', N'/auth/register', 201, N'127.0.0.1', '2026-08-01 15:54:42.492'),
(1277, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:54:43.833'),
(1278, 27, N'Mee', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 15:54:47.089'),
(1279, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/3/answer', 200, N'127.0.0.1', '2026-08-01 15:54:56.396'),
(1280, 27, N'Mee', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/3/submit', 400, N'127.0.0.1', '2026-08-01 15:54:57.638');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1281, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/3/answer', 200, N'127.0.0.1', '2026-08-01 15:55:12.665'),
(1282, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:55:13.375'),
(1283, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/3/answer', 200, N'127.0.0.1', '2026-08-01 15:55:16.354'),
(1284, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/3/answer', 200, N'127.0.0.1', '2026-08-01 15:55:20.645'),
(1285, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/3/answer', 200, N'127.0.0.1', '2026-08-01 15:55:25.415'),
(1286, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/3/answer', 200, N'127.0.0.1', '2026-08-01 15:55:32.103'),
(1287, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:55:32.411'),
(1288, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:55:34.290'),
(1289, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/3/answer', 200, N'127.0.0.1', '2026-08-01 15:55:39.317'),
(1290, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/2/submit', 400, N'127.0.0.1', '2026-08-01 15:55:40.877'),
(1291, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/3/answer', 200, N'127.0.0.1', '2026-08-01 15:55:43.631'),
(1292, 27, N'Mee', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/3/submit', 200, N'127.0.0.1', '2026-08-01 15:55:44.744'),
(1293, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 15:55:56.635'),
(1294, 27, N'Mee', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 15:56:00.619'),
(1295, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/2/submit', 400, N'127.0.0.1', '2026-08-01 15:56:03.274'),
(1296, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/4/answer', 200, N'127.0.0.1', '2026-08-01 15:56:06.679'),
(1297, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:56:09.254'),
(1298, 19, N'zahra', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:56:09.289'),
(1299, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/4/answer', 200, N'127.0.0.1', '2026-08-01 15:56:09.322'),
(1300, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:56:11.581'),
(1301, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:56:11.722'),
(1302, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:56:12.155'),
(1303, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/4/answer', 200, N'127.0.0.1', '2026-08-01 15:56:12.738'),
(1304, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:56:13.935'),
(1305, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:56:14.275'),
(1306, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:56:14.518'),
(1307, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:56:14.703'),
(1308, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 15:56:14.901'),
(1309, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:56:16.530'),
(1310, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/4/answer', 200, N'127.0.0.1', '2026-08-01 15:56:17.174'),
(1311, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:56:18.156'),
(1312, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:56:19.000'),
(1313, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/4/answer', 200, N'127.0.0.1', '2026-08-01 15:56:22.649'),
(1314, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/4/answer', 200, N'127.0.0.1', '2026-08-01 15:56:24.691'),
(1315, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/4/answer', 200, N'127.0.0.1', '2026-08-01 15:56:27.556'),
(1316, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/4/answer', 200, N'127.0.0.1', '2026-08-01 15:56:33.658'),
(1317, 27, N'Mee', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/4/submit', 400, N'127.0.0.1', '2026-08-01 15:56:35.647'),
(1318, 27, N'Mee', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/4/submit', 400, N'127.0.0.1', '2026-08-01 15:56:38.457'),
(1319, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/27', 200, N'127.0.0.1', '2026-08-01 15:56:40.245'),
(1320, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/18', 200, N'127.0.0.1', '2026-08-01 15:56:46.752');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1321, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:56:54.188'),
(1322, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:57:04.085'),
(1323, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/4/answer', 200, N'127.0.0.1', '2026-08-01 15:57:04.085'),
(1324, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/4/answer', 200, N'127.0.0.1', '2026-08-01 15:57:04.967'),
(1325, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:57:05.724'),
(1326, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/4/answer', 200, N'127.0.0.1', '2026-08-01 15:57:06.970'),
(1327, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:57:07.740'),
(1328, 27, N'Mee', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/4/submit', 400, N'127.0.0.1', '2026-08-01 15:57:12.569'),
(1329, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 15:57:16.968'),
(1330, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:57:18.508'),
(1331, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:57:21.377'),
(1332, 27, N'Mee', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/4/submit', 400, N'127.0.0.1', '2026-08-01 15:57:21.826'),
(1333, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/17', 200, N'127.0.0.1', '2026-08-01 15:57:25.489'),
(1334, 18, N'elyar1390', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 15:57:26.455'),
(1335, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:57:26.979'),
(1336, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 15:57:28.785'),
(1337, 18, N'elyar1390', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/5/submit', 400, N'127.0.0.1', '2026-08-01 15:57:30.354'),
(1338, 20, N'sama', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 15:57:31.843'),
(1339, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/6/answer', 200, N'127.0.0.1', '2026-08-01 15:57:36.838'),
(1340, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 15:57:38.367'),
(1341, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 15:57:38.943'),
(1342, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 15:57:39.985'),
(1343, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 15:57:40.795'),
(1344, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:57:43.554'),
(1345, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:57:44.960'),
(1346, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/6/answer', 200, N'127.0.0.1', '2026-08-01 15:57:45.415'),
(1347, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:57:46.230'),
(1348, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:57:50.018'),
(1349, 17, N'arshya1', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 15:57:51.116'),
(1350, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:57:51.452'),
(1351, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:57:52.822'),
(1352, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:57:54.295'),
(1353, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:57:54.799'),
(1354, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/6/answer', 200, N'127.0.0.1', '2026-08-01 15:57:55.518'),
(1355, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/6/answer', 200, N'127.0.0.1', '2026-08-01 15:57:55.525'),
(1356, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:57:55.992'),
(1357, 26, N'مسعود هستم', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:57:58.811'),
(1358, 27, N'Mee', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/4/submit', 400, N'127.0.0.1', '2026-08-01 15:57:59.625'),
(1359, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:58:01.043'),
(1360, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:58:01.070');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1361, 17, N'arshya1', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/7/submit', 400, N'127.0.0.1', '2026-08-01 15:58:02.421'),
(1362, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:58:03.155'),
(1363, 21, N'مسئول امور مالی آموزشگاه', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:58:07.062'),
(1364, 21, N'مسئول امور مالی آموزشگاه', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 15:58:09.054'),
(1365, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/6/answer', 200, N'127.0.0.1', '2026-08-01 15:58:17.971'),
(1366, 21, N'مسئول امور مالی آموزشگاه', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 15:58:18.279'),
(1367, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:58:19.653'),
(1368, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 15:58:22.955'),
(1369, 18, N'elyar1390', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/5/submit', 400, N'127.0.0.1', '2026-08-01 15:58:24.150'),
(1370, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/6/answer', 200, N'127.0.0.1', '2026-08-01 15:58:25.441'),
(1371, 27, N'Mee', N'create', N'shop', NULL, N'ایجاد فروشگاه', N'{"query": null}', N'POST', N'/shop/products/9/like', 200, N'127.0.0.1', '2026-08-01 15:58:27.682'),
(1372, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/6/answer', 200, N'127.0.0.1', '2026-08-01 15:58:32.895'),
(1373, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:58:33.841'),
(1374, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:58:33.851'),
(1375, 27, N'Mee', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 15:58:34.310'),
(1376, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 15:58:36.921'),
(1377, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/4/answer', 200, N'127.0.0.1', '2026-08-01 15:58:38.052'),
(1378, 27, N'Mee', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/4/submit', 200, N'127.0.0.1', '2026-08-01 15:58:39.549'),
(1379, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/6/answer', 200, N'127.0.0.1', '2026-08-01 15:58:39.747'),
(1380, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:58:40.017'),
(1381, 20, N'sama', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/6/submit', 400, N'127.0.0.1', '2026-08-01 15:58:41.917'),
(1382, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:58:45.134'),
(1383, 20, N'sama', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/6/submit', 400, N'127.0.0.1', '2026-08-01 15:58:45.793'),
(1384, 17, N'arshya1', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/7/submit', 400, N'127.0.0.1', '2026-08-01 15:58:46.207'),
(1385, 17, N'arshya1', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/7/submit', 400, N'127.0.0.1', '2026-08-01 15:58:46.284'),
(1386, 20, N'sama', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/6/submit', 400, N'127.0.0.1', '2026-08-01 15:58:47.634'),
(1387, 20, N'sama', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/6/submit', 400, N'127.0.0.1', '2026-08-01 15:58:49.030'),
(1388, 17, N'arshya1', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/7/submit', 400, N'127.0.0.1', '2026-08-01 15:58:49.087'),
(1389, 17, N'arshya1', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/7/submit', 400, N'127.0.0.1', '2026-08-01 15:58:49.114'),
(1390, 17, N'arshya1', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/7/submit', 400, N'127.0.0.1', '2026-08-01 15:58:49.712'),
(1391, 20, N'sama', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/6/submit', 400, N'127.0.0.1', '2026-08-01 15:58:49.863'),
(1392, 20, N'sama', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/6/submit', 400, N'127.0.0.1', '2026-08-01 15:58:50.599'),
(1393, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:58:51.094'),
(1394, 20, N'sama', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/6/submit', 400, N'127.0.0.1', '2026-08-01 15:58:51.737'),
(1395, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:58:51.776'),
(1396, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:58:51.849'),
(1397, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:58:52.309'),
(1398, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:58:52.403'),
(1399, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/6/answer', 200, N'127.0.0.1', '2026-08-01 15:58:57.111'),
(1400, 20, N'sama', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/6/submit', 200, N'127.0.0.1', '2026-08-01 15:58:58.473');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1401, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:58:59.515'),
(1402, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:59:05.010'),
(1403, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:59:05.038'),
(1404, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/7/answer', 200, N'127.0.0.1', '2026-08-01 15:59:09.841'),
(1405, 17, N'arshya1', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/7/submit', 200, N'127.0.0.1', '2026-08-01 15:59:10.824'),
(1406, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:00:18.130'),
(1407, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 16:00:18.397'),
(1408, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 16:00:21.923'),
(1409, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:00:23.217'),
(1410, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 16:00:26.880'),
(1411, 13, N'ابراهیم رئیسی', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 16:00:28.042'),
(1412, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 16:00:29.605'),
(1413, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 16:00:32.550'),
(1414, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 16:00:42.598'),
(1415, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 200, N'127.0.0.1', '2026-08-01 16:00:42.991'),
(1416, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 16:00:43.549'),
(1417, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 16:00:44.664'),
(1418, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 16:00:45.646'),
(1419, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 16:00:46.279'),
(1420, 27, N'Mee', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 16:00:48.764'),
(1421, 17, N'arshya1', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:00:50.495'),
(1422, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/9/answer', 200, N'127.0.0.1', '2026-08-01 16:00:50.909'),
(1423, 17, N'arshya1', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:00:51.208'),
(1424, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 16:00:51.729'),
(1425, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 200, N'127.0.0.1', '2026-08-01 16:00:52.608'),
(1426, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/9/answer', 200, N'127.0.0.1', '2026-08-01 16:00:53.519'),
(1427, 18, N'elyar1390', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/5/answer', 200, N'127.0.0.1', '2026-08-01 16:00:55.361'),
(1428, 17, N'arshya1', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 16:00:55.700'),
(1429, 18, N'elyar1390', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/5/submit', 200, N'127.0.0.1', '2026-08-01 16:00:57.117'),
(1430, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 200, N'127.0.0.1', '2026-08-01 16:00:57.312'),
(1431, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/9/answer', 200, N'127.0.0.1', '2026-08-01 16:00:57.578'),
(1432, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/9/answer', 200, N'127.0.0.1', '2026-08-01 16:01:12.202'),
(1433, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 200, N'127.0.0.1', '2026-08-01 16:01:13.994'),
(1434, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 200, N'127.0.0.1', '2026-08-01 16:01:14.790'),
(1435, 17, N'arshya1', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 422, N'127.0.0.1', '2026-08-01 16:01:15.244'),
(1436, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 200, N'127.0.0.1', '2026-08-01 16:01:15.275'),
(1437, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 200, N'127.0.0.1', '2026-08-01 16:01:15.695'),
(1438, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/9/answer', 200, N'127.0.0.1', '2026-08-01 16:01:17.160'),
(1439, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 200, N'127.0.0.1', '2026-08-01 16:01:18.742'),
(1440, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/9/answer', 200, N'127.0.0.1', '2026-08-01 16:01:20.559');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1441, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/9/answer', 200, N'127.0.0.1', '2026-08-01 16:01:23.357'),
(1442, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/9/answer', 200, N'127.0.0.1', '2026-08-01 16:01:27.269'),
(1443, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 200, N'127.0.0.1', '2026-08-01 16:01:28.024'),
(1444, 17, N'arshya1', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 422, N'127.0.0.1', '2026-08-01 16:01:28.024'),
(1445, 27, N'Mee', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/9/submit', 200, N'127.0.0.1', '2026-08-01 16:01:28.391'),
(1446, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 200, N'127.0.0.1', '2026-08-01 16:01:30.878'),
(1447, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 200, N'127.0.0.1', '2026-08-01 16:01:45.308'),
(1448, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 200, N'127.0.0.1', '2026-08-01 16:01:46.843'),
(1449, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 200, N'127.0.0.1', '2026-08-01 16:01:46.995'),
(1450, 17, N'arshya1', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/10/submit', 400, N'127.0.0.1', '2026-08-01 16:01:47.417'),
(1451, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 200, N'127.0.0.1', '2026-08-01 16:01:47.622'),
(1452, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 200, N'127.0.0.1', '2026-08-01 16:01:48.653'),
(1453, 17, N'arshya1', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 422, N'127.0.0.1', '2026-08-01 16:01:48.661'),
(1454, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 200, N'127.0.0.1', '2026-08-01 16:01:49.844'),
(1455, 17, N'arshya1', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 200, N'127.0.0.1', '2026-08-01 16:01:49.988'),
(1456, 17, N'arshya1', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/10/answer', 422, N'127.0.0.1', '2026-08-01 16:01:49.988'),
(1457, 17, N'arshya1', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/10/submit', 400, N'127.0.0.1', '2026-08-01 16:01:51.763'),
(1458, 17, N'arshya1', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/10/submit', 400, N'127.0.0.1', '2026-08-01 16:01:51.972'),
(1459, 17, N'arshya1', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/10/submit', 400, N'127.0.0.1', '2026-08-01 16:01:52.450'),
(1460, 17, N'arshya1', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/10/submit', 400, N'127.0.0.1', '2026-08-01 16:01:52.594'),
(1461, 20, N'sama', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 16:02:32.012'),
(1462, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 200, N'127.0.0.1', '2026-08-01 16:02:33.064'),
(1463, 20, N'sama', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/11/submit', 400, N'127.0.0.1', '2026-08-01 16:02:35.404'),
(1464, 20, N'sama', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 422, N'127.0.0.1', '2026-08-01 16:02:44.508'),
(1465, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 200, N'127.0.0.1', '2026-08-01 16:02:46.129'),
(1466, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 200, N'127.0.0.1', '2026-08-01 16:02:53.440'),
(1467, 20, N'sama', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/11/submit', 400, N'127.0.0.1', '2026-08-01 16:02:55.446'),
(1468, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 200, N'127.0.0.1', '2026-08-01 16:03:40.701'),
(1469, 20, N'sama', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 422, N'127.0.0.1', '2026-08-01 16:03:42.770'),
(1470, 13, N'ابراهیم رئیسی', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 16:03:43.475'),
(1471, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 200, N'127.0.0.1', '2026-08-01 16:03:44.108'),
(1472, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 200, N'127.0.0.1', '2026-08-01 16:03:45.596'),
(1473, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 200, N'127.0.0.1', '2026-08-01 16:03:46.916'),
(1474, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 200, N'127.0.0.1', '2026-08-01 16:03:47.170'),
(1475, 20, N'sama', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 422, N'127.0.0.1', '2026-08-01 16:03:48.611'),
(1476, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 422, N'127.0.0.1', '2026-08-01 16:03:49.810'),
(1477, 20, N'sama', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 422, N'127.0.0.1', '2026-08-01 16:03:50.100'),
(1478, 20, N'sama', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 422, N'127.0.0.1', '2026-08-01 16:03:50.816'),
(1479, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 422, N'127.0.0.1', '2026-08-01 16:03:51.451'),
(1480, 20, N'sama', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 422, N'127.0.0.1', '2026-08-01 16:03:51.763');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1481, 20, N'sama', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 422, N'127.0.0.1', '2026-08-01 16:03:52.676'),
(1482, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 422, N'127.0.0.1', '2026-08-01 16:03:53.948'),
(1483, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 422, N'127.0.0.1', '2026-08-01 16:03:55.372'),
(1484, 20, N'sama', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/11/submit', 400, N'127.0.0.1', '2026-08-01 16:03:56.413'),
(1485, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 422, N'127.0.0.1', '2026-08-01 16:03:56.986'),
(1486, 20, N'sama', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/11/submit', 400, N'127.0.0.1', '2026-08-01 16:03:58.789'),
(1487, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 16:03:59.213'),
(1488, 13, N'ابراهیم رئیسی', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/8/submit', 400, N'127.0.0.1', '2026-08-01 16:03:59.586'),
(1489, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 422, N'127.0.0.1', '2026-08-01 16:04:02.206'),
(1490, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:04:04.222'),
(1491, 20, N'sama', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/11/submit', 400, N'127.0.0.1', '2026-08-01 16:04:04.233'),
(1492, 20, N'sama', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/11/submit', 400, N'127.0.0.1', '2026-08-01 16:04:07.329'),
(1493, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:04:07.377'),
(1494, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:04:09.834'),
(1495, 20, N'sama', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 422, N'127.0.0.1', '2026-08-01 16:04:10.747'),
(1496, 20, N'sama', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 422, N'127.0.0.1', '2026-08-01 16:04:11.412'),
(1497, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 422, N'127.0.0.1', '2026-08-01 16:04:12.045'),
(1498, 20, N'sama', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 422, N'127.0.0.1', '2026-08-01 16:04:12.348'),
(1499, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:04:13.055'),
(1500, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 16:04:20.834'),
(1501, 27, N'Mee', N'create', N'enrollment', NULL, N'ایجاد ثبت‌نام', N'{"query": null}', N'POST', N'/enrollments', 201, N'127.0.0.1', '2026-08-01 16:04:27.105'),
(1502, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 16:04:28.262'),
(1503, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:04:28.425'),
(1504, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:04:30.558'),
(1505, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:04:32.011'),
(1506, 18, N'elyar1390', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:04:32.683'),
(1507, 18, N'elyar1390', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:04:36.900'),
(1508, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:04:40.953'),
(1509, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:04:44.330'),
(1510, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:04:44.982'),
(1511, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:04:46.234'),
(1512, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:04:47.489'),
(1513, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:04:48.282'),
(1514, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:04:55.053'),
(1515, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:04:56.856'),
(1516, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:04:57.544'),
(1517, 13, N'ابراهیم رئیسی', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 16:05:12.906'),
(1518, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 422, N'127.0.0.1', '2026-08-01 16:05:15.089'),
(1519, 13, N'ابراهیم رئیسی', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:05:18.173'),
(1520, 1, N'admin', N'create', N'user', NULL, N'ناموفق: ایجاد کاربر (404)', N'{"query": null}', N'POST', N'/users/19/reset-password', 404, N'127.0.0.1', '2026-08-01 16:05:20.280');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1521, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:05:21.581'),
(1522, 1, N'admin', N'create', N'user', NULL, N'ناموفق: ایجاد کاربر (404)', N'{"query": null}', N'POST', N'/users/19/reset-password', 404, N'127.0.0.1', '2026-08-01 16:05:22.093'),
(1523, 1, N'admin', N'create', N'user', NULL, N'ناموفق: ایجاد کاربر (404)', N'{"query": null}', N'POST', N'/users/19/reset-password', 404, N'127.0.0.1', '2026-08-01 16:05:23.020'),
(1524, 1, N'admin', N'create', N'user', NULL, N'ناموفق: ایجاد کاربر (404)', N'{"query": null}', N'POST', N'/users/19/reset-password', 404, N'127.0.0.1', '2026-08-01 16:05:23.578'),
(1525, 27, N'Mee', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:05:23.915'),
(1526, 1, N'admin', N'create', N'user', NULL, N'ناموفق: ایجاد کاربر (404)', N'{"query": null}', N'POST', N'/users/19/reset-password', 404, N'127.0.0.1', '2026-08-01 16:05:24.124'),
(1527, 1, N'admin', N'create', N'user', NULL, N'ناموفق: ایجاد کاربر (404)', N'{"query": null}', N'POST', N'/users/19/reset-password', 404, N'127.0.0.1', '2026-08-01 16:05:24.339'),
(1528, 1, N'admin', N'create', N'user', NULL, N'ناموفق: ایجاد کاربر (404)', N'{"query": null}', N'POST', N'/users/19/reset-password', 404, N'127.0.0.1', '2026-08-01 16:05:24.517'),
(1529, 1, N'admin', N'create', N'user', NULL, N'ناموفق: ایجاد کاربر (404)', N'{"query": null}', N'POST', N'/users/19/reset-password', 404, N'127.0.0.1', '2026-08-01 16:05:24.692'),
(1530, 1, N'admin', N'create', N'user', NULL, N'ناموفق: ایجاد کاربر (404)', N'{"query": null}', N'POST', N'/users/19/reset-password', 404, N'127.0.0.1', '2026-08-01 16:05:24.883'),
(1531, 1, N'admin', N'create', N'user', NULL, N'ناموفق: ایجاد کاربر (404)', N'{"query": null}', N'POST', N'/users/19/reset-password', 404, N'127.0.0.1', '2026-08-01 16:05:29.015'),
(1532, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 16:05:39.659'),
(1533, 27, N'Mee', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:05:56.116'),
(1534, 1, N'admin', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (403)', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 403, N'127.0.0.1', '2026-08-01 16:06:00.108'),
(1535, 27, N'Mee', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:06:03.780'),
(1536, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:06:04.991'),
(1537, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:06:09.414'),
(1538, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 16:06:14.187'),
(1539, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:06:14.708'),
(1540, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 422, N'127.0.0.1', '2026-08-01 16:06:18.653'),
(1541, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/18', 200, N'127.0.0.1', '2026-08-01 16:06:24.166'),
(1542, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:06:34.032'),
(1543, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:06:37.360'),
(1544, 20, N'sama', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 422, N'127.0.0.1', '2026-08-01 16:06:37.476'),
(1545, 20, N'sama', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 422, N'127.0.0.1', '2026-08-01 16:06:38.147'),
(1546, 20, N'sama', N'update', N'placement', NULL, N'ناموفق: ویرایش placement (422)', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 422, N'127.0.0.1', '2026-08-01 16:06:39.283'),
(1547, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 16:06:41.266'),
(1548, 20, N'sama', N'create', N'placement', NULL, N'ناموفق: ایجاد placement (400)', N'{"query": null}', N'POST', N'/placement/attempts/11/submit', 400, N'127.0.0.1', '2026-08-01 16:06:41.410'),
(1549, 25, N'Ali', N'create', N'attendance', NULL, N'ایجاد attendance', N'{"query": null}', N'POST', N'/attendance/bulk', 201, N'127.0.0.1', '2026-08-01 16:06:43.908'),
(1550, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:07:02.945'),
(1551, 1, N'admin', N'create', N'user', NULL, N'ناموفق: ایجاد کاربر (404)', N'{"query": null}', N'POST', N'/users/19/reset-password', 404, N'127.0.0.1', '2026-08-01 16:07:02.985'),
(1552, 18, N'elyar1390', N'delete', N'placement', NULL, N'حذف placement', N'{"query": null}', N'DELETE', N'/placement/questions/10', 200, N'127.0.0.1', '2026-08-01 16:07:12.058'),
(1553, 1, N'admin', N'create', N'user', NULL, N'ناموفق: ایجاد کاربر (404)', N'{"query": null}', N'POST', N'/users/19/reset-password', 404, N'127.0.0.1', '2026-08-01 16:07:14.928'),
(1554, 18, N'elyar1390', N'delete', N'placement', NULL, N'حذف placement', N'{"query": null}', N'DELETE', N'/placement/questions/10', 200, N'127.0.0.1', '2026-08-01 16:07:18.066'),
(1555, 26, N'مسعود هستم', N'update', N'teacher', NULL, N'ناموفق: ویرایش مدرس (403)', N'{"query": null}', N'PUT', N'/teachers/42', 403, N'127.0.0.1', '2026-08-01 16:07:18.115'),
(1556, 26, N'مسعود هستم', N'update', N'teacher', NULL, N'ناموفق: ویرایش مدرس (403)', N'{"query": null}', N'PUT', N'/teachers/42', 403, N'127.0.0.1', '2026-08-01 16:07:19.552'),
(1557, 26, N'مسعود هستم', N'update', N'teacher', NULL, N'ناموفق: ویرایش مدرس (403)', N'{"query": null}', N'PUT', N'/teachers/42', 403, N'127.0.0.1', '2026-08-01 16:07:20.638'),
(1558, 26, N'مسعود هستم', N'update', N'teacher', NULL, N'ناموفق: ویرایش مدرس (403)', N'{"query": null}', N'PUT', N'/teachers/42', 403, N'127.0.0.1', '2026-08-01 16:07:21.221'),
(1559, 26, N'مسعود هستم', N'update', N'teacher', NULL, N'ناموفق: ویرایش مدرس (403)', N'{"query": null}', N'PUT', N'/teachers/42', 403, N'127.0.0.1', '2026-08-01 16:07:21.445'),
(1560, 18, N'elyar1390', N'delete', N'placement', NULL, N'حذف placement', N'{"query": null}', N'DELETE', N'/placement/questions/9', 200, N'127.0.0.1', '2026-08-01 16:07:21.571');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1561, 26, N'مسعود هستم', N'update', N'teacher', NULL, N'ناموفق: ویرایش مدرس (403)', N'{"query": null}', N'PUT', N'/teachers/42', 403, N'127.0.0.1', '2026-08-01 16:07:21.664'),
(1562, 26, N'مسعود هستم', N'update', N'teacher', NULL, N'ناموفق: ویرایش مدرس (403)', N'{"query": null}', N'PUT', N'/teachers/42', 403, N'127.0.0.1', '2026-08-01 16:07:21.883'),
(1563, 26, N'مسعود هستم', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:07:29.800'),
(1564, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 423, N'127.0.0.1', '2026-08-01 16:07:33.325'),
(1565, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 423, N'127.0.0.1', '2026-08-01 16:07:34.284'),
(1566, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 16:07:45.042'),
(1567, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 423, N'127.0.0.1', '2026-08-01 16:07:52.896'),
(1568, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:07:53.652'),
(1569, 1, N'admin', N'create', N'user', NULL, N'ناموفق: ایجاد کاربر (404)', N'{"query": null}', N'POST', N'/users/19/reset-password', 404, N'127.0.0.1', '2026-08-01 16:07:53.680'),
(1570, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:08:01.246'),
(1571, 1, N'admin', N'update', N'teacher', NULL, N'ویرایش مدرس', N'{"query": null}', N'PUT', N'/teachers/42', 200, N'127.0.0.1', '2026-08-01 16:08:15.633'),
(1572, 1, N'admin', N'create', N'teacher', NULL, N'ایجاد مدرس', N'{"query": null}', N'POST', N'/teachers/42/photo', 200, N'127.0.0.1', '2026-08-01 16:08:15.657'),
(1573, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:08:47.255'),
(1574, 1, N'admin', N'create', N'user', NULL, N'ایجاد کاربر', N'{"query": null}', N'POST', N'/users/19/reset-password', 200, N'127.0.0.1', '2026-08-01 16:08:47.491'),
(1575, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:09:06.432'),
(1576, 1, N'admin', N'update', N'teacher', NULL, N'ویرایش مدرس', N'{"query": null}', N'PUT', N'/teachers/16', 200, N'127.0.0.1', '2026-08-01 16:09:11.061'),
(1577, 1, N'admin', N'create', N'teacher', NULL, N'ایجاد مدرس', N'{"query": null}', N'POST', N'/teachers/16/photo', 200, N'127.0.0.1', '2026-08-01 16:09:11.082'),
(1578, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:09:13.087'),
(1579, 1, N'admin', N'delete', N'teacher', NULL, N'حذف مدرس', N'{"query": null}', N'DELETE', N'/teachers/42', 200, N'127.0.0.1', '2026-08-01 16:09:16.774'),
(1580, 20, N'sama', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/11/answer', 200, N'127.0.0.1', '2026-08-01 16:09:24.922'),
(1581, 20, N'sama', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/11/submit', 200, N'127.0.0.1', '2026-08-01 16:09:27.535'),
(1582, 1, N'admin', N'create', N'user', NULL, N'ایجاد کاربر', N'{"query": null}', N'POST', N'/users/19/reset-password', 200, N'127.0.0.1', '2026-08-01 16:09:36.356'),
(1583, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:09:43.087'),
(1584, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:09:46.881'),
(1585, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:09:50.209'),
(1586, 18, N'elyar1390', N'create', N'score', NULL, N'ایجاد score', N'{"query": null}', N'POST', N'/scores', 201, N'127.0.0.1', '2026-08-01 16:10:00.642'),
(1587, 18, N'elyar1390', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:10:22.373'),
(1588, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:10:25.656'),
(1589, 19, N'zahra', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:10:26.671'),
(1590, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:10:28.468'),
(1591, 20, N'sama', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:10:47.053'),
(1592, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:10:49.145'),
(1593, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/17', 200, N'127.0.0.1', '2026-08-01 16:11:06.896'),
(1594, 1, N'admin', N'create', N'user', NULL, N'ایجاد کاربر', N'{"query": null}', N'POST', N'/users/10/reset-password', 200, N'127.0.0.1', '2026-08-01 16:11:23.585'),
(1595, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:11:27.579'),
(1596, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:11:27.939'),
(1597, 1, N'admin', N'create', N'user', NULL, N'ایجاد کاربر', N'{"query": null}', N'POST', N'/users/26/reset-password', 200, N'127.0.0.1', '2026-08-01 16:11:28.569'),
(1598, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:11:29.453'),
(1599, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:11:30.306'),
(1600, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:11:30.640');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1601, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:11:31.156'),
(1602, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:11:45.184'),
(1603, 10, N'Heli', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 16:11:50.725'),
(1604, 1, N'admin', N'create', N'user', NULL, N'ایجاد کاربر', N'{"query": null}', N'POST', N'/users/26/reset-password', 200, N'127.0.0.1', '2026-08-01 16:11:54.534'),
(1605, 10, N'Heli', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/12/answer', 200, N'127.0.0.1', '2026-08-01 16:11:54.558'),
(1606, 19, N'zahra', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/questions', 201, N'127.0.0.1', '2026-08-01 16:11:56.481'),
(1607, 10, N'Heli', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/12/answer', 200, N'127.0.0.1', '2026-08-01 16:11:56.752'),
(1608, 10, N'Heli', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/12/answer', 200, N'127.0.0.1', '2026-08-01 16:11:57.364'),
(1609, 10, N'Heli', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/12/answer', 200, N'127.0.0.1', '2026-08-01 16:12:02.141'),
(1610, 10, N'Heli', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/12/answer', 200, N'127.0.0.1', '2026-08-01 16:12:03.498'),
(1611, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:12:03.891'),
(1612, 10, N'Heli', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/12/answer', 200, N'127.0.0.1', '2026-08-01 16:12:04.654'),
(1613, 10, N'Heli', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/12/answer', 200, N'127.0.0.1', '2026-08-01 16:12:08.134'),
(1614, 10, N'Heli', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/12/submit', 200, N'127.0.0.1', '2026-08-01 16:12:17.580'),
(1615, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/18', 200, N'127.0.0.1', '2026-08-01 16:12:33.057'),
(1616, 19, N'zahra', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:12:34.462'),
(1617, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:12:37.766'),
(1618, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:12:38.981'),
(1619, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:12:41.530'),
(1620, 13, N'ابراهیم رئیسی', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 16:12:45.587'),
(1621, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 16:12:47.871'),
(1622, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 200, N'127.0.0.1', '2026-08-01 16:12:54.992'),
(1623, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 200, N'127.0.0.1', '2026-08-01 16:13:01.394'),
(1624, 13, N'ابراهیم رئیسی', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/8/answer', 200, N'127.0.0.1', '2026-08-01 16:13:06.924'),
(1625, 13, N'ابراهیم رئیسی', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/8/submit', 200, N'127.0.0.1', '2026-08-01 16:13:11.803'),
(1626, 13, N'ابراهیم رئیسی', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:13:23.727'),
(1627, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 16:13:24.192'),
(1628, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 16:13:28.424'),
(1629, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 16:13:29.391'),
(1630, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 16:13:29.613'),
(1631, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:13:29.836'),
(1632, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 16:13:40.125'),
(1633, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 16:13:43.976'),
(1634, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 16:13:55.477'),
(1635, 19, N'zahra', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:14:01.505'),
(1636, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:14:06.383'),
(1637, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 16:14:14.427'),
(1638, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 16:14:18.551'),
(1639, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 16:14:19.311'),
(1640, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 16:14:30.232');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1641, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 16:14:32.686'),
(1642, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/2/answer', 200, N'127.0.0.1', '2026-08-01 16:14:36.133'),
(1643, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/2/submit', 200, N'127.0.0.1', '2026-08-01 16:14:37.181'),
(1644, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 16:14:56.935'),
(1645, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/13/answer', 200, N'127.0.0.1', '2026-08-01 16:15:02.776'),
(1646, 10, N'Heli', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:15:04.566'),
(1647, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/13/submit', 200, N'127.0.0.1', '2026-08-01 16:15:04.631'),
(1648, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 16:15:18.940'),
(1649, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/14/answer', 200, N'127.0.0.1', '2026-08-01 16:15:24.902'),
(1650, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/14/submit', 200, N'127.0.0.1', '2026-08-01 16:15:26.192'),
(1651, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 16:15:32.333'),
(1652, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/15/answer', 200, N'127.0.0.1', '2026-08-01 16:15:35.798'),
(1653, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/15/answer', 200, N'127.0.0.1', '2026-08-01 16:15:47.541'),
(1654, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/15/answer', 200, N'127.0.0.1', '2026-08-01 16:15:54.436'),
(1655, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/15/answer', 200, N'127.0.0.1', '2026-08-01 16:16:00.212'),
(1656, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/15/answer', 200, N'127.0.0.1', '2026-08-01 16:16:12.829'),
(1657, 1, N'admin', N'delete', N'score', NULL, N'حذف score', N'{"query": null}', N'DELETE', N'/scores/17', 200, N'127.0.0.1', '2026-08-01 16:16:29.907'),
(1658, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/15/answer', 200, N'127.0.0.1', '2026-08-01 16:16:31.079'),
(1659, 1, N'admin', N'delete', N'score', NULL, N'حذف score', N'{"query": null}', N'DELETE', N'/scores/16', 200, N'127.0.0.1', '2026-08-01 16:16:34.120'),
(1660, 1, N'admin', N'delete', N'score', NULL, N'حذف score', N'{"query": null}', N'DELETE', N'/scores/18', 200, N'127.0.0.1', '2026-08-01 16:16:37.331'),
(1661, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/15/answer', 200, N'127.0.0.1', '2026-08-01 16:16:50.469'),
(1662, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:16:52.905'),
(1663, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 16:16:53.554'),
(1664, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 16:16:54.052'),
(1665, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 16:16:54.421'),
(1666, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 16:16:54.573'),
(1667, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 16:16:54.799'),
(1668, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 16:16:54.926'),
(1669, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 16:16:55.087'),
(1670, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 16:16:55.113'),
(1671, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 16:16:55.147'),
(1672, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 16:16:55.285'),
(1673, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 16:16:55.628'),
(1674, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 16:16:56.144'),
(1675, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 16:16:56.294'),
(1676, NULL, NULL, N'update', N'auth', NULL, N'ناموفق: ویرایش احراز هویت (401)', N'{"query": null}', N'PUT', N'/auth/theme', 401, N'127.0.0.1', '2026-08-01 16:16:57.261'),
(1677, 26, N'مسعود هستم', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/15/answer', 200, N'127.0.0.1', '2026-08-01 16:17:02.949'),
(1678, 26, N'مسعود هستم', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/15/submit', 200, N'127.0.0.1', '2026-08-01 16:17:04.139'),
(1679, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:17:05.492'),
(1680, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 16:17:18.909');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1681, 26, N'مسعود هستم', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:17:38.728'),
(1682, 26, N'مسعود هستم', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:17:39.683'),
(1683, 26, N'مسعود هستم', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:17:40.151'),
(1684, 26, N'مسعود هستم', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:17:40.869'),
(1685, 26, N'مسعود هستم', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:17:42.490'),
(1686, 25, N'Ali', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/test-types', 201, N'127.0.0.1', '2026-08-01 16:17:46.015'),
(1687, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:17:49.104'),
(1688, 26, N'مسعود هستم', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:17:52.022'),
(1689, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:17:57.020'),
(1690, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:18:02.550'),
(1691, 13, N'ابراهیم رئیسی', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:18:30.883'),
(1692, 1, N'admin', N'delete', N'level', NULL, N'حذف سطح', N'{"query": null}', N'DELETE', N'/levels/28', 200, N'127.0.0.1', '2026-08-01 16:18:34.447'),
(1693, 13, N'ابراهیم رئیسی', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:18:39.811'),
(1694, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:18:47.542'),
(1695, 1, N'admin', N'delete', N'level', NULL, N'حذف سطح', N'{"query": null}', N'DELETE', N'/levels/30', 200, N'127.0.0.1', '2026-08-01 16:18:47.955'),
(1696, 1, N'admin', N'delete', N'level', NULL, N'حذف سطح', N'{"query": null}', N'DELETE', N'/levels/27', 200, N'127.0.0.1', '2026-08-01 16:18:53.233'),
(1697, 1, N'admin', N'delete', N'level', NULL, N'حذف سطح', N'{"query": null}', N'DELETE', N'/levels/32', 200, N'127.0.0.1', '2026-08-01 16:18:57.739'),
(1698, 19, N'zahra', N'create', N'attendance', NULL, N'ایجاد attendance', N'{"query": null}', N'POST', N'/attendance/bulk', 201, N'127.0.0.1', '2026-08-01 16:19:04.462'),
(1699, 19, N'zahra', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:19:09.995'),
(1700, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:19:14.202'),
(1701, 25, N'Ali', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/questions', 201, N'127.0.0.1', '2026-08-01 16:19:31.005'),
(1702, 25, N'Ali', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/questions/12', 200, N'127.0.0.1', '2026-08-01 16:19:41.201'),
(1703, 25, N'Ali', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:20:00.208'),
(1704, 1, N'admin', N'create', N'student', NULL, N'ناموفق: ایجاد زبان‌آموز (400)', N'{"query": null}', N'POST', N'/students/bulk-delete', 400, N'127.0.0.1', '2026-08-01 16:20:14.190'),
(1705, 25, N'Ali', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:20:27.667'),
(1706, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-01 16:20:39.850'),
(1707, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:20:43.347'),
(1708, 27, N'Mee', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-01 16:20:48.610'),
(1709, 27, N'Mee', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/16/answer', 200, N'127.0.0.1', '2026-08-01 16:20:50.052'),
(1710, 27, N'Mee', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/16/submit', 200, N'127.0.0.1', '2026-08-01 16:20:51.294'),
(1711, 1, N'admin', N'delete', N'teacher', NULL, N'حذف مدرس', N'{"query": null}', N'DELETE', N'/teachers/89', 200, N'127.0.0.1', '2026-08-01 16:21:08.917'),
(1712, 27, N'Mee', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-01 16:21:13.893'),
(1713, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-01 16:21:29.903'),
(1714, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:21:33.923'),
(1715, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:21:35.110'),
(1716, 1, N'admin', N'create', N'session', NULL, N'ایجاد جلسه', N'{"query": null}', N'POST', N'/sessions', 201, N'127.0.0.1', '2026-08-01 16:22:05.583'),
(1717, 1, N'admin', N'create', N'session', NULL, N'ایجاد جلسه', N'{"query": null}', N'POST', N'/sessions', 201, N'127.0.0.1', '2026-08-01 16:22:22.861'),
(1718, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:22:50.486'),
(1719, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:22:51.528'),
(1720, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:22:52.786');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(1721, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:22:53.360'),
(1722, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:22:54.240'),
(1723, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:22:55.060'),
(1724, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:22:56.248'),
(1725, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:22:57.441'),
(1726, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:22:58.876'),
(1727, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:23:01.124'),
(1728, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:23:04.292'),
(1729, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:23:06.745'),
(1730, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:23:11.564'),
(1731, 11, N'arshya', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:23:22.032'),
(1732, 11, N'arshya', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:23:22.844'),
(1733, 11, N'arshya', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:23:23.351'),
(1734, 11, N'arshya', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:23:23.742'),
(1735, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:23:23.762'),
(1736, 11, N'arshya', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:23:24.143'),
(1737, 11, N'arshya', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:23:24.438'),
(1738, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:23:25.540'),
(1739, 11, N'arshya', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:23:25.800'),
(1740, 11, N'arshya', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-01 16:23:26.040'),
(1741, 1, N'admin', N'create', N'shop', NULL, N'ایجاد فروشگاه', N'{"query": null}', N'POST', N'/shop/products', 201, N'127.0.0.1', '2026-08-01 16:23:30.269'),
(2132, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 13:48:32.269'),
(2133, 1, N'admin', N'delete', N'teacher', NULL, N'حذف مدرس', N'{"query": null}', N'DELETE', N'/teachers/83', 200, N'127.0.0.1', '2026-08-03 13:49:10.253'),
(2134, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-03 13:50:01.479'),
(2135, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 13:50:06.184'),
(2136, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 13:50:08.313'),
(2137, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 13:50:15.510'),
(2138, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-03 13:50:17.840'),
(2139, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 13:50:17.982'),
(2140, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 13:50:23.974'),
(2141, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-03 13:50:36.326'),
(2142, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 13:50:45.678'),
(2143, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 13:50:46.023'),
(2144, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-03 13:50:50.577'),
(2145, 1, N'admin', N'create', N'user', NULL, N'ایجاد کاربر', N'{"query": null}', N'POST', N'/users/18/reset-password', 200, N'127.0.0.1', '2026-08-03 13:50:54.456'),
(2146, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 13:50:54.963'),
(2147, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:04:06.636'),
(2148, 1, N'admin', N'create', N'shop', NULL, N'ایجاد فروشگاه', N'{"query": null}', N'POST', N'/shop/products/22/like', 200, N'127.0.0.1', '2026-08-03 14:14:04.313'),
(2149, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:22:22.740'),
(2150, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:30:49.120');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(2151, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:33:42.246'),
(2152, 1, N'admin', N'update', N'user', NULL, N'ویرایش کاربر', N'{"query": null}', N'PUT', N'/users/22', 200, N'127.0.0.1', '2026-08-03 14:33:54.576'),
(2153, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:34:15.611'),
(2154, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 14:34:28.674'),
(2155, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-03 14:34:39.382'),
(2156, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 14:34:43.475'),
(2157, 1, N'admin', N'create', N'shop', NULL, N'ایجاد فروشگاه', N'{"query": null}', N'POST', N'/shop/products', 201, N'127.0.0.1', '2026-08-03 14:34:56.854'),
(2158, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-03 14:35:26.243'),
(2159, 18, N'elyar1390', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-03 14:35:30.737'),
(2160, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 14:35:38.149'),
(2161, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:35:42.106'),
(2162, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:35:45.598'),
(2163, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:35:47.259'),
(2164, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:35:48.760'),
(2165, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:35:49.201'),
(2166, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:35:50.150'),
(2167, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:35:50.748'),
(2168, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:35:52.294'),
(2169, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:35:54.013'),
(2170, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:35:55.247'),
(2171, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-03 14:35:55.358'),
(2172, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:35:56.376'),
(2173, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:35:57.730'),
(2174, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:00.461'),
(2175, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 14:36:18.886'),
(2176, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:38.309'),
(2177, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:39.953'),
(2178, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:41.680'),
(2179, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:44.183'),
(2180, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:45.198'),
(2181, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:46.232'),
(2182, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:47.249'),
(2183, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:49.899'),
(2184, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 14:36:50.759'),
(2185, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:50.913'),
(2186, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:52.065'),
(2187, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:53.623'),
(2188, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:54.222'),
(2189, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:55.060'),
(2190, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:36:56.515');
GO
INSERT INTO dbo.[ActivityLog] ([Id], [UserRef], [Username], [ActionCode], [EntityType], [EntityId], [Message], [DetailJson], [Method], [Path], [StatusCode], [IpAddress], [CreatedAt])
VALUES
(2191, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:40:42.493'),
(2192, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:40:46.782'),
(2193, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:40:52.730'),
(2194, NULL, NULL, N'logout', N'auth', NULL, N'ناموفق: خروج احراز هویت (401)', N'{"query": null}', N'POST', N'/auth/logout', 401, N'127.0.0.1', '2026-08-03 14:52:02.784'),
(2195, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-03 14:52:32.683'),
(2196, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 14:53:30.810'),
(2197, 1, N'admin', N'create', N'user', NULL, N'ایجاد کاربر', N'{"query": null}', N'POST', N'/users/5/reset-password', 200, N'127.0.0.1', '2026-08-03 14:55:05.182'),
(2198, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-03 14:55:22.629'),
(2199, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-03 14:55:29.823'),
(2200, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 14:55:36.324'),
(2201, 5, N'وحید', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:55:40.780'),
(2202, 5, N'وحید', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts', 201, N'127.0.0.1', '2026-08-03 14:56:12.949'),
(2203, 5, N'وحید', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1002/answer', 200, N'127.0.0.1', '2026-08-03 14:56:32.112'),
(2204, 5, N'وحید', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1002/answer', 200, N'127.0.0.1', '2026-08-03 14:56:39.930'),
(2205, 5, N'وحید', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:58:14.632'),
(2206, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 14:58:45.974'),
(2207, 5, N'وحید', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1002/answer', 200, N'127.0.0.1', '2026-08-03 14:59:01.883'),
(2208, NULL, NULL, N'login', N'auth', NULL, N'تلاش ناموفق برای ورود', N'{"query": null}', N'POST', N'/auth/login', 401, N'127.0.0.1', '2026-08-03 14:59:13.275'),
(2209, 5, N'وحید', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1002/answer', 200, N'127.0.0.1', '2026-08-03 14:59:17.500'),
(2210, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 14:59:23.643'),
(2211, 5, N'وحید', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1002/answer', 200, N'127.0.0.1', '2026-08-03 15:01:03.450'),
(2212, 5, N'وحید', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1002/answer', 200, N'127.0.0.1', '2026-08-03 15:01:11.085'),
(2213, 5, N'وحید', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1002/answer', 200, N'127.0.0.1', '2026-08-03 15:01:21.384'),
(2214, 5, N'وحید', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1002/answer', 200, N'127.0.0.1', '2026-08-03 15:01:28.266'),
(2215, 5, N'وحید', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1002/answer', 200, N'127.0.0.1', '2026-08-03 15:01:35.258'),
(2216, 5, N'وحید', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1002/answer', 200, N'127.0.0.1', '2026-08-03 15:01:38.940'),
(2217, 5, N'وحید', N'update', N'placement', NULL, N'ویرایش placement', N'{"query": null}', N'PUT', N'/placement/attempts/1002/answer', 200, N'127.0.0.1', '2026-08-03 15:01:51.542'),
(2218, 5, N'وحید', N'create', N'placement', NULL, N'ایجاد placement', N'{"query": null}', N'POST', N'/placement/attempts/1002/submit', 200, N'127.0.0.1', '2026-08-03 15:01:53.049'),
(2219, 5, N'وحید', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-03 15:02:12.487'),
(2220, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 15:02:18.810'),
(2221, 1, N'admin', N'update', N'auth', NULL, N'ویرایش احراز هویت', N'{"query": null}', N'PUT', N'/auth/theme', 200, N'127.0.0.1', '2026-08-03 15:10:03.972'),
(2222, 1, N'admin', N'logout', N'auth', NULL, N'خروج از سامانه', N'{"query": null}', N'POST', N'/auth/logout', 200, N'127.0.0.1', '2026-08-03 15:26:09.808'),
(2223, NULL, NULL, N'login', N'auth', NULL, N'ورود موفق به سامانه', N'{"query": null}', N'POST', N'/auth/login', 200, N'127.0.0.1', '2026-08-03 15:26:13.264'),
(2224, 18, N'elyar1390', N'create', N'enrollment', NULL, N'ناموفق: ایجاد ثبت‌نام (400)', N'{"query": null}', N'POST', N'/enrollments', 400, N'127.0.0.1', '2026-08-03 15:26:32.105'),
(2225, 18, N'elyar1390', N'create', N'enrollment', NULL, N'ایجاد ثبت‌نام', N'{"query": null}', N'POST', N'/enrollments', 201, N'127.0.0.1', '2026-08-03 15:26:53.292');
GO
SET IDENTITY_INSERT dbo.[ActivityLog] OFF;
GO


-- Re-enable FK checks
DECLARE @sql nvarchar(max) = N'';
SELECT @sql = @sql + N'ALTER TABLE dbo.' + QUOTENAME(OBJECT_NAME(parent_object_id))
             + N' WITH CHECK CHECK CONSTRAINT ' + QUOTENAME(name) + N';' + CHAR(10)
FROM sys.foreign_keys;
EXEC sp_executesql @sql;
GO

/* ===================== TRIGGERS ===================== */
GO

IF OBJECT_ID(N'dbo.TRG_Course_History', N'TR') IS NOT NULL
    DROP TRIGGER dbo.[TRG_Course_History];
GO
CREATE TRIGGER [dbo].[TRG_Course_History]
    ON [dbo].[Course]
    AFTER UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;
        INSERT INTO dbo.CourseHistory (CourseRef, FieldName, OldValue, NewValue)
        SELECT i.Id, N'Name', CAST(d.Name AS NVARCHAR(500)), CAST(i.Name AS NVARCHAR(500))
        FROM inserted i JOIN deleted d ON i.Id = d.Id WHERE ISNULL(d.Name, N'') <> ISNULL(i.Name, N'');

        INSERT INTO dbo.CourseHistory (CourseRef, FieldName, OldValue, NewValue)
        SELECT i.Id, N'Cost', CAST(d.Cost AS NVARCHAR(500)), CAST(i.Cost AS NVARCHAR(500))
        FROM inserted i JOIN deleted d ON i.Id = d.Id WHERE d.Cost <> i.Cost;

        INSERT INTO dbo.CourseHistory (CourseRef, FieldName, OldValue, NewValue)
        SELECT i.Id, N'SessionsCount', CAST(d.SessionsCount AS NVARCHAR(500)), CAST(i.SessionsCount AS NVARCHAR(500))
        FROM inserted i JOIN deleted d ON i.Id = d.Id WHERE d.SessionsCount <> i.SessionsCount;

        INSERT INTO dbo.CourseHistory (CourseRef, FieldName, OldValue, NewValue)
        SELECT i.Id, N'IsActive', CAST(d.IsActive AS NVARCHAR(500)), CAST(i.IsActive AS NVARCHAR(500))
        FROM inserted i JOIN deleted d ON i.Id = d.Id WHERE d.IsActive <> i.IsActive;

        UPDATE c SET UpdatedAt = SYSUTCDATETIME()
        FROM dbo.Course c
        INNER JOIN inserted i ON c.Id = i.Id;
    END
GO

IF OBJECT_ID(N'dbo.TRG_PreventDeleteCourse', N'TR') IS NOT NULL
    DROP TRIGGER dbo.[TRG_PreventDeleteCourse];
GO
CREATE TRIGGER TRG_PreventDeleteCourse
ON Course
INSTEAD OF DELETE
AS
UPDATE Course SET IsActive = 0
WHERE Id IN (SELECT Id FROM deleted)
GO

IF OBJECT_ID(N'dbo.TRG_PreventDeleteTeacher', N'TR') IS NOT NULL
    DROP TRIGGER dbo.[TRG_PreventDeleteTeacher];
GO
CREATE TRIGGER [dbo].[TRG_PreventDeleteTeacher]
    ON [dbo].[Teacher]
    INSTEAD OF DELETE
    AS
    UPDATE Teacher SET IsActive = 0
    WHERE Id IN (SELECT Id FROM deleted);
GO


PRINT N'LIMDB schema + data script completed (SQL Server 2014 compatible).';
GO
