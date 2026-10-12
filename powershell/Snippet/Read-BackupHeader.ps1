$i = 'LUNA\DE2019'
$SqlInstance = Get-SqlInstance -ServerInstance $i

# $d = 'random_db'
# $t = 'full'
# $dt = Get-Date -Format 'yyyyMMdd_HHmmss'
# $file = "D:\SQL\Backup\$d-$t-$dt.bak"
# Backup-SqlDatabase -ServerInstance $i -Database $d -BackupAction Database -BackupFile $file 
# $t = 'diff'
# $dt = Get-Date -Format 'yyyyMMdd_HHmmss'
# $file = "D:\SQL\Backup\$d-$t-$dt.bak"
# Backup-SqlDatabase -ServerInstance $i -Database $d -BackupAction Database -BackupFile $file -Incremental

$files = Get-ChildItem -Path 'D:\SQL\Backup' -Filter '*.bak'

$server = New-Object Microsoft.SqlServer.Management.Smo.Server $SqlInstance.ConnectionContext.Copy()

$output = foreach ($f in $files) {
    $DeviceType = 'FILE'
    $restore = New-Object Microsoft.SqlServer.Management.Smo.Restore
    $device = New-Object Microsoft.SqlServer.Management.Smo.BackupDeviceItem $f[0].FullName, $DeviceType
    $restore.Devices.Add($device)
    $datatable = $restore.ReadBackupHeader($server)
    $null = $dataTable.Columns.Add("FileList", [object])
    $null = $dataTable.Columns.Add("SqlVersion")
    $null = $dataTable.Columns.Add("BackupPath")

    foreach ($row in $dataTable) {
         <# Select-Object does a quick and dirty conversion from datatable to PS object #>
        $row.FileList = $restore.ReadFileList($server) | Select-Object *
    }
    $dataTable
}
$output | fl


$files.FullName | Read-DbaBackupHeader -SqlInstance $i