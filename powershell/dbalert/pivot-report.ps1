# -- DECLARE @PivotColumns AS NVARCHAR(MAX)
$Query = "SELECT QUOTENAME(Username) FROM (SELECT DISTINCT Username FROM LogonErrors_T) AS L"

$Columns = Invoke-SqlCmd -ServerInstance 'ip,port' -Database DBA -Query $Query | Select-Object -ExpandProperty Column1
$Columns = $Columns -join ','

$PivotSql = "SELECT * FROM (SELECT Username, MachineName, Hostname, RecordId FROM LogonErrors_T) AS BaseData PIVOT (COUNT(RecordID) FOR Username IN ($Columns)) AS PivotTab"
$Table = Invoke-SqlCmd -ServerInstance 'ip,port' -Database DBA -Query $PivotSql

$output = foreach ($row in $Table) {
    $row
}

$output | select *





