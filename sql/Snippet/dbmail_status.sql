-- Msg 14641, Sev 16, State 1, Line 81 : Mail not queued. Database Mail is stopped. Use sysmail_start_sp to start Database Mail. [SQLSTATE 42000]

-- 1. To investigate this issue, firstly confirm whether Database Mail is enabled or not by executing below queries in SQL Server Management Studio-

sp_configure 'show advanced', 1; 
       GO
RECONFIGURE;
       GO
sp_configure;
       GO

-- If the resultset show run_value as 1 then Database Mail is enabled.

-- 2. If the Database Mail option is disabled then run the below queries to enable it-

sp_configure 'Database Mail XPs', 1; 
       GO
RECONFIGURE;
       GO

sp_configure 'show advanced', 0; 
       GO
RECONFIGURE;
       GO

-- 3. Once the Database Mail is enabled then start it using below query on msdb database-

USE msdb
;
EXEC msdb.dbo.sysmail_start_sp;

-- 4. To confirm that Database Mail External Program is started, run the below query-

EXEC msdb.dbo.sysmail_help_status_sp;

-- 5. If the Database Mail external program is started then check the status of mail queue using below statement-

EXEC msdb.dbo.sysmail_help_queue_sp @queue_type = 'mail';