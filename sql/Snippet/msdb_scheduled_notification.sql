SELECT j.name AS job_name,
       CASE j.enabled 
            WHEN 1 THEN 'yes' 
            WHEN 0 THEN 'no'
       END AS is_enabled,
       CASE
            WHEN s.schedule_uid IS NULL THEN 'no'
            ELSE 'yes'
       END AS is_scheduled,
       s.name AS schedule_name,
       o.email_address
  FROM msdb.dbo.sysjobs AS j
       JOIN msdb.dbo.sysjobschedules AS js ON js.job_id = j.job_id
       JOIN msdb.dbo.sysschedules AS s ON s.schedule_id = js.schedule_id
       LEFT JOIN msdb.dbo.sysoperators as o on o.id = j.notify_email_operator_id
 ORDER BY job_name