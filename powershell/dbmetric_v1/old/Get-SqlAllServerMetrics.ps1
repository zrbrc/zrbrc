# bring in functions
. .\Functions.ps1

# bring in configuration
. .\Config.ps1


############################################################################
# init
#region ####################################################################
$Now = Get-Date
$Now
$ErrorActionPreference = 'Stop'

# instance config
$Instance = 'hostnameCLS1LS1,15150'
$Database = 'DBA'
$Schema = 'dbo'

# input and log tables
$ServerTable = 'Servers_T'
$RunlogTable = 'Runlog_T'

# output tables
$AuditTable = 'Audits_T'
$BackupHistoryTable = 'BackupHistory_T'
$BlitzTable = 'Blitz_T'
$DriveStatsTable = 'DriveStats_T'
$JobsTable = 'Jobs_T'
$LogonErrorsTable = 'LogonErrors_T'

# metric names
$AuditName = 'Audit'
$BackupsName = 'Backup'
$BlitzName = 'Blitz'
$DriveStatsName = 'Drive'
$JobsName = 'Jobs'
$LogonErrorsName = 'Logon'

# get local ip, subnet and domain--we use this to filter each zone later on
$LocalIP = (Test-Connection $env:COMPUTERNAME -Count 1).IPV4Address.IPAddressToString
$LocalSubnet = (Get-NetIpAddress | Where-Object { $_.IpAddress -eq $LocalIP }).PrefixLength | Get-SubnetMask
$Domain = (Get-ADDomain).Name
#endregion

############################################################################
# create data tables to store all our data
#region ####################################################################


$RunlogDT = New-Object System.Data.DataTable
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([Int])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'RunTime', ([DateTime])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([String])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'Metric', ([String])))

$AuditDT = New-Object System.Data.DataTable
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([int])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'RecordTime', ([DateTime])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'AuditLog', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'event_time', ([DateTime])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'sequence_number', ([Int])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'action_id', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'succeeded', ([Int])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'is_column_permission', ([Int])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'session_id', ([Int])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'server_principal_id', ([Int])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'database_principal_id', ([Int])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'target_server_principal_id', ([Int])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'target_database_principal_id', ([Int])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'object_id', ([Int])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'class_type', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'session_server_principal_name', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'server_principal_name', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'server_principal_sid', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'database_principal_name', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'target_server_principal_name', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'target_server_principal_sid', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'target_database_principal_name', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'server_instance_name', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'database_name', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'schema_name', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'object_name', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'statement', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'file_name', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'audit_file_offset', ([Int64])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'user_defined_event_id', ([Int])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'user_defined_information', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'audit_schema_version', ([Int])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'sequence_group_id', ([String])))
$AuditDT.Columns.Add((New-Object System.Data.DataColumn 'transaction_id', ([Int64])))

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

$JobsDT = New-Object System.Data.DataTable
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([Int])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'SqlInstance', ([string])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'JobName', ([String])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'JobId', ([String])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'InstanceId', ([Int])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'StartDate', ([DateTime])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'EndDate', ([DateTime])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'RunDuration', ([Int])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'Status', ([String])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'Message', ([String])))

$BlitzDT = New-Object System.Data.DataTable
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([int])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'Runtime', ([DateTime])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([String])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'Priority', ([Int])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'FindingsGroup', ([String])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'Finding', ([String])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'DatabaseName', ([String])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'Details', ([String])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'QueryPlan', ([String])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'QueryPlanFiltered', ([String])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'CheckID', ([Int])))

$DrivesDT = New-Object System.Data.DataTable
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([int])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'RunTimeStamp', ([DateTime])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([string])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'ServerIp', ([string])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'DriveLetter', ([string])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'DriveLabel', ([string])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'SizeGB', ([decimal])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'FreeGB', ([decimal])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'FreePercent', ([decimal])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'History_CD', ([int])))

