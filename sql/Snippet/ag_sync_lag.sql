;WITH ag_stats AS 
(
SELECT
  AR.replica_server_name,
  AG.name AS ag_name,
  HARS.role_desc,
  Db_name(DRS.database_id) as database_name,
  DRS.last_commit_time
FROM
  sys.dm_hadr_database_replica_states AS DRS
  INNER JOIN sys.availability_replicas AS AR ON DRS.replica_id = AR.replica_id
  INNER JOIN sys.dm_hadr_availability_replica_states AS HARS ON AR.group_id = HARS.group_id
                                                            AND AR.replica_id = HARS.replica_id
  INNER JOIN sys.availability_groups AS AG ON AG.group_id = AR.group_id
),
pri_commit_time AS 
(
  SELECT
    replica_server_name,
    ag_name,
    database_name,
    last_commit_time
  FROM
    AG_Stats
  WHERE
    role_desc = 'PRIMARY'
),
sec_commit_time AS 
(
  SELECT  
    replica_server_name,
    ag_name,
    database_name,
    last_commit_time
  FROM
    ag_stats
  WHERE
    role_desc = 'SECONDARY'
)
SELECT
  PCT.replica_server_name AS primary_replica,
  PCT.ag_name,
  PCT.database_name,
  SCT.replica_server_name AS secondary_replica,
  DATEDIFF(ss,SCT.last_commit_time,PCT.last_commit_time) AS sync_latency_secs
FROM
  pri_commit_time AS PCT
  LEFT JOIN sec_commit_time AS SCT ON SCT.database_name = PCT.database_name 
                                 AND SCT.ag_name = PCT.ag_name
WHERE
  DATEDIFF(ss,SCT.last_commit_time,PCT.last_commit_time) > 0