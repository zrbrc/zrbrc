USE DBA
GO
-- variable to hold pivot columns for all servers
DECLARE @PivotColumns AS NVARCHAR(MAX)

-- dynamic sql
DECLARE @SQLQUERY AS NVARCHAR(MAX)

-- get a list of all unique drive letters for dynamic pivot
SELECT @PivotColumns = COALESCE(@PivotColumns + ',','') + QUOTENAME(DriveLetter)
FROM (
    SELECT DISTINCT DriveLetter
      FROM DriveStats_T
) AS Drives
ORDER BY DriveLetter

-- create dynamic sql using drive letters gotten above
SET @SQLQUERY = N'
WITH Drives AS 
(
    SELECT ServerName,
           ServerIp,
           DriveLetter,
           FreePercent
      FROM vwDriveStats
),
DrivePivot AS (
    SELECT *
      FROM Drives
     PIVOT 
     (
        SUM(FreePercent)
        FOR DriveLetter
         IN (' + @PivotColumns + ' )
     ) AS PivotTable
)
SELECT *
  FROM DrivePivot'

-- execute sql
EXEC sp_executesql @SQLQUERY