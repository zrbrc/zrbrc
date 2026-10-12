-- This is not a run and forget script, it has steps and each step must be performed on a particular node(noted),
-- this is only for a proof of concept for the steps needed to setup a new AG database with TDE.
-- The steps needed to perform this on an existing AG database are a little different,
-- for existing, you need to have everything in place before you enable encryption on the database
-- more info here:
-- https://docs.microsoft.com/en-us/sql/relational-databases/security/encryption/transparent-data-encryption?view=sql-server-2016#tde-and-always-on
--
-- on primary
--

-- note: the master key passwords do not need to match on each instance, the way the key is generated
-- they will end up being different in the end anyway

-- step 1 - check if master key exists, if not create one
USE master
SELECT * FROM sys.symmetric_keys

USE master
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'qiRPKAoZLzYn7YBAdWcWOegNS9G03BYc'

-- step 2 - create cert and export to file to import on secondaries
USE master
CREATE CERTIFICATE SB2016 WITH SUBJECT = 'Sandbox'

USE master
BACKUP CERTIFICATE SB2016 
	TO FILE ='M:\Management\Backup\SB2016_cert.crt' 
	WITH PRIVATE KEY (
		FILE='M:\Management\Backup\SB2016_cert.key', 
		ENCRYPTION BY PASSWORD='m5esWCtAPD3xaMw1grwdj0akbfRIe2sN')

--
-- on secondary(s)
--

-- step 3 - check if master key exists, if not create one
USE master
SELECT * FROM sys.symmetric_keys

USE master
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'qiRPKAoZLzYn7YBAdWcWOegNS9G03BYc'

-- step 4 - import cert from primary
CREATE CERTIFICATE SB2016 
	FROM FILE ='\\xx.xx.xx.xx\m$\Management\Backup\SB2016_cert.crt' 
	WITH PRIVATE KEY (
		FILE='\\xx.xx.xx.xx\m$\Management\Backup\SB2016_cert.key', 
		DECRYPTION BY PASSWORD='m5esWCtAPD3xaMw1grwdj0akbfRIe2sN')

--
-- on primary and secondary(s)
--

-- step 5 - verif certificates, they should match out and have 'ENCRYPTED_BY_MASTER_KEY'
USE master
SELECT name, certificate_id, principal_id, pvt_key_encryption_type_desc, start_date, expiry_date, thumbprint
FROM sys.certificates

--
-- on primary
--

-- step 6 - create database key and enable encryption
USE EncryptedDatabase
CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_128 ENCRYPTION BY SERVER CERTIFICATE SB2016
ALTER DATABASE EncryptedDatabase SET ENCRYPTION ON

-- step 7  - check encryption , the value 3 represents an encrypted state on the database and transaction logs.
USE master
SELECT 
	 DB_NAME(database_id) AS DatabaseName
	,Encryption_State AS EncryptionState
	,key_algorithm AS Algorithm
	,key_length AS KeyLength
FROM sys.dm_database_encryption_keys

	-- or for all stats
 SELECT
	d.name,
	d.is_encrypted,
	dmk.encryption_state,
	dmk.percent_complete,
	dmk.key_algorithm,
	dmk.key_length
FROM
	sys.databases d
    LEFT OUTER JOIN sys.dm_database_encryption_keys dmk
    ON d.database_id = dmk.database_id;

-- step 8 - full and log backup, cant use the wizard to join to AG for TDE
BACKUP DATABASE EncryptedDatabase TO  DISK = N'\\xx.xx.xx.xx\dbbackup\sb\sbdbcls1ls1\TDE\EncryptedDatabase.bak' WITH NOFORMAT, NOINIT,  NAME = N'EncryptedDatabase-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
BACKUP LOG EncryptedDatabase TO  DISK = N'\\xx.xx.xx.xx\dbbackup\sb\sbdbcls1ls1\TDE\EncryptedDatabase.trn' WITH NOFORMAT, NOINIT,  NAME = N'EncryptedDatabase-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10

--
-- on secondary(s)
--

-- step 9 - restore full and log backup
USE master
RESTORE DATABASE EncryptedDatabase FROM  DISK = N'\\xx.xx.xx.xx\dbbackup\sb\sbdbcls1ls1\TDE\EncryptedDatabase.bak' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 5
RESTORE LOG EncryptedDatabase FROM  DISK = N'\\xx.xx.xx.xx\dbbackup\sb\sbdbcls1ls1\TDE\EncryptedDatabase.trn' WITH FILE = 1, NORECOVERY, NOUNLOAD,  STATS = 10

--
-- on primary
--

-- step 10 - add database to AG
USE master
ALTER AVAILABILITY GROUP AG2016_1 ADD DATABASE EncryptedDatabase

--
-- on secondary(s)
--

-- step 11 - add database to ag
USE master
ALTER DATABASE EncryptedDatabase SET HADR AVAILABILITY GROUP = AG2016_1
