/* 
  Show connections, source and endpoint, can be helpful to see if the listener isnt being used.
 */

SELECT ec.session_id,
       es.login_name,
       es.host_name,
       es.program_name,
       local_net_address,
       local_tcp_port
  FROM sys.dm_exec_connections AS ec
       JOIN sys.dm_exec_sessions AS es ON ec.session_id = es.session_id
 ORDER BY local_net_address