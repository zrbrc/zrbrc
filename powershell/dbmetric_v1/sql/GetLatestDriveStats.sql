USE DBA
GO

WITH CTE_Drives 
AS 
(
  SELECT ServerName, 
	     MAX(RunTimeStamp) AS MaxRunTimeStamp
	FROM DriveStats_T
   GROUP BY ServerName
)
SELECT D.*
  FROM DriveStats_T AS D
       JOIN CTE_Drives AS C 
	     ON C.MaxRunTimeStamp = D.RunTimeStamp
		    AND C.ServerName = D.ServerName
WHERE D.DriveLetter NOT IN ('T','P')
ORDER BY D.ServerName, D.DriveLetter
GO

-- P I V O T  I T

USE DBA
GO

DECLARE @PivotColumns AS NVARCHAR(MAX)
SELECT @PivotColumns = COALESCE(@PivotColumns + ',','') + QUOTENAME(DriveLetter)
FROM (SELECT DISTINCT DriveLetter FROM Drive_V) AS L

DECLARE @SQLQUERY AS NVARCHAR(MAX)

SET @SQLQUERY = N'
SELECT * FROM Drives_V
) AS BaseData
PIVOT (
	SUM(FreePercent)
	FOR DriveLetter
	IN (' + @PivotColumns + ' )
) as PivotTable'

EXEC sp_executesql @SQLQUERY