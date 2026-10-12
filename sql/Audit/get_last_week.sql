/* 
    These are are couple different queries to get info from the SQL audit files.
    
 */

-- assist/el2
SELECT
    event_time AS event_time_UTC,
    event_time AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS local_time,
    server_instance_name,
    server_principal_name,
    action_id,
    class_type,
    succeeded,
    statement,
    database_principal_name,
    target_server_principal_name,
    database_name,
    schema_name,
    object_name,
    file_name
FROM
    sys.fn_get_audit_file('M:\Management\Audit\*.sqlaudit', DEFAULT, DEFAULT)
WHERE 
    event_time >= DATEADD(day,-8,GETDATE())
    AND server_principal_name NOT IN ('dom\Sentry.Admin')
    AND (server_principal_name NOT IN ('domain\user.dui','domain\user',domain.com.MCI.App') AND action_id != 'AL' AND class_type != 'U')
    AND (action_id != 'VW' AND class_type != 'CK')
    AND action_id NOT IN ('LGIF','LGIS')
ORDER BY 
    event_time DESC

-- decss/dept
SELECT
    event_time AS event_time_UTC,
    event_time AT TIME ZONE 'UTC' AT TIME ZONE 'Eastern Standard Time' AS local_time,
    server_instance_name,
    server_principal_name,
    action_id,
    class_type,
    succeeded,
    statement,
    database_principal_name,
    target_server_principal_name,
    database_name,
    schema_name,
    object_name,
    file_name
FROM
    sys.fn_get_audit_file('M:\Management\Audit\*.sqlaudit', DEFAULT, DEFAULT)
WHERE 
    event_time >= DATEADD(day,-8,GETDATE())
    AND server_principal_name NOT IN ('dom\Sentry.Admin','dom\DECSS.SQLRepl.Prod','sa','dept.scheduler')
    AND (server_principal_name NOT IN ('domain\user.decss') AND action_id != 'AL' AND class_type != 'U')
	AND (action_id != 'OP' AND class_type != 'SK')
	AND (action_id != 'AS' AND class_type != 'CR')
    AND (action_id != 'VW' AND class_type != 'CK')
	AND action_id NOT IN ('LGIF','LGIS')
ORDER BY 
    event_time DESC


-- group by login
SELECT
    server_instance_name,
    server_principal_name,
	MIN(event_time),
	MAX(event_time),
	COUNT(*)
FROM
    sys.fn_get_audit_file('M:\Management\Audit\*.sqlaudit', DEFAULT, DEFAULT)
WHERE 
    event_time >= DATEADD(day,-8,GETDATE())
    AND action_id = 'LGIF'
	AND statement LIKE 'Login failed for user%'
GROUP BY
	server_instance_name,
    server_principal_name

-- group by ip for non-domain failures
;WITH CTE_1 AS (
	SELECT
	    LTRIM(RTRIM(SUBSTRING(LTRIM(RTRIM(SUBSTRING(statement, CHARINDEX('CLIENT:',statement), LEN(statement)-CHARINDEX('CLIENT:',statement)))),8,16))) AS ipaddress
	FROM
	    sys.fn_get_audit_file('M:\Management\Audit\*.sqlaudit', DEFAULT, DEFAULT)
	WHERE 
	    event_time >= DATEADD(day,-1,GETDATE())
	    AND action_id = 'LGIF'
		AND statement NOT LIKE 'Login failed for user%'
)
SELECT 
	ipaddress,
	COUNT(*) as hit_count
FROM
	CTE_1
GROUP BY
	ipaddress