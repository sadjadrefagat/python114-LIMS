/*
  LIMDB — Full schema + data script
  Generated: 2026-07-30 08:53:15
  Server: (local)\SQLEXPRESS2019
  Database: LIMDB
  Includes: tables, constraints, indexes, triggers, views/procs/functions (if any), and row data
*/
USE [master]
GO
IF DB_ID(N'LIMDB') IS NULL
BEGIN
    CREATE DATABASE [LIMDB]
END
GO
USE [LIMDB]
GO
/****** Cannot script Unresolved Entities : Server[@Name='SADJAD-PC\SQLEXPRESS2019']/Database[@Name='LIMDB']/UnresolvedEntity[@Name='inserted'] ******/
GO
/****** Cannot script Unresolved Entities : Server[@Name='SADJAD-PC\SQLEXPRESS2019']/Database[@Name='LIMDB']/UnresolvedEntity[@Name='deleted'] ******/
GO
/****** Object:  UserDefinedFunction [dbo].[CheckNationalCode]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*اعتبار سنجی کد ملی

10   9    8    7    6    5    4    3    2
1    3    7    7    3    9    2    7    5  |  9
10   27   56   49   18   45   8    21   10 = 244
r     0, 1
11-r  > 2
*/
CREATE FUNCTION CheckNationalCode(@NationalCode VARCHAR(10)) RETURNS BIT
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
/****** Object:  Table [dbo].[CourseHistory]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CourseHistory](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CourseRef] [int] NOT NULL,
	[ChangedBy] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ChangedAt] [datetime2](7) NOT NULL,
	[FieldName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[OldValue] [nvarchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[NewValue] [nvarchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_CourseHistory] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Score]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Score](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[RegistrationRef] [int] NOT NULL,
	[ExamType] [nvarchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ScoreValue] [decimal](6, 2) NOT NULL,
	[MaxScore] [decimal](6, 2) NOT NULL,
	[Notes] [nvarchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ExamDate] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CreatedAt] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Score] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Role]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Role](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Name] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SessionType]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SessionType](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_SessionType] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Branch]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Branch](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Address] [nvarchar](300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Phone] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedAt] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Branch] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Language]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Language](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_Language] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Course]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Course](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LanguageRef] [int] NOT NULL,
	[Name] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SessionsCount] [int] NOT NULL,
	[Cost] [int] NOT NULL,
	[Creator] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LevelRef] [int] NULL,
	[Description] [nvarchar](1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PrerequisiteCourseRef] [int] NULL,
	[DurationHours] [int] NULL,
	[Syllabus] [nvarchar](max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TeachingMethod] [nvarchar](200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AgeGroup] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IsHighlighted] [bit] NOT NULL,
	[CreatedAt] [datetime2](7) NOT NULL,
	[UpdatedAt] [datetime2](7) NULL,
 CONSTRAINT [PK_Course] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Level]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Level](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LanguageRef] [int] NOT NULL,
	[Code] [nvarchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Name] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SortOrder] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_Level] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Session]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Session](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ClassRef] [int] NOT NULL,
	[Date] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StartTime] [char](5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[EndTime] [char](5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SessionTypeRef] [int] NOT NULL,
	[Status] [nvarchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CancelReason] [nvarchar](300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MeetingLink] [nvarchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LocationAddress] [nvarchar](300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SubstituteTeacherRef] [int] NULL,
	[IsMakeup] [bit] NOT NULL,
	[Notes] [nvarchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_Session] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Class]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Class](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CourseRef] [int] NOT NULL,
	[TeacherRef] [int] NOT NULL,
	[SessionTypeRef] [int] NOT NULL,
	[StartDate] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EndDate] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Capacity] [int] NOT NULL,
	[Status] [nvarchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CancelReason] [nvarchar](300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ClassType] [nvarchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BranchRef] [int] NULL,
	[LocationAddress] [nvarchar](300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[MeetingLink] [nvarchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CreatedAt] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Class] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Teacher]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Teacher](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[FirstName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[LastName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[FatherName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[NationalCode] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Gender] [int] NOT NULL,
	[BirthDate] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Creator] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Mobile] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Email] [nvarchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Specialty] [nvarchar](200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Bio] [nvarchar](1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedAt] [datetime2](7) NOT NULL,
	[Photo] [varbinary](max) NULL,
	[PhotoMime] [varchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_Teacher] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SessionStudent]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SessionStudent](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SessionRef] [int] NOT NULL,
	[StudentRef] [int] NOT NULL,
	[AttendanceStatus] [nvarchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[RecordedAt] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_SessionStudent] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Registration]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Registration](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Studentref] [int] NOT NULL,
	[CourseRef] [int] NOT NULL,
	[Date] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ClassRef] [int] NULL,
	[Status] [nvarchar](30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[WithdrawReason] [nvarchar](300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[FinancialStatus] [nvarchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CreatedAt] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Registration] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Payment]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Payment](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[StudentRef] [int] NOT NULL,
	[Date] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Amount] [int] NOT NULL,
	[PaymentType] [int] NOT NULL,
	[Status] [nvarchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[PaymentMethod] [nvarchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RegistrationRef] [int] NULL,
	[Description] [nvarchar](300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CreatedAt] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Payment] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Student]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Student](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[FirstName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[LastName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[FatherName] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[NationalCode] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Gender] [int] NOT NULL,
	[BirthDate] [char](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Mobile] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Creator] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Email] [nvarchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[TargetLanguageRef] [int] NULL,
	[CurrentLevelRef] [int] NULL,
	[PreferredUILanguage] [nvarchar](5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[NotificationsEnabled] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedAt] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Student] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AppUser]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AppUser](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Username] [nvarchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Email] [nvarchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[PasswordHash] [nvarchar](200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[FullName] [nvarchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RoleRef] [int] NOT NULL,
	[StudentRef] [int] NULL,
	[TeacherRef] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[PreferredUILanguage] [nvarchar](5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[FailedLoginCount] [int] NOT NULL,
	[LockedUntil] [datetime2](7) NULL,
	[LastLoginAt] [datetime2](7) NULL,
	[CreatedAt] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserSession]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserSession](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UserRef] [int] NOT NULL,
	[TokenHash] [char](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CreatedAt] [datetime2](7) NOT NULL,
	[ExpiresAt] [datetime2](7) NOT NULL,
	[RevokedAt] [datetime2](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[CourseHistory] ON 

INSERT [dbo].[CourseHistory] ([Id], [CourseRef], [ChangedBy], [ChangedAt], [FieldName], [OldValue], [NewValue]) VALUES (1, 50, N'limdbadmin', CAST(N'2026-07-29T15:56:35.8554029' AS DateTime2), N'IsActive', N'1', N'0')
INSERT [dbo].[CourseHistory] ([Id], [CourseRef], [ChangedBy], [ChangedAt], [FieldName], [OldValue], [NewValue]) VALUES (2, 54, N'limdbadmin', CAST(N'2026-07-29T15:56:46.4165845' AS DateTime2), N'IsActive', N'1', N'0')
INSERT [dbo].[CourseHistory] ([Id], [CourseRef], [ChangedBy], [ChangedAt], [FieldName], [OldValue], [NewValue]) VALUES (3, 49, N'limdbadmin', CAST(N'2026-07-29T16:05:04.2333538' AS DateTime2), N'IsActive', N'1', N'0')
INSERT [dbo].[CourseHistory] ([Id], [CourseRef], [ChangedBy], [ChangedAt], [FieldName], [OldValue], [NewValue]) VALUES (4, 52, N'limdbadmin', CAST(N'2026-07-29T16:05:05.8340604' AS DateTime2), N'IsActive', N'1', N'0')
INSERT [dbo].[CourseHistory] ([Id], [CourseRef], [ChangedBy], [ChangedAt], [FieldName], [OldValue], [NewValue]) VALUES (5, 59, N'limdbadmin', CAST(N'2026-07-29T16:05:06.5925960' AS DateTime2), N'IsActive', N'1', N'0')
INSERT [dbo].[CourseHistory] ([Id], [CourseRef], [ChangedBy], [ChangedAt], [FieldName], [OldValue], [NewValue]) VALUES (6, 51, N'limdbadmin', CAST(N'2026-07-29T16:05:33.1709953' AS DateTime2), N'IsActive', N'1', N'0')
INSERT [dbo].[CourseHistory] ([Id], [CourseRef], [ChangedBy], [ChangedAt], [FieldName], [OldValue], [NewValue]) VALUES (7, 60, N'limdbadmin', CAST(N'2026-07-29T16:06:32.4400420' AS DateTime2), N'Name', N'تست سایت', N'دوره فرانسه')
INSERT [dbo].[CourseHistory] ([Id], [CourseRef], [ChangedBy], [ChangedAt], [FieldName], [OldValue], [NewValue]) VALUES (8, 60, N'limdbadmin', CAST(N'2026-07-29T16:06:32.4420613' AS DateTime2), N'SessionsCount', N'1', N'24')
INSERT [dbo].[CourseHistory] ([Id], [CourseRef], [ChangedBy], [ChangedAt], [FieldName], [OldValue], [NewValue]) VALUES (9, 61, N'limdbadmin', CAST(N'2026-07-29T16:12:35.3013699' AS DateTime2), N'IsActive', N'1', N'0')
INSERT [dbo].[CourseHistory] ([Id], [CourseRef], [ChangedBy], [ChangedAt], [FieldName], [OldValue], [NewValue]) VALUES (10, 67, N'limdbadmin', CAST(N'2026-07-30T04:33:44.3681219' AS DateTime2), N'IsActive', N'1', N'0')
INSERT [dbo].[CourseHistory] ([Id], [CourseRef], [ChangedBy], [ChangedAt], [FieldName], [OldValue], [NewValue]) VALUES (11, 66, N'limdbadmin', CAST(N'2026-07-30T04:33:48.2176436' AS DateTime2), N'IsActive', N'1', N'0')
SET IDENTITY_INSERT [dbo].[CourseHistory] OFF
SET IDENTITY_INSERT [dbo].[Score] ON 

INSERT [dbo].[Score] ([Id], [RegistrationRef], [ExamType], [ScoreValue], [MaxScore], [Notes], [ExamDate], [CreatedAt]) VALUES (1, 1002, N'midterm', CAST(78.50 AS Decimal(6, 2)), CAST(100.00 AS Decimal(6, 2)), NULL, NULL, CAST(N'2026-07-29T14:07:44.8300778' AS DateTime2))
SET IDENTITY_INSERT [dbo].[Score] OFF
SET IDENTITY_INSERT [dbo].[Role] ON 

INSERT [dbo].[Role] ([Id], [Code], [Name], [IsActive]) VALUES (1, N'admin', N'مدیر سیستم', 1)
INSERT [dbo].[Role] ([Id], [Code], [Name], [IsActive]) VALUES (2, N'finance', N'کارشناس مالی', 1)
INSERT [dbo].[Role] ([Id], [Code], [Name], [IsActive]) VALUES (3, N'secretary', N'منشی', 1)
INSERT [dbo].[Role] ([Id], [Code], [Name], [IsActive]) VALUES (4, N'teacher', N'مدرس', 1)
INSERT [dbo].[Role] ([Id], [Code], [Name], [IsActive]) VALUES (5, N'student', N'زبان‌آموز', 1)
INSERT [dbo].[Role] ([Id], [Code], [Name], [IsActive]) VALUES (6, N'parent', N'والدین', 1)
SET IDENTITY_INSERT [dbo].[Role] OFF
SET IDENTITY_INSERT [dbo].[SessionType] ON 

INSERT [dbo].[SessionType] ([Id], [Name]) VALUES (1, N'حضوری')
INSERT [dbo].[SessionType] ([Id], [Name]) VALUES (2, N'آنلاین')
INSERT [dbo].[SessionType] ([Id], [Name]) VALUES (3, N'نیمه حضوری')
INSERT [dbo].[SessionType] ([Id], [Name]) VALUES (4, N'آفلاین')
INSERT [dbo].[SessionType] ([Id], [Name]) VALUES (5, N'حضوری 3')
SET IDENTITY_INSERT [dbo].[SessionType] OFF
SET IDENTITY_INSERT [dbo].[Branch] ON 

INSERT [dbo].[Branch] ([Id], [Name], [Address], [Phone], [IsActive], [CreatedAt]) VALUES (1, N'شعبه مرکزی', N'تهران', N'02100000000', 1, CAST(N'2026-07-29T14:01:12.5979648' AS DateTime2))
INSERT [dbo].[Branch] ([Id], [Name], [Address], [Phone], [IsActive], [CreatedAt]) VALUES (3, N'دفتر مرکزی', N'تهران،خیابان جم', N'021-91070008', 1, CAST(N'2026-07-29T14:14:00.2613442' AS DateTime2))
INSERT [dbo].[Branch] ([Id], [Name], [Address], [Phone], [IsActive], [CreatedAt]) VALUES (4, N'شعبه 2', N'تبریز', N'430245613', 1, CAST(N'2026-07-29T14:14:01.2750071' AS DateTime2))
INSERT [dbo].[Branch] ([Id], [Name], [Address], [Phone], [IsActive], [CreatedAt]) VALUES (5, N'شعبه3', N'زنجان', N'430245613', 1, CAST(N'2026-07-29T14:14:41.6155280' AS DateTime2))
INSERT [dbo].[Branch] ([Id], [Name], [Address], [Phone], [IsActive], [CreatedAt]) VALUES (7, N'شعبه شریعی', N'خیابان شریعی, کوی مهران', N'4134442828', 1, CAST(N'2025-05-05T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[Branch] ([Id], [Name], [Address], [Phone], [IsActive], [CreatedAt]) VALUES (8, N'شعبه خیابان شرعیتی', N'خیابان شرعیتی جنوبی جنب بانک ملی', N'09521478525', 0, CAST(N'1365-08-14T00:00:00.0000000' AS DateTime2))
INSERT [dbo].[Branch] ([Id], [Name], [Address], [Phone], [IsActive], [CreatedAt]) VALUES (10, N'شعبه4', N'اهواز', N'4308645297', 1, CAST(N'2026-07-29T14:33:30.7222636' AS DateTime2))
INSERT [dbo].[Branch] ([Id], [Name], [Address], [Phone], [IsActive], [CreatedAt]) VALUES (11, N'شعبه5', N'مشهد', N'09967656554', 1, CAST(N'2026-07-29T14:36:37.3090203' AS DateTime2))
INSERT [dbo].[Branch] ([Id], [Name], [Address], [Phone], [IsActive], [CreatedAt]) VALUES (13, N'شعبه7', N'مشهد', N'09967656554', 1, CAST(N'2026-07-29T14:37:18.1660573' AS DateTime2))
INSERT [dbo].[Branch] ([Id], [Name], [Address], [Phone], [IsActive], [CreatedAt]) VALUES (16, N'شعب85', N'تهران', N'5984265', 1, CAST(N'2026-07-29T14:38:58.6668429' AS DateTime2))
INSERT [dbo].[Branch] ([Id], [Name], [Address], [Phone], [IsActive], [CreatedAt]) VALUES (17, N'شعب8', N'تهران', N'5984265', 1, CAST(N'2026-07-29T14:40:59.5953715' AS DateTime2))
INSERT [dbo].[Branch] ([Id], [Name], [Address], [Phone], [IsActive], [CreatedAt]) VALUES (18, N'شعبه دوم مرکزی', N'شیراز', N'04132589', 1, CAST(N'2026-07-29T16:11:02.9499747' AS DateTime2))
INSERT [dbo].[Branch] ([Id], [Name], [Address], [Phone], [IsActive], [CreatedAt]) VALUES (19, N'شعبه آبرسان', N'آبرسان-ساختمان برج سفید', N'04136656968', 1, CAST(N'2026-07-29T16:17:34.7611032' AS DateTime2))
SET IDENTITY_INSERT [dbo].[Branch] OFF
SET IDENTITY_INSERT [dbo].[Language] ON 

INSERT [dbo].[Language] ([Id], [Name]) VALUES (4, N'آلمانی')
INSERT [dbo].[Language] ([Id], [Name]) VALUES (7, N'اسپانیایی')
INSERT [dbo].[Language] ([Id], [Name]) VALUES (1, N'انگلیسی')
INSERT [dbo].[Language] ([Id], [Name]) VALUES (3, N'ایتالیایی')
INSERT [dbo].[Language] ([Id], [Name]) VALUES (9, N'ترکی آذربایجانی')
INSERT [dbo].[Language] ([Id], [Name]) VALUES (8, N'چینی')
INSERT [dbo].[Language] ([Id], [Name]) VALUES (5, N'روسی')
INSERT [dbo].[Language] ([Id], [Name]) VALUES (6, N'ژاپنی')
INSERT [dbo].[Language] ([Id], [Name]) VALUES (10, N'عربی')
INSERT [dbo].[Language] ([Id], [Name]) VALUES (11, N'فارسی')
INSERT [dbo].[Language] ([Id], [Name]) VALUES (2, N'فرانسوی')
SET IDENTITY_INSERT [dbo].[Language] OFF
SET IDENTITY_INSERT [dbo].[Course] ON 

INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (1, 1, N'دوره فشرده انگلیسی برای کارمندان', 30, 50000000, N'Sadjad-PC\Sadjad', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (3, 2, N'دوره ی آموزش زبان برای کودکان', 40, 35000000, N'vahideh', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (7, 2, N'دوره ی فشرده ی آموزش زبان فرانسه در 60 جلسه', 60, 50000000, N'vahideh', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (8, 1, N'دوره فشرده تافل برای بزرگسالان', 25, 35000000, N'saba', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (9, 1, N'دوره زبان انگلیسی برای نونهالان', 20, 20000000, N'saba', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (10, 2, N'دوره فشورده فرانسوی برای کارمندان', 30, 50000000, N'arshya', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (11, 1, N'دوره فشرده انگلیسی', 40, 900000, N'elyar', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (12, 2, N'دوره فشرده فرانسوی', 40, 1200000, N'elyar', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (17, 2, N'دوره زبان فرانسه برای کارمندان', 30, 50000000, N'asra', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (18, 1, N'دوره فشرده تافل برای کودکان', 30, 50000000, N'asra', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (32, 1, N'دوره نیمه فشرده انگلیسی', 40, 900000, N'elyar', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (33, 2, N'دوره نیمه فشرده فرانسوی', 40, 1200000, N'elyar', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (37, 3, N'دوره ی آموزش زبان ایتالیایی', 30, 42000000, N'vahideh', 1, NULL, N'قفقفقفقفغاخحصثهخ', NULL, NULL, NULL, N'حضوری', N'کودک', 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), CAST(N'2026-07-29T16:13:54.2926852' AS DateTime2))
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (38, 4, N'دوره ی آموزش زبان آلمانی', 30, 42000000, N'vahideh', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (39, 2, N'دوره زبان فرانسوی برای بانوان خانه دار', 30, 45000000, N'saba', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (43, 1, N'دوره نیمه فشرده 90 جلسه ای انگلیسی', 40, 900000, N'elyar', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (44, 2, N'دوره نیمه فشرده80  جلسه ای فرانسوی', 40, 1200000, N'elyar', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (45, 2, N'ترم یک  فرانسوی', 20, 1000000, N'elyar', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (46, 1, N'دوره آموزش رایتینگ تافل', 20, 3000000, N'amirreza', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (49, 1, N'دوره 1111', 11, 11000000, N'limdbadmin', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.6452614' AS DateTime2), CAST(N'2026-07-29T16:05:04.2333538' AS DateTime2))
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (50, 1, N'دوره تست API فاز یک', 20, 1500000, N'limdbadmin', 0, 1, N'این یک دوره تستی برای اعتبارسنجی API فاز یک است', NULL, NULL, NULL, N'ارتباطی', N'بزرگسال', 1, CAST(N'2026-07-29T14:04:43.6657601' AS DateTime2), CAST(N'2026-07-29T15:56:35.8554029' AS DateTime2))
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (51, 1, N'دوره تست API فاز یک ۲', 20, 1500000, N'limdbadmin', 0, 1, N'این یک دوره تستی برای اعتبارسنجی API فاز یک است', NULL, NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:07:44.7474852' AS DateTime2), CAST(N'2026-07-29T16:05:33.1709953' AS DateTime2))
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (52, 2, N'دوره فشرده فرانسوی در 15 جلسه', 15, 25000000, N'limdbadmin', 0, 21, N'سلام به کلاس خوش آمدید', NULL, NULL, NULL, N'تدریس نمیشود', N'5555', 0, CAST(N'2026-07-29T15:34:06.0736209' AS DateTime2), CAST(N'2026-07-29T16:05:05.8340604' AS DateTime2))
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (53, 1, N'دوره 6 ماهه زبان انگلیسی', 100, 350000000, N'limdbadmin', 1, 10, N'دوره 6 ماهه زبان انگلیسی', NULL, NULL, NULL, N'حضوری', N'10-20', 0, CAST(N'2026-07-29T15:41:34.0564935' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (54, 9, N'زبان ترکی', 20, 20000000, N'limdbadmin', 0, NULL, N'زبان ترکی (آذری)', NULL, NULL, NULL, N'حضوری', N'ندارد', 0, CAST(N'2026-07-29T15:43:39.7915648' AS DateTime2), CAST(N'2026-07-29T15:56:46.4165845' AS DateTime2))
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (59, 6, N'دوره تست', 1000222222, 10000000, N'limdbadmin', 0, NULL, N'تست سایت AR', NULL, NULL, NULL, N'حضوری', N'جوان', 1, CAST(N'2026-07-29T15:46:13.8972803' AS DateTime2), CAST(N'2026-07-29T16:05:06.5925960' AS DateTime2))
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (60, 4, N'دوره فرانسه', 24, 1000000000, N'limdbadmin', 1, 4, N'با متد های جدید بین المللی', NULL, NULL, NULL, N'گرامرمحور', N'جوان', 0, CAST(N'2026-07-29T15:49:54.6925248' AS DateTime2), CAST(N'2026-07-29T16:06:32.4420613' AS DateTime2))
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (61, 10, N'عربی زبان قرآن', 124578, 1000000, N'limdbadmin', 0, NULL, N'اهلا و سهلا بلتحصیل الغلت العربی لغت التحصیل قران', NULL, NULL, NULL, N'مکالمه‌محور', N'همه سنین', 1, CAST(N'2026-07-29T15:51:32.1437870' AS DateTime2), CAST(N'2026-07-29T16:12:35.3013699' AS DateTime2))
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (64, 11, N'دوره نمایشی فارسی #20', 16, 15000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'ترکیبی', N'کودک', 0, CAST(N'2026-07-30T04:10:00.7999552' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (65, 5, N'دوره نمایشی روسی #21', 30, 25000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'حضوری', N'نوجوان', 0, CAST(N'2026-07-30T04:10:00.8085354' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (66, 11, N'دوره نمایشی فارسی #22', 30, 25000000, N'seed', 0, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'فشرده', N'جوان', 1, CAST(N'2026-07-30T04:10:00.8138630' AS DateTime2), CAST(N'2026-07-30T04:33:48.2176436' AS DateTime2))
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (67, 10, N'دوره نمایشی عربی #23', 16, 45000000, N'seed', 0, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'گرامرمحور', N'جوان', 1, CAST(N'2026-07-30T04:10:00.8149711' AS DateTime2), CAST(N'2026-07-30T04:33:44.3681219' AS DateTime2))
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (68, 5, N'دوره نمایشی روسی #24', 20, 12000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آنلاین', N'کودک', 0, CAST(N'2026-07-30T04:10:00.8208220' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (69, 5, N'دوره نمایشی روسی #25', 16, 20000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آزمون‌محور', N'بزرگسال', 0, CAST(N'2026-07-30T04:10:00.8232452' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (70, 6, N'دوره نمایشی ژاپنی #26', 12, 45000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'مهارت‌محور', N'کودک', 0, CAST(N'2026-07-30T04:10:00.8288762' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (71, 1, N'دوره نمایشی انگلیسی #27', 16, 15000000, N'seed', 1, 9, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'مهارت‌محور', N'همه سنین', 0, CAST(N'2026-07-30T04:10:00.8328300' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (72, 1, N'دوره نمایشی انگلیسی #28', 12, 15000000, N'seed', 1, 9, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آنلاین', N'بزرگسال', 0, CAST(N'2026-07-30T04:10:00.8358160' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (73, 2, N'دوره نمایشی فرانسوی #29', 24, 8000000, N'seed', 1, 24, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'مهارت‌محور', N'جوان', 0, CAST(N'2026-07-30T04:10:00.8358160' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (74, 5, N'دوره نمایشی روسی #30', 20, 12000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آزمون‌محور', N'کودک', 0, CAST(N'2026-07-30T04:10:00.8420259' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (75, 11, N'دوره نمایشی فارسی #31', 20, 15000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آزمون‌محور', N'نوجوان', 0, CAST(N'2026-07-30T04:10:00.8420259' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (76, 10, N'دوره نمایشی عربی #32', 24, 12000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'گرامرمحور', N'بزرگسال', 0, CAST(N'2026-07-30T04:10:00.8497047' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (77, 2, N'دوره نمایشی فرانسوی #33', 24, 8000000, N'seed', 1, 21, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'ترکیبی', N'کودک', 0, CAST(N'2026-07-30T04:10:00.8559153' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (78, 7, N'دوره نمایشی اسپانیایی #34', 24, 45000000, N'seed', 1, 27, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آنلاین', N'کودک', 0, CAST(N'2026-07-30T04:10:00.8581188' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (79, 1, N'دوره نمایشی انگلیسی #35', 30, 20000000, N'seed', 1, 11, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'حضوری', N'جوان', 0, CAST(N'2026-07-30T04:10:00.8632311' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (80, 9, N'دوره نمایشی ترکی(آذری) #36', 12, 20000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'فشرده', N'بزرگسال', 0, CAST(N'2026-07-30T04:10:00.8698780' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (81, 3, N'دوره نمایشی ایتالیایی #37', 20, 15000000, N'seed', 1, 18, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آزمون‌محور', N'نوجوان', 0, CAST(N'2026-07-30T04:10:00.8747973' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (82, 6, N'دوره نمایشی ژاپنی #38', 24, 25000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'گرامرمحور', N'کودک', 0, CAST(N'2026-07-30T04:10:00.8764061' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (83, 7, N'دوره نمایشی اسپانیایی #39', 30, 8000000, N'seed', 1, 27, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آنلاین', N'بزرگسال', 0, CAST(N'2026-07-30T04:10:00.8818761' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (84, 8, N'دوره نمایشی چینی #40', 12, 12000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آنلاین', N'جوان', 0, CAST(N'2026-07-30T04:10:00.8833648' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (85, 8, N'دوره نمایشی چینی #41', 12, 15000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آنلاین', N'نوجوان', 0, CAST(N'2026-07-30T04:10:00.8833648' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (86, 2, N'دوره نمایشی فرانسوی #42', 16, 35000000, N'seed', 1, 19, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'حضوری', N'همه سنین', 0, CAST(N'2026-07-30T04:10:00.8907630' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (87, 2, N'دوره نمایشی فرانسوی #43', 12, 20000000, N'seed', 1, 23, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'ترکیبی', N'جوان', 0, CAST(N'2026-07-30T04:10:00.8927705' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (88, 3, N'دوره نمایشی ایتالیایی #44', 16, 15000000, N'seed', 1, 13, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'آزمون‌محور', N'کودک', 0, CAST(N'2026-07-30T04:10:00.8927705' AS DateTime2), NULL)
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator], [IsActive], [LevelRef], [Description], [PrerequisiteCourseRef], [DurationHours], [Syllabus], [TeachingMethod], [AgeGroup], [IsHighlighted], [CreatedAt], [UpdatedAt]) VALUES (89, 11, N'دوره نمایشی فارسی #45', 30, 15000000, N'seed', 1, NULL, N'توضیحات نمایشی دوره برای گزارش مدیریتی داشبورد لیمز.', NULL, NULL, NULL, N'حضوری', N'کودک', 0, CAST(N'2026-07-30T04:10:00.8980588' AS DateTime2), NULL)
SET IDENTITY_INSERT [dbo].[Course] OFF
SET IDENTITY_INSERT [dbo].[Level] ON 

INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (1, 4, N'A1', N'مبتدی ۱', 1, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (2, 4, N'A2', N'مبتدی ۲', 2, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (3, 4, N'B1', N'متوسط ۱', 3, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (4, 4, N'B2', N'متوسط ۲', 4, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (5, 4, N'C1', N'پیشرفته ۱', 5, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (6, 4, N'C2', N'پیشرفته ۲', 6, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (7, 1, N'A1', N'مبتدی ۱', 1, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (8, 1, N'A2', N'مبتدی ۲', 2, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (9, 1, N'B1', N'متوسط ۱', 3, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (10, 1, N'B2', N'متوسط ۲', 4, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (11, 1, N'C1', N'پیشرفته ۱', 5, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (12, 1, N'C2', N'پیشرفته ۲', 6, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (13, 3, N'A1', N'مبتدی ۱', 1, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (14, 3, N'A2', N'مبتدی ۲', 2, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (15, 3, N'B1', N'متوسط ۱', 3, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (16, 3, N'B2', N'متوسط ۲', 4, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (17, 3, N'C1', N'پیشرفته ۱', 5, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (18, 3, N'C2', N'پیشرفته ۲', 6, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (19, 2, N'A1', N'مبتدی ۱', 1, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (20, 2, N'A2', N'مبتدی ۲', 2, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (21, 2, N'B1', N'متوسط ۱', 3, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (22, 2, N'B2', N'متوسط ۲', 4, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (23, 2, N'C1', N'پیشرفته ۱', 5, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (24, 2, N'C2', N'پیشرفته ۲', 6, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (25, 4, N's5', N'ituiui', -38, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (26, 1, N'C3', N'متوسط 2', 4, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (27, 7, N'c10', N'پیشرفته', 3, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (28, 4, N'َشئبنثیئ', N'سثقفا', 1, 1)
INSERT [dbo].[Level] ([Id], [LanguageRef], [Code], [Name], [SortOrder], [IsActive]) VALUES (30, 7, N'صقفاتصقفاصشقفاصشفقتا', N'ف4تاثقفافاقاقفاقفا', 112312323, 1)
SET IDENTITY_INSERT [dbo].[Level] OFF
SET IDENTITY_INSERT [dbo].[Session] ON 

INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1, 2, N'1405/04/01', N'17:00', N'20:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (2, 2, N'1405/04/02', N'17:00', N'18:30', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (3, 2, N'1405/04/03', N'17:00', N'20:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (4, 6, N'1405/01/01', N'12:00', N'13:30', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1002, 1004, N'1405/07/10', N'09:00', N'10:30', 2, N'scheduled', NULL, N'https://meet.example.com/room-1', N'هننلعهنبغهنغ', NULL, 0, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1003, 1005, N'1395/02/02', N'10:00', N'11:30', 1, N'scheduled', NULL, NULL, N'شعبه مرکزی', NULL, 0, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1004, 1008, N'1405/05/07', N'10:00', N'11:30', 1, N'scheduled', NULL, NULL, N'اهر', NULL, 0, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1005, 1006, N'1405/05/07', N'10:00', N'11:30', 1, N'scheduled', NULL, NULL, N'تهران', NULL, 0, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1006, 1006, N'1405/05/01', N'10:00', N'11:30', 1, N'scheduled', NULL, NULL, N'تهران', NULL, 0, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1007, 1008, N'1405/05/28', N'10:00', N'11:30', 1, N'scheduled', NULL, NULL, N'اهر', NULL, 0, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1008, 1009, N'1405/05/07', N'10:00', N'11:30', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1009, 1006, N'1405/05/28', N'10:00', N'11:30', 1, N'scheduled', NULL, NULL, N'تهران', NULL, 0, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1010, 1007, N'1409/02/03', N'10:00', N'25:30', 4, N'scheduled', NULL, NULL, N'تهران', NULL, 1, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1011, 1006, N'1405/05/31', N'10:00', N'11:30', 1, N'scheduled', NULL, NULL, N'تهران', NULL, 0, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1012, 1011, N'1405/05/12', N'11:00', N'22:30', 2, N'scheduled', NULL, N'https://wikipedia.com', N'تبریز', NULL, 0, NULL)
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1013, 1042, N'1405/05/16', N'12:00', N'14:00', 3, N'completed', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1014, 1012, N'1405/09/05', N'14:00', N'16:00', 2, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1015, 1026, N'1405/10/01', N'09:00', N'11:00', 3, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1016, 1113, N'1405/10/25', N'14:00', N'16:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1017, 1129, N'1405/05/28', N'13:00', N'15:00', 1, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1018, 1054, N'1404/01/11', N'15:00', N'17:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1019, 1006, N'1404/07/24', N'18:00', N'20:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1020, 1075, N'1404/03/20', N'18:00', N'20:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1021, 1013, N'1405/03/08', N'08:00', N'10:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1022, 1114, N'1405/02/17', N'12:00', N'14:00', 1, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1023, 1098, N'1404/09/01', N'17:00', N'19:00', 5, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1024, 1081, N'1404/05/02', N'13:00', N'15:00', 1, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1025, 1018, N'1404/11/28', N'15:00', N'17:00', 1, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1026, 1076, N'1405/07/01', N'13:00', N'15:00', 3, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1027, 1019, N'1404/09/07', N'17:00', N'19:00', 3, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1028, 1038, N'1404/03/02', N'18:00', N'20:00', 1, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1029, 1021, N'1404/04/04', N'16:00', N'18:00', 2, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1030, 1049, N'1404/03/28', N'12:00', N'14:00', 1, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1031, 1076, N'1404/09/21', N'18:00', N'20:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1032, 1023, N'1404/12/27', N'13:00', N'15:00', 4, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1033, 1112, N'1405/01/25', N'14:00', N'16:00', 5, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1034, 1037, N'1405/03/03', N'18:00', N'20:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1035, 1012, N'1404/12/24', N'14:00', N'16:00', 4, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1036, 1016, N'1405/07/23', N'17:00', N'19:00', 2, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1037, 1089, N'1404/08/20', N'11:00', N'13:00', 1, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1038, 1083, N'1404/05/12', N'10:00', N'12:00', 1, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1039, 1012, N'1404/06/01', N'13:00', N'15:00', 1, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1040, 1132, N'1405/10/28', N'08:00', N'10:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1041, 1031, N'1404/10/06', N'15:00', N'17:00', 4, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1042, 1119, N'1404/07/10', N'10:00', N'12:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1043, 1107, N'1404/02/14', N'10:00', N'12:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1044, 1121, N'1404/12/17', N'17:00', N'19:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1045, 1047, N'1404/02/19', N'12:00', N'14:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1046, 1081, N'1404/05/18', N'16:00', N'18:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1047, 1085, N'1405/01/17', N'14:00', N'16:00', 1, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1048, 1024, N'1405/05/16', N'11:00', N'13:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1049, 1093, N'1405/08/05', N'10:00', N'12:00', 4, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1050, 1078, N'1405/01/16', N'09:00', N'11:00', 3, N'completed', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1051, 1037, N'1405/03/19', N'11:00', N'13:00', 5, N'rescheduled', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1052, 1058, N'1404/12/22', N'17:00', N'19:00', 2, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1053, 1124, N'1405/01/06', N'16:00', N'18:00', 3, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1054, 1091, N'1405/01/19', N'10:00', N'12:00', 3, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1055, 1042, N'1404/05/11', N'11:00', N'13:00', 2, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1056, 1111, N'1404/09/05', N'09:00', N'11:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1057, 1028, N'1405/02/02', N'16:00', N'18:00', 4, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1058, 1026, N'1404/09/02', N'17:00', N'19:00', 2, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1059, 1112, N'1404/12/23', N'18:00', N'20:00', 1, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1060, 1126, N'1405/02/06', N'14:00', N'16:00', 1, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1061, 1007, N'1404/12/03', N'15:00', N'17:00', 4, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1062, 2, N'1404/10/21', N'18:00', N'20:00', 2, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1063, 1107, N'1404/02/13', N'11:00', N'13:00', 3, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1064, 1124, N'1404/09/01', N'14:00', N'16:00', 5, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1065, 1057, N'1405/04/22', N'12:00', N'14:00', 5, N'rescheduled', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1066, 1073, N'1405/03/20', N'16:00', N'18:00', 1, N'completed', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1067, 1043, N'1404/05/18', N'12:00', N'14:00', 5, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1068, 1098, N'1405/01/27', N'13:00', N'15:00', 3, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1069, 1127, N'1405/11/27', N'12:00', N'14:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1070, 1069, N'1405/05/28', N'09:00', N'11:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1071, 1100, N'1404/07/05', N'08:00', N'10:00', 4, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1072, 1120, N'1404/10/23', N'16:00', N'18:00', 1, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1073, 1041, N'1404/11/07', N'08:00', N'10:00', 4, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1074, 1063, N'1404/12/15', N'09:00', N'11:00', 1, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1075, 2, N'1405/06/22', N'14:00', N'16:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1076, 1056, N'1405/09/07', N'17:00', N'19:00', 3, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1077, 1108, N'1404/09/28', N'14:00', N'16:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1078, 1019, N'1405/05/05', N'08:00', N'10:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1079, 1023, N'1404/04/17', N'11:00', N'13:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1080, 1060, N'1404/06/15', N'08:00', N'10:00', 3, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1081, 1008, N'1404/07/06', N'09:00', N'11:00', 2, N'completed', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1082, 1119, N'1404/02/27', N'15:00', N'17:00', 2, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1083, 1097, N'1404/08/08', N'09:00', N'11:00', 1, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1084, 1064, N'1404/03/17', N'12:00', N'14:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1085, 1095, N'1405/10/18', N'16:00', N'18:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1086, 1047, N'1405/02/05', N'12:00', N'14:00', 2, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1087, 1053, N'1404/01/04', N'18:00', N'20:00', 5, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1088, 1021, N'1404/04/17', N'12:00', N'14:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1089, 1061, N'1404/06/09', N'11:00', N'13:00', 3, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1090, 1063, N'1405/09/08', N'12:00', N'14:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1091, 1036, N'1404/01/21', N'08:00', N'10:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1092, 1070, N'1405/05/16', N'09:00', N'11:00', 5, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1093, 1055, N'1405/05/04', N'08:00', N'10:00', 1, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1094, 1079, N'1404/05/10', N'12:00', N'14:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1095, 1040, N'1405/12/24', N'16:00', N'18:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1096, 1004, N'1405/08/17', N'14:00', N'16:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
GO
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1097, 1092, N'1404/02/28', N'12:00', N'14:00', 3, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1098, 1106, N'1405/07/17', N'18:00', N'20:00', 2, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1099, 1053, N'1404/11/14', N'09:00', N'11:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1100, 1124, N'1405/07/26', N'08:00', N'10:00', 2, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1101, 1008, N'1404/12/27', N'09:00', N'11:00', 1, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1102, 1099, N'1404/05/14', N'13:00', N'15:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1103, 1103, N'1405/06/24', N'13:00', N'15:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1104, 1127, N'1405/01/07', N'15:00', N'17:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1105, 1072, N'1405/07/09', N'11:00', N'13:00', 3, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1106, 1013, N'1405/10/17', N'10:00', N'12:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1107, 1056, N'1405/02/18', N'09:00', N'11:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1108, 1021, N'1405/01/13', N'14:00', N'16:00', 4, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1109, 1067, N'1404/01/18', N'14:00', N'16:00', 2, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1110, 1109, N'1405/05/09', N'18:00', N'20:00', 1, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1111, 1066, N'1405/02/15', N'12:00', N'14:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1112, 1072, N'1404/06/20', N'08:00', N'10:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1113, 1061, N'1405/06/14', N'13:00', N'15:00', 3, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1114, 1078, N'1405/06/10', N'18:00', N'20:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1115, 1059, N'1404/09/03', N'08:00', N'10:00', 5, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1116, 1030, N'1405/01/14', N'16:00', N'18:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1117, 1049, N'1405/11/09', N'11:00', N'13:00', 2, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1118, 1042, N'1405/03/07', N'09:00', N'11:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1119, 1123, N'1404/04/10', N'16:00', N'18:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1120, 1057, N'1405/03/18', N'15:00', N'17:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1121, 1122, N'1404/12/11', N'08:00', N'10:00', 2, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1122, 1047, N'1404/03/08', N'13:00', N'15:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1123, 1023, N'1404/11/25', N'10:00', N'12:00', 4, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1124, 1076, N'1404/04/15', N'13:00', N'15:00', 5, N'completed', NULL, NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1125, 1041, N'1404/05/12', N'09:00', N'11:00', 2, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1126, 1019, N'1404/11/23', N'08:00', N'10:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1127, 1097, N'1404/10/12', N'10:00', N'12:00', 2, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 1, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1128, 1010, N'1404/03/16', N'18:00', N'20:00', 1, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1129, 1041, N'1404/12/04', N'11:00', N'13:00', 4, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1130, 1046, N'1404/07/13', N'12:00', N'14:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1131, 1059, N'1405/04/04', N'18:00', N'20:00', 3, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1132, 1082, N'1405/06/09', N'12:00', N'14:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1133, 1031, N'1405/01/15', N'17:00', N'19:00', 2, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1134, 1097, N'1404/06/20', N'13:00', N'15:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1135, 1077, N'1404/06/08', N'16:00', N'18:00', 1, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1136, 1130, N'1404/07/10', N'13:00', N'15:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1137, 1123, N'1405/12/18', N'18:00', N'20:00', 3, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1138, 1087, N'1405/06/02', N'10:00', N'12:00', 2, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1139, 1062, N'1404/05/26', N'18:00', N'20:00', 3, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1140, 1003, N'1405/10/18', N'11:00', N'13:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1141, 1119, N'1404/10/23', N'09:00', N'11:00', 4, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1142, 1115, N'1405/05/21', N'18:00', N'20:00', 5, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1143, 1012, N'1405/07/13', N'09:00', N'11:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1144, 1068, N'1405/04/03', N'14:00', N'16:00', 2, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1145, 1073, N'1404/10/21', N'08:00', N'10:00', 2, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1146, 1083, N'1405/10/17', N'14:00', N'16:00', 4, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1147, 1078, N'1404/07/17', N'16:00', N'18:00', 1, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1148, 1103, N'1405/11/07', N'16:00', N'18:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1149, 1052, N'1405/01/13', N'18:00', N'20:00', 2, N'rescheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1150, 1058, N'1404/09/27', N'17:00', N'19:00', 2, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1151, 1056, N'1404/01/12', N'16:00', N'18:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1152, 1004, N'1405/10/27', N'08:00', N'10:00', 5, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1153, 1050, N'1404/12/27', N'18:00', N'20:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1154, 1037, N'1404/09/10', N'11:00', N'13:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1155, 1035, N'1405/06/26', N'17:00', N'19:00', 4, N'in_progress', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1156, 1096, N'1405/05/21', N'18:00', N'20:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1157, 1049, N'1405/06/25', N'16:00', N'18:00', 3, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1158, 1014, N'1404/10/19', N'16:00', N'18:00', 2, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1159, 1058, N'1404/01/09', N'18:00', N'20:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1160, 1005, N'1404/07/22', N'15:00', N'17:00', 5, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1161, 1058, N'1404/12/06', N'14:00', N'16:00', 4, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1162, 1037, N'1404/09/16', N'09:00', N'11:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1163, 1079, N'1405/08/19', N'16:00', N'18:00', 2, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1164, 1040, N'1404/03/18', N'18:00', N'20:00', 2, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1165, 1027, N'1405/02/17', N'14:00', N'16:00', 2, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1166, 1119, N'1405/02/12', N'15:00', N'17:00', 4, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1167, 1098, N'1404/02/10', N'18:00', N'20:00', 1, N'cancelled', N'لغو جلسه نمایشی', NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1168, 1087, N'1405/05/06', N'13:00', N'15:00', 5, N'completed', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1169, 1052, N'1405/09/02', N'15:00', N'17:00', 1, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1170, 1056, N'1405/05/21', N'18:00', N'20:00', 3, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1171, 1130, N'1404/03/03', N'17:00', N'19:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
INSERT [dbo].[Session] ([Id], [ClassRef], [Date], [StartTime], [EndTime], [SessionTypeRef], [Status], [CancelReason], [MeetingLink], [LocationAddress], [SubstituteTeacherRef], [IsMakeup], [Notes]) VALUES (1172, 1110, N'1404/06/15', N'14:00', N'16:00', 4, N'scheduled', NULL, NULL, NULL, NULL, 0, N'جلسه نمایشی داشبورد')
SET IDENTITY_INSERT [dbo].[Session] OFF
SET IDENTITY_INSERT [dbo].[Class] ON 

INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (2, 1, 1, 1, N'1405/03/20', NULL, 15, N'open', NULL, N'group', 1, NULL, NULL, CAST(N'2026-07-29T14:01:12.7206670' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (6, 1, 5, 1, N'1405/01/01', N'1405/05/07', 15, N'cancelled', N'تعداد نفرات کم', N'group', 1, NULL, NULL, CAST(N'2026-07-29T14:01:12.7206670' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1003, 1, 1, 1, N'1405/06/01', NULL, 10, N'open', NULL, N'group', NULL, N'تهران - کلاس ۱۰۱', NULL, CAST(N'2026-07-29T14:04:43.6791776' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1004, 51, 5, 2, N'1405/07/01', NULL, 8, N'open', NULL, N'group', NULL, NULL, N'https://meet.example.com/room-1', CAST(N'2026-07-29T14:07:44.7675768' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1005, 9, 21, 1, N'????/??/??', N'????/??/??', 15, N'open', NULL, N'private', 1, N'شعبه مرکزی', NULL, CAST(N'2026-07-29T15:09:50.0583576' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1006, 45, 1, 1, N'????/??/??', N'????/??/??', 15, N'open', NULL, N'group', 3, N'تهران', NULL, CAST(N'2026-07-29T15:10:16.3718363' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1007, 46, 42, 3, N'1405/05/07', N'1405/05/07', 15, N'open', NULL, N'group', 11, N'تهران', NULL, CAST(N'2026-07-29T15:25:32.7026835' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1008, 49, 16, 1, N'1406/02/03', N'1384/04/02', 15, N'open', NULL, N'group', NULL, N'اهر', NULL, CAST(N'2026-07-29T15:26:09.2307860' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1009, 46, 17, 4, N'1405/05/07', N'1405/05/07', 14, N'open', NULL, N'private', 8, NULL, NULL, CAST(N'2026-07-29T15:28:50.8043515' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1010, 45, 42, 3, N'1404/08/13', N'1404/08/22', 15, N'open', NULL, N'group', NULL, NULL, NULL, CAST(N'2026-07-29T15:44:12.9633022' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1011, 54, 1, 1, N'1405/05/07', N'1405/06/18', 15, N'open', NULL, N'group', NULL, N'تبریز', NULL, CAST(N'2026-07-29T15:44:57.1688731' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1012, 61, 23, 4, N'1404/09/11', N'1405/05/05', 152, N'open', NULL, N'private', 17, N'اهر', NULL, CAST(N'2026-07-29T15:52:43.6742370' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1013, 39, 26, 3, N'1405/06/08', N'1405/07/22', 20, N'open', NULL, N'group', 17, NULL, NULL, CAST(N'2026-07-30T04:10:00.9086828' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1014, 38, 28, 3, N'1404/09/07', N'1404/12/14', 12, N'finished', NULL, N'vip', 16, NULL, NULL, CAST(N'2026-07-30T04:10:00.9136010' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1015, 33, 81, 2, N'1404/06/06', N'1404/07/20', 10, N'open', NULL, N'semi_private', 11, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:00.9185834' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1016, 82, 38, 3, N'1403/03/19', N'1403/04/12', 15, N'finished', NULL, N'semi_private', 10, NULL, NULL, CAST(N'2026-07-30T04:10:00.9254468' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1017, 32, 39, 4, N'1403/09/03', N'1403/11/15', 12, N'finished', NULL, N'vip', 10, NULL, NULL, CAST(N'2026-07-30T04:10:00.9254468' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1018, 64, 1, 5, N'1405/06/13', N'1405/07/10', 8, N'open', NULL, N'semi_private', 3, NULL, NULL, CAST(N'2026-07-30T04:10:00.9344421' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1019, 9, 9, 2, N'1403/04/02', N'1403/06/13', 12, N'in_progress', NULL, N'vip', 5, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:00.9393854' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1020, 39, 39, 3, N'1405/01/13', N'1405/04/22', 12, N'open', NULL, N'vip', 13, NULL, NULL, CAST(N'2026-07-30T04:10:00.9461009' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1021, 80, 83, 2, N'1403/07/19', N'1403/09/17', 15, N'finished', NULL, N'group', 3, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:00.9461009' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1022, 71, 28, 5, N'1405/07/13', N'1405/10/12', 20, N'open', NULL, N'group', 8, NULL, NULL, CAST(N'2026-07-30T04:10:00.9534057' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1023, 39, 23, 3, N'1403/07/04', N'1403/09/27', 12, N'open', NULL, N'vip', 4, NULL, NULL, CAST(N'2026-07-30T04:10:00.9534057' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1024, 18, 40, 3, N'1405/01/12', N'1405/03/17', 12, N'full', NULL, N'group', 1, NULL, NULL, CAST(N'2026-07-30T04:10:00.9598307' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1025, 75, 42, 2, N'1404/02/11', N'1404/04/23', 10, N'in_progress', NULL, N'semi_private', 11, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:00.9603122' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1026, 38, 40, 4, N'1403/03/04', N'1403/05/10', 15, N'in_progress', NULL, N'private', 11, NULL, NULL, CAST(N'2026-07-30T04:10:00.9670518' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1027, 69, 83, 2, N'1404/08/02', N'1404/09/27', 10, N'cancelled', N'لغو نمایشی', N'group', 7, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:00.9742399' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1028, 8, 27, 4, N'1403/02/11', N'1403/05/23', 15, N'cancelled', N'لغو نمایشی', N'semi_private', 10, NULL, NULL, CAST(N'2026-07-30T04:10:00.9809269' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1029, 72, 9, 3, N'1405/02/04', N'1405/03/10', 18, N'open', NULL, N'vip', 11, NULL, NULL, CAST(N'2026-07-30T04:10:00.9809269' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1030, 33, 83, 5, N'1403/05/13', N'1403/06/22', 12, N'open', NULL, N'group', 1, NULL, NULL, CAST(N'2026-07-30T04:10:00.9809269' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1031, 60, 38, 4, N'1404/06/15', N'1404/09/22', 8, N'draft', NULL, N'semi_private', 11, NULL, NULL, CAST(N'2026-07-30T04:10:00.9879076' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1032, 64, 23, 1, N'1405/09/13', N'1405/11/22', 10, N'finished', NULL, N'semi_private', 18, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:00.9949629' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1033, 39, 40, 1, N'1403/03/11', N'1403/04/22', 8, N'open', NULL, N'semi_private', 13, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.0014191' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1034, 8, 38, 2, N'1405/10/08', N'1405/12/14', 18, N'full', NULL, N'vip', 8, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.0042657' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1035, 87, 16, 1, N'1404/06/13', N'1404/08/17', 18, N'open', NULL, N'group', 3, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.0087038' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1036, 68, 42, 1, N'1405/01/11', N'1405/04/22', 18, N'finished', NULL, N'private', 1, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.0197851' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1037, 75, 26, 1, N'1404/09/01', N'1404/10/25', 18, N'in_progress', NULL, N'semi_private', 11, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.0247991' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1038, 11, 81, 1, N'1403/04/20', N'1403/05/10', 10, N'cancelled', N'لغو نمایشی', N'private', 18, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.0296321' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1039, 65, 86, 4, N'1404/04/02', N'1404/06/12', 8, N'cancelled', N'لغو نمایشی', N'group', 7, NULL, NULL, CAST(N'2026-07-30T04:10:01.0338950' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1040, 69, 27, 2, N'1405/06/11', N'1405/08/13', 12, N'open', NULL, N'private', 18, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.0415175' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1041, 38, 28, 4, N'1404/02/07', N'1404/03/18', 20, N'finished', NULL, N'vip', 3, NULL, NULL, CAST(N'2026-07-30T04:10:01.0430914' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1042, 45, 42, 4, N'1403/01/19', N'1403/03/10', 12, N'in_progress', NULL, N'group', 13, NULL, NULL, CAST(N'2026-07-30T04:10:01.0458920' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1043, 78, 31, 5, N'1403/07/19', N'1403/08/24', 12, N'open', NULL, N'semi_private', 4, NULL, NULL, CAST(N'2026-07-30T04:10:01.0458920' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1044, 43, 11, 4, N'1404/02/17', N'1404/03/24', 20, N'open', NULL, N'private', 16, NULL, NULL, CAST(N'2026-07-30T04:10:01.0511594' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1045, 79, 86, 3, N'1403/02/01', N'1403/04/19', 15, N'open', NULL, N'private', 17, NULL, NULL, CAST(N'2026-07-30T04:10:01.0531662' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1046, 80, 16, 1, N'1403/04/11', N'1403/06/15', 12, N'in_progress', NULL, N'semi_private', 4, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.0531662' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1047, 39, 39, 1, N'1405/10/03', N'1405/11/10', 15, N'open', NULL, N'private', 13, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.0595271' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1048, 86, 21, 5, N'1404/09/03', N'1404/12/23', 18, N'open', NULL, N'vip', 17, NULL, NULL, CAST(N'2026-07-30T04:10:01.0638447' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1049, 10, 19, 1, N'1403/01/18', N'1403/03/21', 18, N'finished', NULL, N'semi_private', 10, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.0648502' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1050, 1, 84, 1, N'1405/10/16', N'1405/12/19', 20, N'cancelled', N'لغو نمایشی', N'group', 1, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.0693814' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1051, 76, 11, 1, N'1403/09/08', N'1403/11/23', 12, N'open', NULL, N'group', 3, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.0720003' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1052, 76, 1, 5, N'1405/02/04', N'1405/03/27', 20, N'in_progress', NULL, N'vip', 17, NULL, NULL, CAST(N'2026-07-30T04:10:01.0771582' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1053, 79, 11, 3, N'1405/03/04', N'1405/05/24', 10, N'open', NULL, N'group', 13, NULL, NULL, CAST(N'2026-07-30T04:10:01.0781523' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1054, 83, 16, 3, N'1405/04/17', N'1405/05/10', 10, N'open', NULL, N'semi_private', 19, NULL, NULL, CAST(N'2026-07-30T04:10:01.0791611' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1055, 85, 16, 1, N'1403/04/10', N'1403/07/17', 15, N'cancelled', N'لغو نمایشی', N'vip', 8, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.0857986' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1056, 45, 17, 1, N'1404/05/02', N'1404/07/16', 12, N'in_progress', NULL, N'semi_private', 5, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.0871123' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1057, 67, 26, 5, N'1405/03/16', N'1405/05/19', 20, N'in_progress', NULL, N'semi_private', 16, NULL, NULL, CAST(N'2026-07-30T04:10:01.0937531' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1058, 89, 83, 3, N'1403/01/11', N'1403/02/17', 12, N'open', NULL, N'private', 8, NULL, NULL, CAST(N'2026-07-30T04:10:01.0957389' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1059, 72, 81, 4, N'1405/09/19', N'1405/10/24', 20, N'open', NULL, N'private', 3, NULL, NULL, CAST(N'2026-07-30T04:10:01.0972023' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1060, 89, 11, 2, N'1403/10/07', N'1403/11/24', 10, N'open', NULL, N'private', 17, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.0982114' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1061, 85, 9, 4, N'1405/06/12', N'1405/08/20', 20, N'in_progress', NULL, N'group', 10, NULL, NULL, CAST(N'2026-07-30T04:10:01.0992411' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1062, 67, 16, 1, N'1405/07/13', N'1405/09/15', 15, N'open', NULL, N'private', 1, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.1003000' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1063, 10, 38, 2, N'1404/06/11', N'1404/09/27', 10, N'open', NULL, N'group', 3, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.1053640' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1064, 66, 7, 2, N'1404/05/12', N'1404/07/19', 20, N'in_progress', NULL, N'vip', 7, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.1063649' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1065, 32, 26, 4, N'1404/02/17', N'1404/04/18', 8, N'cancelled', N'لغو نمایشی', N'private', 13, NULL, NULL, CAST(N'2026-07-30T04:10:01.1124560' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1066, 69, 40, 1, N'1404/09/09', N'1404/11/28', 12, N'in_progress', NULL, N'semi_private', 8, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.1138760' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1067, 46, 23, 1, N'1403/08/11', N'1403/09/22', 15, N'open', NULL, N'group', 18, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.1148874' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1068, 8, 81, 5, N'1405/04/04', N'1405/05/17', 8, N'draft', NULL, N'semi_private', 18, NULL, NULL, CAST(N'2026-07-30T04:10:01.1169628' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1069, 78, 5, 2, N'1403/06/10', N'1403/08/19', 18, N'open', NULL, N'semi_private', 18, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.1194286' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1070, 44, 5, 5, N'1403/03/09', N'1403/06/27', 8, N'in_progress', NULL, N'group', 4, NULL, NULL, CAST(N'2026-07-30T04:10:01.1204908' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1071, 70, 39, 4, N'1403/03/02', N'1403/06/24', 12, N'draft', NULL, N'vip', 4, NULL, NULL, CAST(N'2026-07-30T04:10:01.1249679' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1072, 87, 9, 2, N'1403/01/12', N'1403/04/24', 20, N'full', NULL, N'private', 8, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.1264827' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1073, 17, 82, 2, N'1405/05/07', N'1405/06/15', 20, N'finished', NULL, N'vip', 7, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.1309587' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1074, 73, 86, 3, N'1403/10/07', N'1403/11/25', 15, N'in_progress', NULL, N'vip', 3, NULL, NULL, CAST(N'2026-07-30T04:10:01.1333392' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1075, 45, 9, 5, N'1403/07/03', N'1403/10/28', 18, N'in_progress', NULL, N'semi_private', 3, NULL, NULL, CAST(N'2026-07-30T04:10:01.1357957' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1076, 68, 7, 1, N'1403/01/11', N'1403/02/14', 8, N'finished', NULL, N'semi_private', 11, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.1367959' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1077, 10, 38, 1, N'1403/09/12', N'1403/10/17', 8, N'in_progress', NULL, N'semi_private', 3, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.1387952' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1078, 83, 9, 3, N'1405/03/15', N'1405/04/14', 8, N'open', NULL, N'private', 5, NULL, NULL, CAST(N'2026-07-30T04:10:01.1401044' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1079, 38, 18, 3, N'1404/08/15', N'1404/10/22', 20, N'full', NULL, N'semi_private', 7, NULL, NULL, CAST(N'2026-07-30T04:10:01.1401044' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1080, 74, 84, 4, N'1404/10/07', N'1404/12/18', 15, N'in_progress', NULL, N'vip', 16, NULL, NULL, CAST(N'2026-07-30T04:10:01.1424408' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1081, 72, 84, 1, N'1403/09/01', N'1403/10/11', 10, N'cancelled', N'لغو نمایشی', N'group', 17, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.1434336' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1082, 77, 31, 2, N'1404/09/19', N'1404/12/21', 10, N'finished', NULL, N'vip', 18, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.1445018' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1083, 74, 81, 1, N'1404/03/18', N'1404/05/19', 12, N'in_progress', NULL, N'private', 1, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.1503301' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1084, 64, 19, 4, N'1403/01/03', N'1403/04/22', 15, N'in_progress', NULL, N'private', 18, NULL, NULL, CAST(N'2026-07-30T04:10:01.1513302' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1085, 53, 16, 4, N'1404/01/12', N'1404/04/10', 18, N'cancelled', N'لغو نمایشی', N'vip', 5, NULL, NULL, CAST(N'2026-07-30T04:10:01.1562689' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1086, 8, 27, 5, N'1405/02/08', N'1405/03/23', 12, N'draft', NULL, N'vip', 8, NULL, NULL, CAST(N'2026-07-30T04:10:01.1572685' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1087, 32, 7, 2, N'1403/05/19', N'1403/07/10', 15, N'open', NULL, N'vip', 3, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.1592693' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1088, 72, 80, 1, N'1403/01/11', N'1403/02/23', 10, N'finished', NULL, N'private', 11, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.1602708' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1089, 65, 82, 4, N'1405/09/19', N'1405/10/17', 15, N'open', NULL, N'semi_private', 19, NULL, NULL, CAST(N'2026-07-30T04:10:01.1621590' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1090, 8, 26, 2, N'1404/06/04', N'1404/08/15', 8, N'open', NULL, N'group', 10, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.1621590' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1091, 67, 23, 4, N'1404/04/03', N'1404/06/16', 12, N'in_progress', NULL, N'private', 13, NULL, NULL, CAST(N'2026-07-30T04:10:01.1647764' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1092, 67, 8, 1, N'1403/02/02', N'1403/05/15', 18, N'in_progress', NULL, N'semi_private', 10, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.1663070' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1093, 9, 27, 1, N'1405/06/17', N'1405/08/18', 15, N'finished', NULL, N'group', 17, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.1711242' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1094, 77, 7, 4, N'1404/04/11', N'1404/06/15', 12, N'cancelled', N'لغو نمایشی', N'private', 19, NULL, NULL, CAST(N'2026-07-30T04:10:01.1731244' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1095, 68, 81, 1, N'1405/09/05', N'1405/12/16', 10, N'open', NULL, N'group', 8, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.1750649' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1096, 74, 21, 5, N'1405/06/04', N'1405/08/27', 20, N'full', NULL, N'semi_private', 10, NULL, NULL, CAST(N'2026-07-30T04:10:01.1761699' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1097, 68, 84, 5, N'1405/08/18', N'1405/09/27', 20, N'full', NULL, N'semi_private', 8, NULL, NULL, CAST(N'2026-07-30T04:10:01.1776224' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1098, 71, 17, 2, N'1403/07/16', N'1403/09/20', 12, N'open', NULL, N'vip', 4, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.1791160' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1099, 79, 85, 1, N'1405/10/06', N'1405/12/23', 10, N'in_progress', NULL, N'group', 13, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.1831304' AS DateTime2))
GO
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1100, 79, 19, 4, N'1404/03/09', N'1404/06/20', 18, N'finished', NULL, N'group', 10, NULL, NULL, CAST(N'2026-07-30T04:10:01.1876437' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1101, 12, 21, 1, N'1405/09/03', N'1405/10/20', 8, N'open', NULL, N'group', 10, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.1889973' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1102, 79, 1, 4, N'1404/07/16', N'1404/08/25', 8, N'full', NULL, N'semi_private', 18, NULL, NULL, CAST(N'2026-07-30T04:10:01.1910585' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1103, 75, 39, 3, N'1404/01/09', N'1404/02/17', 10, N'open', NULL, N'private', 3, NULL, NULL, CAST(N'2026-07-30T04:10:01.1924122' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1104, 70, 85, 4, N'1404/05/18', N'1404/08/23', 10, N'finished', NULL, N'private', 4, NULL, NULL, CAST(N'2026-07-30T04:10:01.1971157' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1105, 77, 39, 4, N'1405/06/06', N'1405/07/28', 8, N'cancelled', N'لغو نمایشی', N'semi_private', 17, NULL, NULL, CAST(N'2026-07-30T04:10:01.1982716' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1106, 33, 26, 2, N'1403/05/06', N'1403/06/10', 8, N'open', NULL, N'group', 10, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.1982716' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1107, 8, 18, 3, N'1403/04/19', N'1403/07/23', 12, N'in_progress', NULL, N'private', 11, NULL, NULL, CAST(N'2026-07-30T04:10:01.1982716' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1108, 86, 16, 2, N'1405/05/10', N'1405/06/11', 18, N'open', NULL, N'vip', 7, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.1982716' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1109, 87, 1, 3, N'1405/03/11', N'1405/06/21', 18, N'cancelled', N'لغو نمایشی', N'group', 8, NULL, NULL, CAST(N'2026-07-30T04:10:01.2048331' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1110, 17, 17, 2, N'1405/05/06', N'1405/06/15', 10, N'open', NULL, N'semi_private', 1, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.2068368' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1111, 37, 11, 5, N'1403/10/15', N'1403/11/14', 20, N'open', NULL, N'private', 18, NULL, NULL, CAST(N'2026-07-30T04:10:01.2093142' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1112, 12, 18, 2, N'1404/07/15', N'1404/09/19', 18, N'draft', NULL, N'group', 4, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.2111044' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1113, 33, 83, 5, N'1404/02/07', N'1404/03/14', 10, N'in_progress', NULL, N'semi_private', 4, NULL, NULL, CAST(N'2026-07-30T04:10:01.2111044' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1114, 83, 19, 5, N'1403/09/12', N'1403/10/18', 12, N'in_progress', NULL, N'vip', 3, NULL, NULL, CAST(N'2026-07-30T04:10:01.2170137' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1115, 46, 7, 5, N'1405/09/20', N'1405/11/21', 8, N'in_progress', NULL, N'semi_private', 4, NULL, NULL, CAST(N'2026-07-30T04:10:01.2170137' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1116, 9, 84, 5, N'1403/05/05', N'1403/06/20', 15, N'full', NULL, N'vip', 16, NULL, NULL, CAST(N'2026-07-30T04:10:01.2170137' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1117, 66, 84, 1, N'1404/10/03', N'1404/12/19', 20, N'open', NULL, N'vip', 3, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.2248369' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1118, 83, 17, 3, N'1404/05/04', N'1404/06/21', 18, N'finished', NULL, N'semi_private', 17, NULL, NULL, CAST(N'2026-07-30T04:10:01.2248369' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1119, 11, 84, 1, N'1404/09/17', N'1404/11/20', 8, N'finished', NULL, N'vip', 11, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.2311192' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1120, 65, 11, 2, N'1405/02/20', N'1405/05/15', 8, N'finished', NULL, N'vip', 10, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.2311192' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1121, 86, 8, 3, N'1405/10/04', N'1405/12/10', 8, N'open', NULL, N'group', 7, NULL, NULL, CAST(N'2026-07-30T04:10:01.2311192' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1122, 83, 16, 5, N'1403/03/11', N'1403/04/18', 12, N'cancelled', N'لغو نمایشی', N'group', 11, NULL, NULL, CAST(N'2026-07-30T04:10:01.2311192' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1123, 82, 16, 2, N'1404/06/02', N'1404/09/11', 12, N'open', NULL, N'vip', 18, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.2378365' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1124, 39, 13, 5, N'1404/03/15', N'1404/05/23', 10, N'finished', NULL, N'vip', 4, NULL, NULL, CAST(N'2026-07-30T04:10:01.2378365' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1125, 64, 1, 4, N'1404/07/01', N'1404/09/21', 10, N'open', NULL, N'group', 1, NULL, NULL, CAST(N'2026-07-30T04:10:01.2378365' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1126, 43, 17, 4, N'1405/10/06', N'1405/11/27', 15, N'in_progress', NULL, N'vip', 7, NULL, NULL, CAST(N'2026-07-30T04:10:01.2378365' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1127, 78, 1, 3, N'1403/09/15', N'1403/12/25', 15, N'cancelled', N'لغو نمایشی', N'semi_private', 3, NULL, NULL, CAST(N'2026-07-30T04:10:01.2447558' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1128, 44, 26, 1, N'1404/02/17', N'1404/04/15', 20, N'in_progress', NULL, N'semi_private', 11, N'کلاس نمایشی طبقه ۲', NULL, CAST(N'2026-07-30T04:10:01.2464221' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1129, 82, 85, 5, N'1404/09/19', N'1404/11/16', 12, N'open', NULL, N'semi_private', 16, NULL, NULL, CAST(N'2026-07-30T04:10:01.2464221' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1130, 83, 27, 5, N'1405/05/14', N'1405/06/24', 15, N'finished', NULL, N'semi_private', 16, NULL, NULL, CAST(N'2026-07-30T04:10:01.2486269' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1131, 45, 9, 2, N'1405/09/18', N'1405/12/18', 20, N'open', NULL, N'private', 5, NULL, N'https://meet.demo.lims/class', CAST(N'2026-07-30T04:10:01.2505345' AS DateTime2))
INSERT [dbo].[Class] ([Id], [CourseRef], [TeacherRef], [SessionTypeRef], [StartDate], [EndDate], [Capacity], [Status], [CancelReason], [ClassType], [BranchRef], [LocationAddress], [MeetingLink], [CreatedAt]) VALUES (1132, 72, 19, 4, N'1403/02/03', N'1403/05/20', 15, N'in_progress', NULL, N'group', 18, NULL, NULL, CAST(N'2026-07-30T04:10:01.2519860' AS DateTime2))
SET IDENTITY_INSERT [dbo].[Class] OFF
SET IDENTITY_INSERT [dbo].[Teacher] ON 

INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (1, N'سجاد', N'رفاقت', N'اکبر', N'1377392759', 2, N'1359/09/16', N'Sadjad-PC\Sadjad', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (5, N'امید', N'رهبری', NULL, N'4395680186', 2, N'1375/01/19', N'saba', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (7, N'الیار', N'نورنواز', N'رضا', N'9958105977', 2, N'1368/11/25', N'elyar', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (8, N'اسما', N'نوری', N'احد', N'3200110015', 1, N'1358/02/16', N'elyar', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (9, N'زهرا', N'حبیبی', NULL, N'5254754109', 1, N'1379/12/22', N'saba', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (11, N'سبا', N'دلجوان', NULL, N'9072608895', 1, N'1383/01/31', N'saba', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (13, N'حامد', N'صمدی', N'محمد', N'7696488724', 2, N'1370/11/30', N'vahideh', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (16, N'سارا', N'رحیمی', N'اشکان', N'1364932032', 1, N'1368/06/26', N'asra', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (17, N'الیار', N'نورنواز', N'رضا', N'4321000106', 2, N'1350/12/20', N'elyar', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (18, N'اسما', N'نوری', N'احد', N'6702220847', 1, N'1369/07/15', N'elyar', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (19, N'احمد', N'اصغری', N'علی', N'6100001111', 2, N'1369/08/26', N'elyar', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (21, N'فاطمه', N'سیفی', N'حمید', N'1083143786', 1, N'1367/10/28', N'vahideh', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (23, N'مینا', N'محبی', N'رسول', N'8920522693', 1, N'1359/10/15', N'vahideh', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (24, N'علی', N'اکبری', N'امیر', N'3901081828', 2, N'1372/02/02', N'saba', NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (26, N'مهدی', N'امامی', N'محمد', N'1365207447', 1, N'1378/10/12', N'arshya', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (27, N'صابر', N'معصومی', N'صمد', N'4952913961', 2, N'1383/08/18', N'vahideh', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (28, N'محمد', N'قاسمی', N'میثم', N'8506687640', 2, N'1368/03/25', N'saba', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (31, N'سعید', N'علیون', N'رضا', N'1365091600', 2, N'1360/11/15', N'amirreza', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (38, N'اصغر', N'نوریان', N'رضا', N'1111010013', 2, N'1381/10/15', N'elyar', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (39, N'اسما', N'نوری', N'احد', N'7181590073', 1, N'1382/06/20', N'elyar', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (40, N'احمد', N'اصغری', N'علی', N'3741944270', 2, N'1377/02/15', N'elyar', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (41, N'رها', N'احمدی', N'اصغر', N'4110100100', 1, N'1380/01/15', N'elyar', NULL, NULL, NULL, NULL, 0, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (42, N'هلیا', N'حیدری', N'علی', N'5456769123', 2, N'1381/06/26', N'saba', NULL, NULL, NULL, NULL, 1, CAST(N'2026-07-29T14:01:12.8438717' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (74, N'???', N'????', NULL, N'0012345679', 2, N'1370/01/01', N'limdbadmin', N'09121234567', NULL, N'???????', NULL, 0, CAST(N'2026-07-29T15:15:04.1068078' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (79, N'Nima', N'Karimi', NULL, N'0200000004', 2, N'1368/02/15', N'limdbadmin', N'09123334455', NULL, N'IELTS', NULL, 0, CAST(N'2026-07-29T15:20:11.2129470' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (80, N'الیار', N'نورنواز', N'احمد', N'1365790622', 2, NULL, N'limdbadmin', N'09148054765', NULL, N'آلمانی', NULL, 1, CAST(N'2026-07-29T15:23:14.8685616' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (81, N'سینا', N'مرجانی', NULL, N'7104273255', 2, NULL, N'limdbadmin', N'09145852014', NULL, N'مغز اعصاب', N'یکی از بهترین جراه های دنیا', 1, CAST(N'2026-07-29T15:31:26.0214041' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (82, N'امیر', N'کاظم لو', N'علی', N'3508824799', 2, N'1410/01/02', N'limdbadmin', N'09143512272', NULL, N'انگلیسی', NULL, 1, CAST(N'2026-07-29T15:35:07.0255241' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (83, N'الیار', N'نورنواز', NULL, N'5243680966', 2, NULL, N'limdbadmin', N'09148257645555', NULL, N'انگلیسی', NULL, 1, CAST(N'2026-07-29T15:39:59.2712215' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (84, N'تست', N'تست', NULL, N'7265503996', 2, N'1405/05/06', N'limdbadmin', N'09146661552', NULL, N'تست', NULL, 1, CAST(N'2026-07-29T15:58:20.6624061' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (85, N'ش', N'ش', N'ش', N'4019852480', 2, N'1405/05/07', N'limdbadmin', N'0101010101011', NULL, N'ش', N'ش', 1, CAST(N'2026-07-29T16:00:13.9174772' AS DateTime2), NULL, NULL)
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator], [Mobile], [Email], [Specialty], [Bio], [IsActive], [CreatedAt], [Photo], [PhotoMime]) VALUES (86, N'÷', N'÷', N'÷', N'5315369935', 2, N'1405/05/07', N'limdbadmin', N'103210210210210210', N'101010002145214521', N'14254254125412541', N'1111111111111111', 1, CAST(N'2026-07-29T16:02:32.0682507' AS DateTime2), NULL, NULL)
SET IDENTITY_INSERT [dbo].[Teacher] OFF
SET IDENTITY_INSERT [dbo].[SessionStudent] ON 

INSERT [dbo].[SessionStudent] ([Id], [SessionRef], [StudentRef], [AttendanceStatus], [RecordedAt]) VALUES (1, 1, 1, N'present', CAST(N'2026-07-29T14:01:12.8035290' AS DateTime2))
INSERT [dbo].[SessionStudent] ([Id], [SessionRef], [StudentRef], [AttendanceStatus], [RecordedAt]) VALUES (2, 1, 2, N'present', CAST(N'2026-07-29T14:01:12.8035290' AS DateTime2))
INSERT [dbo].[SessionStudent] ([Id], [SessionRef], [StudentRef], [AttendanceStatus], [RecordedAt]) VALUES (3, 1, 3, N'present', CAST(N'2026-07-29T14:01:12.8035290' AS DateTime2))
INSERT [dbo].[SessionStudent] ([Id], [SessionRef], [StudentRef], [AttendanceStatus], [RecordedAt]) VALUES (4, 1, 4, N'present', CAST(N'2026-07-29T14:01:12.8035290' AS DateTime2))
INSERT [dbo].[SessionStudent] ([Id], [SessionRef], [StudentRef], [AttendanceStatus], [RecordedAt]) VALUES (6, 1, 6, N'present', CAST(N'2026-07-29T14:01:12.8035290' AS DateTime2))
INSERT [dbo].[SessionStudent] ([Id], [SessionRef], [StudentRef], [AttendanceStatus], [RecordedAt]) VALUES (7, 2, 1, N'present', CAST(N'2026-07-29T14:01:12.8035290' AS DateTime2))
INSERT [dbo].[SessionStudent] ([Id], [SessionRef], [StudentRef], [AttendanceStatus], [RecordedAt]) VALUES (8, 2, 2, N'present', CAST(N'2026-07-29T14:01:12.8035290' AS DateTime2))
INSERT [dbo].[SessionStudent] ([Id], [SessionRef], [StudentRef], [AttendanceStatus], [RecordedAt]) VALUES (9, 2, 4, N'present', CAST(N'2026-07-29T14:01:12.8035290' AS DateTime2))
INSERT [dbo].[SessionStudent] ([Id], [SessionRef], [StudentRef], [AttendanceStatus], [RecordedAt]) VALUES (10, 2, 6, N'present', CAST(N'2026-07-29T14:01:12.8035290' AS DateTime2))
INSERT [dbo].[SessionStudent] ([Id], [SessionRef], [StudentRef], [AttendanceStatus], [RecordedAt]) VALUES (11, 3, 1, N'present', CAST(N'2026-07-29T14:01:12.8035290' AS DateTime2))
INSERT [dbo].[SessionStudent] ([Id], [SessionRef], [StudentRef], [AttendanceStatus], [RecordedAt]) VALUES (12, 3, 2, N'present', CAST(N'2026-07-29T14:01:12.8035290' AS DateTime2))
INSERT [dbo].[SessionStudent] ([Id], [SessionRef], [StudentRef], [AttendanceStatus], [RecordedAt]) VALUES (13, 3, 10, N'present', CAST(N'2026-07-29T14:01:12.8035290' AS DateTime2))
INSERT [dbo].[SessionStudent] ([Id], [SessionRef], [StudentRef], [AttendanceStatus], [RecordedAt]) VALUES (1002, 1002, 2, N'present', CAST(N'2026-07-29T14:07:44.8368601' AS DateTime2))
SET IDENTITY_INSERT [dbo].[SessionStudent] OFF
SET IDENTITY_INSERT [dbo].[Registration] ON 

INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1, 1, 1, N'1405/04/31', NULL, N'active', NULL, N'debtor', CAST(N'2026-07-29T14:01:12.8969233' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (2, 2, 1, N'1405/04/30', NULL, N'active', NULL, N'debtor', CAST(N'2026-07-29T14:01:12.8969233' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1002, 2, 51, N'1405/07/01', 1004, N'active', NULL, N'settled', CAST(N'2026-07-29T14:07:44.8055378' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1003, 69, 45, N'1405/05/07', 1006, N'completed', NULL, N'settled', CAST(N'2026-07-29T15:22:18.5475523' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1004, 1227, 51, N'1405/05/07', 1004, N'active', NULL, N'settled', CAST(N'2026-07-29T15:23:42.7085643' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1005, 1214, 51, N'1405/05/07', 1004, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-29T15:27:32.0541822' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1006, 7, 1, N'1405/05/07', 6, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-29T15:30:19.4508488' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1007, 69, 46, N'1405/05/07', 1009, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-29T15:40:38.5432623' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1008, 99, 54, N'1405/05/06', 1011, N'frozen', NULL, N'settled', CAST(N'2026-07-29T15:45:22.9998882' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1009, 1232, 54, N'1405/05/07', 1011, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-29T15:51:41.3032514' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1010, 1233, 61, N'1405/05/07', 1012, N'completed', NULL, N'debtor', CAST(N'2026-07-29T15:55:34.3569145' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1011, 1234, 51, N'1405/05/07', 1004, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-29T16:00:39.2982009' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1012, 46, 66, N'1405/04/03', 1064, N'frozen', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.4984725' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1013, 176, 77, N'1405/05/05', 1082, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5018395' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1014, 84, 79, N'1405/06/01', 1102, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5018395' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1015, 63, 65, N'1405/02/18', 1120, N'transferred', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5089525' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1016, 1214, 79, N'1405/05/01', 1102, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.5158722' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1017, 70, 86, N'1405/01/05', 1121, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5158722' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1018, 98, 75, N'1405/06/12', 1103, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5226655' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1019, 188, 79, N'1405/05/17', 1099, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5254044' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1020, 26, 78, N'1405/03/26', 1069, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5299501' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1021, 59, 74, N'1405/07/17', 1096, N'transferred', NULL, N'settled', CAST(N'2026-07-30T04:10:01.5369312' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1022, 27, 75, N'1405/03/12', 1025, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5369312' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1023, 76, 68, N'1405/06/02', 1095, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5369312' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1024, 144, 53, N'1405/03/22', 1085, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.5440820' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1025, 81, 72, N'1405/07/22', 1088, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5440820' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1026, 132, 49, N'1405/05/10', 1008, N'pending_approval', NULL, N'settled', CAST(N'2026-07-30T04:10:01.5505219' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1027, 122, 64, N'1405/05/14', 1084, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5505219' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1028, 128, 53, N'1405/06/15', 1085, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.5505219' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1029, 86, 75, N'1405/01/07', 1037, N'withdrawn', N'انصراف نمایشی', N'settled', CAST(N'2026-07-30T04:10:01.5505219' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1030, 84, 87, N'1405/02/16', 1035, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5573395' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1031, 2, 18, N'1405/03/23', 1024, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.5589514' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1032, 1235, 65, N'1405/07/19', 1039, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5589514' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1033, 161, 38, N'1405/05/21', 1026, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5589514' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1034, 74, 45, N'1405/02/03', 1075, N'pending_approval', NULL, N'settled', CAST(N'2026-07-30T04:10:01.5642653' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1035, 145, 75, N'1405/01/16', 1025, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.5642653' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1036, 149, 45, N'1405/05/24', 1056, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5642653' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1037, 59, 65, N'1405/06/13', 1120, N'frozen', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5642653' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1038, 149, 64, N'1405/01/01', 1125, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.5709576' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1039, 156, 38, N'1405/02/19', 1079, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.5713221' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1040, 113, 43, N'1405/04/21', 1126, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5713221' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1041, 72, 8, N'1405/04/07', 1107, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5782743' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1042, 65, 64, N'1405/03/27', 1084, N'transferred', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5782743' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1043, 83, 77, N'1405/01/13', 1105, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.5816818' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1044, 4, 69, N'1405/04/13', 1027, N'frozen', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5816818' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1045, 123, 33, N'1405/03/24', 1113, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5850466' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1046, 127, 82, N'1405/01/05', 1129, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5850466' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1047, 1226, 67, N'1405/04/01', 1092, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.5850466' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1048, 24, 38, N'1405/04/10', 1014, N'pending_approval', NULL, N'settled', CAST(N'2026-07-30T04:10:01.5850466' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1049, 138, 8, N'1405/06/09', 1034, N'withdrawn', N'انصراف نمایشی', N'settled', CAST(N'2026-07-30T04:10:01.5850466' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1050, 87, 10, N'1405/04/04', 1077, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5850466' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1051, 149, 10, N'1405/01/12', 1077, N'frozen', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5920039' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1052, 1232, 45, N'1405/04/09', 1010, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5984478' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1053, 147, 12, N'1405/03/10', 1101, N'transferred', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5987735' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1054, 1213, 39, N'1405/01/11', 1013, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.5987735' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1055, 134, 45, N'1405/03/06', 1010, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5987735' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1056, 67, 66, N'1405/01/13', 1117, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.5987735' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1057, 101, 78, N'1405/03/22', 1069, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.6058736' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1058, 134, 10, N'1405/05/12', 1063, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.6058736' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1059, 22, 45, N'1405/06/26', 1056, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6058736' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1060, 25, 46, N'1405/04/17', 1009, N'pending_approval', NULL, N'settled', CAST(N'2026-07-30T04:10:01.6058736' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1061, 72, 72, N'1405/02/23', 1029, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6128611' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1062, 72, 18, N'1405/03/17', 1024, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.6128611' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1063, 25, 8, N'1405/03/13', 1107, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6128611' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1064, 2, 10, N'1405/06/09', 1077, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6128611' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1065, 4, 83, N'1405/02/09', 1078, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.6128611' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1066, 163, 79, N'1405/05/15', 1100, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6196611' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1067, 60, 33, N'1405/06/22', 1106, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6196611' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1068, 89, 65, N'1405/05/21', 1120, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6196611' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1069, 143, 75, N'1405/04/21', 1103, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6196611' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1070, 2, 46, N'1405/06/23', 1067, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6263795' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1071, 148, 8, N'1405/01/05', 1086, N'completed', NULL, N'settled', CAST(N'2026-07-30T04:10:01.6268216' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1072, 22, 64, N'1405/07/27', 1084, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.6268216' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1073, 145, 32, N'1405/02/04', 1087, N'transferred', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6304837' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1074, 66, 76, N'1405/05/02', 1052, N'transferred', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6334059' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1075, 23, 46, N'1405/05/08', 1115, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6344685' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1076, 73, 11, N'1405/01/07', 1038, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6344685' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1077, 155, 46, N'1405/03/22', 1067, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6344685' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1078, 1241, 45, N'1405/01/26', 1131, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6344685' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1079, 23, 82, N'1405/02/21', 1129, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.6401910' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1080, 155, 89, N'1405/01/02', 1058, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6404923' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1081, 1212, 75, N'1405/04/20', 1025, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.6404923' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1082, 12, 79, N'1405/02/16', 1053, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6433360' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1083, 80, 18, N'1405/03/03', 1024, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.6433360' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1084, 145, 78, N'1405/05/19', 1127, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6433360' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1085, 44, 72, N'1405/04/07', 1059, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6471745' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1086, 89, 66, N'1405/04/09', 1064, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6471745' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1087, 114, 71, N'1405/01/12', 1022, N'frozen', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6471745' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1088, 150, 79, N'1405/06/07', 1045, N'transferred', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6471745' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1089, 1, 44, N'1405/05/22', 1070, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.6541551' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1090, 64, 77, N'1405/05/12', 1105, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6561555' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1091, 149, 68, N'1405/01/24', 1076, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6581788' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1092, 144, 9, N'1405/05/25', 1005, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6615027' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1093, 1227, 82, N'1405/01/03', 1016, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.6615027' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1094, 96, 82, N'1405/02/07', 1123, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.6631988' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1095, 1237, 77, N'1405/06/14', 1094, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6631988' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1096, 97, 61, N'1405/03/24', 1012, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6631988' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1097, 173, 8, N'1405/07/23', 1107, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6682735' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1098, 126, 8, N'1405/06/12', 1028, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6682735' AS DateTime2))
GO
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1099, 9, 69, N'1405/07/09', 1040, N'frozen', NULL, N'settled', CAST(N'2026-07-30T04:10:01.6682735' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1100, 176, 66, N'1405/01/08', 1117, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.6682735' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1101, 63, 87, N'1405/04/12', 1072, N'frozen', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6752185' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1102, 163, 83, N'1405/05/04', 1078, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6752185' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1103, 10, 77, N'1405/01/24', 1105, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6752185' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1104, 141, 64, N'1405/02/07', 1018, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6752185' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1105, 60, 87, N'1405/05/10', 1072, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6828153' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1106, 1213, 10, N'1405/07/27', 1049, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.6828153' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1107, 1231, 78, N'1405/01/24', 1043, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6828153' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1108, 84, 11, N'1405/03/16', 1038, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6828153' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1109, 134, 75, N'1405/06/15', 1025, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6828153' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1110, 139, 1, N'1405/04/19', 2, N'withdrawn', N'انصراف نمایشی', N'settled', CAST(N'2026-07-30T04:10:01.6896925' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1111, 117, 80, N'1405/06/22', 1021, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6923250' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1112, 114, 72, N'1405/03/10', 1059, N'frozen', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6923250' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1113, 82, 38, N'1405/02/24', 1026, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.6958936' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1114, 1237, 83, N'1405/03/04', 1078, N'transferred', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6964787' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1115, 113, 11, N'1405/05/02', 1038, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6984840' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1116, 101, 43, N'1405/02/07', 1126, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.6984840' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1117, 19, 32, N'1405/01/28', 1087, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.6984840' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1118, 1232, 10, N'1405/04/10', 1077, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.6984840' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1119, 73, 12, N'1405/05/24', 1112, N'transferred', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7032939' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1120, 1228, 9, N'1405/07/05', 1019, N'transferred', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7032939' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1121, 86, 77, N'1405/03/04', 1094, N'frozen', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7032939' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1122, 83, 69, N'1405/04/07', 1066, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7032939' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1123, 4, 60, N'1405/05/16', 1031, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7100849' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1124, 147, 10, N'1405/05/16', 1063, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.7100849' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1125, 73, 82, N'1405/01/25', 1129, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7100849' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1126, 26, 61, N'1405/02/01', 1012, N'transferred', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7100849' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1127, 77, 78, N'1405/01/16', 1069, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7150604' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1128, 79, 70, N'1405/05/28', 1071, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7150604' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1129, 79, 87, N'1405/03/18', 1035, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7172756' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1130, 97, 38, N'1405/04/10', 1026, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7172756' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1131, 82, 33, N'1405/03/22', 1106, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7205339' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1132, 126, 80, N'1405/01/12', 1046, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.7205339' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1133, 125, 69, N'1405/02/21', 1066, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7239739' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1134, 127, 9, N'1405/04/03', 1116, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7250846' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1135, 188, 44, N'1405/02/28', 1128, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7250846' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1136, 140, 10, N'1405/04/26', 1063, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7250846' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1137, 79, 9, N'1405/06/26', 1093, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7305002' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1138, 1226, 12, N'1405/06/04', 1101, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.7309791' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1139, 67, 77, N'1405/04/17', 1082, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7309791' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1140, 1214, 64, N'1405/04/02', 1125, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.7332007' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1141, 79, 38, N'1405/06/13', 1014, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.7332007' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1142, 74, 38, N'1405/03/07', 1041, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7351411' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1143, 134, 9, N'1405/07/13', 1116, N'frozen', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7351411' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1144, 1232, 82, N'1405/01/09', 1123, N'transferred', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7377919' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1145, 1232, 17, N'1405/01/01', 1110, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7390518' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1146, 97, 86, N'1405/07/16', 1121, N'pending_approval', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7395571' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1147, 99, 72, N'1405/06/02', 1081, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7395571' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1148, 139, 33, N'1405/05/10', 1030, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7395571' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1149, 1238, 9, N'1405/01/26', 1116, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7451441' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1150, 1212, 11, N'1405/01/21', 1038, N'transferred', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7451441' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1151, 12, 79, N'1405/05/15', 1099, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7451441' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1152, 63, 76, N'1405/05/15', 1051, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7451441' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1153, 1239, 85, N'1405/07/14', 1055, N'completed', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7451441' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1154, 1, 37, N'1405/05/14', 1111, N'frozen', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7521078' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1155, 7, 44, N'1405/06/23', 1128, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7521078' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1156, 127, 68, N'1405/02/05', 1036, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7521078' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1157, 141, 17, N'1405/01/22', 1073, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7521078' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1158, 26, 83, N'1405/05/27', 1078, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7521078' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1159, 4, 45, N'1405/04/09', 1131, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.7582552' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1160, 113, 65, N'1405/05/09', 1039, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7587292' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1161, 164, 49, N'1405/06/24', 1008, N'transferred', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7587292' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1162, 167, 60, N'1405/03/11', 1031, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.7587292' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1163, 125, 79, N'1405/06/25', 1053, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7587292' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1164, 98, 9, N'1405/05/10', 1005, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7587292' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1165, 70, 78, N'1405/03/08', 1043, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7652071' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1166, 1226, 79, N'1405/03/12', 1053, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7657447' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1167, 9, 68, N'1405/04/21', 1097, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7657447' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1168, 173, 1, N'1405/04/11', 2, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7657447' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1169, 119, 46, N'1405/02/27', 1115, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7720732' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1170, 124, 72, N'1405/02/16', 1059, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7730063' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1171, 148, 64, N'1405/04/17', 1018, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7730063' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1172, 164, 1, N'1405/05/04', 1003, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7753498' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1173, 124, 11, N'1405/06/23', 1119, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7753498' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1174, 9, 72, N'1405/02/18', 1059, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7753498' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1175, 86, 66, N'1405/05/11', 1064, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.7753498' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1176, 133, 38, N'1405/02/07', 1041, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7798544' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1177, 1239, 68, N'1405/04/13', 1036, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7798544' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1178, 118, 79, N'1405/04/10', 1099, N'frozen', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7798544' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1179, 161, 79, N'1405/07/06', 1053, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7860437' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1180, 96, 68, N'1405/01/07', 1036, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7867285' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1181, 1229, 12, N'1405/02/25', 1112, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7890383' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1182, 84, 38, N'1405/02/04', 1026, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7890383' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1183, 136, 8, N'1405/07/03', 1068, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7890383' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1184, 121, 32, N'1405/02/14', 1087, N'pending_approval', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7890383' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1185, 1232, 12, N'1405/02/26', 1101, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7932808' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1186, 44, 45, N'1405/01/17', 1056, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7932808' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1187, 125, 10, N'1405/05/22', 1063, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7932808' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1188, 1226, 39, N'1405/01/16', 1023, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7932808' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1189, 1241, 44, N'1405/01/04', 1128, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.7987617' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1190, 6, 65, N'1405/06/11', 1039, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.7987617' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1191, 145, 1, N'1405/04/22', 6, N'completed', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8002123' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1192, 118, 69, N'1405/03/15', 1066, N'completed', NULL, N'settled', CAST(N'2026-07-30T04:10:01.8002123' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1193, 150, 1, N'1405/07/06', 1050, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8002123' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1194, 11, 73, N'1405/05/15', 1074, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8002123' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1195, 66, 45, N'1405/03/11', 1010, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.8071503' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1196, 77, 46, N'1405/04/27', 1067, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8071503' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1197, 96, 45, N'1405/02/18', 1010, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8071503' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1198, 73, 83, N'1405/06/19', 1118, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8071503' AS DateTime2))
GO
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1199, 79, 83, N'1405/07/17', 1118, N'frozen', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8138378' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1200, 80, 70, N'1405/03/08', 1104, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8142425' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1201, 1214, 66, N'1405/02/19', 1064, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8142425' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1202, 166, 10, N'1405/05/03', 1077, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8142425' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1203, 143, 45, N'1405/03/25', 1075, N'withdrawn', N'انصراف نمایشی', N'debtor', CAST(N'2026-07-30T04:10:01.8142425' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1204, 115, 69, N'1405/05/15', 1040, N'active', NULL, N'settled', CAST(N'2026-07-30T04:10:01.8210476' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1205, 133, 74, N'1405/01/17', 1080, N'frozen', NULL, N'settled', CAST(N'2026-07-30T04:10:01.8210476' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1206, 1, 39, N'1405/05/08', 1033, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8237580' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1207, 67, 44, N'1405/04/01', 1128, N'transferred', NULL, N'settled', CAST(N'2026-07-30T04:10:01.8237580' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1208, 77, 38, N'1405/07/07', 1026, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.8237580' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1209, 138, 39, N'1405/05/16', 1020, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8280032' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1210, 188, 83, N'1405/03/09', 1054, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8280032' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1211, 1236, 12, N'1405/05/08', 1101, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8280032' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1212, 27, 71, N'1405/02/05', 1022, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8280032' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1213, 13, 46, N'1405/05/03', 1115, N'transferred', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8353414' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1214, 21, 65, N'1405/05/02', 1039, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.8353414' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1215, 126, 82, N'1405/03/21', 1123, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8353414' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1216, 6, 83, N'1405/07/12', 1078, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8353414' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1217, 126, 74, N'1405/02/16', 1096, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8419850' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1218, 188, 9, N'1405/07/02', 1019, N'pending_approval', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8419850' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1219, 25, 69, N'1405/03/04', 1066, N'completed', NULL, N'settled', CAST(N'2026-07-30T04:10:01.8419850' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1220, 136, 9, N'1405/04/23', 1093, N'frozen', NULL, N'settled', CAST(N'2026-07-30T04:10:01.8419850' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1221, 83, 65, N'1405/01/21', 1039, N'pending_payment', NULL, N'settled', CAST(N'2026-07-30T04:10:01.8489401' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1222, 22, 68, N'1405/04/02', 1076, N'frozen', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8508722' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1223, 1212, 49, N'1405/01/14', 1008, N'withdrawn', N'حذف توسط کاربر', N'debtor', CAST(N'2026-07-30T04:10:01.8508722' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1224, 76, 1, N'1405/01/05', 2, N'frozen', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8508722' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1225, 118, 67, N'1405/05/25', 1091, N'pending_payment', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8555262' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1226, 82, 8, N'1405/02/08', 1068, N'transferred', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8572727' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1227, 80, 74, N'1405/06/28', 1080, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8572727' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1228, 19, 8, N'1405/01/12', 1090, N'transferred', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8572727' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1229, 150, 33, N'1405/04/15', 1030, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8572727' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1230, 166, 39, N'1405/01/10', 1033, N'completed', NULL, N'settled', CAST(N'2026-07-30T04:10:01.8627460' AS DateTime2))
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date], [ClassRef], [Status], [WithdrawReason], [FinancialStatus], [CreatedAt]) VALUES (1231, 19, 17, N'1405/03/01', 1073, N'active', NULL, N'debtor', CAST(N'2026-07-30T04:10:01.8627460' AS DateTime2))
SET IDENTITY_INSERT [dbo].[Registration] OFF
SET IDENTITY_INSERT [dbo].[Payment] ON 

INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (1, 2, N'1405/07/01', 900000, 2, N'paid', N'card', 1002, NULL, CAST(N'2026-07-29T14:07:44.8168805' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (2, 2, N'1405/06/26', 20000000, 3, N'failed', N'cash', 1070, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.8694408' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (3, 133, N'1405/02/03', 15000000, 2, N'paid', N'online', 1176, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.8763712' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (4, 1213, N'1405/07/13', 8000000, 3, N'paid', N'cash', 1054, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.8767306' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (5, 1239, N'1405/02/19', 12000000, 3, N'draft', N'card', 1153, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.8836650' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (6, 83, N'1405/06/15', 8000000, 3, N'pending', N'card', 1122, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.8836650' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (7, 125, N'1405/01/20', 8000000, 3, N'overdue', N'card', 1163, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.8836650' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (8, 141, N'1405/06/14', 12000000, 2, N'failed', N'online', 1104, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.8927273' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (9, 82, N'1405/07/24', 25000000, 3, N'paid', N'installment', 1113, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.8990289' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (10, 173, N'1405/04/04', 30000000, 2, N'draft', N'cash', 1168, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.8990289' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (11, 13, N'1405/04/27', 15000000, 2, N'pending', N'online', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9045335' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (12, 136, N'1405/07/18', 20000000, 1, N'paid', N'card', 1220, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9045335' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (13, 1239, N'1405/04/04', 5000000, 3, N'paid', N'card', 1153, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9070392' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (14, 1239, N'1405/04/06', 25000000, 1, N'pending', N'cash', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9070392' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (15, 69, N'1405/05/19', 5000000, 2, N'pending', N'card', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9070392' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (16, 77, N'1405/05/03', 8000000, 1, N'paid', N'installment', 1208, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9070392' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (17, 1232, N'1405/03/10', 8000000, 1, N'paid', N'online', 1144, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9111414' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (18, 97, N'1405/03/24', 15000000, 1, N'pending', N'card', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9115320' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (19, 25, N'1405/07/08', 8000000, 1, N'partially_paid', N'installment', 1219, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9115320' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (20, 73, N'1405/03/12', 30000000, 1, N'draft', N'card', 1198, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9115320' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (21, 63, N'1405/04/04', 15000000, 2, N'paid', N'other', 1152, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9185577' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (22, 22, N'1405/07/24', 8000000, 3, N'paid', N'other', 1059, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9185577' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (23, 4, N'1405/01/14', 12000000, 2, N'paid', N'cash', 1044, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9185577' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (24, 148, N'1405/05/13', 5000000, 2, N'draft', N'other', 1171, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9254935' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (25, 124, N'1405/07/20', 8000000, 1, N'overdue', N'online', 1173, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9254935' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (26, 123, N'1405/07/19', 12000000, 1, N'paid', N'other', 1045, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9254935' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (27, 155, N'1405/03/02', 20000000, 2, N'paid', N'online', 1080, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9254935' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (28, 120, N'1405/02/12', 20000000, 3, N'draft', N'online', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9323170' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (29, 79, N'1405/04/20', 25000000, 1, N'overdue', N'cash', 1141, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9323170' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (30, 96, N'1405/04/20', 10000000, 2, N'paid', N'installment', 1180, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9323170' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (31, 1234, N'1405/04/04', 12000000, 2, N'refunded', N'installment', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9388356' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (32, 9, N'1405/03/15', 20000000, 1, N'pending', N'cash', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9406252' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (33, 65, N'1405/05/25', 12000000, 1, N'paid', N'online', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9406252' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (34, 65, N'1405/05/17', 30000000, 1, N'paid', N'cash', 1042, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9426331' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (35, 126, N'1405/03/23', 10000000, 2, N'failed', N'online', 1217, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9426331' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (36, 4, N'1405/04/05', 25000000, 3, N'paid', N'card', 1065, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9426331' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (37, 87, N'1405/05/04', 30000000, 2, N'overdue', N'other', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9462748' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (38, 95, N'1405/05/08', 10000000, 1, N'draft', N'online', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9462748' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (39, 1238, N'1405/04/23', 8000000, 2, N'pending', N'other', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9527462' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (40, 45, N'1405/05/18', 15000000, 2, N'paid', N'cash', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9531634' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (41, 11, N'1405/07/13', 10000000, 1, N'paid', N'card', 1194, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9531634' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (42, 140, N'1405/02/09', 15000000, 1, N'paid', N'cash', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9531634' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (43, 97, N'1405/03/02', 20000000, 1, N'paid', N'installment', 1096, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9531634' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (44, 140, N'1405/05/05', 10000000, 1, N'pending', N'other', 1136, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9531634' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (45, 73, N'1405/04/27', 8000000, 1, N'paid', N'cash', 1119, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9531634' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (46, 66, N'1405/03/13', 12000000, 2, N'paid', N'installment', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9595976' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (47, 147, N'1405/04/18', 15000000, 3, N'draft', N'other', 1124, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9595976' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (48, 1239, N'1405/04/08', 25000000, 3, N'refunded', N'cash', 1177, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9595976' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (49, 1213, N'1405/07/11', 8000000, 2, N'paid', N'installment', 1054, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9668759' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (50, 2, N'1405/05/08', 10000000, 2, N'partially_paid', N'installment', 1031, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9668759' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (51, 12, N'1405/04/03', 15000000, 3, N'partially_paid', N'other', 1151, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9687447' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (52, 122, N'1405/02/21', 25000000, 3, N'pending', N'cash', 1027, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9687447' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (53, 19, N'1405/06/08', 10000000, 3, N'draft', N'installment', 1117, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9739041' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (54, 59, N'1405/05/25', 30000000, 3, N'failed', N'installment', 1021, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9788103' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (55, 161, N'1405/05/26', 25000000, 1, N'paid', N'cash', 1033, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9808987' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (56, 113, N'1405/02/27', 30000000, 2, N'paid', N'card', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9808987' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (57, 1236, N'1405/04/19', 15000000, 2, N'failed', N'other', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9874461' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (58, 23, N'1405/01/21', 5000000, 2, N'partially_paid', N'other', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9879080' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (59, 1229, N'1405/05/12', 25000000, 1, N'partially_paid', N'cash', 1181, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9879080' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (60, 124, N'1405/07/07', 5000000, 2, N'overdue', N'cash', 1173, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9879080' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (61, 118, N'1405/06/01', 25000000, 1, N'failed', N'card', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9947627' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (62, 161, N'1405/01/26', 12000000, 1, N'paid', N'online', 1033, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9947627' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (63, 1241, N'1405/01/19', 25000000, 1, N'paid', N'card', 1189, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9947627' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (64, 123, N'1405/01/20', 8000000, 3, N'failed', N'other', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:01.9947627' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (65, 79, N'1405/03/12', 5000000, 1, N'refunded', N'other', 1199, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0019822' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (66, 1236, N'1405/05/16', 25000000, 1, N'overdue', N'cash', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0032815' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (67, 64, N'1405/03/01', 25000000, 1, N'overdue', N'online', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0032815' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (68, 27, N'1405/05/06', 8000000, 3, N'paid', N'installment', 1022, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0032815' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (69, 164, N'1405/07/01', 15000000, 2, N'failed', N'other', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0032815' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (70, 67, N'1405/07/24', 12000000, 3, N'pending', N'card', 1056, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0090385' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (71, 76, N'1405/07/14', 30000000, 3, N'paid', N'installment', 1023, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0090385' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (72, 1236, N'1405/02/07', 8000000, 2, N'paid', N'installment', 1211, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0090385' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (73, 23, N'1405/04/22', 30000000, 2, N'failed', N'card', 1079, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0090385' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (74, 1228, N'1405/02/19', 15000000, 1, N'paid', N'online', 1120, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0090385' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (75, 70, N'1405/03/19', 12000000, 1, N'refunded', N'online', 1165, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0151490' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (76, 1232, N'1405/03/15', 10000000, 3, N'overdue', N'installment', 1052, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0155562' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (77, 96, N'1405/02/04', 30000000, 2, N'partially_paid', N'online', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0233550' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (78, 118, N'1405/02/24', 12000000, 3, N'partially_paid', N'online', 1192, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0240508' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (79, 72, N'1405/02/04', 30000000, 1, N'partially_paid', N'cash', 1061, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0240508' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (80, 149, N'1405/01/15', 12000000, 2, N'paid', N'online', 1091, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0240508' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (81, 138, N'1405/04/21', 12000000, 1, N'paid', N'card', 1049, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0260570' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (82, 27, N'1405/05/13', 30000000, 1, N'partially_paid', N'online', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0260570' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (83, 64, N'1405/07/25', 5000000, 3, N'paid', N'card', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0291352' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (84, 77, N'1405/06/16', 10000000, 2, N'partially_paid', N'cash', 1208, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0296261' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (85, 96, N'1405/01/27', 10000000, 3, N'overdue', N'installment', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0296261' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (86, 188, N'1405/03/08', 15000000, 3, N'failed', N'cash', 1019, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0296261' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (87, 27, N'1405/07/14', 30000000, 1, N'paid', N'installment', 1022, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0296261' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (88, 11, N'1405/06/02', 30000000, 2, N'refunded', N'online', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0363509' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (89, 176, N'1405/03/02', 20000000, 3, N'paid', N'cash', 1100, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0363509' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (90, 139, N'1405/03/03', 8000000, 3, N'pending', N'cash', 1110, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0363509' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (91, 73, N'1405/07/12', 10000000, 3, N'paid', N'installment', 1198, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0363509' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (92, 150, N'1405/04/13', 5000000, 2, N'failed', N'other', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0363509' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (93, 64, N'1405/05/13', 10000000, 3, N'overdue', N'installment', 1090, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0363509' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (94, 131, N'1405/02/03', 30000000, 1, N'failed', N'other', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0430441' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (95, 27, N'1405/06/03', 30000000, 1, N'paid', N'card', 1212, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0433818' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (96, 83, N'1405/07/09', 20000000, 1, N'overdue', N'cash', 1043, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0433818' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (97, 79, N'1405/05/05', 25000000, 2, N'paid', N'online', 1129, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0433818' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (98, 4, N'1405/05/06', 15000000, 3, N'partially_paid', N'installment', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0433818' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (99, 21, N'1405/02/07', 25000000, 2, N'failed', N'installment', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0433818' AS DateTime2))
GO
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (100, 167, N'1405/05/18', 15000000, 3, N'draft', N'installment', 1162, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0433818' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (101, 1232, N'1405/05/13', 25000000, 2, N'pending', N'card', 1052, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0502761' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (102, 166, N'1405/02/26', 25000000, 3, N'draft', N'online', 1230, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0502761' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (103, 86, N'1405/07/01', 12000000, 3, N'refunded', N'online', 1175, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0502761' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (104, 23, N'1405/01/08', 10000000, 3, N'paid', N'installment', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0502761' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (105, 46, N'1405/03/23', 20000000, 1, N'partially_paid', N'card', 1012, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0502761' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (106, 50, N'1405/06/09', 5000000, 3, N'pending', N'card', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0502761' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (107, 156, N'1405/07/07', 15000000, 3, N'paid', N'cash', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0502761' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (108, 74, N'1405/02/08', 15000000, 3, N'overdue', N'other', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0572354' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (109, 83, N'1405/02/02', 8000000, 3, N'paid', N'other', 1221, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0572354' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (110, 125, N'1405/03/06', 5000000, 1, N'failed', N'cash', 1187, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0572354' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (111, 1229, N'1405/07/23', 30000000, 1, N'overdue', N'card', 1181, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0572354' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (112, 27, N'1405/05/06', 20000000, 1, N'pending', N'installment', 1212, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0572354' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (113, 10, N'1405/01/10', 25000000, 2, N'paid', N'cash', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0572354' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (114, 77, N'1405/04/12', 12000000, 1, N'overdue', N'card', 1127, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0572354' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (115, 4, N'1405/02/08', 12000000, 2, N'pending', N'other', 1065, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0637433' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (116, 1213, N'1405/02/22', 30000000, 3, N'paid', N'installment', 1106, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0640581' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (117, 155, N'1405/02/08', 10000000, 3, N'pending', N'card', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0655102' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (118, 148, N'1405/03/25', 12000000, 2, N'refunded', N'card', 1171, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0660136' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (119, 80, N'1405/04/11', 5000000, 3, N'paid', N'cash', 1227, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0660136' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (120, 1235, N'1405/04/24', 25000000, 3, N'draft', N'installment', 1032, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0660136' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (121, 4, N'1405/06/07', 20000000, 1, N'paid', N'other', 1159, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0660136' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (122, 22, N'1405/07/20', 30000000, 3, N'partially_paid', N'other', 1222, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0660136' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (123, 1241, N'1405/07/01', 12000000, 1, N'paid', N'card', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0708061' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (124, 176, N'1405/07/24', 25000000, 3, N'paid', N'cash', 1100, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0711910' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (125, 63, N'1405/03/19', 15000000, 2, N'refunded', N'installment', 1101, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0711910' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (126, 1228, N'1405/04/19', 30000000, 3, N'pending', N'card', 1120, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0711910' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (127, 150, N'1405/03/12', 5000000, 3, N'draft', N'other', 1088, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0711910' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (128, 77, N'1405/06/05', 5000000, 2, N'paid', N'other', 1196, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0711910' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (129, 12, N'1405/03/02', 10000000, 1, N'failed', N'installment', 1151, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0711910' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (130, 4, N'1405/02/20', 30000000, 1, N'pending', N'online', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0711910' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (131, 123, N'1405/01/22', 30000000, 1, N'overdue', N'other', 1045, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0711910' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (132, 72, N'1405/02/04', 20000000, 2, N'pending', N'card', 1061, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0779780' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (133, 131, N'1405/01/24', 25000000, 3, N'failed', N'other', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0779780' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (134, 89, N'1405/07/09', 15000000, 2, N'paid', N'cash', 1086, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0779780' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (135, 161, N'1405/06/14', 20000000, 1, N'paid', N'online', 1179, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0779780' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (136, 126, N'1405/04/26', 8000000, 3, N'paid', N'card', 1215, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0779780' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (137, 60, N'1405/04/04', 20000000, 1, N'paid', N'cash', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0779780' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (138, 173, N'1405/01/10', 15000000, 3, N'paid', N'online', 1168, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0779780' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (139, 2, N'1405/06/12', 15000000, 2, N'failed', N'installment', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0849033' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (140, 113, N'1405/03/21', 15000000, 3, N'draft', N'other', 1040, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0849033' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (141, 148, N'1405/01/05', 15000000, 1, N'draft', N'card', 1171, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0849033' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (142, 66, N'1405/04/18', 30000000, 1, N'paid', N'online', 1074, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0849033' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (143, 164, N'1405/06/01', 30000000, 3, N'paid', N'other', 1161, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0849033' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (144, 24, N'1405/05/12', 25000000, 2, N'pending', N'other', 1048, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0849033' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (145, 24, N'1405/01/14', 15000000, 3, N'paid', N'card', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0849033' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (146, 79, N'1405/01/26', 10000000, 1, N'paid', N'other', 1128, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0849033' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (147, 19, N'1405/01/07', 5000000, 2, N'partially_paid', N'cash', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0914910' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (148, 1229, N'1405/05/11', 10000000, 3, N'partially_paid', N'cash', 1181, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0923344' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (149, 155, N'1405/07/01', 30000000, 2, N'paid', N'card', 1080, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0923344' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (150, 67, N'1405/04/23', 10000000, 2, N'paid', N'card', 1056, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0923344' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (151, 112, N'1405/06/07', 20000000, 2, N'pending', N'cash', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0923344' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (152, 118, N'1405/03/13', 20000000, 2, N'overdue', N'cash', 1225, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0923344' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (153, 1233, N'1405/07/01', 15000000, 3, N'paid', N'online', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0923344' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (154, 1227, N'1405/03/19', 5000000, 1, N'paid', N'online', 1093, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0984306' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (155, 150, N'1405/07/15', 15000000, 3, N'overdue', N'installment', 1229, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0988717' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (156, 26, N'1405/02/28', 25000000, 1, N'overdue', N'card', 1020, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0993769' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (157, 2, N'1405/03/22', 10000000, 3, N'paid', N'cash', 1031, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0993769' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (158, 1226, N'1405/04/17', 10000000, 3, N'overdue', N'installment', 1047, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0993769' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (159, 4, N'1405/05/05', 30000000, 3, N'pending', N'other', 1123, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0993769' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (160, 2, N'1405/05/27', 8000000, 1, N'paid', N'installment', 1031, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0993769' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (161, 128, N'1405/06/28', 8000000, 1, N'paid', N'other', 1028, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0993769' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (162, 84, N'1405/04/24', 8000000, 1, N'paid', N'cash', 1030, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0993769' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (163, 148, N'1405/03/13', 15000000, 1, N'paid', N'card', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.0993769' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (164, 73, N'1405/04/02', 30000000, 2, N'pending', N'card', 1125, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1063126' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (165, 63, N'1405/05/18', 30000000, 1, N'paid', N'online', 1015, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1063126' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (166, 132, N'1405/01/08', 25000000, 1, N'paid', N'card', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1063126' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (167, 83, N'1405/01/05', 5000000, 1, N'overdue', N'cash', 1043, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1063126' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (168, 139, N'1405/07/26', 8000000, 1, N'paid', N'installment', 1148, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1063126' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (169, 10, N'1405/03/18', 8000000, 2, N'paid', N'card', 1103, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1063126' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (170, 161, N'1405/06/23', 30000000, 2, N'pending', N'online', 1033, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1063126' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (171, 98, N'1405/04/24', 12000000, 2, N'overdue', N'cash', 1164, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1063126' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (172, 161, N'1405/01/22', 10000000, 3, N'paid', N'cash', 1033, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1123152' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (173, 1241, N'1405/02/22', 10000000, 3, N'draft', N'installment', 1078, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1128392' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (174, 163, N'1405/02/16', 30000000, 2, N'refunded', N'cash', 1102, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1128392' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (175, 1, N'1405/07/01', 20000000, 2, N'draft', N'installment', 1206, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1128392' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (176, 137, N'1405/04/01', 15000000, 1, N'paid', N'installment', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1128392' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (177, 1228, N'1405/03/16', 5000000, 2, N'pending', N'installment', NULL, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1128392' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (178, 2, N'1405/04/09', 5000000, 1, N'overdue', N'installment', 1064, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1128392' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (179, 125, N'1405/01/13', 12000000, 3, N'paid', N'other', 1133, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1192771' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (180, 147, N'1405/06/05', 12000000, 2, N'refunded', N'installment', 1053, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1196485' AS DateTime2))
INSERT [dbo].[Payment] ([Id], [StudentRef], [Date], [Amount], [PaymentType], [Status], [PaymentMethod], [RegistrationRef], [Description], [CreatedAt]) VALUES (181, 173, N'1405/07/24', 30000000, 1, N'paid', N'installment', 1097, N'پرداخت نمایشی داشبورد', CAST(N'2026-07-30T04:10:02.1196485' AS DateTime2))
SET IDENTITY_INSERT [dbo].[Payment] OFF
SET IDENTITY_INSERT [dbo].[Student] ON 

INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1, N'سجاد', N'رفاقت', N'اکبر', N'1377392759', 2, N'1359/09/16', N'09145041648', N'Sadjad-PC\Sadjad', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (2, N'علی', N'احمدی', N'رضا', N'3259124411', 2, N'1390/02/20', N'09123456781', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (3, N'علی', N'فیروزی', N'جعفر', N'1365091600', 2, N'1388/12/30', N'09204917841', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (4, N'آیلار', N'محمدی', N'صمد', N'4444943191', 1, N'1380/1/24 ', N'09145879642', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (6, N'سمانه', N'علیار', N'جواد', N'9246272951', 1, N'1385/12/06', N'09145875798', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (7, N'مریم', N'حسینی', N'رضا', N'5462722109', 1, N'1391/02/20', N'09351246789', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (8, N'یاسین', N'پورنصر', N'بهزاد', N'1898415978', 2, N'1390/10/16', N'09146247798', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (9, N'آنیا', N'کامروا', N'ایلیا', N'9051780699', 1, N'1391/04/06', N'09146223498', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (10, N'زهرا', N'محمدی', N'بابک', N'7458834323', 1, N'1395/03/20', N'09901234567', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (11, N'امیرمحمد', N'رضایی', N'احمد', N'4816927999', 1, N'1388/07/29', N'09146201587', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (12, N'اسرا', N'رهبران', N'سعید', N'1364932032', 1, N'1388/01/11', N'09928698775', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (13, N'سینا', N'کاظمی', N'کریم', N'3405377821', 2, N'1393/06/20', N'09187654321', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (19, N'سینا', N'رفاقت', N'علی اکبر', N'2673180400', 2, N'1385/06/20', N'09914567812', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (21, N'سمانه', N'رسولی', N'علی', N'1487479700', 1, N'1358/06/31', N'09928776554', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (22, N'احمد', N'نوری', N'اصغر', N'9731378286', 2, N'1390/08/28', N'09145024965', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (23, N'اسما', N'اصغری', N'احد', N'3970357403', 1, N'1385/11/22', N'09148347294', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (24, N'احد', N'باقری', N'علی', N'0704041261', 2, N'1380/05/15', N'09147294885', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (25, N'رها', N'نوریان', N'احمد', N'5141202054', 1, N'1350/11/30', N'09935817556', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (26, N'رضا', N'باقر زاده', N'باقر', N'5577380911', 2, N'1359/02/15', N'03995841557', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (27, N'آرش', N'شریفی', N'محمد علی', N'8749702165', 2, N'1387/11/23', N'09141141382', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (44, N'آرتین', N'وصلی', N'حبیب', N'4342010658', 2, N'1388/07/29', N'09146254587', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (45, N'ایلیا', N'رسولیان', N'علیرضا', N'2678458725', 2, N'1320/07/01', N'09934567676', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (46, N'بابک', N'بدری', N'رسول', N'2699165069', 2, N'1392/01/13', N'09146249187', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (50, N'عطا', N'ذوقی', N'عبادالله', N'8711550066', 2, N'1389/03/23', N'09146244127', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (59, N'امیر', N'ذوقی', N'عبادالله', N'5073699440', 2, N'1374/10/07', N'09146243636', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (60, N'احمد', N'نوری', N'اصغر', N'2495334962', 2, N'1390/08/28', N'09145024965', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (61, N'اسما', N'اصغری', N'احد', N'0421584505', 1, N'1385/11/22', N'09148347294', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (62, N'احد', N'باقری', N'علی', N'7129761717', 2, N'1380/05/15', N'09147294885', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (63, N'رها', N'نوریان', N'احمد', N'5289595211', 1, N'1350/11/30', N'09935817556', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (64, N'رضا', N'باقر زاده', N'باقر', N'2111000019', 2, N'1359/02/15', N'03995841557', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (65, N'سعید', N'باقر زاده', N'رضا', N'5265895061', 2, N'1368/05/31', N'09335842515', N'elyar', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (66, N'ماهان', N'رضایی', N'بهرام', N'5465621885', 2, N'1388/10/07', N'09146212636', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (67, N'اشکان', N'رنجبر', N'ارش', N'7887961505', 2, N'1368/05/08', N'09144444994', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (69, N'مهنا', N'آریانی', N'آراز', N'8934812621', 1, N'1389/09/17', N'09144392636', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (70, N'پارسا', N'رنجبری', N'جعفر', N'4760230696', 2, N'1384/04/04', N'09123455454', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (72, N'مهیا', N'حسینی', N'سجاد', N'4546324741', 1, N'1389/11/04', N'09144391467', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (73, N'پارسایی', N'رنجبریان', N'جعفری', N'9504625681', 2, N'1311/11/11', N'09145674332', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (74, N'اسماء', N'واحد', N'محمد', N'3203156148', 1, N'1394/08/08', N'09146791467', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (76, N'علی', N'داداش زاده', N'قاسم', N'0319929991', 2, N'1377/11/12', N'09146661551', N'arshya', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (77, N'ترانه', N'دانشور', N'علی', N'8985216317', 1, N'1393/07/12', N'09146791467', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (79, N'علی', N'فیروزی', N'جعفر', N'0111010004', 2, N'1388/12/30', N'09204917841', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (80, N'جعفر', N'دلریش', N'قاسم', N'0000011101', 2, N'1365/12/30', N'03855454545', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (81, N'محمدرضا', N'خلعتبری', N'محسن', N'0001110101', 2, N'1368/12/2 ', N'09145145200', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (82, N'شهریار', N'مغانلو', N'رضا', N'8542011104', 2, N'1368/12/2 ', N'092457845123', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (83, N'مرتضی', N'تبریزی', N'حمید', N'1101100001', 2, N'1380/1/2  ', N'092457845123', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (84, N'نیما', N'خدایی', N'احمد', N'0741753456', 2, N'1380/06/12', N'09923456565', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (85, N'یسنا', N'راد', N'علی', N'4001366053', 1, N'1389/07/27', N'09146791467', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (86, N'مسعود', N'میر سیدی', N'عزیز', N'3453998065', 2, N'1387/01/02', N'09046361641', N'arshya', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (87, N'سودا', N'عبادی', N'مرسل', N'0010934391', 1, N'1387/10/18', N'09938767667', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (89, N'سونیا', N'عبادیان', N'سجاد', N'8295846094', 1, N'1347/10/28', N'09989878777', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (92, N'سالار', N'مدنی', N'اکبر', N'5405674508', 2, N'1381/03/12', N'09308031129', N'arshya', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (95, N'جولیا', N'عبادیان', N'حمید', N'1639751602', 1, N'1367/04/08', N'09928786565', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (96, N'مبین', N'بهینه', N'مهدی', N'8131608921', 2, N'1382/06/11', N'09308031129', N'arshya', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (97, N'انجلی', N'جولی', N'رضا', N'9345784780', 1, N'1367/08/07', N'09987656565', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (98, N'بهار', N'راهور', N'آرش', N'2859673709', 1, N'1350/03/14', N'9364978521', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (99, N'برد', N'پیت', N'رضا', N'5968881089', 2, N'1367/01/01', N'09923455454', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (101, N'الهام', N'علی پور', N'مرتضی', N'8931479093', 1, N'1389/10/30', N'09369901213', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (112, N'لیلا', N'قانونی', N'مرتضی', N'2504205899', 1, N'1389/10/10', N'09369903313', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (113, N'عبدل مالک', N'فاقدی', N'کاظم', N'2652926373', 2, N'1369/08/01', N'09145481453', N'arshya', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (114, N'سوینن', N'طایف', N'رضا', N'3202230115', 2, N'1367/01/01', N'09928676554', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (115, N'علی', N'فیروزی', N'جعفر', N'9011111109', 2, N'1388/12/30', N'09204917841', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (116, N'جعفر', N'دلریش', N'قاسم', N'2001001010', 2, N'1365/12/30', N'03855454545', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (117, N'محمدرضا', N'خلعتبری', N'محسن', N'7100110017', 2, N'1368/12/2 ', N'09145145200', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (118, N'شهریار', N'مغانلو', N'رضا', N'6633024274', 2, N'1368/12/2 ', N'092457845123', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (119, N'کریم', N'باقری', N'غلامعلی', N'1110111002', 2, N'1380/1/24 ', N'092457845121', N'amirreza', NULL, NULL, NULL, N'fa', 1, 0, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (120, N'مرتضی', N'تبریزی', N'حمید', N'0001011103', 2, N'1380/11/30', N'092457822223', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (121, N'حمید', N'درخشان', N'محمود', N'7010011109', 2, N'1380/12/20', N'092444444423', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (122, N'سیروس', N'دین محمدی', N'مصطفی', N'7101000010', 2, N'1380/2/19 ', N'091457845123', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (123, N'محمد', N'طیبی', N'حسن', N'8110010113', 2, N'1380/12/2 ', N'091757845123', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (124, N'نادر', N'محمدی', N'ناصر', N'0011110015', 2, N'1380/7/2  ', N'092887845123', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (125, N'محسن', N'فروزان', N'حمید', N'9311011101', 2, N'1380/8/11 ', N'090257845123', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (126, N'حسین', N'حسینی', N'حسن', N'9301011018', 2, N'1380/1/8  ', N'098457845123', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (127, N'سیروس', N'قایق ران', N'حمید', N'5201100104', 2, N'1380/2/2  ', N'094257845123', N'amirreza', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (128, N'ماهان', N'زارعی', N'مجتبی', N'9459402577', 2, N'1389/09/10', N'09142502253', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (131, N'شکیرا', N'ایزابل', N'مکس', N'1068301163', 2, N'1359/01/01', N'09923455656', N'asra', NULL, NULL, NULL, N'fa', 1, 0, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (132, N'میلاد', N'بابایی', N'حسین', N'8407229202', 2, N'1386/08/12', N'09143802253', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (133, N'صمیرا', N'صمیرایی', N'مکس', N'4690197717', 1, N'1359/01/01', N'09928798776', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (134, N'محنا', N'معارفی', N'امیر', N'9143077862', 1, N'1386/08/12', N'09363802253', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (135, N'دریا', N'دیرباز', N'حسن', N'2053348658', 1, N'1375/12/14', N'9364912321', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (136, N'عباسعلی', N'براتی', N'علمی زاده', N'7448206540', 2, N'1365/12/21', N'09301545325', N'arshya', NULL, NULL, NULL, N'fa', 1, 0, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (137, N'بیلی', N'ایلیش', N'مکس', N'8952885236', 1, N'1359/01/01', N'09923455454', N'asra', NULL, NULL, NULL, N'fa', 1, 0, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (138, N'ثنا', N'کرمانی', N'رضا', N'4296905521', 1, N'1386/08/21', N'09384002253', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (139, N'کامران', N'شاهد', N'حسین', N'1394557442', 2, N'1386/05/01', N'9364912321', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (140, N'ترویس', N'اسکات', N'مکس', N'1111011117', 2, N'1369/01/01', N'09998887799', N'asra', NULL, NULL, NULL, N'fa', 1, 0, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (141, N'نگار', N'یوسفی', N'شایان', N'9510228745', 1, N'1385/08/21', N'09384009998', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (143, N'احمد', N'زارع', N'محمدعلی', N'7318415549', 2, N'1368/06/21', N'9363568321', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (144, N'مدونا', N'اسکات', N'مکس', N'7294633691', 1, N'1379/11/01', N'09928767676', N'asra', NULL, NULL, NULL, N'fa', 1, 0, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (145, N'حمیده', N'زارع', N'محمدعلی', N'2665190710', 1, N'1368/06/21', N'9363567521', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (146, N'هانیه', N'زمانی', N'احسان', N'5203472203', 1, N'1385/06/21', N'09141189298', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (147, N'قزبس', N'مشهدی', N'حمزه', N'2758282801', 1, N'1366/07/11', N'09961238470', N'arshya', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (148, N'زهرا', N'امینی', N'علی', N'9680241904', 1, N'1384/05/21', N'09141182768', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (149, N'معصومه', N'علیزاده', N'امیر', N'1981742182', 1, N'1384/08/28', N'9363567521', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (150, N'کایلی', N'مکسول', N'جک', N'8880047728', 1, N'1379/11/01', N'09983455353', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (155, N'پریسا', N'باقرپور', N'سعید', N'9407995089', 1, N'1384/05/28', N'09141912768', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (156, N'ناصر', N'ملکی', N'محمد', N'8402251951', 2, N'1393/02/03', N'9363154821', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (161, N'زینب', N'ابراهیم زاده', N'سعید', N'8028551637', 1, N'1375/03/28', N'09141915768', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (162, N'رویا', N'مکسولی', N'جک', N'6807361882', 1, N'1379/11/01', N'09988768776', N'asra', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (163, N'جواد', N'ناصری', N'جلال', N'5826044111', 2, N'1395/11/26', N'9353154821', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (164, N'بایرامعلی', N'سرخی ', N'مرقوب', N'1554357640', 2, N'1376/01/05', N'09142738772', N'arshya', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
GO
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (165, N'ناردین', N'کریمی', N'مهدی', N'6405922715', 1, N'1378/04/09', N'09121915768', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (166, N'رها', N'زند', N'سیروس', N'2094321401', 1, N'1390/09/09', N'9903154821', N'vahideh', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (167, N'جان', N'اسنو', N'ند', N'9334800615', 2, N'1379/11/01', N'09987656565', N'asra', NULL, NULL, NULL, N'fa', 1, 0, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (173, N'نرگس', N'مرتضوی', N'مهدی', N'8260527103', 1, N'1372/04/09', N'09371916668', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (176, N'اریا', N'استارک', N'ند', N'4460185954', 1, N'1379/11/01', N'09989879887', N'asra', NULL, NULL, NULL, N'fa', 1, 0, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (188, N'پویا', N'مرادی', N'محمدرضا', N'3664257340', 2, N'1382/04/09', N'09379122272', N'saba', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:01:12.8696072' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1212, N'آزمایش', N'ثبت‌نام', N'علی', N'6440515195', 2, N'1375/06/15', N'09121234567', N'limdbadmin', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:54:21.7778732' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1213, N'سجاد', N'رفاقت', N'اکبر', N'4444444444', 2, N'1359/09/16', N'09145041648', N'limdbadmin', NULL, 1, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:57:50.4111560' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1214, N'وحید', N'مجیدی', N'محمد', N'0192585002', 2, N'1370/10/26', N'09199185467', N'limdbadmin', NULL, 1, NULL, N'fa', 1, 1, CAST(N'2026-07-29T14:59:07.4917550' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1226, N'المیرا', N'کرمانی', N'امیر', N'1322454647', 1, N'1378/02/30', N'09141156575', N'limdbadmin', NULL, 3, NULL, N'fa', 1, 1, CAST(N'2026-07-29T15:01:10.9811247' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1227, N'مختار', N'ثقفی', N'کریم', N'0250778807', 2, N'1371/03/04', N'09121478563', N'limdbadmin', NULL, 3, NULL, N'fa', 1, 1, CAST(N'2026-07-29T15:23:33.3176883' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1228, N'گورباچف', N'کمونیسم', N'استالین', N'5240221812', 1, N'1405/05/07', N'34456987400000000000', N'limdbadmin', NULL, 4, NULL, N'fa', 1, 1, CAST(N'2026-07-29T15:36:00.7399064' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1229, N'مریم', N'مرادپور', N'کریم', N'5310146962', 1, N'1405/12/03', N'09369082272', N'limdbadmin', NULL, 4, NULL, N'fa', 1, 1, CAST(N'2026-07-29T15:38:03.6492339' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1230, N'آدولف', N'بوش', N'محمد', N'1219187161', 2, N'1405/05/07', N'021452103000000', N'limdbadmin', NULL, 2, NULL, N'fa', 1, 0, CAST(N'2026-07-29T15:38:19.5404154' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1231, N'ولادیمیر', N'پوتین', N'کامران', N'2685718761', 2, N'1405/05/03', N'091444444444444', N'limdbadmin', NULL, 9, NULL, N'fa', 1, 0, CAST(N'2026-07-29T15:47:07.7134584' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1232, N'الیار', N'نورنواز', N'احمد', N'6695199051', 2, N'1405/05/01', N'0384255879855678452', N'limdbadmin', NULL, 4, NULL, N'fa', 1, 1, CAST(N'2026-07-29T15:50:42.1904689' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1233, N'ابوالقاسم', N'فردوسی', N'ابولقدر', N'1557793719', 2, N'1404/10/22', N'0912457896', N'limdbadmin', NULL, 8, NULL, N'fa', 1, 1, CAST(N'2026-07-29T15:55:19.8512490' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1234, N'هلما', N'کاظمی', N'علی', N'6970060276', 1, N'1391/02/04', N'09141201212', N'limdbadmin', NULL, 4, NULL, N'fa', 1, 1, CAST(N'2026-07-29T15:58:52.2590587' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1235, N'احمد', N'نوری زادثیان', N'احد', N'3269485212', 1, N'1402/04/06', N'???????????????', N'limdbadmin', NULL, NULL, NULL, N'fa', 1, 1, CAST(N'2026-07-29T16:00:11.5711420' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1236, N'محمود', N'احمدی نژاد', N'علی', N'3414106280', 2, N'1405/05/04', N'00000000000000', N'limdbadmin', NULL, 3, NULL, N'fa', 1, 0, CAST(N'2026-07-29T16:02:19.8794624' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1237, N'صمد', N'صمدی', N'صادق', N'0462604047', 2, N'1384/01/18', N'09141234567', N'limdbadmin', NULL, 7, NULL, N'fa', 1, 1, CAST(N'2026-07-29T16:08:33.0993157' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1238, N'.', N'خاتمی', N'.', N'8070244161', 2, N'1405/05/03', N'09144102578', N'limdbadmin', NULL, 1, NULL, N'fa', 1, 1, CAST(N'2026-07-29T16:09:15.4480991' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1239, N'تست', N'تست', N'تست', N'8000017482', 1, N'1024/05/04', N'09111111111', N'limdbadmin', NULL, NULL, NULL, N'fa', 1, 0, CAST(N'2026-07-29T16:14:12.9968935' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1240, N'مصطفی', N'خمینی', N'روح الله', N'6750317502', 2, N'1405/05/03', N'09698521471', N'limdbadmin', NULL, 11, NULL, N'fa', 1, 0, CAST(N'2026-07-29T16:15:29.9955910' AS DateTime2))
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator], [Email], [TargetLanguageRef], [CurrentLevelRef], [PreferredUILanguage], [NotificationsEnabled], [IsActive], [CreatedAt]) VALUES (1241, N'اب', N'با', N'بی', N'9820274648', 2, N'1361/02/27', N'09415554875', N'limdbadmin', NULL, 7, NULL, N'fa', 1, 0, CAST(N'2026-07-29T16:16:21.9993184' AS DateTime2))
SET IDENTITY_INSERT [dbo].[Student] OFF
SET IDENTITY_INSERT [dbo].[AppUser] ON 

INSERT [dbo].[AppUser] ([Id], [Username], [Email], [PasswordHash], [FullName], [RoleRef], [StudentRef], [TeacherRef], [IsActive], [PreferredUILanguage], [FailedLoginCount], [LockedUntil], [LastLoginAt], [CreatedAt]) VALUES (1, N'admin', N'admin@lims.local', N'$2b$12$d4n1xDElYyRkDzlS3ZzageuJYbPzQZRtBaHtd1q0NrPUEfS0bKWXm', N'مدیر سیستم', 1, NULL, NULL, 1, N'fa', 0, NULL, CAST(N'2026-07-30T05:04:47.5725472' AS DateTime2), CAST(N'2026-07-29T14:19:35.5370692' AS DateTime2))
INSERT [dbo].[AppUser] ([Id], [Username], [Email], [PasswordHash], [FullName], [RoleRef], [StudentRef], [TeacherRef], [IsActive], [PreferredUILanguage], [FailedLoginCount], [LockedUntil], [LastLoginAt], [CreatedAt]) VALUES (2, N'secretary', N'secretary@lims.local', N'$2b$12$RV9jLmtTJhNjr/sNkQ64hu675SXe4c8fomO4DIcYBqlYB0D0ocbEm', N'منشی آموزشگاه', 3, NULL, NULL, 1, N'fa', 0, NULL, NULL, CAST(N'2026-07-29T14:19:35.7558718' AS DateTime2))
INSERT [dbo].[AppUser] ([Id], [Username], [Email], [PasswordHash], [FullName], [RoleRef], [StudentRef], [TeacherRef], [IsActive], [PreferredUILanguage], [FailedLoginCount], [LockedUntil], [LastLoginAt], [CreatedAt]) VALUES (3, N'user80375', NULL, N'$2b$12$Jeqejmg3sr6UXpx73y6T0eMMg6KJGHCnzork2QMQM67jyJvr/n1u2', N'آزمایش ثبت‌نام', 5, 1212, NULL, 1, N'fa', 0, NULL, NULL, CAST(N'2026-07-29T14:54:21.9874747' AS DateTime2))
INSERT [dbo].[AppUser] ([Id], [Username], [Email], [PasswordHash], [FullName], [RoleRef], [StudentRef], [TeacherRef], [IsActive], [PreferredUILanguage], [FailedLoginCount], [LockedUntil], [LastLoginAt], [CreatedAt]) VALUES (4, N'sref', NULL, N'$2b$12$OuqUZC6/TaYRIum1ggc0.u1cFz4jyikrIPXc2i3X2wot4r4MVNoZq', N'سجاد رفاقت', 5, 1213, NULL, 1, N'fa', 0, NULL, CAST(N'2026-07-29T15:02:44.9555032' AS DateTime2), CAST(N'2026-07-29T14:57:50.8109931' AS DateTime2))
INSERT [dbo].[AppUser] ([Id], [Username], [Email], [PasswordHash], [FullName], [RoleRef], [StudentRef], [TeacherRef], [IsActive], [PreferredUILanguage], [FailedLoginCount], [LockedUntil], [LastLoginAt], [CreatedAt]) VALUES (5, N'وحید', NULL, N'$2b$12$aiAZbli/ph5CtHVJEhxpH.L4NrdR.vNTRodpAhpUncAb9hjCihEMa', N'وحید مجیدی', 5, 1214, NULL, 1, N'fa', 0, NULL, CAST(N'2026-07-29T15:27:27.5196712' AS DateTime2), CAST(N'2026-07-29T14:59:07.7046594' AS DateTime2))
INSERT [dbo].[AppUser] ([Id], [Username], [Email], [PasswordHash], [FullName], [RoleRef], [StudentRef], [TeacherRef], [IsActive], [PreferredUILanguage], [FailedLoginCount], [LockedUntil], [LastLoginAt], [CreatedAt]) VALUES (6, N'Ely78', NULL, N'$2b$12$WBgPLABGZMiKvPoZojNPaOGXF/DBlPWqAl86qCuMz8kTuOV0IEEJO', N'المیرا کرمانی', 5, 1226, NULL, 1, N'fa', 0, NULL, NULL, CAST(N'2026-07-29T15:01:11.1962397' AS DateTime2))
INSERT [dbo].[AppUser] ([Id], [Username], [Email], [PasswordHash], [FullName], [RoleRef], [StudentRef], [TeacherRef], [IsActive], [PreferredUILanguage], [FailedLoginCount], [LockedUntil], [LastLoginAt], [CreatedAt]) VALUES (7, N'مختار', NULL, N'$2b$12$U2hNAE4gZFlvdKs.Np3IM.v5NqsMkB63SXDNAFvt8uyIznrPMJypW', N'مختار ثقفی', 5, 1227, NULL, 1, N'fa', 0, NULL, NULL, CAST(N'2026-07-29T15:23:33.5217760' AS DateTime2))
INSERT [dbo].[AppUser] ([Id], [Username], [Email], [PasswordHash], [FullName], [RoleRef], [StudentRef], [TeacherRef], [IsActive], [PreferredUILanguage], [FailedLoginCount], [LockedUntil], [LastLoginAt], [CreatedAt]) VALUES (8, N'ELYAR', NULL, N'$2b$12$aSNvgMuSoDmS7JfY1cFIBOtniJUQ/tTGml8hvDPItabgI95J3MV1K', N'الیار نورنواز', 5, 1232, NULL, 1, N'fa', 0, NULL, CAST(N'2026-07-29T16:01:51.8271110' AS DateTime2), CAST(N'2026-07-29T15:50:42.3979751' AS DateTime2))
INSERT [dbo].[AppUser] ([Id], [Username], [Email], [PasswordHash], [FullName], [RoleRef], [StudentRef], [TeacherRef], [IsActive], [PreferredUILanguage], [FailedLoginCount], [LockedUntil], [LastLoginAt], [CreatedAt]) VALUES (9, N'فردوسی', NULL, N'$2b$12$SiNGtw.F6U/tcg9GeY9T3ebn72DUEBjFaGl3xjtqppJnfObavwe7.', N'ابوالقاسم فردوسی', 5, 1233, NULL, 1, N'fa', 0, NULL, NULL, CAST(N'2026-07-29T15:55:20.0612227' AS DateTime2))
INSERT [dbo].[AppUser] ([Id], [Username], [Email], [PasswordHash], [FullName], [RoleRef], [StudentRef], [TeacherRef], [IsActive], [PreferredUILanguage], [FailedLoginCount], [LockedUntil], [LastLoginAt], [CreatedAt]) VALUES (10, N'Heli', NULL, N'$2b$12$wD4iFE8SY1TugeyUrrA5Ce8X9TC5.tpQ.8G6aiypWDTA1XhN9Yqn2', N'هلما کاظمی', 5, 1234, NULL, 1, N'fa', 0, NULL, NULL, CAST(N'2026-07-29T15:58:52.4751420' AS DateTime2))
INSERT [dbo].[AppUser] ([Id], [Username], [Email], [PasswordHash], [FullName], [RoleRef], [StudentRef], [TeacherRef], [IsActive], [PreferredUILanguage], [FailedLoginCount], [LockedUntil], [LastLoginAt], [CreatedAt]) VALUES (11, N'arshya', NULL, N'$2b$12$fDl/e4dWNMWc.wZmBY4j.e9mhdqKalCer/it45/I1FsA8Q9sJQm0S', N'اب با', 5, 1241, NULL, 1, N'fa', 0, NULL, CAST(N'2026-07-29T16:17:14.5210747' AS DateTime2), CAST(N'2026-07-29T16:16:22.2061880' AS DateTime2))
SET IDENTITY_INSERT [dbo].[AppUser] OFF
SET IDENTITY_INSERT [dbo].[UserSession] ON 

INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (1, 1, N'a8cc4a950dd2ce1ef6b8f3c03977475ecbd9a062412c281c5391ff971ee9993d', CAST(N'2026-07-29T14:33:13.4114160' AS DateTime2), CAST(N'2026-08-12T14:33:13.4107410' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (2, 1, N'25225cc6aa688c1593cb17f6152db3c3d1f94b4099b5e221a81d927213196a04', CAST(N'2026-07-29T14:42:23.5745434' AS DateTime2), CAST(N'2026-08-12T14:42:23.5725260' AS DateTime2), CAST(N'2026-07-29T15:06:18.1711504' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (3, 1, N'8d47568a02b95b6cfd10ff8af13979a8ef07f2bcd86a42a67afa0d2595d76b62', CAST(N'2026-07-29T14:42:55.4750330' AS DateTime2), CAST(N'2026-08-12T14:42:55.4750330' AS DateTime2), CAST(N'2026-07-29T14:50:02.9012588' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (4, 1, N'c763c8b6c338782c8017d8bab5b3a4c9406a1785ae11c183e72477b631de64ae', CAST(N'2026-07-29T14:43:47.8209213' AS DateTime2), CAST(N'2026-08-12T14:43:47.8189070' AS DateTime2), CAST(N'2026-07-29T14:44:15.2624847' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (5, 1, N'42c783cae389d0c30dad21ad75bde546c0260f602f226fe2c3487c77c31449ac', CAST(N'2026-07-29T14:43:58.5658382' AS DateTime2), CAST(N'2026-08-12T14:43:58.5645110' AS DateTime2), CAST(N'2026-07-29T14:50:16.8777605' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (6, 1, N'139a869403637c944996aa038f1d09a67f8f4b664044f4a514a759bcfb4c8508', CAST(N'2026-07-29T14:44:05.5013258' AS DateTime2), CAST(N'2026-08-12T14:44:05.5013250' AS DateTime2), CAST(N'2026-07-29T14:49:03.3324519' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (7, 1, N'55d39fdf2fe35e162dabee1a6458fb8531c7a883a2a29610ad4edff8ff756229', CAST(N'2026-07-29T14:44:25.3795191' AS DateTime2), CAST(N'2026-08-12T14:44:25.3795190' AS DateTime2), CAST(N'2026-07-29T14:50:13.5164422' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (8, 1, N'b5a83864c17569bc01829cb10a31119bc3e2a21515e3bbe58f2243146c53917c', CAST(N'2026-07-29T14:44:28.2280712' AS DateTime2), CAST(N'2026-08-12T14:44:28.2203740' AS DateTime2), CAST(N'2026-07-29T14:50:01.3248190' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (9, 1, N'ea08b2aca419a4193e1b84b7d28891215182cd62d0ee7149e347e3e98dd16e0c', CAST(N'2026-07-29T14:44:39.3389199' AS DateTime2), CAST(N'2026-08-12T14:44:39.3389190' AS DateTime2), CAST(N'2026-07-29T14:44:47.6048200' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (10, 3, N'5bfd56f70a7b567e741f83b303133d42dc4cb9dff6b58cc38f6f1b179b172eb4', CAST(N'2026-07-29T14:54:21.9977463' AS DateTime2), CAST(N'2026-08-12T14:54:21.9969890' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (11, 1, N'9040bcf0e4df523c1d6d77db9785c587c8ed565074a326cb26f47e30d4c8e95f', CAST(N'2026-07-29T14:55:44.8561311' AS DateTime2), CAST(N'2026-08-12T14:55:44.8561310' AS DateTime2), CAST(N'2026-07-29T14:58:19.1087366' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (12, 1, N'12af6817185f965b2cce88c731c1e6a6e23c5d68049f41a620e1f014590e94a2', CAST(N'2026-07-29T14:56:14.8982893' AS DateTime2), CAST(N'2026-08-12T14:56:14.8982890' AS DateTime2), CAST(N'2026-07-29T14:58:23.0200669' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (13, 4, N'de69a4a0492ee0f7b02fc395e429719f16bf569f2e6789cb5015671bb73a8473', CAST(N'2026-07-29T14:57:50.8109931' AS DateTime2), CAST(N'2026-08-12T14:57:50.8109930' AS DateTime2), CAST(N'2026-07-29T15:01:19.5187748' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (14, 5, N'bd8733d7ae31d317461248cd9e7584646afea2da711e995698ec32675bb6e9ae', CAST(N'2026-07-29T14:59:07.7103427' AS DateTime2), CAST(N'2026-08-12T14:59:07.7103420' AS DateTime2), CAST(N'2026-07-29T15:01:29.1856739' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (15, 6, N'06dd18cfe9d7f2c59324873f7bcedcc281f7bc681ef7015b9fc035f3ec46b259', CAST(N'2026-07-29T15:01:11.1962397' AS DateTime2), CAST(N'2026-08-12T15:01:11.1962390' AS DateTime2), CAST(N'2026-07-29T15:04:30.0086011' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (16, 5, N'3a74d6fffe32f2d570eda848db715954b5689a5b408ea981c9e09c98fc9cd9eb', CAST(N'2026-07-29T15:01:31.2083069' AS DateTime2), CAST(N'2026-08-12T15:01:31.2083060' AS DateTime2), CAST(N'2026-07-29T15:04:43.3024352' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (17, 4, N'b371cdbe2f1fb14351fa51d4c6023fe025bfc9b956e14a024f5f4ddd85a57a07', CAST(N'2026-07-29T15:02:44.9599663' AS DateTime2), CAST(N'2026-08-12T15:02:44.9575130' AS DateTime2), CAST(N'2026-07-29T15:04:18.4149261' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (18, 1, N'fd030ea39823adcfbe70732c797f23a4cb4e64625e7acaf4eff72944b7c5002f', CAST(N'2026-07-29T15:03:12.0810178' AS DateTime2), CAST(N'2026-08-12T15:03:12.0794760' AS DateTime2), CAST(N'2026-07-29T15:03:32.5282781' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (19, 1, N'34b2717f409712494d6e025d0e01ad61b99d84bc4b084380cb8488da0ce0b728', CAST(N'2026-07-29T15:06:15.6907900' AS DateTime2), CAST(N'2026-08-12T15:06:15.6907900' AS DateTime2), CAST(N'2026-07-29T15:48:57.3231169' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (20, 1, N'cf7083f357e010c17fb67c45662e13ffbd9d85b74ae803d46dbd2370f02e2282', CAST(N'2026-07-29T15:06:16.2712764' AS DateTime2), CAST(N'2026-08-12T15:06:16.2651710' AS DateTime2), CAST(N'2026-07-29T15:53:08.1838129' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (21, 1, N'6c3e9314a4fe3c07bdffd034ef8c1b7cd0d87edd17e2ef945fcbc48b74402b1f', CAST(N'2026-07-29T15:06:44.8819550' AS DateTime2), CAST(N'2026-08-12T15:06:44.8774260' AS DateTime2), CAST(N'2026-07-29T15:54:08.0815871' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (22, 1, N'292f4a03b8435aba9077158f63a273a9b69f9ca9752a6d8bd1decc2549c47900', CAST(N'2026-07-29T15:07:28.1982765' AS DateTime2), CAST(N'2026-08-12T15:07:28.1891040' AS DateTime2), CAST(N'2026-07-29T15:13:24.7635924' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (23, 1, N'0f906ddb6d5fdfd5ced61e3fc5cbb5332865594b52f4ad859ea1242b09d1c34f', CAST(N'2026-07-29T15:07:36.6943473' AS DateTime2), CAST(N'2026-08-12T15:07:36.6929820' AS DateTime2), CAST(N'2026-07-29T15:50:17.6964583' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (24, 1, N'45291f11af269768c0bfc9c075d1c3d8c53ce74dac8a73fa68035ae7af946649', CAST(N'2026-07-29T15:15:04.0379158' AS DateTime2), CAST(N'2026-08-12T15:15:04.0379150' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (25, 1, N'6aafaef68267cc1c040e75a1a708ce572e04861a92afdf0371d0bbeb1295af63', CAST(N'2026-07-29T15:15:18.4527458' AS DateTime2), CAST(N'2026-08-12T15:15:18.4501590' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (26, 1, N'6d6c036e53981df535866a23d3a5dad84a22c86101a08fab4901441f6bae9338', CAST(N'2026-07-29T15:15:42.8657506' AS DateTime2), CAST(N'2026-08-12T15:15:42.8657500' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (27, 1, N'cc233de76500e954978c35bb23b7df2658f5f3ba90be8f3eaf9de2ec2524ece9', CAST(N'2026-07-29T15:16:19.9916581' AS DateTime2), CAST(N'2026-08-12T15:16:19.9868810' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (28, 1, N'0f8673f78f962124be4cf82228a46c5dfcabef6965aa8ac24495597c4ff7a893', CAST(N'2026-07-29T15:16:49.1862593' AS DateTime2), CAST(N'2026-08-12T15:16:49.1862590' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (29, 1, N'02450ef0612294ce6badabc4518bde62b0e3014c03f64c40fc534fd097917b5c', CAST(N'2026-07-29T15:18:16.9082104' AS DateTime2), CAST(N'2026-08-12T15:18:16.9082100' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (30, 1, N'567ccbcb4718b8f65f39ae4700b836fa3865226535d55604b9f51dd4ab13687c', CAST(N'2026-07-29T15:19:36.8042622' AS DateTime2), CAST(N'2026-08-12T15:19:36.8042620' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (31, 1, N'018d36e11a08e0adbeda43c41d1335be4a2384dd728e27d242ba9a51a6491d71', CAST(N'2026-07-29T15:20:10.7380349' AS DateTime2), CAST(N'2026-08-12T15:20:10.7380340' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (32, 1, N'84e3ecd6c14997c74692e10f871779ab2d1c3b84787ce88de4113cacfb676626', CAST(N'2026-07-29T15:20:11.2014186' AS DateTime2), CAST(N'2026-08-12T15:20:11.2003290' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (33, 1, N'a212c8e154afb218667226eb4db07fb7034e1662025c745e73bf079c568417f5', CAST(N'2026-07-29T15:22:12.4436577' AS DateTime2), CAST(N'2026-08-12T15:22:12.4426590' AS DateTime2), CAST(N'2026-07-29T15:27:18.9100717' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (34, 7, N'bfc1cf98832fb55c08cbd5fae2d0a963207143aac36311789b8700d5d32f3311', CAST(N'2026-07-29T15:23:33.5256755' AS DateTime2), CAST(N'2026-08-12T15:23:33.5235130' AS DateTime2), CAST(N'2026-07-29T15:24:20.2234498' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (35, 1, N'1232ef5e5dcd875912fb12527859f563832c07e9d988e92e742f3906412a5468', CAST(N'2026-07-29T15:24:22.4472341' AS DateTime2), CAST(N'2026-08-12T15:24:22.4472340' AS DateTime2), CAST(N'2026-07-29T15:53:00.8931450' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (36, 5, N'87747b17d56aa6babd2bda1d2767439d498f9f5cc0c40784d1eb66d10c03ed4b', CAST(N'2026-07-29T15:27:27.5266494' AS DateTime2), CAST(N'2026-08-12T15:27:27.5231540' AS DateTime2), CAST(N'2026-07-29T15:30:50.6363950' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (37, 1, N'80dafbb75ee3e2cce166dbc5e41eeb8262b262abe4453cc03e09eb54437b35ce', CAST(N'2026-07-29T15:33:13.4829497' AS DateTime2), CAST(N'2026-08-12T15:33:13.4820510' AS DateTime2), CAST(N'2026-07-29T15:53:06.8597501' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (38, 1, N'16ccce054e56683a91f049f0e6da129a290377b4112aa71f1d445e969c26a03a', CAST(N'2026-07-29T15:34:07.4971577' AS DateTime2), CAST(N'2026-08-12T15:34:07.4971570' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (39, 8, N'9d4c7d355034999d93c66edecf36831c1dc7b8c351cab306e552beb6531bf00c', CAST(N'2026-07-29T15:50:42.4018610' AS DateTime2), CAST(N'2026-08-12T15:50:42.4018610' AS DateTime2), CAST(N'2026-07-29T15:51:51.7464081' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (40, 1, N'0442d60003ff0ad7b44d2196d16437229d6ab677f5b8c385aee51dd412319dd2', CAST(N'2026-07-29T15:52:48.0727146' AS DateTime2), CAST(N'2026-08-12T15:52:48.0688740' AS DateTime2), CAST(N'2026-07-29T16:01:36.8005011' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (41, 1, N'dabd1af4edff9fd91bec5d84a7438d23e5fce2682cecf43a60eb02ee1f35b9c6', CAST(N'2026-07-29T15:53:47.1846355' AS DateTime2), CAST(N'2026-08-12T15:53:47.1831290' AS DateTime2), CAST(N'2026-07-29T16:15:43.0963211' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (42, 1, N'2134041a7ed1afa1442e5544bf92936e816338ed3b24ce9d6ebe754def2d23a7', CAST(N'2026-07-29T15:54:05.9353038' AS DateTime2), CAST(N'2026-08-12T15:54:05.9353030' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (43, 1, N'e4828af6d649eeb2d4d4a1989874a9eaa484d85babfeb4cfd409e0c50e88a9d9', CAST(N'2026-07-29T15:54:24.8524183' AS DateTime2), CAST(N'2026-08-12T15:54:24.8524180' AS DateTime2), CAST(N'2026-07-29T15:56:22.9612151' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (44, 9, N'98bd90051012c04e9fa6f26c0d9565556ff505565cea12a2902ece7c96d69dc3', CAST(N'2026-07-29T15:55:20.0660074' AS DateTime2), CAST(N'2026-08-12T15:55:20.0632330' AS DateTime2), CAST(N'2026-07-29T15:56:21.0882465' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (45, 1, N'e3e7f202b6aea004f37d1c6852238f1dcf6e3329fe6b0cdb269935e52fd0110d', CAST(N'2026-07-29T15:55:30.3609575' AS DateTime2), CAST(N'2026-08-12T15:55:30.3609570' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (46, 1, N'8a412d264be74fa6d18ae2f3d2469f259881de18564cec767c5623edbdff1b64', CAST(N'2026-07-29T15:56:22.7878830' AS DateTime2), CAST(N'2026-08-12T15:56:22.7831180' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (47, 10, N'7d5ee298cd63613594eb6c2aa7202e87291e775570cb94bd1c85de534cd9483f', CAST(N'2026-07-29T15:58:52.4875101' AS DateTime2), CAST(N'2026-08-12T15:58:52.4834930' AS DateTime2), CAST(N'2026-07-29T16:01:35.2027034' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (48, 8, N'f544c12862c57a40b3ea18918e920f43cec80514dc15a714415bb412a41430a0', CAST(N'2026-07-29T16:01:51.8322434' AS DateTime2), CAST(N'2026-08-12T16:01:51.8296520' AS DateTime2), CAST(N'2026-07-29T16:02:31.0047190' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (49, 1, N'153b00cb27e87615faa28f9eda178a22a6b8610a55a8b3aa58a7a88396a58176', CAST(N'2026-07-29T16:02:22.6411110' AS DateTime2), CAST(N'2026-08-12T16:02:22.6379430' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (50, 1, N'4b70121aa1e4565bc82bfc4e76e0e66e979c38f5cd11fc895684d4d5a22e70ef', CAST(N'2026-07-29T16:02:36.6149466' AS DateTime2), CAST(N'2026-08-12T16:02:36.6126850' AS DateTime2), CAST(N'2026-07-29T16:07:13.8819992' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (51, 1, N'3f22312473197017c25beed509d6b668119b930ed697a9a115c0668f87f463a4', CAST(N'2026-07-29T16:09:04.3961154' AS DateTime2), CAST(N'2026-08-12T16:09:04.3961150' AS DateTime2), CAST(N'2026-07-29T16:15:13.4089388' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (52, 11, N'a61015c290d64d47270c2de4b6632bbd2dfaab57b0f99d8b0e1413aa4ccd6ecf', CAST(N'2026-07-29T16:16:22.2126658' AS DateTime2), CAST(N'2026-08-12T16:16:22.2061880' AS DateTime2), CAST(N'2026-07-29T16:16:27.4925834' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (53, 11, N'782d8765d2f0881164cf927ab438563888f423190a2ed03d6a6a4245d97b6f72', CAST(N'2026-07-29T16:16:42.8720921' AS DateTime2), CAST(N'2026-08-12T16:16:42.8690860' AS DateTime2), CAST(N'2026-07-29T16:16:48.9458577' AS DateTime2))
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (54, 11, N'9cf9ba1e37f9c4b4fa0d7c5299bef7c8aa07461dc55aacfcc8cd979fe52005f5', CAST(N'2026-07-29T16:17:14.5243757' AS DateTime2), CAST(N'2026-08-12T16:17:14.5243750' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (55, 1, N'eed6bc05b4756ebac0c10187802766f1bfdf8d57c0dc60b0a70b5bc6bb1f468d', CAST(N'2026-07-29T16:22:53.0433911' AS DateTime2), CAST(N'2026-08-12T16:22:53.0413720' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (56, 1, N'3b08fb1d335d3532c8322efa18ebab87510111b949544777817a15c6adf06485', CAST(N'2026-07-29T16:24:11.2788928' AS DateTime2), CAST(N'2026-08-12T16:24:11.2788920' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (57, 1, N'8625c7a1a3ef9ef5bb44bf76a9eab95f955750ff1f349ad23e6b2190d76194a9', CAST(N'2026-07-30T03:53:38.6104330' AS DateTime2), CAST(N'2026-08-13T03:53:38.6104330' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (58, 1, N'3ef25cdaf57c25753d9fd0dc3a55204dc8c21f9ee42fa983892bf18709ef33d9', CAST(N'2026-07-30T03:54:24.2710143' AS DateTime2), CAST(N'2026-08-13T03:54:24.2683590' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (59, 1, N'cbed74825631f53de5e55613f6251ee37dd736c501c90ccaa01387aed1905c14', CAST(N'2026-07-30T04:10:16.9828239' AS DateTime2), CAST(N'2026-08-13T04:10:16.9808170' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (60, 1, N'84905b8ad167ec60a49be1d6d0a8c1f8f3f770d3df89351fa4c34d3158621152', CAST(N'2026-07-30T04:10:48.0669235' AS DateTime2), CAST(N'2026-08-13T04:10:48.0649030' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (61, 1, N'926c380e00ee1a85ce7a778f23a4fa5dd8dd39151de091ca6d5920e70f435851', CAST(N'2026-07-30T04:11:03.7147028' AS DateTime2), CAST(N'2026-08-13T04:11:03.7141820' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (62, 1, N'912a17280d0a6df7b3ec19b17917af3bfcf5e3e6ae2515cb15c6e6a05092bf07', CAST(N'2026-07-30T04:12:05.5209110' AS DateTime2), CAST(N'2026-08-13T04:12:05.5145880' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (63, 1, N'a5dc879c155a8cd13d403e6e51515076039860894d26e7d8075ab35d5f97a70b', CAST(N'2026-07-30T04:12:37.8575072' AS DateTime2), CAST(N'2026-08-13T04:12:37.8575070' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (64, 1, N'cc1f425425b740c5237f816da50ef8c4deccd030585b1c204196db2d284b1d3e', CAST(N'2026-07-30T04:12:53.6063913' AS DateTime2), CAST(N'2026-08-13T04:12:53.6001420' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (65, 1, N'e205ff5be66ab699bafa8ff2b66e4c7b4ee33ca64aeb03f4afe62efa8ccd54fc', CAST(N'2026-07-30T04:14:06.5169722' AS DateTime2), CAST(N'2026-08-13T04:14:06.5169720' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (66, 1, N'75668e8850fe34e2d129d70be4bc866f1db9685b592630ea539e8e8f0f2b088f', CAST(N'2026-07-30T04:54:54.9119328' AS DateTime2), CAST(N'2026-08-13T04:54:54.9119320' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (67, 1, N'9dd33d557667310e700b580f4f946daece3af19c69ff1e5f3eee9d059ecb3c30', CAST(N'2026-07-30T04:55:30.9770256' AS DateTime2), CAST(N'2026-08-13T04:55:30.9770250' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (68, 1, N'f6d2e4ccf7b185739cc7213e14660613ff7da73df3cebdf1d48f151d04707c5e', CAST(N'2026-07-30T04:56:00.3328166' AS DateTime2), CAST(N'2026-08-13T04:56:00.3298070' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (69, 1, N'253778a7fac5b77a3088e97450cd91ce6554c14c6d7c2c846faa7b48239ba394', CAST(N'2026-07-30T04:56:28.8483069' AS DateTime2), CAST(N'2026-08-13T04:56:28.8483060' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (70, 1, N'7adfc43b10369df4d47b1beefc5bc9bec57d9f94221c56f0c6ce8185ea36d42d', CAST(N'2026-07-30T04:56:55.5371744' AS DateTime2), CAST(N'2026-08-13T04:56:55.5330370' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (71, 1, N'291594f8d87ce264843f27431fad140fa3cb292563f0f4046c25e8b256eed779', CAST(N'2026-07-30T04:59:52.5917913' AS DateTime2), CAST(N'2026-08-13T04:59:52.5852270' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (72, 1, N'345de72ad0fb4de061c7c00bcf8dd730062d147647dab992fd388a94b9e69c28', CAST(N'2026-07-30T05:00:20.7872596' AS DateTime2), CAST(N'2026-08-13T05:00:20.7800250' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (73, 1, N'3e4527dcb4666cdc192dbde1da6b9052d525f62591f852d2cd9d1527fe58f373', CAST(N'2026-07-30T05:00:45.0322956' AS DateTime2), CAST(N'2026-08-13T05:00:45.0322950' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (74, 1, N'31b620a3443095ddc18ce188c047418a8268a77a5c45cc748b8f2e0dfc8ae337', CAST(N'2026-07-30T05:04:01.9947810' AS DateTime2), CAST(N'2026-08-13T05:04:01.9918930' AS DateTime2), NULL)
INSERT [dbo].[UserSession] ([Id], [UserRef], [TokenHash], [CreatedAt], [ExpiresAt], [RevokedAt]) VALUES (75, 1, N'9c8e8652f027661976206920b6f5e90e6bac9f4cd05a7a67c78acee808a06309', CAST(N'2026-07-30T05:04:47.5800507' AS DateTime2), CAST(N'2026-08-13T05:04:47.5777650' AS DateTime2), NULL)
SET IDENTITY_INSERT [dbo].[UserSession] OFF
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ__Role__A25C5AA75C4BD754]    Script Date: 7/30/2026 8:54:40 AM ******/
ALTER TABLE [dbo].[Role] ADD UNIQUE NONCLUSTERED 
(
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Branch_Name]    Script Date: 7/30/2026 8:54:40 AM ******/
ALTER TABLE [dbo].[Branch] ADD  CONSTRAINT [IX_Branch_Name] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Language]    Script Date: 7/30/2026 8:54:40 AM ******/
ALTER TABLE [dbo].[Language] ADD  CONSTRAINT [IX_Language] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Course]    Script Date: 7/30/2026 8:54:40 AM ******/
ALTER TABLE [dbo].[Course] ADD  CONSTRAINT [IX_Course] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Level_Language_Code]    Script Date: 7/30/2026 8:54:40 AM ******/
ALTER TABLE [dbo].[Level] ADD  CONSTRAINT [IX_Level_Language_Code] UNIQUE NONCLUSTERED 
(
	[LanguageRef] ASC,
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Teacher]    Script Date: 7/30/2026 8:54:40 AM ******/
ALTER TABLE [dbo].[Teacher] ADD  CONSTRAINT [IX_Teacher] UNIQUE NONCLUSTERED 
(
	[NationalCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_SessionStudent_Unique]    Script Date: 7/30/2026 8:54:40 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_SessionStudent_Unique] ON [dbo].[SessionStudent]
