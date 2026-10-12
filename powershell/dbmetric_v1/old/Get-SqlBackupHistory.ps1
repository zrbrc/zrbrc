$DBAInstance = 'xx.xx.xx.xx,15150'

$Servers = Read-SqlTableData -ServerInstance $DBAInstance -Database 'DBA' -SchemaName 'dbo' -TableName 'Servers_T'

# get domain we are running in 
$Domain = $env:USERDOMAIN

# get ip for server we are running on so we can filter on the same zone
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
$datatable.Columns.Add((New-Object System.Data.DataColumn 'ID', ([int]))) # this table ID, not a data field to capture or set
$datatable.Columns.Add((New-Object System.Data.DataColumn 'RunTimeStamp', ([DateTime])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'SqlInstance', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'Database', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'Start', ([DateTime])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'End', ([DateTime])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'Duration', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'FilePath', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'BackupSizeGB', ([Decimal])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'CompressedBackupSizeGB', ([Decimal])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'CompressionRatio', ([Decimal])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'Type', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'BackupSetId', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'IsCopyOnly', ([String])))

foreach ($server in $Servers | Where-Object { $_.Domain -eq $Domain -and $_.DMZ -eq $Zone -and $_.Type -eq 2 } ) {
        
    $server.HostName

    $data = Get-DbaDbBackupHistory -SqlInstance "$($server.HostName),$($server.SqlServerPort)" -IncludeCopyOnly -Type Full, Differential -Since $Yesterday
    
        foreach ($record in $data) {
            $row = $datatable.NewRow()
            $row['RunTimeStamp'] = [DateTime](Get-Date)
            $row['SqlInstance'] = $record.SqlInstance
            $row['Database'] = $record.Database
            $row['Start'] = [DateTime]$record.Start
            $row['End'] = [DateTime]$record.End
            $row['Duration'] = $record.Duration
            $row['FilePath'] = ($record.Path -join ',')
            $row['BackupSizeGB'] = [Decimal]$record.TotalSize.Gigabyte
            $row['CompressedBackupSizeGB'] = [Decimal]$record.CompressedBackupSize.Gigabyte
            $row['CompressionRatio'] = [Decimal]$record.CompressionRatio
            $row['Type'] = $record.Type
            $row['BackupSetId'] = $record.BackupSetId
            $row['IsCopyOnly'] = $record.IsCopyOnly
            $datatable.Rows.Add($row)
        }
}

if ($datatable.count -ne 0) {
    Write-SqlTableData -ServerInstance $DBAInstance -DatabaseName 'DBA' -SchemaName 'dbo' -TableName 'BackupHistory_T' -InputData $datatable -Force
}