Import-Module sqlserver

$instance = 'xx.xx.xx.xx,15150'
$ag = 'AG2016_1'

$agobj = (Get-SqlInstance -ServerInstance $instance).AvailabilityGroups[$ag]

$backups = @()
foreach ($replica in $agobj.AvailabilityReplicas) {
    $replica.Name
    foreach ($db in $agobj.AvailabilityDatabases) {
        $db.Name
        $backups += Get-SqlBackupHistory -ServerInstance $replica.Name -DatabaseName $db.Name -BackupType Database -StartTime ((Get-Date).AddDays(-7)) | Sort-Object BackupStartDate
    }
}

$backups | Select-Object ServerName, DatabaseName, BackupStartDate, BackupFinishDate, UserName | Format-Table