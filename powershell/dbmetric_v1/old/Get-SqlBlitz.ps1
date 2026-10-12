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

$datatable = New-Object System.Data.DataTable
$datatable.Columns.Add((New-Object System.Data.DataColumn 'ID', ([int]))) # this table ID, not a data field to capture or set
$datatable.Columns.Add((New-Object System.Data.DataColumn 'Runtime', ([DateTime])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'Priority', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'FindingsGroup', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'Finding', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'DatabaseName', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'Details', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'QueryPlan', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'QueryPlanFiltered', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'CheckID', ([Int])))

foreach ($server in $Servers | Where-Object { $_.Domain -eq $Domain -and $_.DMZ -eq $Zone -and $_.Type -eq 2 }) {
    "$($server.HostName)"

    try {
        $data = Invoke-DbaQuery -SqlInstance "$($server.HostName),$($server.SqlServerPort)" -Database master -Query 'EXEC sp_Blitz' -EnableException

        foreach ($record in $data) {
            $row = $datatable.NewRow()
            $row['Runtime'] = $now
            $row['ServerName'] = $server.HostName
            $row['Priority'] = $record.Priority
            $row['FindingsGroup'] = $record.FindingsGroup
            $row['Finding'] = $record.Finding
            $row['DatabaseName'] = $record.DatabaseName
            $row['Details'] = $record.Details
            $row['QueryPlan'] = $record.QueryPlan
            $row['QueryPlanFiltered'] = $record.QueryPlanFiltered
            $row['CheckID'] = $record.CheckID
            $datatable.Rows.Add($row)
        }
    }
    catch {
        "Blitz failed to execute on {0}." -f $server.HostName
    }
}


if ($datatable) {
    Write-SqlTableData -ServerInstance $DBAInstance -DatabaseName 'DBA' -SchemaName 'dbo' -TableName 'Blitz_T' -InputData $datatable
}