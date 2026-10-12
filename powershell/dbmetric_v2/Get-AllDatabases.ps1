Set-Location $PSScriptRoot

Start-Transcript .\log\Get-AllDatabases_log.txt

. .\includes\Config

$dbquery = @"
WITH CTE AS (
	SELECT
		d.database_id,
		ROUND(SUM(CAST(mf.size AS bigint)) * 8 / 1024, 0) AS size_mb,
		(SUM(CAST(mf.size AS bigint)) * 8 / 1024) / 1024 AS size_gb
	FROM 
		sys.master_files mf
		INNER JOIN sys.databases d ON d.database_id = mf.database_id
	WHERE
		d.database_id > 4
	GROUP BY
		d.database_id
)
SELECT 
	GETDATE() AS Timestamp,
	@@SERVERNAME AS ServerName,
	d.name AS DatabaseName,
	d.database_id AS DatabaseID,
    d.state_desc AS State,
	CTE.size_mb AS SizeMB,
	CTE.size_gb AS SizeGB,
	ag.name AS AgName,
	ars.role_desc AS RoleDesc
FROM
	master.sys.databases as d
	JOIN CTE ON cte.database_id = d.database_id
	LEFT JOIN master.sys.dm_hadr_database_replica_states AS drs ON drs.database_id = d.database_id
	LEFT JOIN master.sys.dm_hadr_availability_replica_states AS ars ON ars.replica_id = drs.replica_id
	LEFT JOIN master.sys.availability_groups AS ag ON ag.group_id = ars.group_id
WHERE
	d.database_id > 4
	AND (ars.is_local = 1 
         OR ars.is_local IS NULL)
"@

# creates the tables to store all the data
$RunlogDT = New-Object System.Data.DataTable
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([Int])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'RunTime', ([DateTime])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([String])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'Metric', ([String])))

$DatabasesDT = New-Object System.Data.DataTable
$DatabasesDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([Int])))
$DatabasesDT.Columns.Add((New-Object System.Data.DataColumn 'Timestamp', ([DateTime])))
$DatabasesDT.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([string])))
$DatabasesDT.Columns.Add((New-Object System.Data.DataColumn 'DatabaseName', ([string])))
$DatabasesDT.Columns.Add((New-Object System.Data.DataColumn 'DatabaseID', ([int])))
$DatabasesDT.Columns.Add((New-Object System.Data.DataColumn 'State', ([string])))
$DatabasesDT.Columns.Add((New-Object System.Data.DataColumn 'SizeMB', ([int])))
$DatabasesDT.Columns.Add((New-Object System.Data.DataColumn 'SizeGB', ([int])))
$DatabasesDT.Columns.Add((New-Object System.Data.DataColumn 'AgName', ([string])))
$DatabasesDT.Columns.Add((New-Object System.Data.DataColumn 'RoleDesc', ([String])))

try {
	# get server list
	$serversquery = "SELECT Servername, Instance, IP, Port FROM Instances WHERE HistoryCode = 0"
	$servers = Invoke-DbaQuery -SqlInstance $datastore_instance -Database $datastore_database -Query $serversquery -SqlCredential $sqlmetrics -EnableException
	# $servers  | ft
	
    # mark everything as history that wasnt aleady
    $historysql = "UPDATE $DatabaseTable SET HistoryCode = 1 WHERE HistoryCode = 0"
    Invoke-DbaQuery -SqlInstance $datastore_instance -Database $datastore_database -Query $historysql -SqlCredential $sqlmetrics -EnableException
    
    # loop thru each server
	foreach ($s in $servers) {
		"Querying {0}\{1} ({2})" -f $s.Servername, $s.Instance, $s.IP

		# check if the port is open        
		$TcpClient = New-Object System.Net.Sockets.TcpClient
		if (-not ($TcpClient.ConnectAsync($s.Ip, $s.Port).Wait(100))) {
			"`tPORT NOT OPEN"
			continue
		}

        # run query for db info
		$i = "{0},{1}" -f $s.IP, $s.Port
		$output = Invoke-DbaQuery -SqlInstance $i -SqlCredential $sqlmetrics -Query $dbquery -EnableException
        
		# add the jobs to the data table
		$DatabasesDT.Clear()
		foreach ($o in $output) {
			$DatabasesRow = $DatabasesDT.NewRow()
			$DatabasesRow['Timestamp'] = $Now
			$DatabasesRow['ServerName'] = $o.ServerName
			$DatabasesRow['DatabaseName'] = $o.DatabaseName
			$DatabasesRow['DatabaseID'] = $o.DatabaseID
            $DatabasesRow['State'] = $o.State
			$DatabasesRow['SizeMB'] = $o.SizeMB
			$DatabasesRow['SizeGB'] = $o.SizeGB
			$DatabasesRow['AgName'] = $o.AgName
			$DatabasesRow['RoleDesc'] = $o.RoleDesc
            
			$DatabasesDT.Rows.Add($DatabasesRow)
		}
        
		# add the server to the data table
		$RunlogDT.Clear()
		$RunlogRow = $RunlogDT.NewRow()
		$RunlogRow['Runtime'] = $Now
		$RunlogRow['ServerName'] = $s.Servername
		$RunlogRow['Metric'] = 'Databases'
		$RunlogDT.Rows.Add($RunlogRow)

		"Databases:   {0}" -f $DatabasesDT.Rows.Count

		# send all the data to SQL
		if ($DatabasesDT.Rows.count -gt 0) {
			$DatabasesDT | Write-DbaDbTableData -SqlInstance $datastore_instance -Database $datastore_database -Table 'Databases' -SqlCredential $sqlmetrics -EnableException -AutoCreateTable
		}

		if ($RunlogDT.Rows.Count -gt 0) {
			$RunlogDT | Write-DbaDbTableData -SqlInstance $datastore_instance -Database $datastore_database -Table 'Runlog' -SqlCredential $sqlmetrics -EnableException
		}
	}
}
catch {
	$_
	"failed"
}

Stop-Transcript