
SELECT DISTINCT
       volume_mount_point, 
       total_bytes, 
       available_bytes  
  FROM sys.master_files AS f  
 CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.file_id)
 ORDER BY volume_mount_point