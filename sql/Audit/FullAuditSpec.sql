USE [master]
GO
/****** Object:  Audit [Login_Change_Failed]    Script Date: 1/8/2020 3:18:28 PM ******/
CREATE SERVER AUDIT [Login_Change_Failed]
TO FILE ( FILEPATH = N'M:\Management\Audit', MAXSIZE = 150 MB )
ALTER SERVER AUDIT [Login_Change_Failed] WITH (STATE = ON)
GO
CREATE SERVER AUDIT SPECIFICATION [Login_Change_Failed_Spec]
FOR SERVER AUDIT [Login_Change_Failed]
ADD (FAILED_DATABASE_AUTHENTICATION_GROUP),
ADD (FAILED_LOGIN_GROUP),
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (LOGIN_CHANGE_PASSWORD_GROUP),
ADD (USER_CHANGE_PASSWORD_GROUP)
WITH (STATE = ON)
GO

USE [master]
GO
/****** Object:  Audit [Permission_Change]    Script Date: 1/8/2020 3:18:04 PM ******/
CREATE SERVER AUDIT [Permission_Change]
TO FILE ( FILEPATH = N'M:\Management\Audit', MAXSIZE = 150 MB )
ALTER SERVER AUDIT [Permission_Change] WITH (STATE = ON)
GO
CREATE SERVER AUDIT SPECIFICATION [Permission_Change_Spec]
FOR SERVER AUDIT [Permission_Change]
ADD (DATABASE_PERMISSION_CHANGE_GROUP),
ADD (DATABASE_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),
ADD (SERVER_OBJECT_PERMISSION_CHANGE_GROUP)
WITH (STATE = ON)
GO

USE [master]
GO
/****** Object:  Audit [Object_Change]    Script Date: 1/8/2020 3:17:32 PM ******/
CREATE SERVER AUDIT [Object_Change]
TO FILE ( FILEPATH = N'M:\Management\Audit', MAXSIZE = 150 MB )
WHERE (NOT ([object_name]='telemetry_xevents' OR [server_principal_name]='Sentry' OR [server_principal_name] LIKE '%SQLTELEMETRY%' OR [statement] LIKE 'RESTORE VERIFYONLY%' OR [statement] LIKE 'RESTORE LABELONLY%'))
ALTER SERVER AUDIT [Object_Change] WITH (STATE = ON)
GO
CREATE SERVER AUDIT SPECIFICATION [Object_Change_Spec]
FOR SERVER AUDIT [Object_Change]
ADD (DATABASE_CHANGE_GROUP),
ADD (DATABASE_OBJECT_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_CHANGE_GROUP),
ADD (SERVER_OBJECT_CHANGE_GROUP)
WITH (STATE = ON)
GO

USE [master]
GO
/****** Object:  Audit [Prinicipal_Change]    Script Date: 1/8/2020 3:16:56 PM ******/
CREATE SERVER AUDIT [Principal_Change]
TO FILE ( FILEPATH = N'M:\Management\Audit', MAXSIZE = 150 MB )
ALTER SERVER AUDIT [Principal_Change] WITH (STATE = ON)
GO
CREATE SERVER AUDIT SPECIFICATION [Principal_Change_Spec]
FOR SERVER AUDIT [Principal_Change]
ADD (SERVER_PRINCIPAL_CHANGE_GROUP),
ADD (DATABASE_OWNERSHIP_CHANGE_GROUP),
ADD (DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP),
ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP)
WITH (STATE = ON)
GO

USE [master]
GO
/****** Object:  Audit [Audit_Change]    Script Date: 1/8/2020 3:12:58 PM ******/
CREATE SERVER AUDIT [Audit_Change]
TO FILE ( FILEPATH = N'M:\Management\Audit', MAXSIZE = 150 MB )
ALTER SERVER AUDIT [Audit_Change] WITH (STATE = ON)
GO
CREATE SERVER AUDIT SPECIFICATION [Audit_Change_Spec]
FOR SERVER AUDIT [Audit_Change]
ADD (AUDIT_CHANGE_GROUP)
WITH (STATE = ON)
GO

USE [master]
GO
/****** Object:  Audit [SSA_Change]    Script Date: 2/25/2020 10:58:37 AM ******/
CREATE SERVER AUDIT [SSA_Change]
TO FILE 
( FILEPATH = N'M:\Management\Audit', MAXSIZE = 150 MB )
ALTER SERVER AUDIT [SSA_Change] WITH (STATE = ON)
GO
USE [msdb] /* this is a database audit, so changing context */
GO
CREATE DATABASE AUDIT SPECIFICATION [SSA_Change_Spec]
FOR SERVER AUDIT [SSA_Change]
ADD (EXECUTE ON OBJECT::[dbo].[sp_add_schedule] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_attach_schedule] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_detach_schedule] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_update_schedule] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_delete_schedule] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_add_jobstep] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_update_jobstep] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_delete_jobstep] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_add_jobschedule] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_update_jobschedule] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_delete_jobschedule] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_add_job] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_update_job] BY [public]),
ADD (EXECUTE ON OBJECT::[dbo].[sp_delete_job] BY [public])
WITH (STATE = ON)
GO

USE [master]
GO
/****** Object:  Audit [Instance_Config_Change]    Script Date: 2/25/2020 10:58:37 AM ******/
CREATE SERVER AUDIT [Instance_Config_Change]
TO FILE 
( FILEPATH = N'M:\Management\Audit', MAXSIZE = 150 MB )
ALTER SERVER AUDIT [Instance_Config_Change] WITH (STATE = ON)
GO
USE [master] /* this is a database audit, dont really need to change context again */
GO
CREATE DATABASE AUDIT SPECIFICATION [Instance_Config_Change_Spec]
FOR SERVER AUDIT [Instance_Config_Change]
ADD (EXECUTE ON OBJECT::[sys].[sp_configure] BY [public])
WITH (STATE = ON)
GO
