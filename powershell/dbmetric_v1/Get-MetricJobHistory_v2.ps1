# Import-Module '.\modules\dbatools'
$ErrorActionPreference = 'Stop'

$datastore_instance = 'xx.xx.xx.xx,15150'
$datastore_database = 'DBA'

$now = Get-Date
$two_weeks_ago = (Get-Date).AddDays(-14)

# creates the tables to store all the data
$RunlogDT = New-Object System.Data.DataTable
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([Int])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'RunTime', ([DateTime])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([String])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'Metric', ([String])))

$JobsDT = New-Object System.Data.DataTable
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([Int])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'ComputerName', ([string])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'InstanceName', ([string])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'SqlInstance', ([string])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'JobName', ([String])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'RunDate', ([DateTime])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'RunDuration', ([Int])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'Status', ([String])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'Message', ([String])))

try {
    # get server list
    $query = "SELECT S.Servername, S.IP, S.Port, S.Instance, MAX(R.RunTime) AS LastRunTime FROM Servers_T AS S LEFT JOIN NewRunlog AS R ON R.ServerName = S.Servername WHERE History_CD = 0 AND S.Timestamp > DATEADD(DAY,-7,GETDATE()) GROUP BY S.Servername, S.IP, S.Port, S.Instance ORDER BY S.Servername, S.Port"
    $servers = Invoke-DbaQuery -SqlInstance $datastore_instance -Database $datastore_database -Query $query
    # $servers

    # loop thru each server
    foreach ($s in $servers | Select-Object -First 7) {
        "Querying: {0}\{1} ({2})" -f $s.Servername, $s.Instance, $s.IP

        # check if the port is open        
        $TcpClient = New-Object System.Net.Sockets.TcpClient
        if (-not ($TcpClient.ConnectAsync($s.Ip, $s.Port).Wait(100))) {
            "`tPORT NOT OPEN"
            continue
        }

        if ($s.LastRunTime -is [DBNull] -or $s.LastRunTime -lt $two_weeks_ago) {
            $last_run_time = $two_weeks_ago
        }
        # elseif ($s.LastRunTime -lt $two_weeks_ago) {
        #     $last_run_time = $two_weeks_ago
        # }
        else {
            $last_run_time = $s.LastRunTime
        }

        $i = "{0},{1}" -f $s.IP, $s.Port
        $runhistory = Get-DbaAgentJobHistory -SqlInstance $i -StartDate $last_run_time -EndDate $now -ExcludeJobSteps -ExcludeJob 'DatabaseBackup - USER_DATABASES - LOG', 'Output File Cleanup', 'syspolicy_purge_history', 'SQL Sentry 2.0 Alert Trap', 'sp_delete_backuphistory', 'sp_purge_jobhistory', 'CommandLog Cleanup'
        
        # add the jobs to the data table
        $JobsDT.Clear()
        foreach ($r in $runhistory) {
            $JobsRow = $JobsDT.NewRow()
            $JobsRow['ComputerName'] = $r.ComputerName
            $JobsRow['InstanceName'] = $r.InstanceName
            $JobsRow['SqlInstance'] = $r.SqlInstance
            $JobsRow['JobName'] = $r.Job
            $JobsRow['RunDate'] = [DateTime]$r.RunDate
            $JobsRow['RunDuration'] = [Int]$Job.RunDuration
            $JobsRow['Status'] = $r.Status
            $JobsRow['Message'] = $r.Message
            $JobsDT.Rows.Add($JobsRow)
        }
        
        # add the server to the data table
        $RunlogDT.Clear()
        $RunlogRow = $RunlogDT.NewRow()
        $RunlogRow['Runtime'] = $Now
        $RunlogRow['ServerName'] = $s.Servername
        $RunlogRow['Metric'] = 'Jobs'
        $RunlogDT.Rows.Add($RunlogRow)

        "Jobs:   {0}" -f $JobsDT.Rows.Count

        # send all the data to SQL
        if ($JobsDT.Rows.count -gt 0) {
            $JobsDT | Write-DbaDbTableData -SqlInstance $datastore_instance -Database $datastore_database -Table 'NewJobHistory'
        }

        if ($RunlogDT.Rows.Count -gt 0) {
            $RunlogDT | Write-DbaDbTableData -SqlInstance $datastore_instance -Database $datastore_database -Table 'NewRunlog'
        }
    }
}
catch {
    $_
    "failed"
}