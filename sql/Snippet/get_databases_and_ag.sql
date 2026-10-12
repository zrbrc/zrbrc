select
	@@SERVERNAME as server_name,
	d.name as db_name,
	d.state_desc,
	ag.name as ag_name,
	ars.role_desc
from
	master.sys.databases as d
	left join master.sys.dm_hadr_database_replica_states as drs on drs.database_id = d.database_id
	left join master.sys.dm_hadr_availability_replica_states as ars on ars.replica_id = drs.replica_id
	left join master.sys.availability_groups as ag on ag.group_id = ars.group_id
where
	d.database_id > 5
	and (ars.role_desc = 'PRIMARY' or 
		ars.role_desc IS NULL)
order by
	ag_name,
	db_name

