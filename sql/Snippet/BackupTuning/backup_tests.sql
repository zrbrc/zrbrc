/**********************************************************************************************************	 *
* 																											 *
* Name:	Backup Test Harness.sql (version 1.0 2012-12-11)													 *
*																											 *
* Author: Nicholas Cain, http://sirsql.net																	 *
*																											 *
* Purpose: This script is written for the purposes of performing multiple backups of a database using 		 *
*		different MAXTRANSFERSIZE & BUFFERCOUNT values as well as different numbers of backup files. 		 *
*		This is done in an attempt to identify the optimal settings that can be used to minimize backup 	 *
*		times.				  																				 *
* 																											 *
* Notes:																								  	 *
*	When executed the script will create a job on the SQL instance. This job, when executed will perform	 *
*	(at minimum) 40 backups. 																				 *
* 																										  	 *
*	Firstly all the specified maxtranfersize and buffercount combinations will be tested to a nul file. This *
*	will give a value showing the absolute fastest possible backup speed (as it reads all of the pages from  *
*	the database).																						  	 *
* 																										  	 *
*	Next it will move on and perform the same tests with one file, and continue with more files up to the    *
*	limit specified in @MaxBackupFiles.																	  	 *
* 																										  	 *
* 																										  	 *
*	Variables used & purpose:																				 *
* 		@DatabaseName		-	The name of the database you want to test the backups with					 *
* 		@MaxBackupFiles	-	The maximum number of backup files you want to write to							 *
* 		@BackupFolder		-	The destination folder for the backups										 *
* 		@WithCompression	-	Whether or not to use SQL Server compression (SQL 2008+)					 *
* 		@CreateJob		-	This creates a SQL agent job which can be executed to perform the tests			 *
* 		@JobLogFileName	-	The path and filename of the log for the job (used for evaluating data)			 *
* 		@OutputToScreen	-	Outputs the backup commands to the screen ready for copy/paste/execution		 *
* 																										  	 *
* 																										  	 *
*	Additional adjustments that can be made:																 *
* 		@MaxTransferSize table variable contains a list of sizes. Add/remove entries based on preference.	 *
* 				The currently used sizes are a good starting point										  	 *
* 																										  	 *
* 		@BufferCount table variable contains a list of different buffercount sizes. The current sizes are	 *
* 					a good starting point. *WARNING* Higher buffercount values along with high 			  	 *
* 					maxtransfersize values will cause SQL to start paging out memory					  	 *
* 																										  	 *
* 																										  	 *
*	Once the job has been executed the log file can be used with "Parse Backup Perf Tests.ps1" to asses	  	 *
*	the different levels of performance. Use the SQL Server errorlog to look for backup settings that have   *
*	caused memory paging in SQL Server (look for "A significant part of sql server process memory has been   *
*	paged out. This may result in a performance degradation")												 *
*																											 *
*	WARNING: Performing this many backup tests (with all the various settings can and will impact your 		 *
*			server performance. Be aware of	this. Do not cause issues for your users when performing the 	 *
*			tests, they will not like you for it.															 *
* 																										  	 *
*	For more information on backup tuning see the videos at http://midnightdba.itbookworm.com/Admin.aspx	 *
*																										  	 *
*	Issues or concerns with this script please contact me - Nic Cain at Nic@sirql.net						 *
*																										 	 *
**************************************************************************************************************/

SET NOCOUNT ON;

/* Declare the variables we'll use for our settings */
DECLARE @DatabaseName NVARCHAR(128) ,
    @MaxBackupFiles TINYINT ,
    @BackupFolder NVARCHAR(500) ,
    @WithCompression TINYINT ,
    @CreateJob TINYINT ,
    @JobLogFileName NVARCHAR(500) ,
    @OutputToScreen TINYINT


/* Enter the values here for your backup testing */
SELECT
    @DatabaseName = 'DSS_ASSIST_UATPT',
    @MaxBackupFiles = 8,
    @BackupFolder = '\\xx.xx.xx.xx\dbbackup\tmp' ,
    @WithCompression = 1,
    @CreateJob = 1,
    @JobLogFileName = 'M:\Management\Backup.log',
    @OutputToScreen = 0;




/* Table to hold the possible values for MAXTRANSFERSIZE. Add new rows if you want to test additional values */
DECLARE @MaxTransferSize TABLE ( TransferSize INT );
INSERT  INTO @MaxTransferSize
VALUES
    ( 2097152 ),
	( 4194304 );

