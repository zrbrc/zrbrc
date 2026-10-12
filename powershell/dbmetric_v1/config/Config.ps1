############################################################################
# init
#region ####################################################################
$Now = Get-Date
$Now
$ErrorActionPreference = 'Stop'

# used to connect to the DBA database on the non-infra instance
# Get-Credential | Export-Clixml 'D:\Scripts\dbmetric\secrets\sqlmetrics.xml'

$credspath = "$env:LOCALAPPDATA\basetech.xml"
if (Test-Path -Path $credspath -PathType Leaf) {
    $basetech = Import-Clixml $credspath
    $basetech.Password.MarkReadOnly()
    Write-Output "Credentials imported from $credspath."
}
else {
    $basetech = Get-Credential -Credential 'basetech'
    $basetech | Export-Clixml $credspath
    Write-Output "Account credentials stored to $credspath."
}

# instance config
$Instance = 'xx.xx.xx.xx,15150'
$Database = 'DBA'
$Schema = 'dbo'

# input and log tables
$ServerTable = 'Servers'
$RunlogTable = 'Runlog'

# output tables
$AuditTable = 'Audits'
$BackupHistoryTable = 'BackupHistory'
$BlitzTable = 'Blitz'
$DriveStatsTable = 'DriveStats'
$JobsTable = 'Jobs'
$LogonErrorsTable = 'LogonErrors'

# metric names
$AuditName = 'Audit'
$BackupsName = 'Backup'
$BlitzName = 'Blitz'
$DriveStatsName = 'Drive'
$JobsName = 'Jobs'
$LogonErrorsName = 'Logon'

$LocalIP = (Test-Connection $env:COMPUTERNAME -Count 1).IPV4Address.IPAddressToString
# $LocalSubnet = (Get-NetIpAddress | Where-Object { $_.IpAddress -eq $LocalIP }).PrefixLength | Get-SubnetMask
$Domain = (Get-ADDomain).Name
#endregion

