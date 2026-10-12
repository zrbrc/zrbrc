-- https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/automatically-initialize-always-on-availability-group?view=sql-server-ver15#monitor-automatic-seeding-availability-group

-- On the primary replica, query sys.dm_hadr_automatic_seeding to check the status
-- of the automatic seeding process. The view returns one row for each seeding process. 
-- For example:
SELECT local_database_name,
       role_desc,
       internal_state_desc,
       format(transfer_rate_bytes_per_second / 1024, 'N0') as mbps,
       format(transferred_size_bytes / 1024, 'N0') as mb,
       format(database_size_bytes / 1024, 'N0') as mb,
       start_time_utc AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS start_local_time,
       end_time_utc AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS end_local_time
FROM sys.dm_hadr_physical_seeding_stats

-- On the primary replica, query sys.dm_hadr_physical_seeding_stats DMV to see the
-- physical statistics for each seeding process that is currently running. The following
-- query returns rows when seeding is running:
SELECT start_time AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS start_local_time,
       completion_time AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS end_local_time,
       is_source,
       current_state,
       failure_state,
       failure_state_desc
FROM sys.dm_hadr_automatic_seeding
where start_time >= dateadd(day, -1, getdate())
order by  start_time desc