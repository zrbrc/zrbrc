-- Step 1: Configure DIST1, DIST2 as distributors using TSQL only
-- Connect DIS1
 
use master

exec sp_adddistributor @distributor = N'DIS1', @password = N'Password!'

 
-- Connect DIS2
use master

exec sp_adddistributor @distributor = N'DIS2', @password = N'Password!'

-- Step 2: Configure distribution database on DIS1
 
-- Connect DIS1
use master

exec sp_adddistributiondb @database = N'distribution', @data_folder = N'D:\Data', @data_file = N'distribution.MDF', @data_file_size = 50,
@log_folder = N'L:\Logs', @log_file = N'distribution.LDF', @log_file_size = 10, @min_distretention = 0, @max_distretention = 72, @history_retention = 48,
@deletebatchsize_xact = 5000, @deletebatchsize_cmd = 2000, @security_mode = 1
 
-- To support AlwaysOn Availability Groups, change to full recovery and take full backup
-- Settings and backup can be performed using SSMS GUI or TSQL commands
-- we just need this to be able to backup to AG, a proper backup will be taken later 

ALTER DATABASE [distribution] SET RECOVERY FULL WITH NO_WAIT
BACKUP DATABASE [distribution] TO DISK = 'null'

-- Step 3: Create Distributor's Availability Group via SSMS and then add distrubtion database to AG via t-sql.

ALTER AVAILABILITY GROUP [AG2019_X]
ADD DATABASE [distribution]

-- Optional: Distributor Listener Custom Port: If you're using custom port for your Distributor listener, 
-- as shown below, you'll need to create alias for your Distributor listener on each Publisher and 
-- Distributor replica.  Create both 32-bit and 64-bit Client Aliases using SQL Server Configuration Manager.  
-- In this example with 2 Publisher replicas and 2 Distributor replica you'd need to create a 
-- total of (2+2 = 4 replica x 2 32/64bit = 8) eight aliases.

-- Step 4: On DIST2 add distribution database, no additional parameters.

-- Connect DIS2
exec sp_adddistributiondb 'distribution'
 
-- Step 5: Add all publisher(s) to all distributor(s)
-- When step completes, linked servers on DIST1 and DIST2 will point to PUB1, PUB2, and repl_distributor.

-- Connect DIS1
exec sp_adddistpublisher @publisher = 'PUB1', @distribution_db = 'Distribution', @working_directory = '\\dc\Share\Repl'
exec sp_adddistpublisher @publisher = 'PUB2', @distribution_db = 'Distribution', @working_directory = '\\dc\Share\Repl'
 
-- Connect DIS2
exec sp_adddistpublisher @publisher = 'PUB1', @distribution_db = 'Distribution', @working_directory = '\\dc\Share\Repl'
exec sp_adddistpublisher @publisher = 'PUB2', @distribution_db = 'Distribution', @working_directory = '\\dc\Share\Repl'

-- 
-- Publisher Workflow
-- 
-- When completes, linked server on PUB1 will have a linked server to repl_distributor which is mapped in sys.sysservers to DISAGLISTENER.

-- Connect PUB1
 
-- To add the distribution database AG listener as the distributor, on PUB1
Use MASTER
exec sp_adddistributor @distributor = 'DisAGListener', @password = 'Password!'

-- Connect PUB2

-- To add the distribution database AG listener as the distributor, on PUB2
-- Must be executed directly on the Pub2 by connecting via RDP or you'll get an error.
 
exec sp_adddistributor @distributor = 'DisAGListener', @password = 'Password!'
GO

-- Create Publication and specify redirected publisher
-- On active Publisher replica, enable the publisher database for publishing.

-- Connect PUB1
 
USE master
 
EXEC sys.sp_replicationdboption @dbname = 'AW', @optname = 'publish', @value = 'true'

-- Create publication using SSMS Replication wizard or via TSQL replication scripts.  No changes 
-- needed at this step when publication is being created.

-- Connect DIS1
 
-- On Primary Distributor, add Publisher's listener
-- NOTE: If Publisher “listener” is using a non-default port, specify the port number in the @redirected_publisher parameter as shown below.

USE distribution

EXEC sys.sp_redirect_publisher @original_publisher = 'pub1', @publisher_db = 'AW', @redirected_publisher = 'PubAGListener,15150'

-- Validate redirected publisher
-- Make remote desktop connection to DIST1 and execute command to validate redirected publisher.

USE distribution;
 
DECLARE @redirected_publisher sysname;
EXEC sys.sp_validate_replica_hosts_as_publishers @original_publisher = 'pub1', @publisher_db = 'AW', @redirected_publisher = @redirected_publisher output; 
PRINT @redirected_publisher

-- Add subscriptions as normal and use the AG listener as the subscriber.