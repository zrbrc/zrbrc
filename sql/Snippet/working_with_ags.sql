-- In the below examples:
--  AG: AG2016_1
--  Database: DBA

-- add a database on the primary replica to the AG,
-- will use whatever seeding method the AG is set to
ALTER AVAILABILITY GROUP AG2016_1 ADD DATABASE DBA

-- remove database from AG
ALTER AVAILABILITY GROUP AG2016_1 REMOVE DATABASE DBA

-- add a prepared database to a secondary replica
ALTER DATABASE DBA SET HADR AVAILABILITY GROUP = AG2016_1

-- remove database from a secondary replica
ALTER DATABASE DBA SET HADR OFF

-- get endpoints
select * from sys.endpoints

-- stop endpoint
ALTER ENDPOINT Hadr_endpoint STATE = STOPPED

-- start endpoint
ALTER ENDPOINT Hadr_endpoint STATE = STARTED