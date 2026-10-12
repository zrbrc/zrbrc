SELECT
	db_name() as DATABASE_NAME,
	c.TABLE_SCHEMA,
	c.TABLE_NAME,
	c.COLUMN_NAME,
	sep.value AS DESCRIPTION,
	c.DATA_TYPE,
	c.CHARACTER_MAXIMUM_LENGTH,
	c.IS_NULLABLE
FROM
	INFORMATION_SCHEMA.COLUMNS AS c
	INNER JOIN sys.columns AS sc ON sc.object_id = object_id(c.TABLE_SCHEMA + '.' + c.TABLE_NAME) AND sc.name = c.COLUMN_NAME
	LEFT JOIN sys.extended_properties AS sep ON sc.object_id = sep.major_id AND sc.column_id = sep.minor_id AND sep.name = 'MS_Description'
ORDER BY 
	TABLE_SCHEMA,
	TABLE_NAME,
	ORDINAL_POSITION