-- shows file sizes and space used in all files
DROP TABLE IF EXISTS #FileSize
CREATE TABLE #FileSize
(
    db_name NVARCHAR(128),
    filename NVARCHAR(128),
	physical_name NVARCHAR(255),
    type_desc NVARCHAR(128),
    size INT,
    used INT
)

INSERT INTO #FileSize (db_name, filename, physical_name, type_desc, size, used)
EXEC sp_msforeachdb 
'USE [?]
 SELECT
    DB_NAME() AS db_name, 
    name AS filename,
	physical_name,
    type_desc,
    size/128.0 AS size,
    FILEPROPERTY(name, ''SpaceUsed'')/128 AS used
FROM
    sys.database_files
WHERE 
    type IN (0,1)'

SELECT
    db_name,
    filename,
	physical_name,
    type_desc,
    FORMAT(size,'N0') AS size_mb, -- this doesnt sort right as its not a number
    FORMAT(used,'N0') AS used_mb, -- this doesnt sort right as its not a number
    FORMAT(size - used,'N0') AS free_mb, -- this doesnt sort right as its not a number
    FORMAT((size - used)/(size/1.0), 'P') AS free_percent 
FROM
    #FileSize
WHERE 
	db_name NOT IN ('distribution', 'master', 'model', 'msdb', 'tempdb')
    AND size >= 10000
	AND type_desc = 'ROWS'
	AND physical_name LIKE 'D:%'
ORDER BY
	size DESC

DROP TABLE #FileSize

-- another option with diff formatting, same query

CREATE TABLE #file_size
(
    db_name NVARCHAR(128), 
    file_name NVARCHAR(128), 
    type_desc NVARCHAR(128),
    current_size_mb DECIMAL(10,2), 
    freespace_mb DECIMAL(10,2)
)
    
INSERT INTO #file_size(db_name, file_name, type_desc, current_size_mb, freespace_mb)
EXECUTE sp_msforeachdb 
    'USE [?]
     SELECT DB_NAME() AS DbName, 
            name AS FileName, 
            type_desc,
            size/128.0 AS CurrentSizeMB,  
            size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0 AS FreeSpaceMB
    FROM sys.database_files
    WHERE type IN (0,1)'
    
SELECT
   db_name,
	 file_name,
	 type_desc,
	 CAST((current_size_mb / 1024) AS DECIMAL(10,2)) AS current_size_gb,
	 CAST(freespace_mb / 1024 AS DECIMAL(10,2)) AS freespace_gb,
	 CAST((current_size_mb - freespace_mb) / 1024 AS DECIMAL(10,2)) AS used_space_gb,
	 FORMAT(freespace_mb/current_size_mb,'p') AS percent_free
FROM 
  #file_size
WHERE
	--db_name LIKE '%Log%' --= 'DSS_WorkerWebLog_UATCR'
	db_name NOT IN ('master','model','msdb','tempdb')
	AND type_desc = 'ROWS'
	--AND current_size_mb > 30000
 ORDER BY used_space_gb DESC
   
DROP TABLE #file_size;


--DBCC TRACESTATUS(9567)