/* Table to hold the possible values for BUFFERCOUNT. Add new rows if you want to test additional values */
DECLARE @Buffercount TABLE ( Buffers SMALLINT );
INSERT  INTO @Buffercount
VALUES
    ( 24 ),
	( 48 );

/* Create the temp table to hold a list of the files based on location & file count */
IF OBJECT_ID('tempdb..#Disk') IS NOT NULL 
    DROP TABLE #Disk;

CREATE TABLE #Disk
(
    Id SMALLINT IDENTITY(1, 1) ,
    FileCount TINYINT ,
    Cmd NVARCHAR(4000)
);

/* Build our disk commands based on the max number of backup files */
DECLARE @FilesCmd NVARCHAR(4000) ,
    @CurrFile TINYINT;

SELECT
    @CurrFile = 1 ,
    @FilesCmd = N'TO';
WHILE @CurrFile <= @MaxBackupFiles 
    BEGIN
    IF @CurrFile > 1 
            SELECT
        @FilesCmd = @FilesCmd + N',';
    SELECT
        @FilesCmd = @FilesCmd + N' DISK = ' + CHAR(39) + @BackupFolder
                + '\BackupPerfTest' + CONVERT(NVARCHAR(2), @CurrFile) + '.bak'
                + CHAR(39);
    INSERT  INTO #Disk
        ( FileCount, Cmd )
    SELECT
        @CurrFile,
        @FilesCmd;
    SELECT
        @CurrFile = @CurrFile + 1;
END

/* Create a table to hold all the backup commands, ready for executing */
IF OBJECT_ID('tempdb..#BackupCommands') IS NOT NULL 
    DROP TABLE #BackupCommands;
CREATE TABLE #BackupCommands
(
    Id SMALLINT IDENTITY(1, 1) ,
    BackupCmd NVARCHAR(4000)
);

/* Add entries for enabling the traceflag to output the backup config values & cycle the error log */
INSERT  INTO #BackupCommands
    ( BackupCmd
    )
SELECT
    'DBCC TRACEON (3213, 3604, -1);
		EXEC sp_cycle_Errorlog;'

/* Backup with default options for current baseline */
INSERT  INTO #BackupCommands
    ( BackupCmd
    )
SELECT
    'RAISERROR('+CHAR(39)+'NEW BACKUP' + CHAR(39) + ',0,1) WITH NOWAIT;' + CHAR(13)+CHAR(10)
				+ 'RAISERROR ('+CHAR(39) + 'BACKUP SETTINGS: MAXTRANSFERSIZE=0'
				+ ' BUFFERCOUNT=0'
				+ ' FILECOUNT=' + CONVERT(NVARCHAR(2), b.FileCount)
				+ CHAR(39) + ', 0, 1) WITH NOWAIT, LOG ;'+ CHAR(13) + CHAR(10) 
				+ 'BACKUP DATABASE ' + QUOTENAME(@DatabaseName) + N' ' + b.Cmd
                + ' WITH FORMAT, INIT' + CASE @WithCompression
                                           WHEN 1 THEN ', COMPRESSION;'
                                           ELSE ';'
                                         END
FROM
    #Disk b
ORDER BY b.Id

/* Backup to NUL for all the various options, this is the max possible backup speed */
INSERT  INTO #BackupCommands
    ( BackupCmd
    )
SELECT
    'RAISERROR('+CHAR(39)+'NEW BACKUP' + CHAR(39) + ',0,1) WITH NOWAIT;' + CHAR(13)+CHAR(10)
				+ 'RAISERROR ('+CHAR(39) + 'BACKUP SETTINGS: MAXTRANSFERSIZE='+ CONVERT(VARCHAR(7), TransferSize)
				+ ' BUFFERCOUNT='+ CONVERT(VARCHAR(4), Buffers)
				+ ' FILECOUNT=0' 
				+ CHAR(39) + ', 0, 1) WITH NOWAIT, LOG ;'+ CHAR(13) + CHAR(10) 
				+ 'BACKUP DATABASE ' + QUOTENAME(@DatabaseName) + N' TO DISK = '
                + CHAR(39) + 'NUL' + CHAR(39)
                + ' WITH FORMAT, INIT, MAXTRANSFERSIZE = '
                + CONVERT(VARCHAR(7), TransferSize) + ', BUFFERCOUNT = '
                + CONVERT(VARCHAR(4), Buffers)
                + CASE @WithCompression
                    WHEN 1 THEN ', COMPRESSION;'
                    ELSE ';'
                  END
