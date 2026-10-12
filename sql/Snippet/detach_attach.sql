-- this will find filestreams too
WITH Targets AS (
	SELECT d.name db_name, 
		   f.physical_name,
	       d.database_id
    FROM   sys.databases d
	       JOIN sys.master_files f on f.database_id = d.database_id
    WHERE  d.database_id > 4
     AND   f.state_desc = 'ONLINE'
)
SELECT db_name,
       'exec sp_detach_db @dbname = N''' + db_name + ''';' AS Detach,
       'CREATE DATABASE ' + db_name + ' ON ' +
        STUFF((SELECT  ',(FILENAME = ''' + physical_name + ''')'
		       FROM Targets f
		       WHERE f.database_id = d.database_id
		       FOR XML PATH ('')),1,1,'')
		+ ' FOR ATTACH;' AS Attach
FROM (SELECT DISTINCT database_id, db_name FROM Targets) d
ORDER BY db_name