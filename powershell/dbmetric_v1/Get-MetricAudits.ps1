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

$logname = '.\log\Audit_' + (Get-Date -Format 'yyyyMMdd_hhmmss') + '.txt'
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

"Start: {0}" -f (Get-Date -Format g)

# gets local subnet to determine if we should try to scan the target, if out of subnet we skip it later
$LocalSubnet = (Get-NetIpAddress | Where-Object { $_.IpAddress -eq $LocalIP }).PrefixLength | Get-SubnetMask

# gets the latest list of sql instances we created above.
$Query = "SELECT * FROM $ServerTable WHERE History_CD = 0 ORDER BY Servername"
$Servers = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $Query

# get runlog for metric
$Query = "SELECT MAX(RunTime) as LastRunTime, ServerName FROM $RunlogTable WHERE Metric = 'Audit' GROUP BY ServerName"
$LastRun = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $Query

foreach ($Server in $Servers) {
    try {
        $AuditDT.Clear()

        # if subnet mask and domain dont match and the server details are older than 15 minutes, skip it
        if ( -not ((([System.Net.IPAddress]$LocalIP).Address -band $LocalSubnet.Address ) -eq 
                (([System.Net.IPAddress]$Server.IP).Address -band $LocalSubnet.Address) -and 
                $Server.Domain -eq $Domain -and
                $Server.Timestamp -gt (Get-Date).AddMinutes(-60) )) {
            "Skipping: {0} {1}" -f $Server.Servername, $Server.IP
            continue
        }
        
        
        # get start time, either since the last run or last 24 hours
        if (-not ($StartTime = $LastRun | Where-Object { $_.ServerName -eq $Server.Servername } | Select-Object -ExpandProperty LastRunTime )) {
            $StartTime = (Get-Date).ToUniversalTime().AddHours(-24)
        }
        
        "Sql Server: {0} Last Run: {1} UTC" -f $Server.Servername, $StartTime

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
           WHERE  event_time >= '$StartTime'
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

        if ($AuditDT.Rows.Count -gt 0) {
            "Writing {0} new audit records." -f $AuditDT.Rows.Count
            Write-SqlTableData -InputData $AuditDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $AuditTable
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