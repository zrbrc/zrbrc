-- for a second RFC to update the filters to be more restrictive
USE [master]
GO

ALTER SERVER AUDIT [Object_Change] WITH (STATE = OFF)
GO

ALTER SERVER AUDIT [Object_Change]
WHERE (NOT ([object_name]='telemetry_xevents' OR [statement] like 'create event session telemetry_xevents%' OR [server_principal_name] like '%sentry%' OR [statement] like 'RESTORE VERIFYONLY%' OR [statement] like 'RESTORE LABELONLY%' OR [statement] like 'UPDATE STAT%' OR [action_id]=(538990422)))
GO

ALTER SERVER AUDIT [Object_Change] WITH (STATE = ON)
GO