$EventsDT = New-Object System.Data.DataTable
$EventsDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([int])))
$EventsDT.Columns.Add((New-Object System.Data.DataColumn 'RecordTime', ([DateTime])))
$EventsDT.Columns.Add((New-Object System.Data.DataColumn 'EventId', ([Int])))
$EventsDT.Columns.Add((New-Object System.Data.DataColumn 'LogName', ([String])))
$EventsDT.Columns.Add((New-Object System.Data.DataColumn 'ServerHostname', ([String])))
$EventsDT.Columns.Add((New-Object System.Data.DataColumn 'Username', ([String])))
$EventsDT.Columns.Add((New-Object System.Data.DataColumn 'Domain', ([String])))
$EventsDT.Columns.Add((New-Object System.Data.DataColumn 'SourceHostname', ([String])))
$EventsDT.Columns.Add((New-Object System.Data.DataColumn 'EventRecordID', ([Int])))
$EventsDT.Columns.Add((New-Object System.Data.DataColumn 'EventType', ([String])))
$EventsDT.Columns.Add((New-Object System.Data.DataColumn 'EventTime', ([DateTime])))
#endregion


# gets the latest list of sql instances we created above.
$Query = "SELECT * FROM Servers_V ORDER BY Servername"
$Servers = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $Query
#endregion

############################################################################
# get runlog data
#region ####################################################################

$Query = "SELECT MAX(RunTime) as LastRunTime, ServerName, Metric FROM $RunlogTable Group by ServerName, Metric"
$LastRun = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $Query
#endregion

