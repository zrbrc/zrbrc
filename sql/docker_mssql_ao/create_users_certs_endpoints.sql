-- step 1 - node 1
USE master  
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'PassWOrd123!'  
GO

USE master
CREATE CERTIFICATE node1_cert WITH SUBJECT = 'node1_cert'  
BACKUP CERTIFICATE node1_cert TO FILE = '/var/opt/mssql/shared/node1_cert.crt'   
GO 

CREATE ENDPOINT hadr_endpoint  
   STATE = STARTED  
   AS TCP (  
      LISTENER_PORT=5022  
      , LISTENER_IP = ALL  
   )   
   FOR DATABASE_MIRRORING (   
      AUTHENTICATION = CERTIFICATE node1_cert 
      , ENCRYPTION = REQUIRED ALGORITHM AES  
      , ROLE = ALL  
   )  
GO 

-- step 2 - node 2
USE master
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'PassWOrd123!'  
GO 

USE master
CREATE CERTIFICATE node2_cert WITH SUBJECT = 'node2_cert'  
BACKUP CERTIFICATE node2_cert TO FILE = '/var/opt/mssql/shared/node2_cert.crt'  
GO

CREATE ENDPOINT hadr_endpoint  
   STATE = STARTED  
   AS TCP (  
      LISTENER_PORT=5022  
      , LISTENER_IP = ALL  
   )   
   FOR DATABASE_MIRRORING (   
      AUTHENTICATION = CERTIFICATE node2_cert
      , ENCRYPTION = REQUIRED ALGORITHM AES  
      , ROLE = ALL  
   )  
GO

-- step 3 - node 1
USE master  
CREATE LOGIN node2_login WITH PASSWORD = 'PassWord123!'  
CREATE USER node2_user FOR LOGIN node2_login  
GO  

CREATE CERTIFICATE node2_cert  
   AUTHORIZATION node2_user  
   FROM FILE = '/var/opt/mssql/shared/node2_cert.crt'  
GO 

GRANT CONNECT ON ENDPOINT::hadr_endpoint TO node2_login  
GO

-- step 4 - node 2
USE master  
CREATE LOGIN node1_login WITH PASSWORD = 'PassWord123!'  
CREATE USER node1_user FOR LOGIN node1_login  
GO  

CREATE CERTIFICATE node1_cert  
   AUTHORIZATION node1_user  
   FROM FILE = '/var/opt/mssql/shared/node1_cert.crt'    
GO 

GRANT CONNECT ON ENDPOINT::hadr_endpoint TO node1_login  
GO