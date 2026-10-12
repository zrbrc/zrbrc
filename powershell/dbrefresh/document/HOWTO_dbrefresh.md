# DBRefresh

## Current Installs

dbrefresh is current installed at the below locations.

| Environment   | Zone  | Server                         | Path                               |
| :------------ | :---- | :----------------------------- | ---------------------------------- |
| TEST (ASSIST) | EL2   | hostnameclsn1 (xx.xx.xx.xx) | M:\\Management\\dbrefresh          |
| TEST (DECSS)  | IDMZ3 | hostname8n1 (xx.xx.xx.xx)  | M:\\Management\\Scripts\\dbrefresh |
| DEV           | DEV   | host04 (xx.xx.xx.xx)     | M:\\Management\\dbrefresh          |

## Logs

dbrefresh logs to the network by default, the locations for each environment are below, copy and paste them into the path into Windows Explorer. Sub-folders are date stamped. There will be a log file for each run.

| Environment | Zone  | Path                                  |
| :---------- | :---- | :------------------------------------ |
| TEST        | EL2   | \\\\xx.xx.xx.xx\\dbbackup\\refresh |
| TEST        | IDMZ3 | \\\\xx.xx.xx.xx\\tsdeptc2\\refresh   |
| DEV         | IDEV  | \\\\xx.xx.xx.xx\\backup\\refresh   |

## Requirements

1. **dbrefresh script package**: This is in the DBA-TFS git repo. It can be gotten via VSCODE or via the TFS web interface. Download the whole folder and copy it to the server you will be running this process from. The location does not matter.

1. **PowerShell 5.x**: This is the default version on Windows 10/11 and Server 2016/2019. If you are trying to execute this on Server 2012, you will need to install WMF5 (aka PowerShell 5) to run these scripts. There is also a minor difference in the install routine for the modules, on Server 2012, the modules path does not support version number in the path, so you would need to move all the files\\folders in that versioned folder up 1 folder level, you should then be able to delete the empty version number folder. Please ask if unclear about this step.

1. **dbatools module**: This PowerShell module is needed on the server running the scripts. It is not needed on any of the target SQL Instances. Dbatools can be downloaded on a local desktop and then copied to the server.
    1. Look at method 1 at this link: <https://dbatools.io/offline/>

    1. The downloaded module will need to be copied to the server. The
        easiest way is to copy it to the global module folder,
        'C:\\Program Files\\WindowsPowerShell\\Modules'.

    1. You should end up with a folder like, 'C:\\Program Files\\WindowsPowerShell\\Modules\\dbatools\\1.0.101' and then a files and folders under that path for the module.

    1. You can then test this by opening a PowerShell prompt and running Import-Module dbatools. This will either work and not display any error or give an error. You can also test via Get-Module dbatools -ListAvailable

1. THIS IS NO LONGER USED, USING NATIVE Start-Job. ~~**poshrsjob module**: This PowerShell module allows running multiple threads in the background to be able to perform restores to multiple instances at the same time. This is installed in the same manner as above.~~

1. **sqlserver module**: This PowerShell module is the Microsoft PowerShell module for SQL Server. There is an older module, 'sqlps' that may come installed on some systems with SSMS or SQl Server, but 'sqlserver' is the newer current version. Same install method as above.

1. **Permissions on target server**: You will need SA permissions to do any of these restores.

## Word Document

You can turn this .md file into a word docx file buy running this command. You need pandoc installed and is easiest via WSL.

    pandoc -s -o HOWTO_dbrefresh.docx HOWTO_dbrefresh.md

## Getting Started

### Special Notes

#### Assist DEV and SIT

DEV and SIT refreshes require use of the 'Copy Drive'. Firewall/network rules prevent getting backup files via this script as it does with TEST. Using the LocalFile switch allows use of files from the 'Copy Drive', see parameters section for more info on it. Please coordinate with Telecomm and get prod backup files copied to the 'Copy Drive' and then attached to **xx.xx.xx.xx**.

#### DECSS TEST

