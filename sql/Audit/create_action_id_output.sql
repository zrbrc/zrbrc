-- https://techcommunity.microsoft.com/t5/sql-server-blog/filter-sql-server-audit-on-action-id-class-type-predicate/ba-p/384140
-- the audit action IDs are all codes, this will convery them to meaningful info.
-- create function
CREATE FUNCTION dbo.Getint_action_id (@action_id VARCHAR(4))
RETURNS INT

BEGIN
	DECLARE @x INT

	SET @x = CONVERT(INT, CONVERT(VARBINARY(1), Upper(Substring(@action_id, 1, 1))))

	IF Len(@action_id) >= 2
		SET @x = CONVERT(INT, CONVERT(VARBINARY(1), Upper(Substring(@action_id, 2, 1)))) * Power(2, 8) + @x
	ELSE
		SET @x = CONVERT(INT, CONVERT(VARBINARY(1), ' ')) * Power(2, 8) + @x

	IF Len(@action_id) >= 3
		SET @x = CONVERT(INT, CONVERT(VARBINARY(1), Upper(Substring(@action_id, 3, 1)))) * Power(2, 16) + @x
	ELSE
		SET @x = CONVERT(INT, CONVERT(VARBINARY(1), ' ')) * Power(2, 16) + @x

	IF Len(@action_id) >= 4
		SET @x = CONVERT(INT, CONVERT(VARBINARY(1), Upper(Substring(@action_id, 4, 1)))) * Power(2, 24) + @x
	ELSE
		SET @x = CONVERT(INT, CONVERT(VARBINARY(1), ' ')) * Power(2, 24) + @x

	RETURN @x
END
GO

--then run this to get the output
SELECT DISTINCT 
  dbo.Getint_action_id(action_id) Action_ID_Int, 
  action_id, 
  NAME AS Action_Description
FROM 
  sys.dm_audit_actions
ORDER BY 
  action_id