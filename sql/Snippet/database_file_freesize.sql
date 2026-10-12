-- you can take the output from this query and choose some high impact datafiles and then run a shrinkfile on them.
-- its set to shrink at a point that its freeing half of the current free space.
-- example: data file is 10gb, there is 4gb free, meaning 6gb used. It will target the datafile to shrink to 8gb, freeing half of the freespace
-- this is NOT intended for Prod usage, only something like DEV where performance is not critical

CREATE TABLE #file_size
(
    db_name NVARCHAR(128), 
    file_name NVARCHAR(128), 
    type_desc NVARCHAR(128),
    current_size_mb DECIMAL(10,2),
    usedspace_mb DECIMAL(10,2),  
    freespace_mb DECIMAL(10,2)
)
    
INSERT INTO #file_size(db_name, file_name, type_desc, current_size_mb, usedspace_mb, freespace_mb)
EXECUTE sp_msforeachdb 
    'USE [?]
     SELECT DB_NAME() AS DbName, 
            name AS FileName, 
            type_desc,
            size/128.0 AS CurrentSizeMB,
            CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0 as UsedSpaceMB,
            size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0 AS FreeSpaceMB
    FROM sys.database_files
    WHERE type IN (0,1)'
    
SELECT db_name,
	   file_name,
	   CAST((current_size_mb - (freespace_mb / 2)) as INT) as free_target_mb,
	   FORMAT(freespace_mb/current_size_mb,'p') AS percent_free,
	   type_desc,
	   current_size_mb,
       usedspace_mb,
	   freespace_mb
  FROM #file_size
 WHERE db_name NOT IN ('distribution', 'master', 'model', 'msdb', 'tempdb') and type_desc = 'ROWS'
 ORDER BY freespace_mb DESC

-- cleanup    
DROP TABLE #file_size;


--
-- another option for just 1 DB
--

USE <dbname>
GO
SELECT DB_NAME() AS DbName, 
       name AS FileName, 
       type_desc,
       FORMAT((size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0)/(size/128.0),'p') AS percent_free,
       size/128.0 AS CurrentSizeMB,  
       size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT)/128.0 AS FreeSpaceMB
FROM sys.database_files
WHERE type IN (0,1)
   