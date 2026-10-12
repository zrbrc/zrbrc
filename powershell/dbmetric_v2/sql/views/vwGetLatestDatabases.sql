USE [DBA]
GO

/****** Object:  View [dbo].[vwGetLatestDatabases]    Script Date: 12/11/2025 9:24:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vwGetLatestDatabases] AS (
SELECT
	*
FROM
	Databases
WHERE
	HistoryCode = 0

)
GO

