# SQL Server Audits

## Audits

*Auditing an instance of the SQL Server Database Engine or an individual database involves tracking and logging events that occur on the Database Engine. SQL Server audit lets you create server audits, which can contain server audit specifications for server level events, and database audit specifications for database level events. Audited events can be written to the event logs or to audit files.*

[https://learn.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-database-engine?view=sql-server-ver16](https://learn.microsoft.com/en-us/sql/relational-databases/security/auditing/sql-server-audit-database-engine?view=sql-server-ver16)

We are not capturing data changes--only config, schema, or login/user related changes. You can see what exactly in the next section on creating the Audits.

## Create Audits and Audit Specs

Audits can be created using the script ```FullAuditSpec.sql```. Change any audit types that you do or do not want to be captured, make sure the path exists, and run against the instance(s).

### Filters

Filters can be created on the audit specs to filter out 'junk' events that we are not concerned with capturing. There are some defaults setup on the **Object_Change** audit to filter Sentry and SQLTelemetry events. Filtering needs can also differ depending on the features in use on the instance. For example, Biztalk and DICER both do a lot of table create/truncate for their internal processes that we dont need to capture. The filter on **class_type** and **action_id** is not the code in the logs, it uses an integer value that can viewed in the ```action_id.md``` and ```class_type.md```.

#### Example Filter

```sql
-- the where conditionals are whats used in the filter pane, the rest of the query (SELECT, FROM, etc) is understood already.
(not
  (
  [object_name]='telemetry_xevents' OR 
  [statement] like 'create event session telemetry_xevents%' OR
  [server_principal_name] like '%sentry%' OR 
  [statement] like 'RESTORE VERIFYONLY%' OR 
  [statement] like 'RESTORE LABELONLY%' OR
  [statement] like 'UPDATE STAT%' OR
  [action_id] = 538990422
  )
)
```

## View Audits

Audits events can be viewed either in SSMS via Security\Audits->View Audit logs or via T-SQL using ```get_last_week.sql```, also below. The T-SQL method is more flexible and allows for more filtering and is my preferred method. I generally filter on a couple different things--service accounts and login failures. It really depends on the application using the instance/database.

```sql
-- will check space usage on the audit folder, xp_cmdshell might not be enabled everywhere, so commented out
-- exec xp_cmdshell 'Powershell.exe -Command "& { (Get-ChildItem M:\Management\Audit -ErrorAction Ignore | Measure-Object -Sum Length).Sum / 1GB }"'

-- grabs all audit info from the past week--except login failures, add other filters as necessary
SELECT event_time as event_time_UTC,
       event_time AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS local_time,
       server_instance_name,
       server_principal_name,
       action_id,
       class_type,
       succeeded,
       statement,
       database_principal_name,
       target_server_principal_name,
       database_name,
       schema_name,
       object_name,
       file_name
  FROM sys.fn_get_audit_file('M:\Management\Audit\*.sqlaudit', DEFAULT, DEFAULT)
 WHERE event_time >= DATEADD(day,-8,GETDATE())
   -- AND session_server_principal_name NOT LIKE 'NT Service\%'
   -- AND session_server_principal_name = '<username>'
   AND action_id != 'LGIF'
 ORDER BY event_time DESC
 ```

 END