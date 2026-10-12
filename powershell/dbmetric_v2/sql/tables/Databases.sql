USE [DBA]
GO

/****** Object:  Table [dbo].[Databases]    Script Date: 12/11/2025 9:23:06 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Databases](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Timestamp] [datetime2](7) NULL,
	[ServerName] [varchar](100) NULL,
	[DatabaseName] [varchar](100) NULL,
	[DatabaseID] [int] NULL,
	[State] [varchar](100) NULL,
	[SizeMB] [varchar](100) NULL,
	[SizeGB] [varchar](100) NULL,
	[AgName] [varchar](100) NULL,
	[RoleDesc] [varchar](100) NULL,
	[HistoryCode] [int] NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Databases] ADD  CONSTRAINT [DF_Databases_HistoryCode]  DEFAULT ((0)) FOR [HistoryCode]
GO

