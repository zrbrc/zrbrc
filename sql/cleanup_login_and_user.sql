-- domain.com.dv.atasphere.ap'
-- domain.com.ts.atasphere.ap'
-- domain.com.atasphere.ap'

EXECUTE sp_MSforeachdb '
USE [?];
BEGIN TRY
	DROP USER domain.com.ts.atasphere.ap]
	PRINT @@SERVERNAME + '' : ? : USER DROPPED''
END TRY
BEGIN CATCH
	PRINT @@SERVERNAME + '' : ? : USER NOT FOUND''
END CATCH'

BEGIN TRY
	DROP LOGIN domain.com.ts.atasphere.ap]
	PRINT @@SERVERNAME + ' : LOGIN DROPPED'
END TRY
BEGIN CATCH
	PRINT @@SERVERNAME + ' : LOGIN NOT FOUND'
END CATCH