SELECT
	DATEADD(SECOND, FileSize.Timestamp * 5, '20000101 00:00:00') AS Timestamp,
	Conn.ObjectName,
	PASF.DatabaseID,
	PASD.Name AS DatabaseName,
	PASF.FileID,
	PASF.Name,
	PASF.FileName,
	FORMAT(FileSize.Value, 'N0') AS TotalSize,
	CASE FileSize.PerformanceAnalysisCounterID WHEN 251 THEN 'DATA' WHEN 253 THEN 'LOG' END as FileType
FROM 
	dbo.PerformanceAnalysisDataRollup12 AS FileSize WITH (NOLOCK)
	JOIN PerformanceAnalysisSqlFile AS PASF ON PASF.EventSourceConnectionID = FileSize.EventSourceConnectionID 
	JOIN PerformanceAnalysisSqlDatabase AS PASD ON PASD.DatabaseID = PASF.DatabaseID AND PASD.EventSourceConnectionID = PASF.EventSourceConnectionID
	JOIN dbo.EventSourceConnection AS Conn ON Conn.ID = FileSize.EventSourceConnectionID 
		AND (convert(varchar(10),PASF.EventSourceConnectionID) + ',' + convert(varchar(10),PASF.DatabaseID) + ',' + convert(varchar(10),PASF.FileID))=FileSize.InstanceName
WHERE 
	FileSize.PerformanceAnalysisCounterID in (251,253)
	AND FileSize.Timestamp >= dbo.fnConvertDateTimeToTimestamp('2025-01-01')
	AND FileSize.Timestamp <= dbo.fnConvertDateTimeToTimestamp('2026-03-01')
	AND PASD.CreatedDate <= dbo.fnConvertTimestampToDateTime(FileSize.Timestamp)
	AND PASF.DatabaseID > 5
	AND Conn.ObjectName LIKE 'hostname1n1%'
ORDER BY
	Conn.ObjectName,
	PASD.DatabaseID,
	PASF.FileID,
	Timestamp


-- sums all files for each DB

SELECT
    DATEADD(SECOND, FileSize.Timestamp * 5, '20000101 00:00:00') AS Timestamp,
    Conn.ObjectName,
    SqlDatabase.Name,
    --SqlFile.FileName,
    --CASE FileSize.PerformanceAnalysisCounterID WHEN 251 THEN 'DATA' WHEN 253 THEN 'LOG' END as FileType,
    FORMAT(SUM(FileSize.Value), 'N0') AS FileSizeMB
FROM EventSourceConnection AS Conn 
    JOIN EventSourceConnectionType AS ConnType ON ConnType.ObjectID = Conn.EventSourceConnectionTypeID
    JOIN PerformanceAnalysisSqlFile AS SqlFile ON SqlFile.EventSourceConnectionID = Conn.ID  
    JOIN PerformanceAnalysisSqlDatabase AS SqlDatabase ON SqlDatabase.DatabaseID = SqlFile.DatabaseID AND SqlDatabase.EventSourceConnectionID = SqlFile.EventSourceConnectionID
    JOIN PerformanceAnalysisDataRollup12 AS FileSize ON FileSize.EventSourceConnectionID = SqlFile.EventSourceConnectionID 
        AND (convert(varchar(10),SqlFile.EventSourceConnectionID) + ',' + convert(varchar(10),SqlFile.DatabaseID) + ',' + convert(varchar(10),SqlFile.FileID))=FileSize.InstanceName
WHERE Conn.ObjectName LIKE 'hostname1n1%' 
    AND ConnType.Name = 'SQL Server'
    AND SqlFile.DatabaseID = 34
    AND FileSize.PerformanceAnalysisCounterID IN (251,253)
    AND FileSize.Timestamp >= dbo.fnConvertDateTimeToTimestamp('2025-01-01')
	AND FileSize.Timestamp <= dbo.fnConvertDateTimeToTimestamp('2026-01-01')
GROUP BY
    Timestamp,
    Conn.ObjectName,
    SqlDatabase.Name
ORDER BY
    SqlDatabase.Name, 
    TimeStamp
