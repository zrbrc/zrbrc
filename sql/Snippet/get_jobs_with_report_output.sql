-- simple script to find jobs that have output set so we can unset if needed (log backup jobs)
-- remove where condition or set as needed to find jobs without output set
SELECT @@SERVERNAME,
       j.name,
       js.step_name,
       js.output_file_name
  FROM sysjobs AS j
       JOIN sysjobsteps AS js ON js.job_id = j.job_id
 WHERE js.output_file_name IS NOT NULL
 ORDER BY j.name,
          js.step_id