USE [DBA]
GO

/****** Object:  Table [dbo].[Servers]    Script Date: 12/11/2025 9:23:58 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Servers](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ServerName] [varchar](100) NOT NULL,
	[IP] [varchar](100) NOT NULL,
	[Port] [int] NOT NULL,
	[Active] [int] NOT NULL,
	[Status] [varchar](100) NULL,
	[Comment] [varchar](100) NULL,
	[Scanned] [datetime2](7) NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Servers] ADD  CONSTRAINT [DF_Servers_Active]  DEFAULT ((1)) FOR [Active]
GO

