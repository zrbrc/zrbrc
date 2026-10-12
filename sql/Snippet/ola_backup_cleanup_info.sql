-- this will grab the cleanup time and databases for each backup job
-- was easier to do as CTE instead of redoing all the different SUBSTRING and CHARINDEX together
WITH
  CTE1
  AS
  (
    SELECT
      sj.name,
      sjs.step_name,
      sjs.command
    FROM
      msdb..sysjobs AS sj
      JOIN msdb..sysjobsteps AS sjs ON sj.job_id = sjs.job_id
    WHERE sj.enabled = 1
      AND sjs.command LIKE 'EXEC%DatabaseBackup%'
      AND sjs.command LIKE '%@CleanupTime%'
      AND sjs.command LIKE '%@Database%'
  )
SELECT
  name,
  step_name,
  LTRIM(SUBSTRING(SUBSTRING(command, CHARINDEX('@CleanupTime',command), CHARINDEX(',',SUBSTRING(command,CHARINDEX('@CleanupTime',command),30))-1),CHARINDEX('=',SUBSTRING(command, CHARINDEX('@CleanupTime',command), CHARINDEX(',',SUBSTRING(command,CHARINDEX('@CleanupTime',command),30))-1)) + 1,5)) AS "cleanup_time",
  LTRIM(REPLACE(SUBSTRING(SUBSTRING(command, CHARINDEX('@Databases',command), CHARINDEX(''',',SUBSTRING(command,CHARINDEX('@Database',command),255))),CHARINDEX('=',SUBSTRING(command, CHARINDEX('@Databases',command), CHARINDEX(''',',SUBSTRING(command,CHARINDEX('@Database',command),255)))) + 1,50),'''','')) AS "databases"
FROM
  CTE1

/* 

Another option, longer code, less confusing

 */

-- this will grab the cleanup time and databases for each backup job
-- was easier to do as CTE instead of redoing all the different SUBSTRING and CHARINDEX together
WITH CTE1 AS (
SELECT sj.job_id,
       sj.name,
       sjs.step_name,
       sjs.command
  FROM msdb..sysjobs AS sj
       JOIN msdb..sysjobsteps AS sjs ON sj.job_id = sjs.job_id
 WHERE sj.enabled = 1
   AND sjs.command LIKE 'EXEC%DatabaseBackup%'
),
CTE2 AS (
SELECT job_id,
       name,
       step_name,
       command,

       PATINDEX('%@Databases%',command) AS db_s,
       CASE WHEN PATINDEX('%@Database%',command) != 0 -- make sure this an occurance
            THEN CASE WHEN CHARINDEX(''',',command,PATINDEX('%@Database%',command)) = 0 -- checks if it is the last entry and gets length and uses that as end
                      THEN LEN(command)
                      ELSE CHARINDEX(''',',command,PATINDEX('%@Database%',command)) -- up until next parameter
                 END
            ELSE 0
       END AS db_e,

       PATINDEX('%@CleanupTime%',command) AS cu_s,
       CASE WHEN PATINDEX('%@CleanupTime%',command) != 0 -- make sure this an occurance
            THEN CASE WHEN CHARINDEX(',',command,PATINDEX('%@CleanupTime%',command)) = 0 -- checks if it is the last entry and gets length and uses that as end
                      THEN LEN(command)
                      ELSE CHARINDEX(',',command,PATINDEX('%@CleanupTime%',command)) -- up until next parameter
                 END
            ELSE 0
       END AS cu_e,

       PATINDEX('%@LogToTable%',command) AS ltt_s,
       CASE WHEN PATINDEX('%@LogToTable%',command) != 0 -- make sure this an occurance
            THEN CASE WHEN CHARINDEX(',',command,PATINDEX('%@LogToTable%',command)) = 0 -- checks if it is the last entry and gets length and uses that as end
                      THEN LEN(command)
                      ELSE CHARINDEX(',',command,PATINDEX('%@LogToTable%',command)) -- up until next parameter
                 END
            ELSE 0
       END AS ltt_e
  FROM CTE1
)

SELECT name,
       step_name,
       REPLACE(RTRIM(SUBSTRING(command,db_s,db_e-db_s)),'''','') AS databases,
       RTRIM(SUBSTRING(command,cu_s,cu_e-cu_s)) AS cleanup_time,
       REPLACE(RTRIM(SUBSTRING(command,ltt_s,ltt_e-ltt_s)),'''','') AS log_to_table,
       command
  FROM CTE2