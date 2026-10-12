USE [DBA]
GO

/****** Object:  View [dbo].[vwAllInstances]    Script Date: 12/11/2025 9:24:26 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE     VIEW [dbo].[vwAllInstances] AS
(
SELECT
	S.Comment,
	S.Servername,
	S.IP,
	I.Domain,
	I.OS,
	I.CoreCount,
	I.MemoryMB,
	I.Product,
	I.Version,
	I.SP,
	I.CU,
	I.Instance,
	I.Port
FROM
	Servers AS S
	LEFT JOIN Instances AS I ON S.ServerName = I.ServerName AND S.Port = I.Port
WHERE
	HistoryCode = 0 OR HistoryCode IS NULL
)
GO

