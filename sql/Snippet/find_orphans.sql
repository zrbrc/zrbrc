-- find and fix orphans, also can cause this error
https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-change-users-login-transact-sql?view=sql-server-ver15

-- identify
USE <DBNAME>
GO
EXEC sp_change_users_login 'Report'
GO

-- identify all at once
EXECUTE sp_MSforeachdb '
Use [?]
SELECT DB_NAME() AS DatabaseName
EXECUTE sp_change_users_login @Action=''Report''
'

-- fix, login and user must exist for autofix without a password being specified.
USE <DBNAME>
GO
EXEC sp_change_users_login 'Auto_Fix', 'user.name'
GO
