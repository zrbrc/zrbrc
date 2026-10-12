DECLARE @LOGIN VARCHAR(100), @WINDOWSID VARCHAR(100)

SET @LOGIN = domain.comPRCXXA04$' -- use the login that is failing, user or computer account
SET @WINDOWSID = 'S-1-5-21-1957994488-1425521274-839522115-61826' -- get this from Get-ADuser or get-ADComputer

-- get binary SID for SQL and WINDOWS for compairson, check if the match
SELECT SUSER_SID(@LOGIN,0) AS "SQL_BINARY_SID",
       SID_BINARY(@WINDOWSID) AS "WINDOWS_BINARY_SID"

-- match WINDOWS SID back to a SQL LOGIN, if this fails, this is probably our problem and might need to recreate the login
select SUSER_SNAME(SID_BINARY(@WINDOWSID)) AS "MATCHING_LOGIN"