############################################################################
# query our servers for info
#region ####################################################################
foreach ($Server in $Servers) {
    try {
        # if subnet mask and domain dont match and the server details are older than 15 minutes, skip it
        if ( -not ((([System.Net.IPAddress]$LocalIP).Address -band $LocalSubnet.Address ) -eq 
                (([System.Net.IPAddress]$Server.IP).Address -band $LocalSubnet.Address) -and 
                $Server.Domain -eq $Domain -and
                $Server.Timestamp -gt (Get-Date).AddMinutes(-60) )) {
            "Skipping: {0} {1}" -f $Server.Servername, $Server.IP
            continue
        }

        # sql server metrics
        "Sql Server: {0}" -f $Server.Servername
    
        #region audit
        "`tMetric: Audit"
        # clear audit table to start fresh for next server
        $AuditDT.Clear()

        # get start time, either since the last run or last 24 hours
        if (-not ($AuditStartTime = $LastRun | Where-Object { $_.ServerName -eq $Server.Servername -and $_.Metric -eq $AuditName } | Select-Object -ExpandProperty LastRunTime )) {
            $AuditStartTime = (Get-Date).ToUniversalTime().AddHours(-24)
        }

        # get audit definitions
        $Audits = Get-DbaInstanceAudit -SqlInstance "$($Server.Servername),$($Server.Port)" -EnableException

        foreach ($Audit in $Audits) {
            $Query = "SELECT
                  event_time,
                  sequence_number,
                  action_id,
                  succeeded,
                  is_column_permission,
                  session_id,
                  server_principal_id,
                  database_principal_id,
                  target_server_principal_id,
                  target_database_principal_id,
                  object_id,
                  class_type,
                  session_server_principal_name,
                  server_principal_name,
                  convert(varchar(50), server_principal_sid, 2) as server_principal_sid,
                  database_principal_name,
                  target_server_principal_name,
                  convert(varchar(50), target_server_principal_sid, 2) as target_server_principal_sid,
                  target_database_principal_name,
                  server_instance_name,
                  database_name,
                  schema_name,
                  object_name,
                  statement,
                  file_name,
                  audit_file_offset,
                  user_defined_event_id,
                  user_defined_information,
                  audit_schema_version,
                  convert(varchar(50), sequence_group_id, 2) as sequence_group_id,
                  transaction_id
           FROM   sys.fn_get_audit_file('M:\Management\Audit\$($Audit.Name)*.sqlaudit', DEFAULT, DEFAULT)
           WHERE  event_time >= '$AuditStartTime'
           AND    event_time < '$($Now.ToUniversalTime())'"
   
            # gets audit data from server
            Invoke-DbaQuery -SqlInstance "$($Server.Servername),$($Server.Port)" -Database 'master' -Query $Query -EnableException |
            ForEach-Object {

                # decode the action_id
                switch ($_.action_id) {
                    "ACDO" { $action = "DATABASE_OBJECT_ACCESS_GROUP" }
                    "ACO  " { $action = "SCHEMA_OBJECT_ACCESS_GROUP" }
                    "ADBO" { $action = "BULKADMIN" }
                    "ADDP" { $action = "DATABASE_ROLE_MEMBER_CHANGE_GROUP" }
                    "ADSP" { $action = "SERVER_ROLE_MEMBER_CHANGE_GROUP" }
                    "AL  " { $action = "ALTER" }
                    "ALCN" { $action = "ALTERCONNECTION" }
                    "ALRS" { $action = "ALTERRESOURCES" }
                    "ALSS" { $action = "ALTERSERVERSTATE" }
                    "ALST" { $action = "ALTERSETTINGS" }
                    "ALTR" { $action = "ALTERTRACE" }
                    "APRL" { $action = "ADDMEMBER" }
                    "AS  " { $action = "ACCESS" }
                    "AUSC" { $action = "AUDITSESSIONCHANGED" }
                    "AUSF" { $action = "AUDITSHUTDOWNONFAILURE" }
                    "AUTH" { $action = "AUTHENTICATE" }
                    "BA  " { $action = "BACKUP" }
                    "BAL " { $action = "BACKUPLOG" }
                    "BCM " { $action = "BATCHCOMPLETED" }
                    "BCMG" { $action = "BATCH_COMPLETED_GROUP" }
                    "BRDB" { $action = "BACKUP_RESTORE_GROUP" }
                    "BST " { $action = "BATCHSTARTED" }
                    "BSTG" { $action = "BATCH_STARTED_GROUP" }
                    "C2OF" { $action = "TRACEAUDITC2OFF" }
                    "C2ON" { $action = "TRACEAUDITC2ON" }
                    "CCLG" { $action = "CHANGELOGINCREDENTIAL" }
                    "CMLG" { $action = "CREDENTIALMAPTOLOGIN" }
                    "CNAU" { $action = "AUDIT_CHANGE_GROUP" }
                    "CO  " { $action = "CONNECT" }
                    "CP  " { $action = "CHECKPOINT" }
                    "CR  " { $action = "CREATE" }
                    "D   " { $action = "DENY" }
                    "DAGF" { $action = "FAILED_DATABASE_AUTHENTICATION_GROUP" }
                    "DAGL" { $action = "DATABASE_LOGOUT_GROUP" }
                    "DAGS" { $action = "SUCCESSFUL_DATABASE_AUTHENTICATION_GROUP" }
                    "DBAF" { $action = "DATABASEAUTHENTICATIONFAILED" }
                    "DBAS" { $action = "DATABASEAUTHENTICATIONSUCCEEDED" }
                    "DBCC" { $action = "DBCC" }
                    "DBCG" { $action = "DBCC_GROUP" }
                    "DBL " { $action = "DATABASELOGOUT" }
                    "DL  " { $action = "DELETE" }
                    "DPRL" { $action = "DROPMEMBER" }
                    "DR  " { $action = "DROP" }
                    "DWC " { $action = "DENYWITHCASCADE" }
                    "EX  " { $action = "EXECUTE" }
                    "FT  " { $action = "FULLTEXT" }
                    "FTG " { $action = "FULLTEXT_GROUP" }
                    "G   " { $action = "GRANT" }
                    "GRDB" { $action = "DATABASE_PERMISSION_CHANGE_GROUP" }
                    "GRDO" { $action = "DATABASE_OBJECT_PERMISSION_CHANGE_GROUP" }
                    "GRO " { $action = "SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP" }
                    "GRSO" { $action = "SERVER_OBJECT_PERMISSION_CHANGE_GROUP" }
                    "GRSV" { $action = "SERVER_PERMISSION_CHANGE_GROUP" }
                    "GWG " { $action = "GRANTWITHGRANT" }
                    "IMDP" { $action = "DATABASE_PRINCIPAL_IMPERSONATION_GROUP" }
                    "IMP " { $action = "IMPERSONATE" }
                    "IMSP" { $action = "SERVER_PRINCIPAL_IMPERSONATION_GROUP" }
                    "IN  " { $action = "INSERT" }
                    "LGB " { $action = "BROKERLOGIN" }
                    "LGBG" { $action = "BROKER_LOGIN_GROUP" }
                    "LGDA" { $action = "DISABLE" }
                    "LGDB" { $action = "CHANGEDEFAULTDATABASE" }
                    "LGEA" { $action = "ENABLE" }
                    "LGFL" { $action = "FAILED_LOGIN_GROUP" }
                    "LGG " { $action = "GLOBALTRANSACTIONSLOGIN" }
                    "LGGG" { $action = "GLOBAL_TRANSACTIONS_LOGIN_GROUP" }
                    "LGIF" { $action = "LOGINFAILED" }
                    "LGIS" { $action = "LOGINSUCCEEDED" }
                    "LGLG" { $action = "CHANGEDEFAULTLANGUAGE" }
                    "LGM " { $action = "DATABASEMIRRORINGLOGIN" }
                    "LGMG" { $action = "DATABASE_MIRRORING_LOGIN_GROUP" }
                    "LGNM" { $action = "NAMECHANGE" }
                    "LGO " { $action = "LOGOUT" }
                    "LGSD" { $action = "SUCCESSFUL_LOGIN_GROUP" }
                    "LO  " { $action = "LOGOUT_GROUP" }
                    "MNDB" { $action = "DATABASE_CHANGE_GROUP" }
                    "MNDO" { $action = "DATABASE_OBJECT_CHANGE_GROUP" }
                    "MNDP" { $action = "DATABASE_PRINCIPAL_CHANGE_GROUP" }
                    "MNO " { $action = "SCHEMA_OBJECT_CHANGE_GROUP" }
                    "MNSO" { $action = "SERVER_OBJECT_CHANGE_GROUP" }
                    "MNSP" { $action = "SERVER_PRINCIPAL_CHANGE_GROUP" }
                    "NMLG" { $action = "NOCREDENTIALMAPTOLOGIN" }
                    "OP  " { $action = "OPEN" }
                    "OPDB" { $action = "DATABASE_OPERATION_GROUP" }
                    "OPSV" { $action = "SERVER_OPERATION_GROUP" }
                    "PWAR" { $action = "APPLICATION_ROLE_CHANGE_PASSWORD_GROUP" }
                    "PWC " { $action = "CHANGEPASSWORD" }
                    "PWCG" { $action = "LOGIN_CHANGE_PASSWORD_GROUP" }
                    "PWCS" { $action = "CHANGEOWNPASSWORD" }
                    "PWEX" { $action = "PASSWORDEXPIRATION" }
                    "PWMC" { $action = "MUSTCHANGEPASSWORD" }
                    "PWPL" { $action = "PASSWORDPOLICY" }
                    "PWR " { $action = "RESETPASSWORD" }
                    "PWRS" { $action = "RESETOWNPASSWORD" }
                    "PWU " { $action = "UNLOCKACCOUNT" }
                    "R   " { $action = "REVOKE" }
                    "RC  " { $action = "RECEIVE" }
                    "RF  " { $action = "REFERENCES" }
                    "RS  " { $action = "RESTORE" }
                    "RWC " { $action = "REVOKEWITHCASCADE" }
                    "RWG " { $action = "REVOKEWITHGRANT" }
                    "SL  " { $action = "SELECT" }
                    "SN  " { $action = "SEND" }
                    "SPLN" { $action = "SHOWPLAN" }
                    "STSV" { $action = "SERVER_STATE_CHANGE_GROUP" }
                    "SUQN" { $action = "SUBSCRIBEQUERYNOTIFICATION" }
                    "SVCN" { $action = "SERVERCONTINUE" }
                    "SVPD" { $action = "SERVERPAUSED" }
                    "SVSD" { $action = "SERVERSHUTDOWN" }
                    "SVSR" { $action = "SERVERSTARTED" }
                    "TASA" { $action = "TRACEAUDITSTART" }
                    "TASP" { $action = "TRACEAUDITSTOP" }
                    "TO  " { $action = "TAKEOWNERSHIP" }
                    "TODB" { $action = "DATABASE_OWNERSHIP_CHANGE_GROUP" }
                    "TODO" { $action = "DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP" }
                    "TOO " { $action = "SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP" }
                    "TOSO" { $action = "SERVER_OBJECT_OWNERSHIP_CHANGE_GROUP" }
                    "TRCG" { $action = "TRACE_CHANGE_GROUP" }
                    "TRO " { $action = "TRANSFER" }
                    "TX  " { $action = "TRANSACTION_GROUP" }
                    "TXBG" { $action = "TRANSACTIONBEGIN" }
                    "TXCG" { $action = "TRANSACTION_COMMIT_GROUP" }
                    "TXCM" { $action = "TRANSACTIONCOMMIT" }
                    "TXGG" { $action = "TRANSACTION_BEGIN_GROUP" }
                    "TXRB" { $action = "TRANSACTIONROLLBACK" }
                    "TXRG" { $action = "TRANSACTION_ROLLBACK_GROUP" }
                    "UCGP" { $action = "USER_CHANGE_PASSWORD_GROUP" }
                    "UDAG" { $action = "USER_DEFINED_AUDIT_GROUP" }
                    "UDAU" { $action = "USERDEFINEDAUDIT" }
                    "UNDG" { $action = "STATEMENT_ROLLBACK_GROUP" }
                    "UNDO" { $action = "STATEMENTROLLBACK" }
                    "UP  " { $action = "UPDATE" }
                    "USAF" { $action = "CHANGEUSERSLOGINAUTO" }
                    "USLG" { $action = "CHANGEUSERSLOGIN" }
                    "USTC" { $action = "COPYPASSWORD" }
                    "VDST" { $action = "VIEWDATABASESTATE" }
                    "VSST" { $action = "VIEWSERVERSTATE" }
                    "VW  " { $action = "VIEW" }
                    "VWCT" { $action = "VIEWCHANGETRACKING" }
                    "XA  " { $action = "EXTERNALACCESSASSEMBLY" }
                    "XU  " { $action = "UNSAFEASSEMBLY" }
                    default { $action = $record.action_id }
                }

                $AuditRow = $AuditDT.NewRow()
                $AuditRow['RecordTime'] = [DateTime](Get-Date)
                $AuditRow['AuditLog'] = $Audit.Name
                $AuditRow['event_time'] = $_.event_time
                $AuditRow['sequence_number'] = $_.sequence_number
                $AuditRow['action_id'] = $action
                $AuditRow['succeeded'] = $_.succeeded
                $AuditRow['is_column_permission'] = $_.is_column_permission
                $AuditRow['session_id'] = $_.session_id
                $AuditRow['server_principal_id'] = $_.server_principal_id
                $AuditRow['database_principal_id'] = $_.database_principal_id
                $AuditRow['target_server_principal_id'] = $_.target_server_principal_id
                $AuditRow['target_database_principal_id'] = $_.target_database_principal_id
                $AuditRow['object_id'] = $_.object_id
                $AuditRow['class_type'] = $_.class_type
                $AuditRow['session_server_principal_name'] = $_.session_server_principal_name
                $AuditRow['server_principal_name'] = $_.server_principal_name
                $AuditRow['server_principal_sid'] = $_.server_principal_sid
                $AuditRow['database_principal_name'] = $_.database_principal_name
                $AuditRow['target_server_principal_name'] = $_.target_server_principal_name
                $AuditRow['target_server_principal_sid'] = $_.target_server_principal_sid
                $AuditRow['target_database_principal_name'] = $_.target_database_principal_name
                $AuditRow['server_instance_name'] = $_.server_instance_name
                $AuditRow['database_name'] = $_.database_name
                $AuditRow['schema_name'] = $_.schema_name
                $AuditRow['object_name'] = $_.object_name
                $AuditRow['statement'] = $_.statement
                $AuditRow['file_name'] = $_.file_name
                $AuditRow['audit_file_offset'] = $_.audit_file_offset
                $AuditRow['user_defined_event_id'] = $_.user_defined_event_id
                $AuditRow['user_defined_information'] = $_.user_defined_information
                $AuditRow['audit_schema_version'] = $_.audit_schema_version
                $AuditRow['sequence_group_id'] = $_.sequence_group_id
                $AuditRow['transaction_id'] = $_.transaction_id
                $AuditDT.Rows.Add($AuditRow)
            }
        }

        $RunlogRow = $RunlogDT.NewRow()
        $RunlogRow['Runtime'] = $Now.ToUniversalTime()
        $RunlogRow['ServerName'] = $Server.Servername
        $RunlogRow['Metric'] = $AuditName
        $RunlogDT.Rows.Add($RunlogRow)
        #endregion

        #region backuphistory
        "`tMetric: Backup"

        # clear audit table to start fresh for next server
        $BackupsDT.Clear()

        # get start time, either since the last run or last 24 hours
        if (-not ($BackupStartTime = $LastRun | Where-Object { $_.ServerName -eq $Server.Servername -and $_.Metric -eq $BackupsName } | Select-Object -ExpandProperty LastRunTime )) {
            $BackupStartTime = (Get-Date).AddHours(-24)
        }

        # get backup history
        Get-DbaDbBackupHistory -SqlInstance "$($Server.Servername),$($Server.Port)" -IncludeCopyOnly -Type Full, Differential -Since $BackupStartTime -EnableException |
        ForEach-Object {
            $BackupsRow = $BackupsDT.NewRow()
            $BackupsRow['RunTimeStamp'] = [DateTime](Get-Date)
            $BackupsRow['SqlInstance'] = $_.SqlInstance
            $BackupsRow['Database'] = $_.Database
            $BackupsRow['Start'] = [DateTime]$_.Start
            $BackupsRow['End'] = [DateTime]$_.End
            $BackupsRow['Duration'] = $_.Duration
            $BackupsRow['FilePath'] = ($_.Path -join ',')
            $BackupsRow['BackupSizeGB'] = [Decimal]$_.TotalSize.Gigabyte
            $BackupsRow['CompressedBackupSizeGB'] = [Decimal]$_.CompressedBackupSize.Gigabyte
            $BackupsRow['CompressionRatio'] = [Decimal]$_.CompressionRatio
            $BackupsRow['Type'] = $_.Type
            $BackupsRow['BackupSetId'] = $_.BackupSetId
            $BackupsRow['IsCopyOnly'] = $_.IsCopyOnly
            $BackupsDT.Rows.Add($BackupsRow)
        }

        $RunlogRow = $RunlogDT.NewRow()
        $RunlogRow['Runtime'] = $Now
        $RunlogRow['ServerName'] = $Server.Servername
        $RunlogRow['Metric'] = $BackupsName
        $RunlogDT.Rows.Add($RunlogRow)
        #endregion

        #region jobhistory
        "`tMetric: Jobs"
        # get start time, either since the last run or last 24 hours
        if (-not ($JobStartTime = $LastRun | Where-Object { $_.ServerName -eq $Server.Servername -and $_.Metric -eq $JobsName } | Select-Object -ExpandProperty LastRunTime )) {
            $JobStartTime = (Get-Date).AddHours(-24)
        }

        Get-DbaAgentJobHistory -SqlInstance "$($Server.Servername),$($Server.Port)" -StartDate $JobStartTime -EndDate $Now -ExcludeJobSteps -EnableException |
        ForEach-Object {
            $JobsRow = $JobsDT.NewRow()
            $JobsRow['SqlInstance'] = $_.SqlInstance
            $JobsRow['JobName'] = $_.JobName
            $JobsRow['JobId'] = $_.JobID
            $JobsRow['InstanceId'] = $_.InstanceID
            $JobsRow['StartDate'] = [DateTime]$_.StartDate
            $JobsRow['EndDate'] = [DateTime]$_.EndDate
            $JobsRow['RunDuration'] = [Int]$_.RunDuration
            $JobsRow['Status'] = $_.Status
            $JobsRow['Message'] = $_.Message
            $JobsDT.Rows.Add($JobsRow)
        }
        $RunlogRow = $RunlogDT.NewRow()
        $RunlogRow['Runtime'] = $Now
        $RunlogRow['ServerName'] = $Server.Servername
        $RunlogRow['Metric'] = $JobsName
        $RunlogDT.Rows.Add($RunlogRow)
        #endregion

        #region blitz
        "`tMetric: Blitz"
        # put this in a try in case Blitz is not installed there, we can trap it
        try {
            Invoke-DbaQuery -SqlInstance "$($Server.Servername),$($Server.Port)" -Database master -Query 'EXEC sp_Blitz' -EnableException |
            ForEach-Object {
                $BlitzRow = $BlitzDT.NewRow()
                $BlitzRow['Runtime'] = $now
                $BlitzRow['ServerName'] = $Server.Servername
                $BlitzRow['Priority'] = $_.Priority
                $BlitzRow['FindingsGroup'] = $_.FindingsGroup
                $BlitzRow['Finding'] = $_.Finding
                $BlitzRow['DatabaseName'] = $_.DatabaseName
                $BlitzRow['Details'] = $_.Details
                $BlitzRow['QueryPlan'] = $_.QueryPlan
                $BlitzRow['QueryPlanFiltered'] = $_.QueryPlanFiltered
                $BlitzRow['CheckID'] = $_.CheckID
                $BlitzDT.Rows.Add($row)
            }
            $RunlogRow = $RunlogDT.NewRow()
            $RunlogRow['Runtime'] = $Now
            $RunlogRow['ServerName'] = $Server.Servername
            $RunlogRow['Metric'] = $BlitzName
            $RunlogDT.Rows.Add($RunlogRow)
        }
        catch {
            "`tBlitz failed to execute on {0}." -f $Server.Servername
        }
        #endregion

        #region drive stats
        "`tMetric: DriveStats"
        Get-CimInstance -Class CIM_LogicalDisk -ComputerName $Server.Servername | Where-Object { $_.DriveType -eq '3' } | ForEach-Object {

            $DrivesRow = $DrivesDT.NewRow()
            $DrivesRow['RunTimeStamp'] = [DateTime](Get-Date)
            $DrivesRow['ServerName'] = $Server.Servername
            $DrivesRow['ServerIp'] = $Server.IP
            $DrivesRow['DriveLetter'] = ($_.DeviceId -replace ':', '')
            $DrivesRow['DriveLabel'] = $_.VolumeName
            $DrivesRow['SizeGB'] = [math]::Round(($_.Size / 1024 / 1024 / 1024), 2)
            $DrivesRow['FreeGB'] = [math]::Round(($_.FreeSpace / 1024 / 1024 / 1024), 2)
            $DrivesRow['FreePercent'] = [math]::Round((($_.FreeSpace / $_.Size) * 100), 2)
            $DrivesRow['History_CD'] = 0
            $DrivesDT.Rows.Add($DrivesRow)
        }

        $RunlogRow = $RunlogDT.NewRow()
        $RunlogRow['Runtime'] = $Now
        $RunlogRow['ServerName'] = $env:COMPUTERNAME
        $RunlogRow['Metric'] = $DriveStatsName
        $RunlogDT.Rows.Add($RunlogRow)
        #endregion

    }
    catch {
        "`t`t {0} failed." -f $Server.Servername
        continue
    }
}

