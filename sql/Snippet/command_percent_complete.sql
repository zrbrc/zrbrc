SELECT DB_NAME(req.database_id) AS database_name,
       ses.login_name,
       command,
       percent_complete AS percent_complete,
       FORMAT(CONVERT(TIME, GETDATE() - start_time),'hh\:mm\:ss') as running_time,
       FORMAT(CONVERT(TIME, DATEADD(MILLISECOND,estimated_completion_time,0)), 'hh\:mm\:ss') as time_to_go,
       st.text AS query_text
  FROM sys.dm_exec_requests AS req
       LEFT JOIN sys.dm_exec_sessions AS ses ON ses.session_id = req.session_id
       CROSS APPLY sys.dm_exec_sql_text(req.sql_handle) AS st
 WHERE command NOT IN ('SELECT', 'EXECUTE', 'INSERT')