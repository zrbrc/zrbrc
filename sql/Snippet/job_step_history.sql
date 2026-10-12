SELECT
	sj.NAME JobName,
	sjh.step_id,
	ISNULL(sjs.step_name, 'Job Status') StepName,
	dbo.agent_datetime(sjh.run_date, sjh.run_time) RunDateAndTime,
	STUFF(STUFF(RIGHT('00000' + CAST(run_duration AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':'),
	CASE sjh.run_status
		WHEN 0 THEN 'Failed'
		WHEN 1 THEN 'Succeeded'
		WHEN 2 THEN 'Retry'
		WHEN 3 THEN 'Canceled'
		WHEN 4 THEN 'In Progress'
	END RunStatus,
	sjh.message
FROM
	dbo.sysjobs sj
	INNER JOIN dbo.sysjobhistory sjh ON sj.job_id = sjh.job_id
	LEFT JOIN dbo.sysjobsteps sjs ON sjh.job_id = sjs.job_id AND sjh.step_id = sjs.step_id
WHERE 
	sj.NAME NOT IN ('DatabaseBackup - USER_DATABASES - LOG','PurgeSSAResponseTable','syspolicy_purge_history')
	AND sjh.run_status = 0
ORDER BY
	RunDateAndTime DESC
