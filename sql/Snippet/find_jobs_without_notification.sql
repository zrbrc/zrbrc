USE msdb
GO

SELECT j.name AS JobName
  FROM sysjobs j
       LEFT JOIN sysoperators AS o ON o.id = j.notify_email_operator_id
 WHERE j.enabled = 1
   AND j.notify_level_email NOT IN (1, 2, 3)
 ORDER BY JobName
