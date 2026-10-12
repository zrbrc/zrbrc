SELECT
    ag.name AS ag_name,
    dbs.name AS database_name,
    ar.replica_server_name,
    ar.availability_mode_desc,
    ars.role_desc,
    ars.connected_state_desc,
    drs.synchronization_state_desc,
    drs.synchronization_health_desc,
    drs.log_send_queue_size,
    drs.log_send_rate,
    drs.redo_rate,
    drs.end_of_log_lsn,
    drs.last_hardened_lsn
FROM
    sys.dm_hadr_database_replica_states drs
    JOIN sys.databases AS dbs ON dbs.database_id = drs.database_id
    JOIN sys.availability_groups AS ag ON drs.group_id = ag.group_id
    JOIN sys.availability_replicas AS ar ON ag.group_id = ar.group_id AND drs.replica_id = ar.replica_id
    JOIN sys.dm_hadr_availability_replica_states AS ars ON ar.replica_id = ars.replica_id
WHERE 
    drs.synchronization_health_desc != 'HEALTHY'
ORDER BY 
    ag.name,
    ars.role_desc,
    dbs.name,
    ar.replica_server_name