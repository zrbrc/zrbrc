$DBAInstance = 'xx.xx.xx.xx,15150'

$Servers = Read-SqlTableData -ServerInstance $DBAInstance -Database 'DBA' -SchemaName 'dbo' -TableName 'Servers_T'

# get domain we are running in 
$Domain = $env:USERDOMAIN

# get ip for server we are running on
$IPAddress = (Test-Connection $env:COMPUTERNAME -Count 1 | Select-Object -First 1).IPV4Address.IPAddressToString

# determine our network zone
switch -Wildcard ($IPAddress) {
    "172.31.23*" { $Zone = 'EL2' }
    "172.31.45.*" { $Zone = 'IMDZ3' }
    "172.31.121.*" { $Zone = 'IDEV' }
    default { $Zone = $null }
}

# 6:00:00am yesterday to 5:59:59am today
$Yesterday = (Get-Date -Hour 6 -minute 0 -Second 0).AddDays(-1)
$Today = (Get-Date -Hour 5 -minute 59 -Second 59)

$datatable = New-Object System.Data.DataTable
$datatable.Columns.Add((New-Object System.Data.DataColumn 'ID', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'SqlInstance', ([string])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'JobName', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'JobId', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'InstanceId', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'StartDate', ([DateTime])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'EndDate', ([DateTime])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'RunDuration', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'Status', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'Message', ([String])))

foreach ($server in $Servers | Where-Object { $_.Domain -eq $Domain -and $_.DMZ -eq $Zone -and $_.Type -eq 2 }) {
    "$($server.HostName)"

    $JobData = Get-DbaAgentJobHistory -SqlInstance "$($server.HostName),$($server.SqlServerPort)" -StartDate $Yesterday -EndDate $Today -ExcludeJobSteps

    
    foreach ($job in $JobData) {
        $row = $datatable.NewRow()
        $row['SqlInstance'] = $job.SqlInstance
        $row['JobName'] = $job.JobName
        $row['JobId'] = $job.JobID
        $row['InstanceId'] = $job.InstanceID
        $row['StartDate'] = [DateTime]$job.StartDate
        $row['EndDate'] = [DateTime]$job.EndDate
        $row['RunDuration'] = [Int]$job.RunDuration
        $row['Status'] = $job.Status
        $row['Message'] = $job.Message
        $datatable.Rows.Add($row)
    }
}

Write-SqlTableData -ServerInstance $DBAInstance -DatabaseName 'DBA' -SchemaName 'dbo' -TableName 'Jobs_T' -InputData $datatable

