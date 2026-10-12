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
$datatable.Columns.Add((New-Object System.Data.DataColumn 'ID', ([int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'RunTimeStamp', ([DateTime])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([string])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'ServerIp', ([string])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'DriveLetter', ([string])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'DriveLabel', ([string])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'SizeGB', ([decimal])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'FreeGB', ([decimal])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'FreePercent', ([decimal])))

foreach ($server in $Servers | Where-Object { $_.Domain -eq $Domain -and $_.DMZ -eq $Zone -and $_.Type -eq 1}) {
    "$($server.HostName)"

    Get-CimInstance -Class CIM_LogicalDisk -ComputerName $server.Hostname | Where-Object { $_.DriveType -eq '3' } | ForEach-Object {

        $row = $datatable.NewRow()
        $row['RunTimeStamp'] = [DateTime](Get-Date)
        $row['ServerName'] = $server.Hostname
        $row['ServerIp'] = $server.IPv4Address
        $row['DriveLetter'] = ($_.DeviceId -replace ':', '')
        $row['DriveLabel'] = $_.VolumeName
        $row['SizeGB'] = [math]::Round(($_.Size / 1024 / 1024 / 1024), 2)
        $row['FreeGB'] = [math]::Round(($_.FreeSpace / 1024 / 1024 / 1024), 2)
        $row['FreePercent'] = [math]::Round((($_.FreeSpace / $_.Size) * 100), 2)
        $datatable.Rows.Add($row)
    }
}

if ($datatable) {
    Write-SqlTableData -ServerInstance $DBAInstance -DatabaseName 'DBA' -SchemaName 'dbo' -TableName 'DriveStats_T' -InputData $datatable
}