FROM
    @MaxTransferSize
                CROSS APPLY @Buffercount
ORDER BY Buffers ,
                TransferSize;


/* Backup with all the various file counts, transfer sizes and buffer options */
INSERT  INTO #BackupCommands
    ( BackupCmd
    )
SELECT
    'RAISERROR('+CHAR(39)+'NEW BACKUP' + CHAR(39) + ',0,1) WITH NOWAIT;' + CHAR(13)+CHAR(10)
				+ 'RAISERROR ('+CHAR(39) + 'BACKUP SETTINGS: MAXTRANSFERSIZE='+ CONVERT(VARCHAR(7), TransferSize)
				+ ' BUFFERCOUNT='+ CONVERT(VARCHAR(4), Buffers)
				+ ' FILECOUNT=' + CONVERT(NVARCHAR(2), b.FileCount)
				+ CHAR(39) + ', 0, 1) WITH NOWAIT, LOG ;'+ CHAR(13) + CHAR(10) 
				+ 'BACKUP DATABASE ' + QUOTENAME(@DatabaseName) + N' ' + b.Cmd
                + ' WITH FORMAT, INIT, MAXTRANSFERSIZE = '
                + CONVERT(VARCHAR(7), TransferSize) + ', BUFFERCOUNT = '
                + CONVERT(VARCHAR(4), Buffers)
                + CASE @WithCompression
                    WHEN 1 THEN ', COMPRESSION;'
                    ELSE ';'
                  END
FROM
    @MaxTransferSize
                CROSS APPLY @Buffercount
                CROSS APPLY #Disk b
ORDER BY b.Id ,
                Buffers ,
                TransferSize;


/* Don't forget to turn off the trace flags */
INSERT  INTO #BackupCommands
    ( BackupCmd
    )
SELECT
    'DBCC TRACEOFF (3213, 3604, -1);'



/* Create a SQL job which can be used to run the backups (if option enabled) */
IF @CreateJob = 1 
    BEGIN
    DECLARE @JobCmd NVARCHAR(MAX) ,
            @TotalCmds TINYINT;
    SELECT
        @JobCmd = '' ,
        @CurrFile = 1 ,
        @TotalCmds = MAX(Id)
    FROM
        #BackupCommands;
    WHILE @CurrFile <= @TotalCmds 
            BEGIN
        SELECT
            @JobCmd = @JobCmd + BackupCmd + CHAR(13) + CHAR(10)
        FROM
            #BackupCommands
        WHERE   @CurrFile = Id;
        SELECT
            @CurrFile = @CurrFile + 1;
    END



    DECLARE @jobId BINARY(16), @JobName NVARCHAR(128);
    SELECT
        @JobName = N'Test Backup Performance '+ CONVERT(NCHAR(20), GETDATE(), 120)
    EXEC msdb.dbo.sp_add_job @job_name = @JobName,
    @enabled = 1, @notify_level_eventlog = 0, @notify_level_email = 0,
    @notify_level_netsend = 0, @notify_level_page = 0, @delete_level = 0,
    @description = N'Runs multiple database backups to assess performance of various options',
    @category_name = N'[Uncategorized (Local)]', @owner_login_name = N'sa',
    @job_id = @jobId OUTPUT;

    EXEC msdb.dbo.sp_add_jobstep @job_id = @jobId, @step_name = N'Run Backups',
    @step_id = 1, @cmdexec_success_code = 0, @on_success_action = 1,
    @on_success_step_id = 0, @on_fail_action = 2, @on_fail_step_id = 0,
    @retry_attempts = 0, @retry_interval = 0, @os_run_priority = 0,
    @subsystem = N'TSQL', @command = @JobCmd, @database_name = N'master',
    @output_file_name = @JobLogFileName, @flags = 0;

    EXEC msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1;

    EXEC msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)';


END


/* Output to screen if option enabled */
IF @OutputToScreen = 1 
    BEGIN
    SELECT
        BackupCmd
    FROM
        #BackupCommands
    ORDER BY Id
END

IF OBJECT_ID('tempdb..#Disk') IS NOT NULL 
    DROP TABLE #Disk;

IF OBJECT_ID('tempdb..#BackupCommands') IS NOT NULL 
    DROP TABLE #BackupCommands;