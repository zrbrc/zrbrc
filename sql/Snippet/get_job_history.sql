-- just basic job count, looking about increasing retention for non-log jobs
SELECT
	sj.name,
	COUNT(*) as execution_count
FROM
	msdb.dbo.sysjobs sj
	JOIN msdb.dbo.sysjobhistory sjh ON sj.job_id = sjh.job_id
WHERE
	sjh.step_id = 0
GROUP BY
	sj.name
ORDER BY
	execution_count DESC

/* 

-- setting:

EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=50000, @jobhistory_max_rows_per_job=1000

-- job:

USE [msdb]

EXEC msdb.dbo.sp_update_jobstep @job_name=N'sp_purge_jobhistory', @step_id=1, 
@command=N'DECLARE @CleanupDate datetime

SET @CleanupDate = DATEADD(dd,-60,GETDATE())
EXECUTE dbo.sp_purge_jobhistory @oldest_date = @CleanupDate

SET @CleanupDate = DATEADD(dd,-1,GETDATE())
EXECUTE dbo.sp_purge_jobhistory @job_name = ''DatabaseBackup - USER_DATABASES - LOG'', @oldest_date = @CleanupDate'


 */