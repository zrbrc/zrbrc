-- just the login and server grant sql
-- this is a simplication and merging of the 2nd and 3rd query below to only give the SQL needed
-- copy the create sql column for the login you need
SELECT
    p.name AS LoginName,
    CONCAT(N'CREATE LOGIN ', QUOTENAME(p.name), N' WITH PASSWORD = ', CONVERT(VARCHAR(514), sl.password_hash, 1), N' HASHED, SID = ', CONVERT(VARCHAR(514), p.sid, 1), N', DEFAULT_DATABASE = ', QUOTENAME(p.default_database_name), N', CHECK_POLICY = ', IIF(sl.is_policy_checked=1,N'ON','OFF'), N', CHECK_EXPIRATION = ', IIF(sl.is_expiration_checked=1,N'ON','OFF'), N'; ',
          N'ALTER LOGIN ', QUOTENAME(p.name), IIF(p.is_disabled = 1,' DISABLE',' ENABLE'), N'; ',
          perm.state_desc, N' ', perm.permission_name, N' TO ', QUOTENAME(p.name) COLLATE Latin1_General_CI_AS_KS_WS, N'; '
    ) AS CreateSql
FROM
    sys.server_principals AS p
    LEFT JOIN sys.sql_logins AS sl ON p.name = sl.name
    LEFT JOIN sys.server_permissions AS perm ON perm.grantee_principal_id = p.principal_id AND perm.type = 'COSQ' AND perm.state IN ('G','W') AND p.is_disabled = 0
WHERE 
    p.type = 'S'
    AND p.name <> N'sa'
    AND p.name NOT LIKE N'##%##';


-- create login
SELECT
    p.sid AS LoginSid,
    p.name AS LoginName,
    p.type_desc AS LoginType,
    p.default_database_name AS DefaultDatabase,
    sl.password_hash AS VarbinaryPasswordHash,
    IIF(sl.is_policy_checked=1,1,0) AS IsPolicyChecked,
    IIF(sl.is_expiration_checked=1,1,0) AS IsExpirationChecked,
    IIF(p.is_disabled = 0,1,0) AS IsEnabled,
    IIF(perm.state IN ('G','W'),1,0) AS CanLogIn,
    CASE WHEN p.type IN ('U','G')
              THEN CONCAT(N'CREATE LOGIN ', QUOTENAME(p.name), N' FROM WINDOWS', N' WITH DEFAULT_DATABASE = ', QUOTENAME(p.default_database_name), N';')
         WHEN p.type = 'S'
              THEN CONCAT(N'CREATE LOGIN ', QUOTENAME(p.name), N' WITH PASSWORD = ', CONVERT(VARCHAR(514), sl.password_hash, 1), N' HASHED, SID = ', CONVERT(VARCHAR(514), p.sid, 1), N', DEFAULT_DATABASE = ', QUOTENAME(p.default_database_name), N', CHECK_POLICY = ', IIF(sl.is_policy_checked=1,N'ON','OFF'), N', CHECK_EXPIRATION = ', IIF(sl.is_expiration_checked=1,N'ON','OFF'), N';')
    END AS CreateSql,
    CONCAT(N'ALTER LOGIN ', QUOTENAME(p.name), ' ', IIF(p.is_disabled = 1,' DISABLE',' ENABLE'), N';') AS EnableSql,
    DateCreated             = p.create_date,
    DateModified            = p.modify_date
FROM
    sys.server_principals AS p
    LEFT JOIN sys.sql_logins AS sl ON p.name = sl.name
    LEFT JOIN sys.server_permissions AS perm ON perm.grantee_principal_id = p.principal_id AND perm.type = 'COSQ' AND perm.state IN ('G','W') AND p.is_disabled = 0
WHERE 
    p.type IN ('S','U','G')
    AND p.name <> N'sa'
    AND p.name NOT LIKE N'##%##';

-- grant server permissions
SELECT
    p.sid AS LoginSid,
    p.name AS LoginName,
    p.type_desc AS LoginType,
    p.default_database_name AS DefaultDatabase,
    IIF(p.is_disabled = 0,1,0) AS LoginIsEnabled,
    COALESCE((SELECT TOP 1 1 FROM sys.server_permissions AS cosq
              WHERE cosq.grantee_principal_id = p.principal_id
              AND cosq.type = 'COSQ' 
              AND cosq.state IN ('G','W')
              AND p.is_disabled = 0), 0) AS CanLogIn,
    perm.type AS PermissionType,
    perm.state AS PermissionState,
    CONCAT(perm.state_desc, N' ', perm.permission_name, N' TO ', QUOTENAME(p.name) COLLATE Latin1_General_CI_AS_KS_WS,  N';') AS PermissionSql,
    p.create_date AS DateLoginCreated,
    p.modify_dat AS DateLoginModifiede
FROM
    sys.server_principals AS p
    JOIN sys.server_permissions AS perm ON perm.grantee_principal_id = p.principal_id
WHERE 
    p.type IN ('S','U','G')
    AND p.name <> N'sa'
    AND p.name NOT LIKE N'##%##';

