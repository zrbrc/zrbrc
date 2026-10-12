USE [db_DollarUniverse_PROD]
GO

/****** Object:  Table [dbo].[Objects]    Script Date: 11/20/2020 9:20:04 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Objects](
	[Node] [nvarchar](250) NULL,
	[Area] [nvarchar](250) NULL,
	[TaskName] [nvarchar](250) NULL,
	[TaskLabel] [nvarchar](250) NULL,
	[MU] [nvarchar](250) NULL,
	[Schedule] [nvarchar](250) NULL,
	[StartTime] [nvarchar](250) NULL
)


