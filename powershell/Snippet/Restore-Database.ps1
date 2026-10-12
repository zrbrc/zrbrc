<#
This is a simple DB restore script for AGs.
Steps:
    1-Perform a DIFF
    2-Get DB replica info
    3-Drop DBs from AG
    4-Find latest bak for the sourceDB name
    5-Restore to each replica, 'withreplace'
    6-Perform a transaction log backup and restore to secondaries
    7-Join DB back to AG

#>
Import-Module dbatools

# Fill in the below info
$bakroot = '\\xx.xx.xx.xx\dbbackup' # where the bak files are for this DB, it can be root and it will search all subfolder using a filter of the sourceDB name.
$Listener = 'xx.xx.xx.xx,15150' # what AG listener are we restoring to
$SourceDb = 'DSS_POC_UATCR' # the source DB namem used for finding the bak file to use
$TargetDb = 'DSS_POC_UATCR' # target DB name
$Ag = 'AG2016_1' # Ag Name

$aginit = '\\xx.xx.xx.xx\dbbackup\tmp' # network share where the trn backups can be place and accessible from all instances involved

# gets last diff info
$LastDiff = Get-DbaDbBackupHistory -SqlInstance $Listener -Database $SourceDb -LastDiff

# gets just diff folder path
$DiffPath = Split-Path $LastDiff.FullName -Parent

# does a diff before tearing it down
Backup-DbaDatabase -SqlInstance $Listener -Database $TargetDb -Path $DiffPath -Type Diff

$Replicas = Get-DbaAgReplica -SqlInstance $Listener -AvailabilityGroup $Ag

# remove all the DBs from the AG
Remove-DbaAgDatabase -SqlInstance $Listener -Database $TargetDb -AvailabilityGroup AG2016_1 #-Confirm:$false

# set bak file locations
$bak = Get-ChildItem -Path $bakroot -Filter "*$($SourceDb)*FULL*.bak" -Recurse | Select-Object -ExpandProperty FullName -Last 1

$Replicas | Format-Table

# restore to replica 1
foreach ($Replica in $Replicas) {
    $RestoreParams = @{
        SqlInstance         = $Replica.Name
        DatabaseName        = $TargetDb
        WithReplace         = $true
        ReplaceDbNameInFile = $true
        EnableException     = $true
        Path                = $bak
    }
    if ($Replica.Role -eq "Secondary") {
        $RestoreParams.Add("NoRecovery", $true)
    }
    Restore-DbaDatabase @RestoreParams
    Write-Output "Restored to $($Replica.Name)"
}

# backup and restore trn files to each secondary
$trn = Backup-DbaDatabase -SqlInstance $(($Replicas | Where-Object { $_.Role -eq 'Primary' }).Name) -Database $TargetDb -BackupDirectory $aginit -Type Log
Restore-DbaDatabase -SqlInstance $(($Replicas | Where-Object { $_.Role -eq 'Secondary' }).Name) -Database $TargetDb -Path $trn.Path -NoRecovery -Continue

# add them back to the ag
Add-SqlAvailabilityDatabase -Path SQLSERVER:\SQL\$(($Replicas | Where-Object { $_.Role -eq 'Primary' }).Name)\AvailabilityGroups\$($Ag) -Database $TargetDb
foreach ($Replica in $Replicas) {
    Add-SqlAvailabilityDatabase -Path SQLSERVER:\SQL\$($Replica.Name)\AvailabilityGroups\$($Ag) -Database $TargetDb
}



