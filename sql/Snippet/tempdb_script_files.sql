-- edit line 5 for new location, it will use same size as current and zero growth

DECLARE @newDriveAndFolder VARCHAR(8000);

SET @newDriveAndFolder = 'T:\TempDB';

SELECT [name] AS [Logical Name]
    ,physical_name AS [Current Location]
    ,'ALTER DATABASE tempdb MODIFY FILE (NAME = ''' + f.[name]
    + ''', FILENAME = ''' + @newDriveAndFolder + CHAR(92) /* Backslash */ + f.[name]
    + CASE WHEN f.[type] = 1 /* Log */ THEN '.ldf' ELSE '.mdf' END  + ''''
	+ ', FILESIZE = ' + CONVERT(varchar(10), size / 128) + 'MB, AUTOGROWTH = 0'
    + ');'
    AS [Create new TempDB files]
FROM sys.master_files f
WHERE f.database_id = DB_ID(N'tempdb')
ORDER BY f.[type];