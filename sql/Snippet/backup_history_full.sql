-- simple backup history
SELECT backupset.database_name,
       backupset.user_name,
       backupset.server_name,
       CAST(compressed_backup_size / 1024000 AS DECIMAL(10, 2) ) AS compressed_backup_size,
       backupset.backup_start_date,
       backupset.backup_finish_date,
       DATEDIFF(SECOND, backupset.backup_start_date, backupset.backup_finish_date) AS duration_seconds,
       backupset.type,
       mediafamily.physical_device_name
  FROM msdb..backupmediafamily mediafamily
       INNER JOIN msdb..backupmediaset mediaset 
          ON mediafamily.media_set_id = mediaset.media_set_id
       INNER JOIN msdb..backupset backupset
          ON backupset.media_set_id = mediaset.media_set_id
 WHERE type in ('D')
   AND backupset.backup_finish_date >= DATEADD(day,-10,GETDATE())
   AND database_name = '<dbname>'
 ORDER BY backup_start_date


-- get lag between operations
SELECT backupset.database_name,
       backupset.user_name,
       backupset.server_name,
       CAST(compressed_backup_size / 1024000 AS DECIMAL(10, 2) ) AS compressed_backup_size,
       backupset.backup_start_date,
       backupset.backup_finish_date,
       DATEDIFF(second, LAG(backup_finish_date) OVER (ORDER BY backup_start_date), backup_start_date) as backup_start_lag,
       DATEDIFF(SECOND, backupset.backup_start_date, backupset.backup_finish_date) AS duration_seconds,
       backupset.type,
       mediafamily.physical_device_name
  FROM msdb..backupmediafamily mediafamily
       INNER JOIN msdb..backupmediaset mediaset 
          ON mediafamily.media_set_id = mediaset.media_set_id
       INNER JOIN msdb..backupset backupset
          ON backupset.media_set_id = mediaset.media_set_id
 WHERE type in ('D','I','L')
   AND backupset.backup_finish_date BETWEEN '2021-08-05 03:00:00.000' AND '2021-08-05 04:30:00.000'
--    AND DATEDIFF(SECOND, backupset.backup_start_date, backupset.backup_finish_date) > 0
--    AND database_name = 'DSS_WorkerWeb_TEST'
 ORDER BY backup_start_date


-- get time difference between backups time
WITH CTE1 AS
(
SELECT backupset.database_name,
       backupset.user_name,
       backupset.server_name,
       CAST(compressed_backup_size / 1024 / 1024 AS DECIMAL(10, 2) ) AS compressed_backup_size,
       backupset.backup_start_date,
       backupset.backup_finish_date,
       DATEDIFF(SECOND, backupset.backup_start_date, backupset.backup_finish_date) AS duration_seconds,
       DATEDIFF(SECOND, backupset.backup_start_date, backupset.backup_finish_date) - LAG(DATEDIFF(SECOND, backupset.backup_start_date, backupset.backup_finish_date)) OVER (PARTITION BY backupset.database_name, backupset.server_name ORDER BY backup_start_date) as duration_difference,
       backupset.type,
       mediafamily.physical_device_name
  FROM msdb..backupmediafamily mediafamily
       INNER JOIN msdb..backupmediaset mediaset ON mediafamily.media_set_id = mediaset.media_set_id
       INNER JOIN msdb..backupset backupset ON backupset.media_set_id = mediaset.media_set_id
 WHERE type in ('D')
   AND backupset.backup_finish_date >= DATEADD(day,-7,GETDATE())

)
SELECT *,
       FORMAT(CTE1.compressed_backup_size/CTE1.duration_seconds, 'N2') AS MBPS
  FROM CTE1
 WHERE CTE1.duration_seconds > 0
 ORDER BY CTE1.database_name,
          CTE1.backup_start_date


-- get time difference between backups time
-- this will group like databases to get more comparisons as they are coming from the same backup files
WITH CTE1 AS
(
SELECT backupset.server_name,
       REPLACE(REPLACE(REPLACE(backupset.database_name,'_UATCR',''),'_TEST',''),'_UAT3','') AS database_name_suffix,
       backupset.database_name,
       --backupset.user_name,
       CAST(compressed_backup_size / 1024 / 1024 AS DECIMAL(10, 2) ) AS compressed_backup_size_mb,
       backupset.backup_start_date,
       backupset.backup_finish_date,

       --backupset.type,
       mediafamily.physical_device_name
  FROM msdb..backupmediafamily mediafamily
       INNER JOIN msdb..backupmediaset mediaset ON mediafamily.media_set_id = mediaset.media_set_id
       INNER JOIN msdb..backupset backupset ON backupset.media_set_id = mediaset.media_set_id
 WHERE type in ('D')
   AND backupset.backup_finish_date >= DATEADD(day,-7,GETDATE())

),
CTE2 AS (
SELECT *,
       DATEDIFF(SECOND, CTE1.backup_start_date, CTE1.backup_finish_date) AS duration_seconds,
       DATEDIFF(SECOND, CTE1.backup_start_date, CTE1.backup_finish_date) - LAG(DATEDIFF(SECOND, CTE1.backup_start_date, CTE1.backup_finish_date)) OVER (PARTITION BY CTE1.database_name_suffix, CTE1.server_name ORDER BY CTE1.backup_start_date) as duration_difference
       FROM CTE1
)
SELECT *,
       FORMAT(CTE2.compressed_backup_size_mb/CTE2.duration_seconds, 'N2') AS "mbs",
       FORMAT(CAST(CTE2.duration_seconds AS decimal) / (CAST(CTE2.duration_seconds AS decimal) - CAST(CTE2.duration_difference AS decimal)),'P') AS percent_increase
  FROM CTE2
 WHERE CTE2.duration_seconds > 0
   --AND CTE1.compressed_backup_size_mb > 500
   AND CTE2.database_name_suffix IN (
       'DMS_FORCES',
	   'DMS_FORCESReports',
	   'DMS_FORCESStaging',
	   'DSS_ASSIST',
	   'DSS_DataServicesHub',
	   'DSS_POC',
	   'DSS_POCReports',
	   'DSS_POCStaging',
	   'DSS_PRONTO',
	   'DSS_PSS',
	   'DSS_SCREENDRIVER',
	   'DSS_SummerEBT',
	   'DSS_WorkerWeb',
	   'DSS_WorkerWebReports',
	   'DSS_WorkerWebStaging',
	   'DSSC_LIHEAP',
	   'DSSC_LIHEAPReports',
	   'DSSC_LIHEAPStaging')
 ORDER BY CTE2.database_name_suffix,
          CTE2.backup_start_date