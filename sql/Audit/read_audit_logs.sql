-- this script is used to read audits file in SSMS from disk.
-- there are a couple of commented lines shows as example. 
-- the below code will read all rows from 1 audit file.

SELECT @@SERVERNAME,
	   file_name,
	   event_time,
	   action_id,
	   session_server_principal_name,
	   server_instance_name,
	   database_name,
	   schema_name,
	   object_name,
	   statement
  FROM sys.fn_get_audit_file('M:\Management\Audit\*.sqlaudit', DEFAULT, DEFAULT)
 WHERE event_time >= '2021-04-01 00:00:00'
   AND session_server_principal_name = '<username>'
   AND statement LIKE '%job%'