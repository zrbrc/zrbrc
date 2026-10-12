-- show usage and transtions
SELECT
SUM (user_object_reserved_page_count)*8/1024.0/1024.0 as user_obj_GB,
SUM (internal_object_reserved_page_count)*8/1024.0/1024.0 as internal_obj_GB,
SUM (version_store_reserved_page_count)*8/1024.0/1024.0  as version_store_GB,
SUM (unallocated_extent_page_count)*8/1024.0/1024.0 as freespace_GB,
SUM (mixed_extent_page_count)*8/1024.0/1024.0 as mixedextent_GB
FROM sys.dm_db_file_space_usage

select
t.transaction_id,t.name,t.transaction_type, t.transaction_state,
s.transaction_id,s.session_id,
s.elapsed_time_seconds/60/60.0 as hours_tran_has_been_open,  p.status, p.cmd
from sys.dm_tran_active_transactions t
  join sys.dm_tran_active_snapshot_database_transactions s
     on t.transaction_id = s.transaction_id
  join sys.sysprocesses p
     on p.spid = s.session_id