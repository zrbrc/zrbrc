-- this script will start a SQL Agent Job by name, wait for its completion,
-- and then report on the outcome, there is no check for the job already
-- executing as sp_start_job has that check in it already

DECLARE @JobName 	  SYSNAME = 'Fake_wait_job'
DECLARE @JobId 		  BINARY(16)
DECLARE @ReturnCode INT
DECLARE @RunStatus 	INT
DECLARE @JobRunTime INT
DECLARE @Message 	  NVARCHAR(4000)
DECLARE @Now        DATETIME = GETDATE()
SELECT @ReturnCode = 0

-- get job_id by name, we can submit by name, but we need it for results for later, so using job_id
SELECT @JobId = job_id 
  FROM msdb.dbo.sysjobs
 WHERE name = @JobName

-- execute job by job_id
EXEC @ReturnCode = msdb.dbo.sp_start_job @job_id = @JobId
IF @ReturnCode <> 0
BEGIN
  RAISERROR('Job failed to start.',16,1)
  RETURN
END

-- waits for current execution to have an end time
WHILE NOT EXISTS (
  SELECT *
    FROM msdb.dbo.sysjobactivity
   WHERE job_id = @JobId
     AND start_execution_date > @Now
     AND stop_execution_date IS NOT NULL
) 
WAITFOR DELAY '00:00:03'

-- Get runtime, status, message
SELECT @RunStatus  = jh.run_status,
 	     @Message    = jh.message,
       @JobRunTime = DATEDIFF(SECOND, start_execution_date, stop_execution_date)
  FROM msdb.dbo.sysjobactivity ja 
       LEFT JOIN msdb.dbo.sysjobhistory AS jh ON jh.instance_id = ja.job_history_id
 WHERE ja.job_id = @JobId
   AND ja.start_execution_date > @Now

IF @RunStatus <> 1
BEGIN
  RAISERROR('Job failed.',16,2)
  RETURN
END

PRINT @Message
PRINT 'Execution time: ' + CONVERT(nvarchar, @JobRunTime) + 's'
