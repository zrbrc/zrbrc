<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
Set-Location $PSScriptRoot
. .\config\Config.ps1
. .\function\Functions.ps1

$logname = '.\log\Backup_' + (Get-Date -Format 'yyyyMMdd_hhmmss') + '.txt'
Start-Transcript -Path $logname

if (Get-Module dbatools -ListAvailable) { 
    Import-Module dbatools
}
else {
    throw 'dbatools module not found.'
    exit
}
if (Get-Module SqlServer -ListAvailable) { 
    Import-Module SqlServer
}
else {
    throw 'SqlServer module not found.'
    exit
}

# test DBA target instance 
if (-not (Get-SqlInstance -ServerInstance $Instance)) {
    throw 'Cant connect to DBA instance.'
    exit
}

$RunlogDT = New-Object System.Data.DataTable
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([Int])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'RunTime', ([DateTime])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([String])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'Metric', ([String])))

$BackupsDT = New-Object System.Data.DataTable
$BackupsDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([int])))
$BackupsDT.Columns.Add((New-Object System.Data.DataColumn 'RunTimeStamp', ([DateTime])))
$BackupsDT.Columns.Add((New-Object System.Data.DataColumn 'SqlInstance', ([String])))
$BackupsDT.Columns.Add((New-Object System.Data.DataColumn 'Database', ([String])))
$BackupsDT.Columns.Add((New-Object System.Data.DataColumn 'Start', ([DateTime])))
$BackupsDT.Columns.Add((New-Object System.Data.DataColumn 'End', ([DateTime])))
$BackupsDT.Columns.Add((New-Object System.Data.DataColumn 'Duration', ([String])))
$BackupsDT.Columns.Add((New-Object System.Data.DataColumn 'FilePath', ([String])))
$BackupsDT.Columns.Add((New-Object System.Data.DataColumn 'BackupSizeGB', ([Decimal])))
$BackupsDT.Columns.Add((New-Object System.Data.DataColumn 'CompressedBackupSizeGB', ([Decimal])))
$BackupsDT.Columns.Add((New-Object System.Data.DataColumn 'CompressionRatio', ([Decimal])))
$BackupsDT.Columns.Add((New-Object System.Data.DataColumn 'Type', ([String])))
$BackupsDT.Columns.Add((New-Object System.Data.DataColumn 'BackupSetId', ([String])))
$BackupsDT.Columns.Add((New-Object System.Data.DataColumn 'IsCopyOnly', ([String])))

"Start: {0}" -f (Get-Date -Format g)

# gets local subnet to determine if we should try to scan the target, if out of subnet we skip it later
$LocalSubnet = (Get-NetIpAddress | Where-Object { $_.IpAddress -eq $LocalIP }).PrefixLength | Get-SubnetMask

# gets the latest list of sql instances we created above.
$Query = "SELECT * FROM $ServerTable WHERE History_CD = 0 ORDER BY Servername"
$Servers = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $Query

# get runlog for metric
$Query = "SELECT MAX(RunTime) as LastRunTime, ServerName FROM $RunlogTable WHERE Metric = 'Backup' GROUP BY ServerName"
$LastRun = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $Query

foreach ($Server in $Servers) {
    try {
        $BackupsDT.Clear()

        # if subnet mask and domain dont match and the server details are older than 15 minutes, skip it
        if ( -not ((([System.Net.IPAddress]$LocalIP).Address -band $LocalSubnet.Address ) -eq 
                (([System.Net.IPAddress]$Server.IP).Address -band $LocalSubnet.Address) -and 
                $Server.Domain -eq $Domain -and
                $Server.Timestamp -gt (Get-Date).AddDays(-1) )) {
            "Skipping: {0} {1}" -f $Server.Servername, $Server.IP
            continue
        }
    
        if (-not ($StartTime = $LastRun | Where-Object { $_.ServerName -eq $Server.Servername } | Select-Object -ExpandProperty LastRunTime )) {
            $StartTime = (Get-Date).AddHours(-24)
        }

        "Sql Server: {0} Last Run: {1} UTC" -f $Server.Servername, $StartTime

        $Backups = Get-DbaDbBackupHistory -SqlInstance "$($Server.Servername),$($Server.Port)" -IncludeCopyOnly -Type Full, Differential -Since $StartTime -EnableException
        foreach ($Backup in $Backups) {
            $BackupsRow = $BackupsDT.NewRow()
            $BackupsRow['RunTimeStamp'] = [DateTime](Get-Date)
            $BackupsRow['SqlInstance'] = $Backup.SqlInstance
            $BackupsRow['Database'] = $Backup.Database
            $BackupsRow['Start'] = [DateTime]$Backup.Start
            $BackupsRow['End'] = [DateTime]$Backup.End
            $BackupsRow['Duration'] = $Backup.Duration
            $BackupsRow['FilePath'] = ($Backup.Path -join ',')
            $BackupsRow['BackupSizeGB'] = [Decimal]$Backup.TotalSize.Gigabyte
            $BackupsRow['CompressedBackupSizeGB'] = [Decimal]$Backup.CompressedBackupSize.Gigabyte
            $BackupsRow['CompressionRatio'] = [Decimal]$Backup.CompressionRatio
            $BackupsRow['Type'] = $Backup.Type
            $BackupsRow['BackupSetId'] = $Backup.BackupSetId
            $BackupsRow['IsCopyOnly'] = $Backup.IsCopyOnly
            $BackupsDT.Rows.Add($BackupsRow)
        }

        $RunlogRow = $RunlogDT.NewRow()
        $RunlogRow['Runtime'] = $Now
        $RunlogRow['ServerName'] = $Server.Servername
        $RunlogRow['Metric'] = $BackupsName
        $RunlogDT.Rows.Add($RunlogRow)

        if ($BackupsDT.Rows.count -gt 0) {
            "Writing {0} new backup records." -f $BackupsDT.Rows.count
            Write-SqlTableData -InputData $BackupsDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $BackupHistoryTable
        }
    }
    catch {
        $ErrorException = $_.Exception
        "`t`t {0} failed." -f $Server.Servername
        $ErrorException
        continue
    }
}

if ($RunlogDT.Rows.Count -gt 0) {
    Write-SqlTableData -InputData $RunlogDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $RunlogTable
}
"End:   {0}" -f (Get-Date -Format g)