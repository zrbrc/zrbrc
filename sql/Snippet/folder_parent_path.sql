
SELECT
	database_name,
	backup_finish_date,
	LEFT(bmf.physical_device_name, CHARINDEX('\', bmf.physical_device_name, CHARINDEX('\', bmf.physical_device_name, CHARINDEX('\', bmf.physical_device_name,CHARINDEX('\', bmf.physical_device_name)+1)+1)+1)-1) as backup_root,
	bmf.physical_device_name AS backup_file
FROM
	msdb.dbo.backupset AS bs
	INNER JOIN msdb.dbo.backupmediafamily AS bmf ON bmf.media_set_id = bs.media_set_id
WHERE
	database_name NOT IN ('master','msdb','model')
	AND backup_start_date > DATEADD(day, -7, GETDATE())
	AND bs.type = 'D'
	AND bmf.physical_device_name LIKE '\\%'

	

/* 
This will give something like this:

| database_name                    | backup_finish_date      | backup_root               | backup_file                                                                                                                                                                           |
| -------------------------------- | ----------------------- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| db_CorticonAutomation_TEST     | 2024-10-20 03:00:04.000 | \\xx.xx.xx.xx\dbbackup | \\xx.xx.xx.xx\dbbackup\ts\hostname4\hostname4$AG2016_1\db_CorticonAutomation_TEST\FULL\hostname4$AG2016_1_db_CorticonAutomation_TEST_FULL_20241020_030003.bak         |
| db_CorticonAutomation_UATCR    | 2024-10-20 03:00:06.000 | \\xx.xx.xx.xx\dbbackup | \\xx.xx.xx.xx\dbbackup\ts\hostname4\hostname4$AG2016_1\db_CorticonAutomation_UATCR\FULL\hostname4$AG2016_1_db_CorticonAutomation_UATCR_FULL_20241020_030004.bak       |
| db_DataServicesHubArchive_TEST | 2024-10-20 03:00:24.000 | \\xx.xx.xx.xx\dbbackup | \\xx.xx.xx.xx\dbbackup\ts\hostname4\hostname4$AG2016_1\db_DataServicesHubArchive_TEST\FULL\hostname4$AG2016_1_db_DataServicesHubArchive_TEST_FULL_20241020_030006.bak |

 */