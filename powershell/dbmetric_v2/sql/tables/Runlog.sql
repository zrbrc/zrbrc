USE [DBA]
GO

/****** Object:  Table [dbo].[Runlog]    Script Date: 12/11/2025 9:23:50 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Runlog](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RunTime] [datetime2](7) NOT NULL,
	[ServerName] [nvarchar](100) NOT NULL,
	[Metric] [nvarchar](100) NOT NULL
) ON [PRIMARY]
GO

