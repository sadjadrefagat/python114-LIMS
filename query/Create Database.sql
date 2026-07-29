USE [master]
GO
/*
  اسکریپت اولیه ساخت پایگاه داده LIMDB (نسخه آموزشی قدیمی)
  برای تکمیل اسکیما مطابق SRS فاز ۱، پس از ساخت دیتابیس این فایل را اجرا کنید:
    query/Upgrade Schema Phase1.sql
*/
/****** Object:  Database [LIMDB]    Script Date: 7/22/2026 7:23:53 PM ******/
CREATE DATABASE [LIMDB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'LIMDB', FILENAME = N'F:\LIMS\database\LIMDB.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'LIMDB_log', FILENAME = N'F:\LIMS\database\LIMDB_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [LIMDB] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [LIMDB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [LIMDB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [LIMDB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [LIMDB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [LIMDB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [LIMDB] SET ARITHABORT OFF 
GO
ALTER DATABASE [LIMDB] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [LIMDB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [LIMDB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [LIMDB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [LIMDB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [LIMDB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [LIMDB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [LIMDB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [LIMDB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [LIMDB] SET  DISABLE_BROKER 
GO
ALTER DATABASE [LIMDB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [LIMDB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [LIMDB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [LIMDB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [LIMDB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [LIMDB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [LIMDB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [LIMDB] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [LIMDB] SET  MULTI_USER 
GO
ALTER DATABASE [LIMDB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [LIMDB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [LIMDB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [LIMDB] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [LIMDB] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [LIMDB] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
ALTER DATABASE [LIMDB] SET QUERY_STORE = OFF
GO
USE [LIMDB]
GO
/****** Object:  User [vahideh]    Script Date: 7/22/2026 7:23:53 PM ******/
CREATE USER [vahideh] FOR LOGIN [vahideh] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [saba]    Script Date: 7/22/2026 7:23:53 PM ******/
CREATE USER [saba] FOR LOGIN [saba] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [elyar]    Script Date: 7/22/2026 7:23:53 PM ******/
CREATE USER [elyar] FOR LOGIN [elyar] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [asra]    Script Date: 7/22/2026 7:23:53 PM ******/
CREATE USER [asra] FOR LOGIN [asra] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [arshya]    Script Date: 7/22/2026 7:23:53 PM ******/
CREATE USER [arshya] FOR LOGIN [arshya] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [amirreza]    Script Date: 7/22/2026 7:23:53 PM ******/
CREATE USER [amirreza] FOR LOGIN [amirreza] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [vahideh]
GO
ALTER ROLE [db_owner] ADD MEMBER [saba]
GO
ALTER ROLE [db_owner] ADD MEMBER [elyar]
GO
ALTER ROLE [db_owner] ADD MEMBER [asra]
GO
ALTER ROLE [db_owner] ADD MEMBER [arshya]
GO
ALTER ROLE [db_owner] ADD MEMBER [amirreza]
GO
/****** Object:  UserDefinedFunction [dbo].[CheckNationalCode]    Script Date: 7/22/2026 7:23:53 PM ******/
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
CREATE FUNCTION [dbo].[CheckNationalCode](@NationalCode VARCHAR(10)) RETURNS BIT
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
/****** Object:  Table [dbo].[Class]    Script Date: 7/22/2026 7:23:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Class](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CourseRef] [int] NOT NULL,
	[TeacherRef] [int] NOT NULL,
	[SessionType] [int] NOT NULL,
 CONSTRAINT [PK_Class] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Course]    Script Date: 7/22/2026 7:23:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Course](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LanguageRef] [int] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[SessionsCount] [int] NOT NULL,
	[Cost] [int] NOT NULL,
	[Creator] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Course] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Language]    Script Date: 7/22/2026 7:23:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Language](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Language] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Payment]    Script Date: 7/22/2026 7:23:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Payment](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[StudentRef] [int] NOT NULL,
	[Date] [char](10) NOT NULL,
	[Amount] [int] NOT NULL,
	[PaymentType] [int] NOT NULL,
 CONSTRAINT [PK_Payment] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Registration]    Script Date: 7/22/2026 7:23:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Registration](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Studentref] [int] NOT NULL,
	[CourseRef] [int] NOT NULL,
	[Date] [char](10) NOT NULL,
 CONSTRAINT [PK_Registration] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SessionType]    Script Date: 7/22/2026 7:23:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SessionType](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_SessionType] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Student]    Script Date: 7/22/2026 7:23:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Student](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[FatherName] [nvarchar](50) NOT NULL,
	[NationalCode] [varchar](10) NOT NULL,
	[Gender] [int] NOT NULL,
	[BirthDate] [char](10) NOT NULL,
	[Mobile] [varchar](50) NOT NULL,
	[Creator] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Student] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Teacher]    Script Date: 7/22/2026 7:23:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Teacher](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[FatherName] [nvarchar](50) NULL,
	[NationalCode] [varchar](10) NOT NULL,
	[Gender] [int] NOT NULL,
	[BirthDate] [char](10) NULL,
	[Creator] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Teacher] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[Course] ON 

INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (1, 1, N'دوره فشرده انگلیسی برای کارمندان', 30, 50000000, N'Sadjad-PC\Sadjad')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (3, 2, N'دوره ی آموزش زبان برای کودکان', 40, 35000000, N'vahideh')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (7, 2, N'دوره ی فشرده ی آموزش زبان فرانسه در 60 جلسه', 60, 50000000, N'vahideh')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (8, 1, N'دوره فشرده تافل برای بزرگسالان', 25, 35000000, N'saba')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (9, 1, N'دوره زبان انگلیسی برای نونهالان', 20, 20000000, N'saba')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (10, 2, N'دوره فشورده فرانسوی برای کارمندان', 30, 50000000, N'arshya')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (11, 1, N'دوره فشرده انگلیسی', 40, 900000, N'elyar')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (12, 2, N'دوره فشرده فرانسوی', 40, 1200000, N'elyar')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (17, 2, N'دوره زبان فرانسه برای کارمندان', 30, 50000000, N'asra')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (18, 1, N'دوره فشرده تافل برای کودکان', 30, 50000000, N'asra')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (32, 1, N'دوره نیمه فشرده انگلیسی', 40, 900000, N'elyar')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (33, 2, N'دوره نیمه فشرده فرانسوی', 40, 1200000, N'elyar')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (37, 3, N'دوره ی آموزش زبان ایتالیایی', 30, 42000000, N'vahideh')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (38, 4, N'دوره ی آموزش زبان آلمانی', 30, 42000000, N'vahideh')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (39, 2, N'دوره زبان فرانسوی برای بانوان خانه دار', 30, 45000000, N'saba')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (43, 1, N'دوره نیمه فشرده 90 جلسه ای انگلیسی', 40, 900000, N'elyar')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (44, 2, N'دوره نیمه فشرده80  جلسه ای فرانسوی', 40, 1200000, N'elyar')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (45, 2, N'ترم یک  فرانسوی', 20, 1000000, N'elyar')
INSERT [dbo].[Course] ([Id], [LanguageRef], [Name], [SessionsCount], [Cost], [Creator]) VALUES (46, 1, N'دوره آموزش رایتینگ تافل', 20, 3000000, N'amirreza')
SET IDENTITY_INSERT [dbo].[Course] OFF
GO
SET IDENTITY_INSERT [dbo].[Language] ON 

INSERT [dbo].[Language] ([Id], [Name]) VALUES (4, N'آلمانی')
INSERT [dbo].[Language] ([Id], [Name]) VALUES (1, N'انگلیسی')
INSERT [dbo].[Language] ([Id], [Name]) VALUES (3, N'ایتالیایی')
INSERT [dbo].[Language] ([Id], [Name]) VALUES (2, N'فرانسوی')
SET IDENTITY_INSERT [dbo].[Language] OFF
GO
SET IDENTITY_INSERT [dbo].[Registration] ON 

INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date]) VALUES (1, 1, 1, N'1405/04/31')
INSERT [dbo].[Registration] ([Id], [Studentref], [CourseRef], [Date]) VALUES (2, 2, 1, N'1405/04/30')
SET IDENTITY_INSERT [dbo].[Registration] OFF
GO
SET IDENTITY_INSERT [dbo].[SessionType] ON 

INSERT [dbo].[SessionType] ([Id], [Name]) VALUES (1, N'حضوری')
INSERT [dbo].[SessionType] ([Id], [Name]) VALUES (2, N'آنلاین')
INSERT [dbo].[SessionType] ([Id], [Name]) VALUES (3, N'نیمه حضوری')
INSERT [dbo].[SessionType] ([Id], [Name]) VALUES (4, N'آفلاین')
SET IDENTITY_INSERT [dbo].[SessionType] OFF
GO
SET IDENTITY_INSERT [dbo].[Student] ON 

INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (1, N'سجاد', N'رفاقت', N'اکبر', N'1377392759', 2, N'1359/09/16', N'09145041648', N'Sadjad-PC\Sadjad')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (2, N'علی', N'احمدی', N'رضا', N'3259124411', 2, N'1390/02/20', N'09123456781', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (3, N'علی', N'فیروزی', N'جعفر', N'1365091600', 2, N'1388/12/30', N'09204917841', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (4, N'آیلار', N'محمدی', N'صمد', N'4444943191', 1, N'1380/1/24 ', N'09145879642', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (6, N'سمانه', N'علیار', N'جواد', N'9246272951', 1, N'1385/12/06', N'09145875798', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (7, N'مریم', N'حسینی', N'رضا', N'5462722109', 1, N'1391/02/20', N'09351246789', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (8, N'یاسین', N'پورنصر', N'بهزاد', N'1898415978', 2, N'1390/10/16', N'09146247798', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (9, N'آنیا', N'کامروا', N'ایلیا', N'9051780699', 1, N'1391/04/06', N'09146223498', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (10, N'زهرا', N'محمدی', N'بابک', N'7458834323', 1, N'1395/03/20', N'09901234567', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (11, N'امیرمحمد', N'رضایی', N'احمد', N'4816927999', 1, N'1388/07/29', N'09146201587', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (12, N'اسرا', N'رهبران', N'سعید', N'1364932032', 1, N'1388/01/11', N'09928698775', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (13, N'سینا', N'کاظمی', N'کریم', N'3405377821', 2, N'1393/06/20', N'09187654321', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (19, N'سینا', N'رفاقت', N'علی اکبر', N'2673180400', 2, N'1385/06/20', N'09914567812', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (21, N'سمانه', N'رسولی', N'علی', N'1487479700', 1, N'1358/06/31', N'09928776554', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (22, N'احمد', N'نوری', N'اصغر', N'9731378286', 2, N'1390/08/28', N'09145024965', N'elyar')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (23, N'اسما', N'اصغری', N'احد', N'3970357403', 1, N'1385/11/22', N'09148347294', N'elyar')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (24, N'احد', N'باقری', N'علی', N'0704041261', 2, N'1380/05/15', N'09147294885', N'elyar')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (25, N'رها', N'نوریان', N'احمد', N'5141202054', 1, N'1350/11/30', N'09935817556', N'elyar')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (26, N'رضا', N'باقر زاده', N'باقر', N'5577380911', 2, N'1359/02/15', N'03995841557', N'elyar')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (27, N'آرش', N'شریفی', N'محمد علی', N'8749702165', 2, N'1387/11/23', N'09141141382', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (44, N'آرتین', N'وصلی', N'حبیب', N'4342010658', 2, N'1388/07/29', N'09146254587', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (45, N'ایلیا', N'رسولیان', N'علیرضا', N'2678458725', 2, N'1320/07/01', N'09934567676', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (46, N'بابک', N'بدری', N'رسول', N'2699165069', 2, N'1392/01/13', N'09146249187', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (50, N'عطا', N'ذوقی', N'عبادالله', N'8711550066', 2, N'1389/03/23', N'09146244127', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (59, N'امیر', N'ذوقی', N'عبادالله', N'5073699440', 2, N'1374/10/07', N'09146243636', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (60, N'احمد', N'نوری', N'اصغر', N'2495334962', 2, N'1390/08/28', N'09145024965', N'elyar')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (61, N'اسما', N'اصغری', N'احد', N'0421584505', 1, N'1385/11/22', N'09148347294', N'elyar')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (62, N'احد', N'باقری', N'علی', N'7129761717', 2, N'1380/05/15', N'09147294885', N'elyar')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (63, N'رها', N'نوریان', N'احمد', N'5289595211', 1, N'1350/11/30', N'09935817556', N'elyar')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (64, N'رضا', N'باقر زاده', N'باقر', N'2111000019', 2, N'1359/02/15', N'03995841557', N'elyar')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (65, N'سعید', N'باقر زاده', N'رضا', N'5265895061', 2, N'1368/05/31', N'09335842515', N'elyar')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (66, N'ماهان', N'رضایی', N'بهرام', N'5465621885', 2, N'1388/10/07', N'09146212636', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (67, N'اشکان', N'رنجبر', N'ارش', N'7887961505', 2, N'1368/05/08', N'09144444994', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (69, N'مهنا', N'آریانی', N'آراز', N'8934812621', 1, N'1389/09/17', N'09144392636', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (70, N'پارسا', N'رنجبری', N'جعفر', N'4760230696', 2, N'1384/04/04', N'09123455454', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (72, N'مهیا', N'حسینی', N'سجاد', N'4546324741', 1, N'1389/11/04', N'09144391467', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (73, N'پارسایی', N'رنجبریان', N'جعفری', N'9504625681', 2, N'1311/11/11', N'09145674332', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (74, N'اسماء', N'واحد', N'محمد', N'3203156148', 1, N'1394/08/08', N'09146791467', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (76, N'علی', N'داداش زاده', N'قاسم', N'0319929991', 2, N'1377/11/12', N'09146661551', N'arshya')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (77, N'ترانه', N'دانشور', N'علی', N'8985216317', 1, N'1393/07/12', N'09146791467', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (79, N'علی', N'فیروزی', N'جعفر', N'0111010004', 2, N'1388/12/30', N'09204917841', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (80, N'جعفر', N'دلریش', N'قاسم', N'0000011101', 2, N'1365/12/30', N'03855454545', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (81, N'محمدرضا', N'خلعتبری', N'محسن', N'0001110101', 2, N'1368/12/2 ', N'09145145200', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (82, N'شهریار', N'مغانلو', N'رضا', N'8542011104', 2, N'1368/12/2 ', N'092457845123', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (83, N'مرتضی', N'تبریزی', N'حمید', N'1101100001', 2, N'1380/1/2  ', N'092457845123', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (84, N'نیما', N'خدایی', N'احمد', N'0741753456', 2, N'1380/06/12', N'09923456565', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (85, N'یسنا', N'راد', N'علی', N'4001366053', 1, N'1389/07/27', N'09146791467', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (86, N'مسعود', N'میر سیدی', N'عزیز', N'3453998065', 2, N'1387/01/02', N'09046361641', N'arshya')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (87, N'سودا', N'عبادی', N'مرسل', N'0010934391', 1, N'1387/10/18', N'09938767667', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (89, N'سونیا', N'عبادیان', N'سجاد', N'8295846094', 1, N'1347/10/28', N'09989878777', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (92, N'سالار', N'مدنی', N'اکبر', N'5405674508', 2, N'1381/03/12', N'09308031129', N'arshya')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (95, N'جولیا', N'عبادیان', N'حمید', N'1639751602', 1, N'1367/04/08', N'09928786565', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (96, N'مبین', N'بهینه', N'مهدی', N'8131608921', 2, N'1382/06/11', N'09308031129', N'arshya')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (97, N'انجلی', N'جولی', N'رضا', N'9345784780', 1, N'1367/08/07', N'09987656565', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (98, N'بهار', N'راهور', N'آرش', N'2859673709', 1, N'1350/03/14', N'9364978521', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (99, N'برد', N'پیت', N'رضا', N'5968881089', 2, N'1367/01/01', N'09923455454', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (101, N'الهام', N'علی پور', N'مرتضی', N'8931479093', 1, N'1389/10/30', N'09369901213', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (112, N'لیلا', N'قانونی', N'مرتضی', N'2504205899', 1, N'1389/10/10', N'09369903313', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (113, N'عبدل مالک', N'فاقدی', N'کاظم', N'2652926373', 2, N'1369/08/01', N'09145481453', N'arshya')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (114, N'سوینن', N'طایف', N'رضا', N'3202230115', 2, N'1367/01/01', N'09928676554', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (115, N'علی', N'فیروزی', N'جعفر', N'9011111109', 2, N'1388/12/30', N'09204917841', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (116, N'جعفر', N'دلریش', N'قاسم', N'2001001010', 2, N'1365/12/30', N'03855454545', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (117, N'محمدرضا', N'خلعتبری', N'محسن', N'7100110017', 2, N'1368/12/2 ', N'09145145200', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (118, N'شهریار', N'مغانلو', N'رضا', N'6633024274', 2, N'1368/12/2 ', N'092457845123', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (119, N'کریم', N'باقری', N'غلامعلی', N'1110111002', 2, N'1380/1/24 ', N'092457845121', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (120, N'مرتضی', N'تبریزی', N'حمید', N'0001011103', 2, N'1380/11/30', N'092457822223', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (121, N'حمید', N'درخشان', N'محمود', N'7010011109', 2, N'1380/12/20', N'092444444423', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (122, N'سیروس', N'دین محمدی', N'مصطفی', N'7101000010', 2, N'1380/2/19 ', N'091457845123', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (123, N'محمد', N'طیبی', N'حسن', N'8110010113', 2, N'1380/12/2 ', N'091757845123', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (124, N'نادر', N'محمدی', N'ناصر', N'0011110015', 2, N'1380/7/2  ', N'092887845123', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (125, N'محسن', N'فروزان', N'حمید', N'9311011101', 2, N'1380/8/11 ', N'090257845123', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (126, N'حسین', N'حسینی', N'حسن', N'9301011018', 2, N'1380/1/8  ', N'098457845123', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (127, N'سیروس', N'قایق ران', N'حمید', N'5201100104', 2, N'1380/2/2  ', N'094257845123', N'amirreza')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (128, N'ماهان', N'زارعی', N'مجتبی', N'9459402577', 2, N'1389/09/10', N'09142502253', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (131, N'شکیرا', N'ایزابل', N'مکس', N'1068301163', 2, N'1359/01/01', N'09923455656', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (132, N'میلاد', N'بابایی', N'حسین', N'8407229202', 2, N'1386/08/12', N'09143802253', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (133, N'صمیرا', N'صمیرایی', N'مکس', N'4690197717', 1, N'1359/01/01', N'09928798776', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (134, N'محنا', N'معارفی', N'امیر', N'9143077862', 1, N'1386/08/12', N'09363802253', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (135, N'دریا', N'دیرباز', N'حسن', N'2053348658', 1, N'1375/12/14', N'9364912321', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (136, N'عباسعلی', N'براتی', N'علمی زاده', N'7448206540', 2, N'1365/12/21', N'09301545325', N'arshya')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (137, N'بیلی', N'ایلیش', N'مکس', N'8952885236', 1, N'1359/01/01', N'09923455454', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (138, N'ثنا', N'کرمانی', N'رضا', N'4296905521', 1, N'1386/08/21', N'09384002253', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (139, N'کامران', N'شاهد', N'حسین', N'1394557442', 2, N'1386/05/01', N'9364912321', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (140, N'ترویس', N'اسکات', N'مکس', N'1111011117', 2, N'1369/01/01', N'09998887799', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (141, N'نگار', N'یوسفی', N'شایان', N'9510228745', 1, N'1385/08/21', N'09384009998', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (143, N'احمد', N'زارع', N'محمدعلی', N'7318415549', 2, N'1368/06/21', N'9363568321', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (144, N'مدونا', N'اسکات', N'مکس', N'7294633691', 1, N'1379/11/01', N'09928767676', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (145, N'حمیده', N'زارع', N'محمدعلی', N'2665190710', 1, N'1368/06/21', N'9363567521', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (146, N'هانیه', N'زمانی', N'احسان', N'5203472203', 1, N'1385/06/21', N'09141189298', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (147, N'قزبس', N'مشهدی', N'حمزه', N'2758282801', 1, N'1366/07/11', N'09961238470', N'arshya')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (148, N'زهرا', N'امینی', N'علی', N'9680241904', 1, N'1384/05/21', N'09141182768', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (149, N'معصومه', N'علیزاده', N'امیر', N'1981742182', 1, N'1384/08/28', N'9363567521', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (150, N'کایلی', N'مکسول', N'جک', N'8880047728', 1, N'1379/11/01', N'09983455353', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (155, N'پریسا', N'باقرپور', N'سعید', N'9407995089', 1, N'1384/05/28', N'09141912768', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (156, N'ناصر', N'ملکی', N'محمد', N'8402251951', 2, N'1393/02/03', N'9363154821', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (161, N'زینب', N'ابراهیم زاده', N'سعید', N'8028551637', 1, N'1375/03/28', N'09141915768', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (162, N'رویا', N'مکسولی', N'جک', N'6807361882', 1, N'1379/11/01', N'09988768776', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (163, N'جواد', N'ناصری', N'جلال', N'5826044111', 2, N'1395/11/26', N'9353154821', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (164, N'بایرامعلی', N'سرخی ', N'مرقوب', N'1554357640', 2, N'1376/01/05', N'09142738772', N'arshya')
GO
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (165, N'ناردین', N'کریمی', N'مهدی', N'6405922715', 1, N'1378/04/09', N'09121915768', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (166, N'رها', N'زند', N'سیروس', N'2094321401', 1, N'1390/09/09', N'9903154821', N'vahideh')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (167, N'جان', N'اسنو', N'ند', N'9334800615', 2, N'1379/11/01', N'09987656565', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (173, N'نرگس', N'مرتضوی', N'مهدی', N'8260527103', 1, N'1372/04/09', N'09371916668', N'saba')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (176, N'اریا', N'استارک', N'ند', N'4460185954', 1, N'1379/11/01', N'09989879887', N'asra')
INSERT [dbo].[Student] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Mobile], [Creator]) VALUES (188, N'پویا', N'مرادی', N'محمدرضا', N'3664257340', 2, N'1382/04/09', N'09379122272', N'saba')
SET IDENTITY_INSERT [dbo].[Student] OFF
GO
SET IDENTITY_INSERT [dbo].[Teacher] ON 

INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (1, N'سجاد', N'رفاقت', N'اکبر', N'1377392759', 2, N'1359/09/16', N'Sadjad-PC\Sadjad')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (5, N'امید', N'رهبری', NULL, N'4395680186', 2, N'1375/01/19', N'saba')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (7, N'الیار', N'نورنواز', N'رضا', N'9958105977', 2, N'1368/11/25', N'elyar')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (8, N'اسما', N'نوری', N'احد', N'3200110015', 1, N'1358/02/16', N'elyar')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (9, N'زهرا', N'حبیبی', NULL, N'5254754109', 1, N'1379/12/22', N'saba')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (11, N'سبا', N'دلجوان', NULL, N'9072608895', 1, N'1383/01/31', N'saba')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (13, N'حامد', N'صمدی', N'محمد', N'7696488724', 2, N'1370/11/30', N'vahideh')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (16, N'سارا', N'رحیمی', N'اشکان', N'1364932032', 1, N'1368/06/26', N'asra')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (17, N'الیار', N'نورنواز', N'رضا', N'4321000106', 2, N'1350/12/20', N'elyar')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (18, N'اسما', N'نوری', N'احد', N'6702220847', 1, N'1369/07/15', N'elyar')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (19, N'احمد', N'اصغری', N'علی', N'6100001111', 2, N'1369/08/26', N'elyar')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (21, N'فاطمه', N'سیفی', N'حمید', N'1083143786', 1, N'1367/10/28', N'vahideh')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (23, N'مینا', N'محبی', N'رسول', N'8920522693', 1, N'1359/10/15', N'vahideh')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (24, N'علی', N'اکبری', N'امیر', N'3901081828', 2, N'1372/02/02', N'saba')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (26, N'مهدی', N'امامی', N'محمد', N'1365207447', 1, N'1378/10/12', N'arshya')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (27, N'صابر', N'معصومی', N'صمد', N'4952913961', 2, N'1383/08/18', N'vahideh')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (28, N'محمد', N'قاسمی', N'میثم', N'8506687640', 2, N'1368/03/25', N'saba')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (31, N'سعید', N'علیون', N'رضا', N'1365091600', 2, N'1360/11/15', N'amirreza')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (38, N'اصغر', N'نوریان', N'رضا', N'1111010013', 2, N'1381/10/15', N'elyar')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (39, N'اسما', N'نوری', N'احد', N'7181590073', 1, N'1382/06/20', N'elyar')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (40, N'احمد', N'اصغری', N'علی', N'3741944270', 2, N'1377/02/15', N'elyar')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (41, N'رها', N'احمدی', N'اصغر', N'4110100100', 1, N'1380/01/15', N'elyar')
INSERT [dbo].[Teacher] ([Id], [FirstName], [LastName], [FatherName], [NationalCode], [Gender], [BirthDate], [Creator]) VALUES (42, N'هلیا', N'حیدری', N'علی', N'5456769123', 2, N'1381/06/26', N'saba')
SET IDENTITY_INSERT [dbo].[Teacher] OFF
GO
SET ANSI_PADDING ON
GO

INSERT [dbo].[Class] ([CourseRef] ,[TeacherRef],[SessionType]) VALUES(46,13,1)
INSERT [dbo].[Class] ([CourseRef] ,[TeacherRef],[SessionType]) VALUES(9,21,2)
INSERT [dbo].[Class] ([CourseRef] ,[TeacherRef],[SessionType]) VALUES(11,5,1)
INSERT [dbo].[Class] ([CourseRef] ,[TeacherRef],[SessionType]) VALUES(32,31,3)
INSERT [dbo].[Class] ([CourseRef] ,[TeacherRef],[SessionType]) VALUES(7,42,1)
INSERT [dbo].[Class] ([CourseRef] ,[TeacherRef],[SessionType]) VALUES(10,8,2)
INSERT [dbo].[Class] ([CourseRef] ,[TeacherRef],[SessionType]) VALUES(46,13,1)
INSERT [dbo].[Class] ([CourseRef] ,[TeacherRef],[SessionType]) VALUES(9,21,2)
INSERT [dbo].[Class] ([CourseRef] ,[TeacherRef],[SessionType]) VALUES(11,5,1)
INSERT [dbo].[Class] ([CourseRef] ,[TeacherRef],[SessionType]) VALUES(32,31,3)
INSERT [dbo].[Class] ([CourseRef] ,[TeacherRef],[SessionType]) VALUES(7,42,1)
INSERT [dbo].[Class] ([CourseRef] ,[TeacherRef],[SessionType]) VALUES(10,8,2)
INSERT [dbo].[Class] ([CourseRef] ,[TeacherRef],[SessionType]) VALUES(7,8,2)
GO
/****** Object:  Index [IX_Course]    Script Date: 7/22/2026 7:23:53 PM ******/
ALTER TABLE [dbo].[Course] ADD  CONSTRAINT [IX_Course] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Language]    Script Date: 7/22/2026 7:23:53 PM ******/
ALTER TABLE [dbo].[Language] ADD  CONSTRAINT [IX_Language] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Student]    Script Date: 7/22/2026 7:23:53 PM ******/
ALTER TABLE [dbo].[Student] ADD  CONSTRAINT [IX_Student] UNIQUE NONCLUSTERED 
(
	[NationalCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Teacher]    Script Date: 7/22/2026 7:23:53 PM ******/
ALTER TABLE [dbo].[Teacher] ADD  CONSTRAINT [IX_Teacher] UNIQUE NONCLUSTERED 
(
	[NationalCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Course] ADD  CONSTRAINT [DF_Course_Creator]  DEFAULT (original_login()) FOR [Creator]
GO
ALTER TABLE [dbo].[Student] ADD  CONSTRAINT [DF_Student_Creator]  DEFAULT (original_login()) FOR [Creator]
GO
ALTER TABLE [dbo].[Teacher] ADD  CONSTRAINT [DF_Teacher_Creator]  DEFAULT (original_login()) FOR [Creator]
GO
ALTER TABLE [dbo].[Class]  WITH CHECK ADD  CONSTRAINT [FK_Class_Course] FOREIGN KEY([CourseRef])
REFERENCES [dbo].[Course] ([Id])
GO
ALTER TABLE [dbo].[Class] CHECK CONSTRAINT [FK_Class_Course]
GO
ALTER TABLE [dbo].[Class]  WITH CHECK ADD  CONSTRAINT [FK_Class_SessionType] FOREIGN KEY([SessionType])
REFERENCES [dbo].[SessionType] ([Id])
GO
ALTER TABLE [dbo].[Class] CHECK CONSTRAINT [FK_Class_SessionType]
GO
ALTER TABLE [dbo].[Class]  WITH CHECK ADD  CONSTRAINT [FK_Class_Teacher] FOREIGN KEY([TeacherRef])
REFERENCES [dbo].[Teacher] ([Id])
GO
ALTER TABLE [dbo].[Class] CHECK CONSTRAINT [FK_Class_Teacher]
GO
ALTER TABLE [dbo].[Course]  WITH CHECK ADD  CONSTRAINT [FK_Course_Language] FOREIGN KEY([LanguageRef])
REFERENCES [dbo].[Language] ([Id])
GO
ALTER TABLE [dbo].[Course] CHECK CONSTRAINT [FK_Course_Language]
GO
ALTER TABLE [dbo].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_Student] FOREIGN KEY([StudentRef])
REFERENCES [dbo].[Student] ([Id])
GO
ALTER TABLE [dbo].[Payment] CHECK CONSTRAINT [FK_Payment_Student]
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
ALTER TABLE [dbo].[Student]  WITH CHECK ADD  CONSTRAINT [جنسیت دانشجو نامعتبر است] CHECK  (([Gender]=(2) OR [Gender]=(1)))
GO
ALTER TABLE [dbo].[Student] CHECK CONSTRAINT [جنسیت دانشجو نامعتبر است]
GO
ALTER TABLE [dbo].[Student]  WITH CHECK ADD  CONSTRAINT [کد ملی دانشجو نامعتبر است] CHECK  (([dbo].[CheckNationalCode]([NationalCode])=(1)))
GO
ALTER TABLE [dbo].[Student] CHECK CONSTRAINT [کد ملی دانشجو نامعتبر است]
GO
ALTER TABLE [dbo].[Teacher]  WITH CHECK ADD  CONSTRAINT [جنسیت مدرس نامعتبر است] CHECK  (([Gender]=(2) OR [Gender]=(1)))
GO
ALTER TABLE [dbo].[Teacher] CHECK CONSTRAINT [جنسیت مدرس نامعتبر است]
GO
ALTER TABLE [dbo].[Teacher]  WITH CHECK ADD  CONSTRAINT [کد ملی مدرس نامعتبر است] CHECK  (([dbo].[CheckNationalCode]([NationalCode])=(1)))
GO
ALTER TABLE [dbo].[Teacher] CHECK CONSTRAINT [کد ملی مدرس نامعتبر است]
GO
USE [master]
GO
ALTER DATABASE [LIMDB] SET  READ_WRITE 
GO
