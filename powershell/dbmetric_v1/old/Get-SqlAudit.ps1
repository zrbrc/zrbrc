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

# $datatable = New-Object System.Data.DataTable
$datatable = New-Object System.Data.DataTable
$datatable.Columns.Add((New-Object System.Data.DataColumn 'ID', ([int]))) # this table ID, not a data field to capture or set
$datatable.Columns.Add((New-Object System.Data.DataColumn 'RecordTime', ([DateTime])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'AuditLog', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'event_time', ([DateTime])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'sequence_number', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'action_id', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'succeeded', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'is_column_permission', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'session_id', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'server_principal_id', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'database_principal_id', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'target_server_principal_id', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'target_database_principal_id', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'object_id', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'class_type', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'session_server_principal_name', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'server_principal_name', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'server_principal_sid', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'database_principal_name', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'target_server_principal_name', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'target_server_principal_sid', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'target_database_principal_name', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'server_instance_name', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'database_name', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'schema_name', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'object_name', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'statement', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'file_name', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'audit_file_offset', ([Int64])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'user_defined_event_id', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'user_defined_information', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'audit_schema_version', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'sequence_group_id', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'transaction_id', ([Int64])))

foreach ($server in $Servers | Where-Object { $_.Domain -eq $Domain -and $_.DMZ -eq $Zone -and $_.Type -eq 2 } ) {
    "$($server.HostName)"

    $Audits = Get-DbaInstanceAudit -SqlInstance "$($server.HostName),$($server.SqlServerPort)" 

    # get start and end dates
    $YesterdayStart = (Get-Date -Hour 0 -Minute 0 -Second 0).AddDays(-1)
    $YesterdayEnd = (Get-Date -Hour 0 -Minute 0 -Second 0)

    # loop thru each audit type and dump to SQL
    foreach ($Audit in $Audits) {

        $query = "SELECT
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
       WHERE  event_time >= '$YesterdayStart'
       AND    event_time < '$YesterdayEnd'"
       
        # gets audit data from server
        $data = Invoke-DbaQuery -SqlInstance "$($server.HostName),$($server.SqlServerPort)"  -Database 'master' -Query $query 

        foreach ($record in $data) {

            # decode the action_id
            switch ($record.action_id) {
                "ACDO" { $action = "DATABASE_OBJECT_ACCESS_GROUP" }
                " " { $action = "SCHEMA_OBJECT_ACCESS_GROUP" }
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

            $row = $datatable.NewRow()
            $row['RecordTime'] = [DateTime](Get-Date)
            $row['AuditLog'] = $Audit.Name
            $row['event_time'] = $record.event_time
            $row['sequence_number'] = $record.sequence_number
            $row['action_id'] = $action
            $row['succeeded'] = $record.succeeded
            $row['is_column_permission'] = $record.is_column_permission
            $row['session_id'] = $record.session_id
            $row['server_principal_id'] = $record.server_principal_id
            $row['database_principal_id'] = $record.database_principal_id
            $row['target_server_principal_id'] = $record.target_server_principal_id
            $row['target_database_principal_id'] = $record.target_database_principal_id
            $row['object_id'] = $record.object_id
            $row['class_type'] = $record.class_type
            $row['session_server_principal_name'] = $record.session_server_principal_name
            $row['server_principal_name'] = $record.server_principal_name
            $row['server_principal_sid'] = $record.server_principal_sid
            $row['database_principal_name'] = $record.database_principal_name
            $row['target_server_principal_name'] = $record.target_server_principal_name
            $row['target_server_principal_sid'] = $record.target_server_principal_sid
            $row['target_database_principal_name'] = $record.target_database_principal_name
            $row['server_instance_name'] = $record.server_instance_name
            $row['database_name'] = $record.database_name
            $row['schema_name'] = $record.schema_name
            $row['object_name'] = $record.object_name
            $row['statement'] = $record.statement
            $row['file_name'] = $record.file_name
            $row['audit_file_offset'] = $record.audit_file_offset
            $row['user_defined_event_id'] = $record.user_defined_event_id
            $row['user_defined_information'] = $record.user_defined_information
            $row['audit_schema_version'] = $record.audit_schema_version
            $row['sequence_group_id'] = $record.sequence_group_id
            $row['transaction_id'] = $record.transaction_id
            $datatable.Rows.Add($row)

        }
    }
}

Write-SqlTableData -ServerInstance $DBAInstance -DatabaseName 'DBA' -SchemaName 'dbo' -TableName 'Audits_T' -InputData $datatable -ErrorAction Stop