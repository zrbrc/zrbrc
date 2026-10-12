WITH CTE1 AS (
     SELECT sj.name,
            sjs.step_name,
     	      REPLACE(RTRIM(c.value), ',' + CHAR(13), '') AS backup_option
       FROM msdb..sysjobs AS sj
            LEFT JOIN msdb..sysjobsteps AS sjs ON sj.job_id = sjs.job_id
     	      CROSS APPLY string_split(command,'@') AS c
      WHERE sjs.step_name LIKE 'DatabaseBackup%'
        AND LTRIM(c.value) NOT LIKE 'EXEC%'
)
SELECT name + '\' + step_name AS job_name_step_name,
       RTRIM(SUBSTRING(backup_option,0,CHARINDEX('=',backup_option, 0))) AS ola_param,
       LTRIM(SUBSTRING(backup_option,CHARINDEX('=',backup_option, 0)+1,LEN(backup_option)-CHARINDEX('=',backup_option, 0)+1)) AS ola_value
  FROM CTE1
 ORDER BY job_name_step_name,
          ola_param
