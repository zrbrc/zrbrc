-- show execution plans, no sql text shown
select * from sys.dm_exec_query_stats

-- use this join to show plan and sql text
select plan_handle, creation_time, last_execution_time, execution_count, qt.text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text (qs.[sql_handle]) AS qt

-- find the execution plan and then run this
DBCC FREEPROCCACHE (plan_handle_id_goes_here)

-- remove all
-- DBCC FREESYSTEMCACHE ('ALL') WITH MARK_IN_USE_FOR_REMOVAL