USE [DBA]
GO

/****** Object:  Table [dbo].[Jobs]    Script Date: 12/11/2025 9:23:36 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Jobs](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ServerName] [nvarchar](100) NULL,
	[InstanceName] [nvarchar](100) NULL,
	[SqlInstance] [nvarchar](100) NULL,
	[JobName] [nvarchar](100) NULL,
	[StartDate] [datetime2](7) NULL,
	[EndDate] [datetime2](7) NULL,
	[Status] [nvarchar](max) NULL,
	[Message] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