"Event Forwarder: {0}" -f $env:COMPUTERNAME
"`tMetric: Logon Errors"

if (-not ($EventStartTime = $LastRun | Where-Object { $_.ServerName -eq $env:COMPUTERNAME -and $_.Metric -eq $LogonErrorsName } | Select-Object -ExpandProperty LastRunTime )) {
    $EventStartTime = (Get-Date).AddHours(-24)
}

# logon errors are fowarded and collected on the collector server, so this is not a loop of servers
try {
    $Events = Get-WinEvent -FilterHashtable @{
        Logname   = 'ForwardedEvents'
        ID        = '4625'
        StartTime = $EventStartTime
        EndTime   = $Now
    }
    
    $Events | ForEach-Object {
        $EventsRow = $EventsDT.NewRow()
        $EventsRow['RecordTime'] = $Now
        $EventsRow['EventId'] = [INT]$_.Id
        $EventsRow['LogName'] = $_.LogName
        $EventsRow['ServerHostname'] = $_.MachineName
        $EventsRow['Username'] = $_.Properties[5].Value
        $EventsRow['Domain'] = $_.Properties[6].Value
        $EventsRow['SourceHostname'] = $_.Properties[13].value
        $EventsRow['EventRecordID'] = [INT]$_.RecordId
        $EventsRow['EventType'] = $_.TaskDisplayName
        $EventsRow['EventTime'] = [DateTime]$_.TimeCreated
        $EventsDT.Rows.Add($EventsRow)
    }

    $RunlogRow = $RunlogDT.NewRow()
    $RunlogRow['Runtime'] = $Now
    $RunlogRow['ServerName'] = $env:COMPUTERNAME
    $RunlogRow['Metric'] = $LogonErrorsName
    $RunlogDT.Rows.Add($RunlogRow)
}
catch {
    $ErrorException = $_
    if ($ErrorException.CategoryInfo.Category -eq 'ObjectNotFound') {
        "`tNo logon error rows to write."
    }
    else {
        throw "`tCouldnt get winevents."
    }
}
#endregion

