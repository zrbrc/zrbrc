Set-Location $PSScriptRoot

Start-Transcript .\log\Get-MetricJobHistory_log.txt

. .\includes\Config.ps1

$one_week_ago = (Get-Date).AddDays(-7)

# creates the tables to store all the data
$RunlogDT = New-Object System.Data.DataTable
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([Int])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'RunTime', ([DateTime])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([String])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'Metric', ([String])))

$JobsDT = New-Object System.Data.DataTable
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([Int])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([string])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'InstanceName', ([string])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'SqlInstance', ([string])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'JobName', ([String])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'StartDate', ([DateTime])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'EndDate', ([DateTime])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'Status', ([String])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'Message', ([String])))

try {
    # get server list
    $query = "SELECT S.Servername, S.IP, S.Port, S.Instance, MAX(R.RunTime) AS LastRunTime FROM Instances AS S LEFT JOIN Runlog AS R ON R.ServerName = S.Servername WHERE HistoryCode = 0 AND S.Timestamp > DATEADD(DAY,-7,GETDATE()) AND R.Metric = 'Jobs' GROUP BY S.Servername, S.IP, S.Port, S.Instance HAVING (MAX(R.RunTime) < DATEADD(HOUR,-1,GETDATE()) OR MAX(R.RunTime) IS NULL) ORDER BY S.Servername, S.Port"
    $servers = Invoke-DbaQuery -SqlInstance $datastore_instance -Database $datastore_database -Query $query -SqlCredential $sqlmetrics -EnableException
    # $servers

    # loop thru each server
    foreach ($s in $servers) {
        "Querying {0}\{1} ({2}) since {3}" -f $s.Servername, $s.Instance, $s.IP, $s.LastRunTime

        # check if the port is open        
        $TcpClient = New-Object System.Net.Sockets.TcpClient
        if (-not ($TcpClient.ConnectAsync($s.Ip, $s.Port).Wait(100))) {
            "`tPORT NOT OPEN"
            continue
        }

        if ($s.LastRunTime -is [DBNull] -or $s.LastRunTime -lt $one_week_ago) {
            $last_run_time = $one_week_ago
        }
        # elseif ($s.LastRunTime -lt $one_week_ago) {
        #     $last_run_time = $one_week_ago
        # }
        else {
            $last_run_time = $s.LastRunTime
        }

        $i = "{0},{1}" -f $s.IP, $s.Port
        
        $runhistory = Get-DbaAgentJobHistory -SqlInstance $i -StartDate $last_run_time -EndDate $now -ExcludeJobSteps -ExcludeJob $jobs_filter -SqlCredential $sqlmetrics -EnableException
        
        # add the jobs to the data table
        $JobsDT.Clear()
        foreach ($r in $runhistory) {
            $JobsRow = $JobsDT.NewRow()
            $JobsRow['ServerName'] = $r.ComputerName
            $JobsRow['InstanceName'] = $r.InstanceName
            $JobsRow['SqlInstance'] = $r.SqlInstance
            $JobsRow['JobName'] = $r.Job
            $JobsRow['StartDate'] = [DateTime]$r.StartDate
            $JobsRow['EndDate'] = [DateTime]$r.EndDate
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
            $JobsDT | Write-DbaDbTableData -SqlInstance $datastore_instance -Database $datastore_database -Table 'Jobs' -SqlCredential $sqlmetrics -EnableException
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

"End:   {0}" -f (Get-Date)

Stop-Transcript