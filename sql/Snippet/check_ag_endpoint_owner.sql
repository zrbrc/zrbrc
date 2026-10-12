THROW 60000,'Oops! No, dont just hit F5. Run these pieces one at a time as needed.',1
GO
/* 
more info here 
https://jackworthen.com/2020/01/06/changing-the-owner-of-an-availability-group-endpoint/
*/

USE master

-- step 1: check owner of endpoint
SELECT SUSER_NAME(principal_id) AS endpoint_owner,
       name AS endpoint_name
  FROM sys.database_mirroring_endpoints

-- step 2: Check and record any permissions. (you will need to add this back)
SELECT EPS.name,
       SPS.STATE,
       CONVERT(nvarchar(38),SUSER_NAME(SPS.grantor_principal_id)) AS GrantedBy,
       SPS.TYPE AS Permission,
       CONVERT(nvarchar(46),SUSER_NAME(SPS.grantee_principal_id)) AS GrantedTo
  FROM sys.server_permissions SPS,
       sys.endpoints EPS
 WHERE SPS.major_id = EPS.endpoint_id
   AND name = 'Hadr_endpoint'
 ORDER BY Permission,
          GrantedBy,
          GrantedTo

-- step 3: change owner and give grant connect back
ALTER AUTHORIZATION ON ENDPOINT::Hadr_endpoint TO DECSSsa
GRANT CONNECT ON ENDPOINT::Hadr_endpoint TO [domain\user]

-- step 4: run step 1 again to verify ownership change

-- step 5 check if the AG is owned by someone
SELECT ar.replica_server_name
      ,ag.name AS ag_name
      ,ar.owner_sid
      ,sp.name
 FROM sys.availability_replicas ar
      LEFT JOIN sys.server_principals sp ON sp.sid = ar.owner_sid 
      INNER JOIN sys.availability_groups ag ON ag.group_id = ar.group_id
WHERE ar.replica_server_name = SERVERPROPERTY('ServerName')

-- step 6: set endpoint ownership
ALTER AUTHORIZATION ON AVAILABILITY GROUP::hostdcssCPag to [domain\user]