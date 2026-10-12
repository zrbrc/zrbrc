SELECT
	sj.name,
	sj.enabled,
	sjs.last_run_date,
	sjs.last_run_time,
	msdb.dbo.agent_datetime(last_run_date,last_run_time) as last_run_datetime
FROM 
	msdb.dbo.sysjobservers AS sjs
	JOIN msdb.dbo.sysjobs AS sj ON sjs.job_id = sj.job_id
WHERE
	last_run_date != 0
	AND last_run_time != 0

SELECT
	@@SERVERNAME as instance,
	j.name,
	j.enabled,
	js.last_run_date,
	sc.schedule_id,
	sc.next_run_date
FROM 
	msdb.dbo.sysjobs AS j 
	join msdb.dbo.sysjobservers AS js ON js.job_id = j.job_id
	JOIN msdb.dbo.sysjobschedules as sc on sc.job_id = j.job_id
WHERE
	Js.last_run_date <= 20250101
	AND j.description NOT LIKE '%ola%'