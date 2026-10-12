USE master
 GO

SELECT * FROM sys.fn_builtin_permissions(DEFAULT)            
              WHERE class_desc IN ('ENDPOINT','LOGIN','SERVER','AVAILABILITY GROUP','SERVER ROLE')            
               ORDER BY class_desc, permission_name