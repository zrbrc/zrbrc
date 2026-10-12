DECLARE @PivotColumns AS NVARCHAR(MAX)
SELECT @PivotColumns = COALESCE(@PivotColumns + ',','') + QUOTENAME(Username)
FROM (SELECT DISTINCT Username FROM LogonErrors_T) AS L

DECLARE @SQLQUERY AS NVARCHAR(MAX)
SET @SQLQUERY = N'
SELECT * FROM (
	SELECT 
		Username,
		MachineName,
		Hostname,
		RecordId 
	FROM LogonErrors_T
) AS BaseData
PIVOT (
	COUNT(RecordID)
	FOR Username 
	IN (' + @PivotColumns + ' )
) AS PivotTable'

EXEC sp_executesql @SQLQUERY