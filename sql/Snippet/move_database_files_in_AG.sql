-- in the below example, 
-- DBA is the database name
-- AG2016_1 is the AG name

-- make sure you substitue the DB and AG you want to work with

-- 1. get the list of files we want to move and create the alter statement to move the data files, like step 4 below
SELECT db_name(database_id) AS db_name,
       name,
       physical_Name,
       type_desc,
       size * 8 / 1024 AS size_mb
  FROM sys.master_files
 ORDER BY db_name, 
       name, 
       physical_name

-- 2. stop log backup jobs on the AG cluster, primary and secondary(s) and make sure they are finished before continuing.

-- 3. on secondary(s) only, remove the database from the AG (we will put it back after), yes its scary
-- we need to do this bc we can't run the alter while the DB is in the AG, but can after we remove it
-- and its in 'restoring' state, the primary replica will still have this DB and be serving it via the listener.
-- This is not needed if readable secondary is YES, you should able to run this alter without AG work.
ALTER DATABASE DBA SET HADR SUSPEND

-- 4. run the alter statement to move the files where you need them, like below examples:
ALTER DATABASE DBA MODIFY FILE ( NAME = DBA_log, FILENAME= 'L:\Logs\DBA_log.ldf')
ALTER DATABASE DBA MODIFY FILE ( NAME = DBA, FILENAME= 'D:\Data\DBA.mdf')

-- 5. stop sql services on the secondary node and manually move the files to the paths set in step 4
-- we need to stop SQL bc we cant take the DB offline while its in 'restoring' state,
-- the secondary replicas is down, but the primary is still up and serving the database

-- 6. start sql services and then re-add db to AG
-- you dont need this if you didnt need to do it in step 3.
ALTER DATABASE DBA SET HADR RESUME