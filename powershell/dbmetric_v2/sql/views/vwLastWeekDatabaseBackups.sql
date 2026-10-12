USE [DBA]
GO

/****** Object:  View [dbo].[vwLastWeekDatabaseBackups]    Script Date: 12/11/2025 9:25:08 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[vwLastWeekDatabaseBackups] AS (
SELECT
	J.SqlInstance,
	S.Comment,
	J.JobName,
	J.Status,
	FORMAT(J.StartDate, 'yyyy-MM-dd HH:mm:ss') AS StartDate,
	FORMAT(J.EndDate, 'yyyy-MM-dd HH:mm:ss') as EndDate,
	CONVERT(VARCHAR(8), DATEADD(second, DATEDIFF(second, J.StartDate, J.EndDate), 0), 108 ) as RunTimeHHMMSS
FROM
	Jobs AS J
	JOIN Servers AS S on S.ServerName = J.ServerName
WHERE
	StartDate >= DATEADD(DAY,-7,GETDATE())
	AND JobName LIKE '%backup%' 
	AND JobName like '%full%'
	AND JobName NOT LIKE '%system%'
)

GO