(
	[SessionRef] ASC,
	[StudentRef] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Student]    Script Date: 7/30/2026 8:54:40 AM ******/
ALTER TABLE [dbo].[Student] ADD  CONSTRAINT [IX_Student] UNIQUE NONCLUSTERED 
(
	[NationalCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_AppUser_Username]    Script Date: 7/30/2026 8:54:40 AM ******/
ALTER TABLE [dbo].[AppUser] ADD  CONSTRAINT [UQ_AppUser_Username] UNIQUE NONCLUSTERED 
(
	[Username] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_UserSession_TokenHash]    Script Date: 7/30/2026 8:54:40 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_UserSession_TokenHash] ON [dbo].[UserSession]
(
	[TokenHash] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CourseHistory] ADD  CONSTRAINT [DF_CourseHistory_ChangedBy]  DEFAULT (original_login()) FOR [ChangedBy]
GO
ALTER TABLE [dbo].[CourseHistory] ADD  CONSTRAINT [DF_CourseHistory_ChangedAt]  DEFAULT (sysutcdatetime()) FOR [ChangedAt]
GO
ALTER TABLE [dbo].[Score] ADD  CONSTRAINT [DF_Score_MaxScore]  DEFAULT ((100)) FOR [MaxScore]
GO
ALTER TABLE [dbo].[Score] ADD  CONSTRAINT [DF_Score_CreatedAt]  DEFAULT (sysutcdatetime()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[Role] ADD  CONSTRAINT [DF_Role_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Branch] ADD  CONSTRAINT [DF_Branch_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Branch] ADD  CONSTRAINT [DF_Branch_CreatedAt]  DEFAULT (sysutcdatetime()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[Course] ADD  CONSTRAINT [DF_Course_Creator]  DEFAULT (original_login()) FOR [Creator]
GO
ALTER TABLE [dbo].[Course] ADD  CONSTRAINT [DF_Course_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Course] ADD  CONSTRAINT [DF_Course_IsHighlighted]  DEFAULT ((0)) FOR [IsHighlighted]
GO
ALTER TABLE [dbo].[Course] ADD  CONSTRAINT [DF_Course_CreatedAt]  DEFAULT (sysutcdatetime()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[Level] ADD  CONSTRAINT [DF_Level_SortOrder]  DEFAULT ((0)) FOR [SortOrder]
GO
ALTER TABLE [dbo].[Level] ADD  CONSTRAINT [DF_Level_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Session] ADD  CONSTRAINT [DF_Session_Status]  DEFAULT (N'scheduled') FOR [Status]
GO
ALTER TABLE [dbo].[Session] ADD  CONSTRAINT [DF_Session_IsMakeup]  DEFAULT ((0)) FOR [IsMakeup]
GO
ALTER TABLE [dbo].[Class] ADD  CONSTRAINT [DF_Class_Capacity]  DEFAULT ((15)) FOR [Capacity]
GO
ALTER TABLE [dbo].[Class] ADD  CONSTRAINT [DF_Class_Status]  DEFAULT (N'open') FOR [Status]
GO
ALTER TABLE [dbo].[Class] ADD  CONSTRAINT [DF_Class_ClassType]  DEFAULT (N'group') FOR [ClassType]
GO
ALTER TABLE [dbo].[Class] ADD  CONSTRAINT [DF_Class_CreatedAt]  DEFAULT (sysutcdatetime()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[Teacher] ADD  CONSTRAINT [DF_Teacher_Creator]  DEFAULT (original_login()) FOR [Creator]
GO
ALTER TABLE [dbo].[Teacher] ADD  CONSTRAINT [DF_Teacher_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Teacher] ADD  CONSTRAINT [DF_Teacher_CreatedAt]  DEFAULT (sysutcdatetime()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[SessionStudent] ADD  CONSTRAINT [DF_SessionStudent_AttendanceStatus]  DEFAULT (N'present') FOR [AttendanceStatus]
GO
ALTER TABLE [dbo].[SessionStudent] ADD  CONSTRAINT [DF_SessionStudent_RecordedAt]  DEFAULT (sysutcdatetime()) FOR [RecordedAt]
GO
ALTER TABLE [dbo].[Registration] ADD  CONSTRAINT [DF_Registration_Status]  DEFAULT (N'active') FOR [Status]
GO
ALTER TABLE [dbo].[Registration] ADD  CONSTRAINT [DF_Registration_FinancialStatus]  DEFAULT (N'debtor') FOR [FinancialStatus]
GO
ALTER TABLE [dbo].[Registration] ADD  CONSTRAINT [DF_Registration_CreatedAt]  DEFAULT (sysutcdatetime()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[Payment] ADD  CONSTRAINT [DF_Payment_Status]  DEFAULT (N'paid') FOR [Status]
GO
ALTER TABLE [dbo].[Payment] ADD  CONSTRAINT [DF_Payment_CreatedAt]  DEFAULT (sysutcdatetime()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[Student] ADD  CONSTRAINT [DF_Student_Creator]  DEFAULT (original_login()) FOR [Creator]
GO
ALTER TABLE [dbo].[Student] ADD  CONSTRAINT [DF_Student_PreferredUILanguage]  DEFAULT (N'fa') FOR [PreferredUILanguage]
GO
ALTER TABLE [dbo].[Student] ADD  CONSTRAINT [DF_Student_NotificationsEnabled]  DEFAULT ((1)) FOR [NotificationsEnabled]
GO
ALTER TABLE [dbo].[Student] ADD  CONSTRAINT [DF_Student_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Student] ADD  CONSTRAINT [DF_Student_CreatedAt]  DEFAULT (sysutcdatetime()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[AppUser] ADD  CONSTRAINT [DF_AppUser_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[AppUser] ADD  CONSTRAINT [DF_AppUser_UI]  DEFAULT (N'fa') FOR [PreferredUILanguage]
GO
ALTER TABLE [dbo].[AppUser] ADD  CONSTRAINT [DF_AppUser_Fail]  DEFAULT ((0)) FOR [FailedLoginCount]
GO
ALTER TABLE [dbo].[AppUser] ADD  CONSTRAINT [DF_AppUser_CreatedAt]  DEFAULT (sysutcdatetime()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[UserSession] ADD  CONSTRAINT [DF_UserSession_CreatedAt]  DEFAULT (sysutcdatetime()) FOR [CreatedAt]
GO
ALTER TABLE [dbo].[CourseHistory]  WITH CHECK ADD  CONSTRAINT [FK_CourseHistory_Course] FOREIGN KEY([CourseRef])
REFERENCES [dbo].[Course] ([Id])
GO
ALTER TABLE [dbo].[CourseHistory] CHECK CONSTRAINT [FK_CourseHistory_Course]
GO
ALTER TABLE [dbo].[Score]  WITH CHECK ADD  CONSTRAINT [FK_Score_Registration] FOREIGN KEY([RegistrationRef])
REFERENCES [dbo].[Registration] ([Id])
GO
ALTER TABLE [dbo].[Score] CHECK CONSTRAINT [FK_Score_Registration]
GO
ALTER TABLE [dbo].[Course]  WITH CHECK ADD  CONSTRAINT [FK_Course_Language] FOREIGN KEY([LanguageRef])
REFERENCES [dbo].[Language] ([Id])
GO
ALTER TABLE [dbo].[Course] CHECK CONSTRAINT [FK_Course_Language]
GO
ALTER TABLE [dbo].[Course]  WITH NOCHECK ADD  CONSTRAINT [FK_Course_Level] FOREIGN KEY([LevelRef])
REFERENCES [dbo].[Level] ([Id])
GO
ALTER TABLE [dbo].[Course] CHECK CONSTRAINT [FK_Course_Level]
GO
ALTER TABLE [dbo].[Course]  WITH NOCHECK ADD  CONSTRAINT [FK_Course_Prerequisite] FOREIGN KEY([PrerequisiteCourseRef])
REFERENCES [dbo].[Course] ([Id])
GO
ALTER TABLE [dbo].[Course] CHECK CONSTRAINT [FK_Course_Prerequisite]
GO
ALTER TABLE [dbo].[Level]  WITH CHECK ADD  CONSTRAINT [FK_Level_Language] FOREIGN KEY([LanguageRef])
REFERENCES [dbo].[Language] ([Id])
GO
ALTER TABLE [dbo].[Level] CHECK CONSTRAINT [FK_Level_Language]
GO
ALTER TABLE [dbo].[Session]  WITH CHECK ADD  CONSTRAINT [FK_Session_Class] FOREIGN KEY([ClassRef])
REFERENCES [dbo].[Class] ([Id])
GO
ALTER TABLE [dbo].[Session] CHECK CONSTRAINT [FK_Session_Class]
GO
ALTER TABLE [dbo].[Session]  WITH CHECK ADD  CONSTRAINT [FK_Session_SessionType] FOREIGN KEY([SessionTypeRef])
REFERENCES [dbo].[SessionType] ([Id])
GO
ALTER TABLE [dbo].[Session] CHECK CONSTRAINT [FK_Session_SessionType]
GO
ALTER TABLE [dbo].[Session]  WITH NOCHECK ADD  CONSTRAINT [FK_Session_SubstituteTeacher] FOREIGN KEY([SubstituteTeacherRef])
REFERENCES [dbo].[Teacher] ([Id])
GO
ALTER TABLE [dbo].[Session] CHECK CONSTRAINT [FK_Session_SubstituteTeacher]
GO
ALTER TABLE [dbo].[Class]  WITH NOCHECK ADD  CONSTRAINT [FK_Class_Branch] FOREIGN KEY([BranchRef])
REFERENCES [dbo].[Branch] ([Id])
GO
ALTER TABLE [dbo].[Class] CHECK CONSTRAINT [FK_Class_Branch]
GO
ALTER TABLE [dbo].[Class]  WITH CHECK ADD  CONSTRAINT [FK_Class_Course] FOREIGN KEY([CourseRef])
REFERENCES [dbo].[Course] ([Id])
GO
ALTER TABLE [dbo].[Class] CHECK CONSTRAINT [FK_Class_Course]
GO
ALTER TABLE [dbo].[Class]  WITH CHECK ADD  CONSTRAINT [FK_Class_SessionType] FOREIGN KEY([SessionTypeRef])
REFERENCES [dbo].[SessionType] ([Id])
GO
ALTER TABLE [dbo].[Class] CHECK CONSTRAINT [FK_Class_SessionType]
GO
ALTER TABLE [dbo].[Class]  WITH CHECK ADD  CONSTRAINT [FK_Class_Teacher] FOREIGN KEY([TeacherRef])
REFERENCES [dbo].[Teacher] ([Id])
GO
ALTER TABLE [dbo].[Class] CHECK CONSTRAINT [FK_Class_Teacher]
GO
ALTER TABLE [dbo].[SessionStudent]  WITH CHECK ADD  CONSTRAINT [FK_SessionStudent_Session] FOREIGN KEY([SessionRef])
REFERENCES [dbo].[Session] ([Id])
GO
ALTER TABLE [dbo].[SessionStudent] CHECK CONSTRAINT [FK_SessionStudent_Session]
GO
ALTER TABLE [dbo].[SessionStudent]  WITH CHECK ADD  CONSTRAINT [FK_SessionStudent_Student] FOREIGN KEY([StudentRef])
REFERENCES [dbo].[Student] ([Id])
GO
ALTER TABLE [dbo].[SessionStudent] CHECK CONSTRAINT [FK_SessionStudent_Student]
GO
ALTER TABLE [dbo].[Registration]  WITH NOCHECK ADD  CONSTRAINT [FK_Registration_Class] FOREIGN KEY([ClassRef])
REFERENCES [dbo].[Class] ([Id])
GO
ALTER TABLE [dbo].[Registration] CHECK CONSTRAINT [FK_Registration_Class]
GO
ALTER TABLE [dbo].[Registration]  WITH CHECK ADD  CONSTRAINT [FK_Registration_Course] FOREIGN KEY([CourseRef])
REFERENCES [dbo].[Course] ([Id])
GO
ALTER TABLE [dbo].[Registration] CHECK CONSTRAINT [FK_Registration_Course]
GO
ALTER TABLE [dbo].[Registration]  WITH CHECK ADD  CONSTRAINT [FK_Registration_Student] FOREIGN KEY([Studentref])
REFERENCES [dbo].[Student] ([Id])
GO
ALTER TABLE [dbo].[Registration] CHECK CONSTRAINT [FK_Registration_Student]
GO
ALTER TABLE [dbo].[Payment]  WITH NOCHECK ADD  CONSTRAINT [FK_Payment_Registration] FOREIGN KEY([RegistrationRef])
REFERENCES [dbo].[Registration] ([Id])
GO
ALTER TABLE [dbo].[Payment] CHECK CONSTRAINT [FK_Payment_Registration]
GO
ALTER TABLE [dbo].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_Student] FOREIGN KEY([StudentRef])
REFERENCES [dbo].[Student] ([Id])
GO
ALTER TABLE [dbo].[Payment] CHECK CONSTRAINT [FK_Payment_Student]
GO
ALTER TABLE [dbo].[Student]  WITH NOCHECK ADD  CONSTRAINT [FK_Student_CurrentLevel] FOREIGN KEY([CurrentLevelRef])
REFERENCES [dbo].[Level] ([Id])
GO
ALTER TABLE [dbo].[Student] CHECK CONSTRAINT [FK_Student_CurrentLevel]
GO
ALTER TABLE [dbo].[Student]  WITH NOCHECK ADD  CONSTRAINT [FK_Student_TargetLanguage] FOREIGN KEY([TargetLanguageRef])
REFERENCES [dbo].[Language] ([Id])
GO
ALTER TABLE [dbo].[Student] CHECK CONSTRAINT [FK_Student_TargetLanguage]
GO
ALTER TABLE [dbo].[AppUser]  WITH CHECK ADD  CONSTRAINT [FK_AppUser_Role] FOREIGN KEY([RoleRef])
REFERENCES [dbo].[Role] ([Id])
GO
ALTER TABLE [dbo].[AppUser] CHECK CONSTRAINT [FK_AppUser_Role]
GO
ALTER TABLE [dbo].[AppUser]  WITH CHECK ADD  CONSTRAINT [FK_AppUser_Student] FOREIGN KEY([StudentRef])
REFERENCES [dbo].[Student] ([Id])
GO
ALTER TABLE [dbo].[AppUser] CHECK CONSTRAINT [FK_AppUser_Student]
GO
ALTER TABLE [dbo].[AppUser]  WITH CHECK ADD  CONSTRAINT [FK_AppUser_Teacher] FOREIGN KEY([TeacherRef])
REFERENCES [dbo].[Teacher] ([Id])
GO
ALTER TABLE [dbo].[AppUser] CHECK CONSTRAINT [FK_AppUser_Teacher]
GO
ALTER TABLE [dbo].[UserSession]  WITH CHECK ADD  CONSTRAINT [FK_UserSession_User] FOREIGN KEY([UserRef])
REFERENCES [dbo].[AppUser] ([Id])
GO
ALTER TABLE [dbo].[UserSession] CHECK CONSTRAINT [FK_UserSession_User]
GO
ALTER TABLE [dbo].[Score]  WITH CHECK ADD  CONSTRAINT [CK_Score_ExamType] CHECK  (([ExamType]=N'assignment' OR [ExamType]=N'quiz' OR [ExamType]=N'final' OR [ExamType]=N'midterm' OR [ExamType]=N'placement'))
GO
ALTER TABLE [dbo].[Score] CHECK CONSTRAINT [CK_Score_ExamType]
GO
ALTER TABLE [dbo].[Score]  WITH CHECK ADD  CONSTRAINT [CK_Score_Range] CHECK  (([ScoreValue]>=(0) AND [ScoreValue]<=[MaxScore]))
GO
ALTER TABLE [dbo].[Score] CHECK CONSTRAINT [CK_Score_Range]
GO
ALTER TABLE [dbo].[Course]  WITH CHECK ADD  CONSTRAINT [CK_Course_Cost_NonNegative] CHECK  (([Cost]>=(0)))
GO
ALTER TABLE [dbo].[Course] CHECK CONSTRAINT [CK_Course_Cost_NonNegative]
GO
ALTER TABLE [dbo].[Course]  WITH CHECK ADD  CONSTRAINT [CK_Course_SessionsCount_Positive] CHECK  (([SessionsCount]>(0)))
GO
ALTER TABLE [dbo].[Course] CHECK CONSTRAINT [CK_Course_SessionsCount_Positive]
GO
ALTER TABLE [dbo].[Session]  WITH CHECK ADD  CONSTRAINT [CK_Session_Status] CHECK  (([Status]=N'rescheduled' OR [Status]=N'cancelled' OR [Status]=N'completed' OR [Status]=N'in_progress' OR [Status]=N'scheduled'))
GO
ALTER TABLE [dbo].[Session] CHECK CONSTRAINT [CK_Session_Status]
GO
ALTER TABLE [dbo].[Class]  WITH CHECK ADD  CONSTRAINT [CK_Class_Capacity_NonNegative] CHECK  (([Capacity]>=(0)))
GO
ALTER TABLE [dbo].[Class] CHECK CONSTRAINT [CK_Class_Capacity_NonNegative]
GO
ALTER TABLE [dbo].[Class]  WITH CHECK ADD  CONSTRAINT [CK_Class_ClassType] CHECK  (([ClassType]=N'vip' OR [ClassType]=N'private' OR [ClassType]=N'semi_private' OR [ClassType]=N'group'))
GO
ALTER TABLE [dbo].[Class] CHECK CONSTRAINT [CK_Class_ClassType]
GO
ALTER TABLE [dbo].[Class]  WITH CHECK ADD  CONSTRAINT [CK_Class_Status] CHECK  (([Status]=N'cancelled' OR [Status]=N'finished' OR [Status]=N'in_progress' OR [Status]=N'full' OR [Status]=N'open' OR [Status]=N'draft'))
GO
ALTER TABLE [dbo].[Class] CHECK CONSTRAINT [CK_Class_Status]
GO
ALTER TABLE [dbo].[Teacher]  WITH CHECK ADD  CONSTRAINT [جنسیت مدرس نامعتبر است] CHECK  (([Gender]=(2) OR [Gender]=(1)))
GO
ALTER TABLE [dbo].[Teacher] CHECK CONSTRAINT [جنسیت مدرس نامعتبر است]
GO
ALTER TABLE [dbo].[Teacher]  WITH CHECK ADD  CONSTRAINT [کد ملی مدرس نامعتبر است] CHECK  (([dbo].[CheckNationalCode]([NationalCode])=(1)))
GO
ALTER TABLE [dbo].[Teacher] CHECK CONSTRAINT [کد ملی مدرس نامعتبر است]
GO
ALTER TABLE [dbo].[SessionStudent]  WITH CHECK ADD  CONSTRAINT [CK_SessionStudent_AttendanceStatus] CHECK  (([AttendanceStatus]=N'leave' OR [AttendanceStatus]=N'late' OR [AttendanceStatus]=N'absent' OR [AttendanceStatus]=N'present'))
GO
ALTER TABLE [dbo].[SessionStudent] CHECK CONSTRAINT [CK_SessionStudent_AttendanceStatus]
GO
ALTER TABLE [dbo].[Registration]  WITH CHECK ADD  CONSTRAINT [CK_Registration_FinancialStatus] CHECK  (([FinancialStatus]=N'settled' OR [FinancialStatus]=N'creditor' OR [FinancialStatus]=N'debtor'))
GO
ALTER TABLE [dbo].[Registration] CHECK CONSTRAINT [CK_Registration_FinancialStatus]
GO
ALTER TABLE [dbo].[Registration]  WITH CHECK ADD  CONSTRAINT [CK_Registration_Status] CHECK  (([Status]=N'transferred' OR [Status]=N'withdrawn' OR [Status]=N'completed' OR [Status]=N'frozen' OR [Status]=N'active' OR [Status]=N'pending_approval' OR [Status]=N'pending_payment'))
GO
ALTER TABLE [dbo].[Registration] CHECK CONSTRAINT [CK_Registration_Status]
GO
ALTER TABLE [dbo].[Payment]  WITH CHECK ADD  CONSTRAINT [CK_Payment_Amount_NonNegative] CHECK  (([Amount]>=(0)))
GO
ALTER TABLE [dbo].[Payment] CHECK CONSTRAINT [CK_Payment_Amount_NonNegative]
GO
ALTER TABLE [dbo].[Payment]  WITH CHECK ADD  CONSTRAINT [CK_Payment_Method] CHECK  (([PaymentMethod] IS NULL OR ([PaymentMethod]=N'other' OR [PaymentMethod]=N'installment' OR [PaymentMethod]=N'online' OR [PaymentMethod]=N'card' OR [PaymentMethod]=N'cash')))
GO
ALTER TABLE [dbo].[Payment] CHECK CONSTRAINT [CK_Payment_Method]
GO
ALTER TABLE [dbo].[Payment]  WITH CHECK ADD  CONSTRAINT [CK_Payment_Status] CHECK  (([Status]=N'overdue' OR [Status]=N'partially_paid' OR [Status]=N'refunded' OR [Status]=N'failed' OR [Status]=N'paid' OR [Status]=N'pending' OR [Status]=N'draft'))
GO
ALTER TABLE [dbo].[Payment] CHECK CONSTRAINT [CK_Payment_Status]
GO
ALTER TABLE [dbo].[Student]  WITH CHECK ADD  CONSTRAINT [جنسیت دانشجو نامعتبر است] CHECK  (([Gender]=(2) OR [Gender]=(1)))
GO
ALTER TABLE [dbo].[Student] CHECK CONSTRAINT [جنسیت دانشجو نامعتبر است]
GO
ALTER TABLE [dbo].[Student]  WITH CHECK ADD  CONSTRAINT [کد ملی دانشجو نامعتبر است] CHECK  (([dbo].[CheckNationalCode]([NationalCode])=(1)))
GO
ALTER TABLE [dbo].[Student] CHECK CONSTRAINT [کد ملی دانشجو نامعتبر است]
GO
/****** Object:  Trigger [dbo].[TRG_Course_History]    Script Date: 7/30/2026 8:54:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
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
ALTER TABLE [dbo].[Course] ENABLE TRIGGER [TRG_Course_History]
GO
/****** Object:  Trigger [dbo].[TRG_PreventDeleteCourse]    Script Date: 7/30/2026 8:54:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER TRG_PreventDeleteCourse
ON Course
INSTEAD OF DELETE
AS
UPDATE Course SET IsActive = 0
WHERE Id IN (SELECT Id FROM deleted)
GO
ALTER TABLE [dbo].[Course] ENABLE TRIGGER [TRG_PreventDeleteCourse]
GO
/****** Object:  Trigger [dbo].[TRG_PreventDeleteTeacher]    Script Date: 7/30/2026 8:54:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

    CREATE TRIGGER [dbo].[TRG_PreventDeleteTeacher]
    ON [dbo].[Teacher]
    INSTEAD OF DELETE
    AS
    UPDATE Teacher SET IsActive = 0
    WHERE Id IN (SELECT Id FROM deleted);
    
GO
ALTER TABLE [dbo].[Teacher] ENABLE TRIGGER [TRG_PreventDeleteTeacher]
GO
