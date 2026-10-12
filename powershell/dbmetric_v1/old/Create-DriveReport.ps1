$Instance = 'xx.xx.xx.xx,15150'
$Database = 'DBA'

$query = "DECLARE @PivotColumns AS NVARCHAR(MAX)
          SELECT @PivotColumns = COALESCE(@PivotColumns + ',','') + QUOTENAME(DriveLetter)
          FROM (SELECT DISTINCT DriveLetter FROM DriveStats_T) AS L ORDER BY DriveLetter
          
          DECLARE @SQLQUERY AS NVARCHAR(MAX)
          
          SET @SQLQUERY = N'
          SELECT * FROM (
          SELECT	A.ServerName
          		,A.ServerIp
          		,A.DriveLetter
          		,A.FreePercent
          FROM	DriveStats_T AS A
          INNER JOIN (SELECT ServerName, 
          				   DriveLetter, 
          	               MAX(ID) AS MAXID 
          			FROM DriveStats_T
          			WHERE RunTimeStamp > DATEADD(day,-7,GETDATE())
          			GROUP BY ServerName, 
          			         DriveLetter) AS B ON B.MAXID = A.ID AND B.ServerName = A.ServerName and B.DriveLetter = A.DriveLetter
          WHERE A.DriveLetter NOT IN (''T'',''U'',''P'')
          ) AS BaseData
          PIVOT (
          	SUM(FreePercent)
          	FOR DriveLetter
          	IN (' + @PivotColumns + ' )
          ) as PivotTable'
          
          EXEC sp_executesql @SQLQUERY"

$output = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $Query -OutputAs DataTable 
$table = $output.Rows | Select-Object * -Exclude RowError, RowState, Table, ItemArray, HasErrors | Sort-Object ServerName
$table | ft *
$table | ConvertTo-Html | Out-File .\out.html
Invoke-Item .\out.html
