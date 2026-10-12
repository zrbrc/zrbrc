USE [DBA]
GO

/****** Object:  Table [dbo].[Instances]    Script Date: 12/11/2025 9:23:29 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Instances](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Timestamp] [datetime2](7) NOT NULL,
	[Domain] [varchar](100) NOT NULL,
	[ServerName] [varchar](100) NOT NULL,
	[IP] [varchar](100) NOT NULL,
	[OS] [varchar](100) NULL,
	[Product] [varchar](100) NULL,
	[Version] [varchar](100) NULL,
	[SP] [varchar](100) NULL,
	[CU] [varchar](100) NULL,
	[Instance] [varchar](100) NULL,
	[Port] [varchar](100) NULL,
	[HistoryCode] [int] NOT NULL,
	[CoreCount] [int] NULL,
	[MemoryMB] [int] NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Instances] ADD  CONSTRAINT [DF_InstancesNew_HistoryCode]  DEFAULT ((0)) FOR [HistoryCode]
GO

