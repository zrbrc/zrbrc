# init
$Now = Get-Date
$one_week_ago = (Get-Date).AddDays(-7)
$Now

$ErrorActionPreference = 'Stop'

Import-Module D:\Scripts\MSSQL\modules\dbatools.library
Import-Module D:\Scripts\MSSQL\modules\dbatools

Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true

# used to connect to the DBA database on the non-infra instance
$credspath = "$env:LOCALAPPDATA\sqlmetrics.xml"
if (-not (Test-Path -Path $credspath -PathType Leaf)) {
    Read-Host 'Enter password for sqlmetrics' -AsSecureString | Export-Clixml $credspath
}
$password = Import-Clixml $credspath
$sqlmetrics = New-object -TypeName System.Management.Automation.PSCredential('sqlmetrics', $password)

# instance config
$datastore_instance = 'hostnidbc1ls1,15150'
$datastore_database = 'DBA'

# input and log tables
$InstanceTable = 'Instances'
$RunlogTable = 'Runlog'

# output tables
$AuditTable = 'Audits'
$BackupHistoryTable = 'BackupHistory'
$BlitzTable = 'Blitz'
$DriveStatsTable = 'DriveStats'
$JobsTable = 'Jobs'
$LogonErrorsTable = 'LogonErrors'
$DatabaseTable = 'Databases'

# metric names
$AuditName = 'Audit'
$BackupsName = 'Backup'
$BlitzName = 'Blitz'
$DriveStatsName = 'Drive'
$JobsName = 'Jobs'
$LogonErrorsName = 'Logon'

$LocalIP = (Test-Connection $env:COMPUTERNAME -Count 1).IPV4Address.IPAddressToString
$Domain = (Get-ADDomain).Name


$jobs_filter = @(
    'Agent history clean up: distribution',
    'Backup BizTalk Server (BizTalkMgmtDb)',
    'CleanupBTFExpiredEntriesJob_BizTalkMgmtDb',
    'CommandLog Cleanup',
    'DatabaseBackup - SSISDB - LOG',
    'DatabaseBackup - USER_DATABASES - LOG',
    'DBA_Updt_DBStatTracking_CPUUtil',
    'Distribution clean up: distribution',
    'DTA Purge and Archive (BizTalkDTADb)',
    'MessageBox_DeadProcesses_Cleanup_BizTalkMsgBoxDb',
    'MessageBox_Message_Cleanup_BizTalkMsgBoxDb',
    'MessageBox_Message_ManageRefCountLog_BizTalkMsgBoxDb',
    'MessageBox_Parts_Cleanup_BizTalkMsgBoxDb',
    'MessageBox_UpdateStats_BizTalkMsgBoxDb',
    'Monitor and sync replication agent jobs',
    'Operations_OperateOnInstances_OnMaster_BizTalkMsgBoxDb',
    'Output File Cleanup',
    'PurgeSSAResponseTable',
    'PurgeSubscriptionsJob_BizTalkMsgBoxDb',
    'RemoveStuckTasks - DCSE_CORE_TEST',
    'Replication agents checkup',
    'Rules_Database_Cleanup_BizTalkRuleEngineDb',
    'sp_delete_backuphistory',
    'sp_purge_jobhistory',
    'SQL Sentry 2.0 Alert Trap',
    'SSIS Failover Monitor Job',
    'SSIS Server Maintenance Job',
    'syspolicy_purge_history',
    'TrackedMessages_Copy_BizTalkMsgBoxDb',
    'DBA_USER_LOG_BACKUP_FULL'
)

if (-not (Connect-DbaInstance -SqlInstance $datastore_instance -SqlCredential $sqlmetrics )) {
    throw 'Cant connect to DBA instance.'
    exit
}