############################################################################
# store data collected
#region ####################################################################
if ($AuditDT.Rows.Count -gt 0) {
    "Writing {0} new audit records." -f $AuditDT.Rows.Count
    Write-SqlTableData -InputData $AuditDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $AuditTable
}

if ($BackupsDT.Rows.count -gt 0) {
    "Writing {0} new backup records." -f $BackupsDT.Rows.count
    Write-SqlTableData -InputData $BackupsDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $BackupHistoryTable
}

if ($JobsDT.Rows.count -gt 0) {
    "Writing {0} new job records." -f $JobsDT.Rows.count
    Write-SqlTableData -InputData $JobsDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $JobsTable
}

if ($BlitzDT.Rows.count -gt 0) {
    "Writing {0} new blitz records." -f $BlitzDT.Rows.count
    Write-SqlTableData -InputData $BlitzDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $BlitzTable
}

if ($DrivesDT.Rows.Count -gt 0) {
    "Writing {0} new drive records." -f $DrivesDT.Rows.Count
    Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query 'UPDATE DriveStats_T SET History_CD = 1 WHERE History_CD = 0'
    Write-SqlTableData -InputData $DrivesDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $DriveStatsTable
}

if ($EventsDT.Rows.Count -gt 0) {
    "Writing {0} new event records." -f $EventsDT.Rows.Count
    Write-SqlTableData -InputData $EventsDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $LogonErrorsTable
}
#endregion

############################################################################
# finally store the runlog 
#region ####################################################################
if ($RunlogDT.Rows.Count -gt 0) {
    Write-SqlTableData -InputData $RunlogDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $RunlogTable
}
#endregion
Get-Date