DECSS TEST requires some special attention because replication is involved. The main refresh process is still the same, but is a script before and a script after that needs to run for dropping and recreating the replication subscriptions respectively. The scripts are numbered in the order they should be performed in. 1-Drop Replication, 2-Run Refresh, 3-Create Replication. Fedcert, Timewarp and Sandbox do not have replication and thus do no need any special handling. Fedcaert and Sandbox are scheduling in SSA--Sandbox every morning at 5am and Fedcert first Friday of the month at 8am. On-request refreshes are likely only for Timewarp and Test (aka Static/Online).

### Steps

1. Get the refresh request. The refresh request should have a list of the requested databases to refresh, to what server(s), and possibly if to apply any dacpac (Assist/WW) or to make any environmental reference changes in stored procedures, views, functions, or synonyms (i.e. Change \_PROD to \_TEST). Sometimes it is requested to use diffs as well as fulls to do the restore. The newest version of dbrefresh supports using diffs during the restore process and it is controlled by a switch on the script. More on that later.

1. Once we have the request for what to refresh, we need to tell the script what to refresh. This is accomplished by updating a text file with the requested DBs.

   1. Browse to the dbdeploy folder (noted above for each environment), you should see the below folder structure. Go into the 'request' folder and find the file corresponding to the environment you were asked to request. Note: TEST and UATCR are broken into 2 'workload' files. This is split in 2 workloads driven by DataServicesHub and WorkerWeb and then other databases to try and split the work evenly, this allows us to run these groups in parallel and get more work done. Most if not all of the DBs should already be in the file and can be (un)commented as needed, more on that later.

   ![folder](.//media/image1.png)
   ![requests](.//media/image2.png)

1. The request files are delimited files, delimited by ';'. Each line is a request for 1 database to be refreshed. They are refreshed in the order listed, so if there is a dependency on any, do them in the proper order. The only current dependency is for MCI and MVMultiIndex. MVMultiIndex needs to happen before MCI because MCI has a post-process script to update the MCI sequence number and it uses data from MVMultiIndex for that. This dependency order is already defined in the MCI request file. The file format is like such:

   ![requests](.//media/image3.png)

    1. **Header**: The top line is a header and must be left as is. The 'columns' are Database, Transform, and Filter and must be left alone for proper functionality.

    1. **Database** is self-explanatory, this is the **target** database that is wanted to be restored, this may or may not be the name that will be supplied in the request as sometimes they request the PROD DB name. There is also an exception, there are a couple different databases that have naming difference other than just \_TEST/\_PROD. For example, DSS\_DataServiceHub\_TEST vs D**H**SS\_DataServiceHub\_PROD. This naming discrepancy is handled in the request and reference file. The name in the request file should be what it's named on the target server that you want to the refresh/restore to happen on.

    1. **Transform** is what type of transformations to perform after the restore, there are 3 options, **DAC**, **REP** and **\<blank\>**. **DAC** is to apply a **DACPAC** and **REP** is to replace references, i.e. \_PROD to \_TEST, and **\<blank\>** is to do neither, the usual config for MCI databases. What to replace is defined in the reference file and is for the most part static. Both options have further details about what and where in the references file, will be discussed later.

    1. **Filter** is just that, you can put a list of strings, comma seperated, in this field and it will be used for filtering on the .bak files during the restore. If you wanted to use a particular backup file, you can add any string to filter on that file, in the example, it's a piece of the datestamp on the .bak file. This field is used as is, so you need to add the wildcard **(\*)** if you need to use it.

    **NOTE**: For running refresh in SIT/DEV, this is a **mandatory** field because all of the .bak files are in the same folder and we need to filter on the bak file for the DB we are refreshing, in SIT the filter is the DB name minus the environment suffix. The request file is already pre-populated with this data. This could also be handled differently by putting all the backups in their own folders and then a filter would not be needed.

    1. Choosing **what** to refresh is a simple as (un)commenting out a line. Putting a '\#' on any line at the start (in column one) will make the refresh process skip that DB, just be sure to not do so on line 1 as the header is always needed.

1. At this point we are almost ready to execute the script, but let's go over some more info about other aspects of the script.

1. There are numerous Run-Refresh\*.ps1 files in the dbrefresh folder. These are the 'runner' scripts to perform the refresh. There is one for each environment and then some 'work' splits for larger refresh groups, as explained above, for DataServicesHub and WorkerWeb. Each Run-Refresh\* script is mostly the same except for passed parameters to run the refresh for that particular environment. Here is an example of one:

   ![parameters](.//media/image4.png)

1. There are 2 input files for the refresh script, parameter lines 1 and 2 above. Line 2 is the RequestFile as explained above in 2.3. Each Run-Refresh\* script points to a similarly named request file

1. The other file on line 1 DbConfigFile is the reference file, this parameter has a default value and does not need to be used unless you want to override it. In the example above it was set for a special refresh request of some old backups. The reference file is another delimited file that contains all the info about a particular database. It has the instance\\listener, source database name, target database name, AG name, data and log paths, etc. Check the glossary for more details on the whole file

1. The other line that is not a switch/boolean value is Notify, line 4 above. This is a list of emails to notify upon completion or failure, in the format of 'email1\@company.com','email2\@company.com'. If the line is commented, no notifcations will happen, uncommented, it will notify those email addresses

1. There are numerous switches that can be passed to the refresh script, you can see some samples above. These switches can be turned on and off by commenting the line with a \#, similar to the requests file. Each switch parameter is listed for ease of use. Commented out means false, un-commented means true.

   > NOTE: This format of passing variables using the \@splat is called
   > splatting. It's an easier to read way to organize parameters passed
   > than to have a long line of variables. This method vs the more
   > standard **CmdLet -Name 'Value'** both work equally.

1. The last line & .\\Refresh-Database.ps1 \@splat, is where the call
    to the main refresh script is happening, passing in the all the
    above parameters.

1. The RequestFile is the only mandatory parameter.

## Executing the Refresh

1. After the request file is set for the requested refreshes and you copied dacpacs as noted above (if needed), executing the script can be completed in Windows Explorer for the correct environment/request, Right-Click -\> Run with Powershell. You do **NOT** need to run this as admin. Powershell will use the credentials of the user executing for instance permissions.

1. The script will start with some initializations, if you have Verify set to true, it will ask for a couple confirmations before doing any work. The first will be to confirm what you requested is what's being run. It will list the info in the **RequestFile**. The second confirmation will happen for each DB refresh, it has the options (y)es/(n)o/(a)ll. If you answer a, it will skip the remaining confirmations for each database and proceed all the way thru with each request. During a new/modified request run, I like to include the verify switch to check everything on the first execution and then use 'a' to continue uninterrupted after that.

1. Upon completion, there will be a summary of any warnings\\errors and a summary of what was refreshed. If notifications were enabled, a simple email report will be sent. Depending on the level of error, the refresh script may skip the database in question or stop all further processing. Investigations will need to be made.

## Refresh Process

Below is a summary of the steps taken during the refresh process. Some
may not pertain to the requested refresh if not requested or relevant.

1. Initialize variables.
1. Create working folders, where is dependant upon the environment.
1. Import RequestFile and DBConfig files.
1. Import needed PowerShell Modules.
1. Create credential object for sqladmin.refresh so SQL Server can map a drive to the Prod backup share.
1. Gather data on databases being requested for refresh.
1. Then on each database requested the below happens in a loop.
   1. Disable Log Backup
   1. Differential or Full backup, can be skipped with switch. Will attempt a diff backup first. Also supports forcing a full backup.
   1. Export users and roles.
   1. Copy table data to staging database.
   1. Pre-process data.
   1. Restore\--this will be run for each replica for the AG if one is involved, can be skipped for testing purposes.
      1. Drop database from AG.
      1. Map network share **with-in** SQL Server on each replica to the Prod backup shares. This can skipped with the -LocalFile. For example, this is not needed for SIT since all the files are local and not cross-domain.
      1. Find backup files on the mapped drive, FULL and DIFF if switch is set.
      1. Disable SSA log backup job
      1. Restore to replica. This is run in parallel on each replica using powershell ultithreading.
      1. Wait for all replica restores to complete.
      1. Create log backup on primary replica
      1. Restore log backup on secondary replica(s).
      1. Join database to AG.
   1. Fix logical names, fix owner, fix FileStream and set Read-only.
   1. Remove un-needed schemas and views, named '\*\\\*'.
   1. Drop all non-system roles and users.
   1. Add all previously exported roles and users.
   1. Add persisted data back into restored database if requested.
   1. Run transformation, DACPAC or 'export, rename, import'.
   1. Post-Process data, these are specific to each DB and equates to running SQL against each database that needs it.
   1. Perform full backup, can be skipped with switch.
   1. Shrink log file if requested.
1. All restores for all requested databases are completed.
1. Saves all data gathered throughout the process and saves it to an XML file so that we can pickup where we left off. More on Restart later.
1. Display what work we did.
1. Re-enable SSA Log jobs for any instance where we had turned them off where another refresh is not still happening. This is tested by looking for any database in **restoring** state.
1. Create restore report and display or email restore report depending on what was requested.
1. Display Log Summary about what happened. If there were no errors, nothing is displayed unless **-Verbose** was passed.
1. Completed.
1. There is a script included in the document folder for creating a more detailed restore report that I usually send out to the group upon completed, 'Restore\_Report.sql'

## Errors and Restarts

The refresh script will attempt to restart any failed process on a subsequent run. It will attempt to continue from the database and step that it failed on. It will skip refreshes for a database that already completed successfully. It will also skip steps for a database that had already completed. Depending on the reason for failure, you may or may not be able to just re-run and let it perform a restart on its own. If you need to have a particular database started again from step 1, the easiest way to do so is go to the request file and comment out any previous databases, these should have already completed anyway. The refresh script is smart enough to check updated dates on the request file and the xml data file. If the request file was updated after the refresh data was last saved, it will treat this as a new request and start on step 1. For other issues, further investigation may be needed. For example, if a database failed to add to the AG post restore, it would be easier to manually add the DB to the AG and then restart from the next step. The details on the restores and progress are kept in the working folder data folder. This is an XML file named for the request file and with a timestamp. Check the glossary for what each steps number is.

Some errors are terminating errors and some are warnings. Generally, warnings should be checked for any action that might needs to be taken. Warnings can include skipping backups, since this can be requested when the refresh was called, mostly likely its expected. Other warnings could be database not in AG. This particular warning usually happens during a recovery attempt after another error. It's easier to recover with the database only existing on the primary replica and not in the AG versus trying to get everything synchronizing in the AG again, especially for a large database. The script will attempt to put the database back in the AG after the restores to the replicas as defined in the DbConfig file. Other warnings could include not being able to find a role/user export file, this will not drop roles users from the restored DB unless we have a file to replace that with.

There are too numerous of possible errors to list here, so investigations will need to be made if something should occur.

## Reference

### Working folders

This is where all log files, exports, trn files, and backup files (if a previous backup path cannot be found) will be stored during the refresh. Depending on where the script is running, it will check for these paths, if it cannot find any of them, it will create a datestamped working folder in the current folder of the script.

| Network        | Backup Path                           |
| :------------- | :------------------------------------ |
| TEST-EL2       | \\\\xx.xx.xx.xx\\dbbackup\\refresh |
| TEST-EL1-IDMZ3 | \\\\xx.xx.xx.xx\\tsdcssc2\\refresh   |
| DEV\\SIT       | \\\\xx.xx.xx.xx\\backup\\refresh   |

### Script Parameters

These are the parameters found in the Run-*.ps1 scripts. These scripts call the main Refresh-Database.ps1 script.

| Parameter              | type      | comment                                                                                                                                                                                         |
| :--------------------- | :-------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RequestFile**        | mandatory | This is a list of the target dbs that you want restored/refreshed.                                                                                                                              |
| **DbConfigFile**       | optional  | This uses the default DbConfig.csv unless you set your own for testing purposes.                                                                                                                |
| **BackupPath**         | optional  | If you need to or want to override the backup path logic, you can set a path and all backups will go to that folder.                                                                            |
| **WorkingPath**        | mandatory | This is the root folder where all refresh output files are generated.                                                                                                                           |
| **Notify**             | optional  | This will send notifitcations via email for errors, completions  and a final report.                                                                                                            |
| **Verify**             | optional  | This will force the confirmation for each DB before making changes. You can answer \'a\' to skip remaining prompts when running.                                                                |
| **LocalFile**          | optional  | This will make the process use the backup paths as-is and not create a mapping with credentials to the path. Good for using files in the same domain/zone.  This is used for DEV/SIT refreshes. |
| **UseDiff**            | optional  | This will bring in diffs for the restore process, else it will only use fulls.                                                                                                                  |
| **SkipPreBackup**      | optional  | This will skip the diff before restores.                                                                                                                                                        |
| **PreBackupCleanup**   | optional  | This will attempt to cleanup old refresh backup files if a backup was taken. If pre backup was skipped, it will not do any cleanup.                                                             |
| **PreBackupForceFull** | optional  | This will force a pre full backup to be done and skip the logic to determine if it should take a diff or full.                                                                                  |
| **SkipRoleUsers**      | optional  | This will skip the exporting roles and users.                                                                                                                                                   |
| **SkipSynonyms**       | optional  | This will skip the exporting synonyms.                                                                                                                                                          |
| **SkipPreProcessing**  | optional  | This will skip preprocessing.                                                                                                                                                                   |
| **SkipRestore**        | optional  | This will skip the restore and only do checking and post-processing. For testing purposes mainly.                                                                                               |
| **SkipPostProcessing** | optional  | This will skip post processing.                                                                                                                                                                 |
| **SkipPostBackup**     | optional  | This will skip the full after restores.                                                                                                                                                         |
| **PostBackupCleanup**  | optional  | This will attempt to cleanup old refresh backup files if a backup was taken. If post backup was skipped, it will not do any cleanup.                                                            |
| **SkipShrinkLog**      | optional  | This will shrink the log as the last step for each database.                                                                                                                                    |
| **Verbose**            | optional  | This is a standard PS parameter, but it will also show some extra output for debugging purposes.                                                                                                |
| **CallingScript**      | internal  | This is used for determining if we should start a new run using updated dates on the Runner script. Not a user option that needs to be concern.                                                 |

### DBConfig/Reference File

This file is the definition of every database, where and how to refresh it and what options to use. See below for a sample and explanation of the fields.

![data list](.//media/image5.png)

#### Listener

The AG listener or SQL Instance for standalone, works in conjunction with AG field, read its description for better understanding of listener vs standalone.

#### SourceDB

The name of the source database backup file.

#### TargetDB

The name of the target database.

#### AG

The AG name. If this field is filled, the refresh process will try to put the database into the AG, even if it is not currently in one. Conversely, if this field is blank, all AG processing is skipped even if it currently is in one.

#### DataPath

Data file path on target instance.

#### LogPath

Log file path on target instance.

#### BakPath

Location of the backup files to use for the restores. The path is mapped within SQL Server unless LocalFile is passed, then this is skipped and path used as-is from the config file.

#### FileMapping

Special handling for secondary data files. By default, everything goes to the data and log paths above. If this is filled, it will override those paths and put each file where specified. Comma delimited list, it gets converted to a hashtable during refresh process for correct functionality. Currently needed for MVMultiIndex and WW.

#### DacPacPath

Location of the Dacpacs for post restore. Not currently used in SIT environment.

#### ReplaceSp, ReplaceVw, ReplaceFn, ReplaceSyn

This is used for reference replacement for stored procs, functions, views, synonyms\--if not using a DACPAC. This needs to be requested per database in request file. The format of this field is like: *'old1\|new1;old2\|new2'*...etc. Doubly delimited list, ';' then '\|'.

#### PersistTable

What if any tables to export and import after the restore process. This is currently used for a couple tables in 5 main Assist database. Contraint/FK support work in progress.

#### PreProcess

Any scripts to be run before restores. This is still work in progress, nothing currently using.

#### PostProcess

Any scripts to be run after the restores. The are a few databases currently using this process.

#### Refresh Steps Numbers

There are steps A, B, C, D and 0(zero). These are not official tracked steps in the refresh process and are initialization and setup steps for the script itself. Step 0(zero) is the verify/confirmation step before any work begins. Step 1 is where actual work starts and where the tracking in the refresh data file starts. Upon the complete of each step, the refresh data last completion step is updated, upon complete of step 13, the overall status is set as complete for that refresh request.

##### Steps

1. Disable Log Backup
1. Pre Backup
1. Export Roles and Users to Persist
1. Export Synonyms
1. Export Data to Persist
1. Pre-Process data, this is not currently implemented
1. Remove from AG, Restore Database, and Add to AG
1. Set logical names, set owner, rename filestream and set read-only.
1. Persist Roles and Users
1. Add Synonyms
1. Transformations
1. Persist Data
1. Post-process.
1. Post Backup
1. Shrink log file(s)

## Advanced

### Restart

Restarting and skipping a step can be accomplished by editing the data .xml file. The default behavior is to restart and re-try from the failed step.

#### Background

In the same network path where the **logs** exists, there is also a **data** folder, this has 1 subfolder called **archive**. **Data** is for current executing or in-progress refreshes and archive is for completed refreshes. In **data** folder, there maybe a data file, it will be named similarly to the request file you are running plus a timestamp added to the name, e.g. **WW\_UATCR\_20211027.xml**. This is a PowerShell XML export of the PowerShell objects used during the refresh process, this makes the data portable and useable for restarts. In the XML file, you will find all the details (gathered/processed so far) for each database that was requested in the refresh. I say so far, because more details do get added as each refresh happens; completed refreshes will have more details, not started will have less. It can be viewed/edited with notepad(++).

#### Details

The fields we are interested in the file are Status and LastCompleted, there will be a set for each database requested. Status is the overall status of a database refresh and LastCompleted is the last completed step. See steps in previous section.

For example, if LastCompleted is 5, that means that the database had all it's prerestore details extracted and the refresh process failed somewhere in step 6. Step 6 has a couple different pieces, it removes the DB from the AG, does the restore, and adds the DB back to the AG. To determine where it failed, you will need to look at the log. The most common error is failing to add the DB back to the AG, usually on the secondary. In this case, rather than completely running the whole restore process, as it would start from the beginning of step 6, we can finish step 6 manually. In this scenario, complete adding the DB to the AG, this can be done in SSMS. Once that is complete, step 6 is considered complete, the DB is healthy and in the AG. So now we only need to reflect that status in the data .xml file.

#### XML Steps

Open the data .xml file, it should be in the aforementioned data folder. Make sure you open the correct one if there are multiple refreshes currently running. Find the database in question and look for LastCompleted, check the step it did last complete, and change the 5 to a 6. This will then cause the refresh script, when restarted to assume step 6 is completed and start at step 7.

![data file](.//media/image6.png)

The refresh script should then continue with the rest of the requested databases after that one is completed.

### Special Requests

Special request are generally to restore an older backup. In this case the best method is to use the filter field on the request file.

If you were requested to restore an older full and diff backup, that still exists on the backup share. You could set the filter like below.
  
  > \*FULL_20210618\*,\*DIFF_20210619\*

There are 2 things to be aware of here.

1. You need to make sure you know the correct file names and set the filter correctly for the files you want. You can use wildcard anywhere in the filter field, i.e. **\*FULL\*2021\*.bak**
1. If the request is for a FULL and DIFF, you need to make sure you also set the **UseDiff** switch on the **Run-\*.ps1** script or else it will still only grab the full.
