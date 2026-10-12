/* 

2 options below


THROW is the newer better option per MS.

 */

IF sys.fn_hadr_is_primary_replica('<dbname>') <> 1
BEGIN
   -- this is better as it allow informational/lower sev messages vs throw
    RAISERROR ('This IS secondary replica. Do NOT countinue this job.',11,1);
END

-- https://www.brentozar.com/archive/2015/06/how-to-configure-alwayson-ag-backups-with-ola-hallengrens-scripts/
IF (SELECT role_desc
	FROM sys.dm_hadr_availability_replica_states
	INNER JOIN sys.dm_hadr_name_id_map ON sys.dm_hadr_availability_replica_states.group_id = sys.dm_hadr_name_id_map.ag_id
	WHERE sys.dm_hadr_name_id_map.ag_name = 'AG2016_1'
	AND is_local = 1) = 'primary'
BEGIN
	PRINT ('This IS primary replica and you can GO TO NEXT step.');
END
ELSE
BEGIN
	RAISERROR('This IS secondary replica. Do NOT countinue this job.',11,1);
END



IF sys.fn_hadr_is_primary_replica ('<database name>') <> 1
BEGIN
	THROW 50000, 'This is not a primary replica', 1
END