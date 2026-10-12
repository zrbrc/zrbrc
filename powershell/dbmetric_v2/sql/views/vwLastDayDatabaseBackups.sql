USE [DBA]
GO

/****** Object:  View [dbo].[vwLastDayDatabaseBackups]    Script Date: 12/11/2025 9:24:51 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE     VIEW [dbo].[vwLastDayDatabaseBackups] AS (
SELECT
	  SqlInstance,
      Comment,
      JobName,
      Status,
      StartDate,
      EndDate,
      RunTimeHHMMSS
FROM
	vwLastWeekDatabaseBackups
WHERE
	StartDate >= DATEADD(DAY,-1,GETDATE())
)

GO

