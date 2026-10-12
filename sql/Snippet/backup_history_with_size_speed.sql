WITH
    LastBackUp AS
    (
        SELECT
            bs.database_name,
            bs.backup_start_date,
            bs.backup_finish_date,
            bs.type,
            CAST(compressed_backup_size / 1024000 AS DECIMAL(10, 2) ) AS size_mbs,
            COALESCE(NULLIF(DATEDIFF(second, bs.backup_start_date,bs.backup_finish_date), 0), 1) AS backup_seconds,
            bmf.physical_device_name,
			ROW_NUMBER() OVER ( PARTITION BY bms.media_set_id ORDER BY bs.backup_start_date DESC) AS backup_set -- to handle file striping
        FROM
            msdb.dbo.backupmediafamily bmf
            JOIN msdb.dbo.backupmediaset bms ON bmf.media_set_id = bms.media_set_id
            JOIN msdb.dbo.backupset bs ON bms.media_set_id = bs.media_set_id
        WHERE 
			backup_start_date > = DATEADD(day,-7,GETDATE()) -- how many days to look back
            AND bs.database_name NOT IN ('master','msdb','model')
            AND bs.type != 'L'
    )
SELECT
    database_name,
    FORMAT(backup_start_date,'yyyy-MM-dd HH:mm:ss') AS start_date,
    FORMAT(backup_finish_date,'yyyy-MM-dd HH:mm:ss') AS end_date,
    CASE WHEN type = 'D' THEN 'FULL' WHEN type = 'I' THEN 'DIFF' WHEN type = 'L' THEN 'LOG' END AS backup_type,
    FORMAT(CONVERT(TIME, DATEADD(SECOND,backup_seconds,0)), 'hh\:mm\:ss') AS duration,
    FORMAT((backup_seconds * 1.00)/CAST(LAG(backup_seconds) OVER (PARTITION BY database_name, type ORDER BY backup_start_date) AS DECIMAL), 'P') AS vs_prev,
    -- some more info if you want it
    --FORMAT(CONVERT(TIME, DATEADD(SECOND,AVG(backup_seconds) OVER (PARTITION BY database_name, type ORDER BY backup_start_date),0)), 'hh\:mm\:ss') AS duration_trend,
    --FORMAT((backup_seconds * 1.00)/CAST(AVG(backup_seconds) OVER (PARTITION BY database_name, type ORDER BY backup_start_date) AS DECIMAL), 'P') AS vs_prev_trend,
    FORMAT(size_mbs, 'N') AS size_mbs,
    FORMAT((size_mbs * 1.00)/(LAG(size_mbs) OVER (PARTITION BY database_name, type ORDER BY backup_start_date)) * 1.00, 'P') AS size_vs_prev,
    CAST(size_mbs / backup_seconds * 8 AS NUMERIC(10,2)) AS speed_mbps,
    physical_device_name AS backup_location
FROM
    LastBackUp
WHERE 
	backup_start_date IS NOT NULL
	AND backup_set = 1
ORDER BY 
    backup_start_date