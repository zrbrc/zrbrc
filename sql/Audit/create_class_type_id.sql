CREATE OR ALTER FUNCTION dbo.GetInt_class_type (@class_type VARCHAR(2))
RETURNS INT

BEGIN
	DECLARE @x INT

	SET @x = convert(INT, convert(VARBINARY(1), upper(substring(@class_type, 1, 1))))

	IF LEN(@class_type) >= 2
		SET @x = convert(INT, convert(VARBINARY(1), upper(substring(@class_type, 2, 1)))) * power(2, 8) + @x
	ELSE
		SET @x = convert(INT, convert(VARBINARY(1), ' ')) * power(2, 8) + @x

	RETURN @x
END
GO

SELECT DISTINCT dbo.GetInt_class_type(class_type) class_type_int, class_type, class_type_desc
FROM sys.dm_audit_class_type_map
ORDER BY class_type