DECLARE @database_name VARCHAR(100)

-- declare cursor
DECLARE databases_cursor CURSOR
	FOR	SELECT name FROM sys.databases WHERE database_id > 4 ORDER BY name

-- open cursor and fetch first item
OPEN databases_cursor
FETCH NEXT FROM databases_cursor
INTO @database_name, @id

-- start fetch loop, gets next item at end
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT @database_name


	-- do work here



	FETCH NEXT FROM databases_cursor
	INTO @database_name
END

CLOSE databases_cursor
DEALLOCATE databases_cursor
