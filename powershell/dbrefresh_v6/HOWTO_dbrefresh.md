# DBRefresh

## Current Installs

dbrefresh is current installed at the below locations.

| Environment   | Zone  | Server                      | Path                               |
| :------------ | :---- | :-------------------------- | ---------------------------------- |
| TEST (ASSIST) | EL2   | hostnameclsn1 (xx.xx.xx.xx) | M:\\Management\\dbrefresh          |
| TEST (DECSS)  | IDMZ3 | hostname8n1 (xx.xx.xx.xx)   | M:\\Management\\Scripts\\dbrefresh |
| DEV           | DEV   | host04 (xx.xx.xx.xx)        | M:\\Management\\dbrefresh          |

## Logs

dbrefresh logs to the network by default, the locations for each environment are below, copy and paste them into Windows Explorer. Sub-folders are date stamped. There is one log file per run in the `log` sub-folder, written by Refresh-Database.ps1 itself (PowerShell transcript), so the Run-\*.ps1 scripts no longer need `Tee-Object`.

| Environment | Zone  | Path                                |
| :---------- | :---- | :---------------------------------- |
| TEST        | EL2   | \\\\xx.xx.xx.xx\\dbbackup\\refresh  |
| TEST        | IDMZ3 | \\\\xx.xx.xx.xx\\tsdeptc2\\refresh  |
| DEV         | IDEV  | \\\\xx.xx.xx.xx\\backup\\refresh    |

## Folder Layout

| Path                                | Purpose                                                                 |
| :---------------------------------- | :---------------------------------------------------------------------- |
| Refresh-Database.ps1                | Main script, orchestration only.                                        |
| Run-Refresh\*.ps1                   | Thin runners, one per environment/workload.                             |
| config\\DbConfig\*.csv              | Database reference files (unchanged format).                            |
| config\\Settings.psd1               | Email, share account, secrets path, log job names, default owners, etc. |
| config\\DacOptions.psd1             | Default dacpac DeployOptions.                                           |
| request\\\*.txt                     | Request files (unchanged format).                                       |
| function\\Common.ps1                | Logging, display, credential, email helpers.                            |
| function\\Refresh-Steps.ps1         | Plan builder, step engine and every refresh step.                       |
| function\\Refresh-Functions.ps1     | Pre/post process functions (unchanged).                                 |

Removed in version 6: `include\Init.ps1`, `include\HtmlHeader.ps1`, `include\DacOptions.ps1`, `function\Functions.ps1`, `function\Sql-Functions.ps1` (was unused) and `Set-SimpleMode.ps1` (now the `-SetSimpleRecovery` switch).

## Requirements

1. **dbrefresh script package**: This is in the DBA-TFS git repo. It can be gotten via VSCODE or via the TFS web interface. Download the whole folder and copy it to the server you will be running this process from. The location does not matter.

1. **PowerShell 5.1**: This is the default version on Windows 10/11 and Server 2016/2019. If you are trying to execute this on Server 2012, you will need to install WMF5.1 to run these scripts. On Server 2012, the modules path does not support version number in the path, so you would need to move all the files\\folders in that versioned folder up 1 folder level, you should then be able to delete the empty version number folder.

1. **dbatools module**: This PowerShell module is needed on the server running the scripts. It is not needed on any of the target SQL Instances. Dbatools can be downloaded on a local desktop and then copied to the server.
    1. Look at method 1 at this link: <https://dbatools.io/offline/>

    1. The downloaded module will need to be copied to the server. The easiest way is to copy it to the global module folder, 'C:\\Program Files\\WindowsPowerShell\\Modules'.

    1. You should end up with a folder like, 'C:\\Program Files\\WindowsPowerShell\\Modules\\dbatools\\2.x.x' and then files and folders under that path for the module.

    1. You can then test this by opening a PowerShell prompt and running Import-Module dbatools. This will either work and not display any error or give an error. You can also test via Get-Module dbatools -ListAvailable

1. The **sqlserver** module is no longer needed (it was only used by Set-SimpleMode.ps1).

1. **Permissions on target server**: You will need SA permissions to do any of these restores. `xp_cmdshell` must be enabled on the target instances unless `-LocalFile` is used.

## Credential

The share account (`ShareAccount` in config\\Settings.psd1) is used by SQL Server, through `xp_cmdshell net use`, to reach the Prod backup share in the other domain.

- The password is stored in `<SecretsPath>\<account>_<COMPUTER>_<USER>.cred.xml`, encrypted with Windows DPAPI. Only the same Windows user on the same server can read it.
- First run as a new user prompts for the password.
- If the old `<account>.key` / `<account>.pw` files exist, they are converted automatically on first run, so scheduled (SQL Agent) runs keep working. Once every account that runs the refresh has converted, delete the old .key/.pw files; a key stored next to the password it protects is effectively plain text.
- A non-interactive run with no credential file and no old files fails with a message telling you which account needs to run it once interactively.
- The share is only mapped when SQL Server cannot already reach it, so the password is not sent on every run.

## Word Document

You can turn this .md file into a word docx file buy running this command. You need pandoc installed and is easiest via WSL.

    pandoc -s -o HOWTO_dbrefresh.docx HOWTO_dbrefresh.md

## Getting Started

### Special Notes

#### Assist DEV and SIT

DEV and SIT refreshes require use of the 'Copy Drive'. Firewall/network rules prevent getting backup files via this script as it does with TEST. Using the LocalFile switch allows use of files from the 'Copy Drive', see parameters section for more info on it. Please coordinate with Telecomm and get prod backup files copied to the 'Copy Drive' and then attached to **xx.xx.xx.xx**.

#### DECSS TEST

DECSS TEST requires some special attention because replication is involved. The main refresh process is still the same, but is a script before and a script after that needs to run for dropping and recreating the replication subscriptions respectively. The scripts are numbered in the order they should be performed in. 1-Drop Replication, 2-Run Refresh, 3-Create Replication. Fedcert, Timewarp and Sandbox do not have replication and thus do no need any special handling. Fedcert and Sandbox are scheduled in SSA--Sandbox every morning at 5am and Fedcert first Friday of the month at 8am. On-request refreshes are likely only for Timewarp and Test (aka Static/Online).

### Steps

1. Get the refresh request. The refresh request should have a list of the requested databases to refresh, to what server(s), and possibly if to apply any dacpac (Assist/WW) or to make any environmental reference changes in stored procedures, views, functions, or synonyms (i.e. Change \_PROD to \_TEST). Sometimes it is requested to use diffs as well as fulls to do the restore, this is controlled by the `UseDiff` switch.

1. Once we have the request for what to refresh, we need to tell the script what to refresh. This is accomplished by updating a text file with the requested DBs.

   1. Browse to the dbrefresh folder (noted above for each environment) and go into the 'request' folder and find the file corresponding to the environment you were asked to refresh. Note: TEST and UATCR are broken into 2 'workload' files, driven by DataServicesHub and WorkerWeb and then other databases, to split the work evenly so the groups can run in parallel. Most if not all of the DBs should already be in the file and can be (un)commented as needed.

   ![folder](.//media/image1.png)
   ![requests](.//media/image2.png)

1. The request files are delimited by ';'. Each line is a request for 1 database to be refreshed. They are refreshed in the order listed, so if there is a dependency on any, do them in the proper order. The only current dependency is for MCI and MVMultiIndex. MVMultiIndex needs to happen before MCI because MCI has a post-process script to update the MCI sequence number and it uses data from MVMultiIndex for that. This dependency order is already defined in the MCI request file. The file format is like such:

   ![requests](.//media/image3.png)

    1. **Header**: The top line is a header and must be left as is. The 'columns' are Database, Transform, and Filter.

    1. **Database** is the **target** database to be restored. This may or may not be the name that will be supplied in the request as sometimes they request the PROD DB name. A couple of databases have naming differences other than just \_TEST/\_PROD, e.g. DSS\_DataServiceHub\_TEST vs D**H**SS\_DataServiceHub\_PROD. This is handled in the request and reference file. The name in the request file should be what it's named on the target server.

    1. **Transform** is what type of transformation to perform after the restore: **DAC** (apply a **DACPAC**), **REP** (replace references, i.e. \_PROD to \_TEST) or **\<blank\>** (neither, the usual config for MCI databases). What to replace is defined in the reference file.

    1. **Filter** is a comma separated list of wildcards matched against the .bak file path. Add the wildcard **(\*)** yourself, it is used as-is.

    **NOTE**: For SIT/DEV this is **mandatory** because all of the .bak files are in the same folder; in SIT the filter is the DB name minus the environment suffix. The request file is already pre-populated with this data.

    1. Choosing **what** to refresh is as simple as (un)commenting a line with a '\#' in column one. Blank lines are ignored. Never comment line 1, the header is always needed.

1. There are numerous Run-Refresh\*.ps1 files in the dbrefresh folder. These are the 'runner' scripts. Each one is a splat of parameters for that environment and a call to Refresh-Database.ps1. Commented out means off, un-commented means on:

    ```powershell
    $Splat = @{
        RequestFile    = '.\request\SBX.txt'
        DbConfigFile   = '.\config\DbConfigSbx.csv'
        WorkingPath    = '\\xx.xx.xx.xx\dbbackup'
        DbOwner        = 'irmsa'
        SkipPostBackup = $true
        # Verify         = $true
        # Notify         = '{0}@delaware.gov' -f $env:USERNAME
        CallingScript  = $PSCommandPath
    }

    & .\Refresh-Database.ps1 @Splat
    ```

1. **RequestFile** and **WorkingPath** are mandatory. **DbConfigFile** defaults to config\\DbConfig.csv, **SettingsFile** defaults to config\\Settings.psd1.

1. **Notify** is a list of emails to notify on a database failure and with the final report, e.g. `'email1@company.com', 'email2@company.com'`.

1. **Updating other runners**: older Run-\*.ps1 scripts that dot-source `include\Init.ps1` and pipe to `Tee-Object $LogFile` must be changed to the format above (copy Run-RefreshSBX.ps1 and change the splat). `-Verbose = $true` still works and is the same as `-Detailed`.

## Executing the Refresh

1. After the request file is set and dacpacs copied (if needed), right-click the Run-\*.ps1 for the environment -\> Run with PowerShell. You do **NOT** need to run this as admin. PowerShell uses the credentials of the user executing for instance permissions.

1. With **Verify** on, it asks before doing any work: first that the scheduled Full/Diff backups are done, then whether the listed request is correct, then before each database with (y)es/(n)o/(a)ll. 'a' stops asking for the rest of the run.

1. A failure in one database is logged, emailed (if Notify is set), and that database is skipped; **the remaining databases still run**. At the end there is a summary of every database (Completed/Failed and at which step), any errors, and the restore history. Re-run the same runner to resume the failed databases from the step that failed.

1. Exit codes (useful for SQL Agent): 0 = everything completed, 1 = completed with errors, 2 = initialization failed. The runner passes this on, and only waits for ENTER when run by hand.

## Refresh Process

1. Initialize, create working folders, start the log, load request/config/settings, load dbatools.
1. Load the share credential (skipped with -LocalFile).
1. Gather data on each requested database, or resume today's data file. A database missing from the config or the instance is logged as an error and skipped, the rest continue.
1. For each database, run the steps below in order. Each completed step is saved to the data file.
1. Cleanup, always run even after an error or Ctrl+C: re-enable the log backup jobs this run disabled (and any matching job disabled with a run in the last 3 days, in case a parallel refresh disabled it) on every instance where no database is still restoring. Archive the data file when everything completed.
1. Summary, error and restore report, displayed and emailed if Notify is set.

### Steps

The data file records completed steps **by name** (CompletedSteps), not by number.

| Name             | What it does                                                                                                                       | Skip switch       |
| :--------------- | :--------------------------------------------------------------------------------------------------------------------------------- | :---------------- |
| PreBackup        | Diff backup to the folder of the last diff, else full to the folder of the last full. `-PreBackupForceFull`, `-BackupPath`, `-PreBackupCleanup`. | SkipPreBackup     |
| ExportPrincipals | Script roles and users with permissions and memberships.                                                                           | SkipRolesUsers    |
| ExportSynonyms   | Script synonyms.                                                                                                                   | SkipSynonyms      |
| ExportData       | Copy PersistTable tables to the staging database.                                                                                  |                   |
| PreProcess       | Run the PreProcess functions from the config file.                                                                                 | SkipPreProcess    |
| Restore          | See below.                                                                                                                         | SkipRestore       |
| DatabaseSettings | Filestream directory name + read-only, logical names (\_PROD to \_TEST), owner.                                                   | SkipRestore       |
| ImportPrincipals | Drop 'DOMAIN\\user' views and schemas, user-owned schemas to dbo, replace roles and users with the exported ones.                 |                   |
| ImportSynonyms   | Replace synonyms with the exported ones.                                                                                           |                   |
| ImportData       | Copy persisted tables back (identity values and nulls kept).                                                                       |                   |
| Transform        | DAC = publish dacpac, REP = replace references in procs/functions/views.                                                           | SkipTransform     |
| PostProcess      | Run the PostProcess functions from the config file.                                                                                | SkipPostProcess   |
| PostBackup       | Full backup. `-BackupPath`, `-PostBackupCleanup`.                                                                                  | SkipPostBackup    |
| ShrinkLog        | Shrink the log file.                                                                                                               | SkipShrinkLog     |
| RecoveryModel    | Set SIMPLE recovery, non-AG only. Only runs with `-SetSimpleRecovery`.                                                             |                   |

**Restore** checks everything before it changes anything:

1. On every replica: map the backup share (unless already reachable or -LocalFile) and find the backup files. If any replica fails here, nothing has been touched.
1. Disable the log backup jobs on every replica (recorded in the data file) and wait for any running one to finish (`LogJobWaitMinutes`).
1. Remove the database from the AG.
1. Restore: in parallel on every replica for an AG (secondaries WITH NORECOVERY), inline for a standalone.
1. AG only: log backup on the primary, restore it on the secondaries, add the database to the AG.

## Errors and Restarts

Running the same request again on the same day resumes it: completed databases are skipped, failed or not-started databases continue from the first step not yet completed. If the request file was changed after the data file was last saved, it is treated as a new request and starts from the beginning. Data files from version 5 cannot be resumed by version 6; finish any in-flight refresh with the old version.

To start one database from the beginning, edit the request file (comment out the others), which makes it a new request.

Warnings should be checked. They include requested skips, a missing role/user/synonym export (the restored ones are then kept, not dropped), and log backup jobs left disabled because a database is still restoring.

## Reference

### Working folders

All logs, exports, trn files and data files go under `<WorkingPath>\refresh\<yyyyMMdd>\`: `log`, `export`, `trn`, `data`, `data\archive`.

| Network        | WorkingPath                      |
| :------------- | :------------------------------- |
| TEST-EL2       | \\\\xx.xx.xx.xx\\dbbackup        |
| TEST-EL1-IDMZ3 | \\\\xx.xx.xx.xx\\tsdcssc2        |
| DEV\\SIT       | \\\\xx.xx.xx.xx\\backup          |

### Script Parameters

| Parameter              | type      | comment                                                                                                                    |
| :--------------------- | :-------- | :------------------------------------------------------------------------------------------------------------------------- |
| **RequestFile**        | mandatory | List of the target dbs to refresh.                                                                                         |
| **WorkingPath**        | mandatory | Root folder for all refresh output.                                                                                        |
| **DbConfigFile**       | optional  | Defaults to config\\DbConfig.csv.                                                                                          |
| **SettingsFile**       | optional  | Defaults to config\\Settings.psd1.                                                                                         |
| **BackupPath**         | optional  | Folder for pre and post backups, overrides the 'folder of the last backup' logic.                                          |
| **Notify**             | optional  | Emails for failures and the final report.                                                                                  |
| **Verify**             | optional  | Confirmation prompts. 'a' skips the remaining prompts.                                                                     |
| **LocalFile**          | optional  | Use backup paths as-is, no share mapping or credential. Used for DEV/SIT.                                                  |
| **UseDiff**            | optional  | Restore full + diff, else full only.                                                                                       |
| **SkipPreBackup**      | optional  | Skip the backup before the restore.                                                                                        |
| **PreBackupCleanup**   | optional  | Hours. Remove older PRE refresh backups after taking a new one.                                                            |
| **PreBackupForceFull** | optional  | Always take a full for the pre backup.                                                                                     |
| **SkipRolesUsers**     | optional  | Skip exporting roles and users.                                                                                            |
| **SkipSynonyms**       | optional  | Skip exporting synonyms.                                                                                                   |
| **SkipPreProcess**     | optional  | Skip preprocessing.                                                                                                        |
| **SkipRestore**        | optional  | Skip the restore and database settings. For testing.                                                                       |
| **SkipTransform**      | optional  | Skip dacpac / reference replacement.                                                                                       |
| **SkipPostProcess**    | optional  | Skip postprocessing.                                                                                                       |
| **SkipPostBackup**     | optional  | Skip the full after the refresh.                                                                                           |
| **PostBackupCleanup**  | optional  | Hours. Remove older POST refresh backups after taking a new one.                                                           |
| **SkipShrinkLog**      | optional  | Skip the log shrink.                                                                                                       |
| **SkipFileRename**     | optional  | Skip renaming logical files.                                                                                               |
| **SkipDbOwner**        | optional  | Skip setting the database owner.                                                                                           |
| **DbOwner**            | optional  | Database owner, overrides DbOwnerByDomain in Settings.psd1.                                                                |
| **SetSimpleRecovery**  | optional  | Set SIMPLE recovery as the last step, non-AG only. Replaces Set-SimpleMode.ps1.                                            |
| **Detailed**           | optional  | Extra tables for troubleshooting. -Verbose does the same.                                                                  |
| **CallingScript**      | optional  | Informational, shown in the run header.                                                                                    |

### Settings File (config\\Settings.psd1)

| Setting                | Purpose                                                                       |
| :--------------------- | :---------------------------------------------------------------------------- |
| Email                  | From address and SMTP server.                                                 |
| ShareAccount           | Account used to map the cross-domain backup share.                            |
| SecretsPath            | Folder for the encrypted credential file.                                     |
| StagingDb              | Staging database for persisted tables.                                        |
| LogJobInclude/Exclude  | Log backup job names or wildcards disabled during restores.                   |
| LogJobWaitMinutes      | How long to wait for a running log backup before failing the database.        |
| DbOwnerByDomain        | Default owner per domain, falls back to the running user.                     |
| FullBackupFileCount    | Stripes for full backups.                                                     |
| BackupHistoryDays      | Days of history searched for the existing backup folder.                      |
| RestoreProgressSeconds | How often restore progress is shown during parallel restores.                 |
| HtmlHead               | CSS for the email report.                                                     |

### DBConfig/Reference File

This file is the definition of every database, where and how to refresh it and what options to use. The format is unchanged. See below for a sample and explanation of the fields.

![data list](.//media/image5.png)

#### Listener

The AG listener or SQL Instance for standalone, works in conjunction with AG field.

#### SourceDB

The name of the source database backup file.

#### TargetDB

The name of the target database. Should be listed once; if it is listed twice the first entry is used and a warning logged.

#### AG

The AG name. If this field is filled, the refresh process will put the database into the AG, even if it is not currently in one. If this field is blank, all AG processing is skipped even if it currently is in one.

#### DataPath

Data file path on target instance.

#### LogPath

Log file path on target instance.

#### BakPath

Location of the backup files. Multiple paths are separated with '|'. The path is mapped within SQL Server unless LocalFile is passed.

#### FileMapping

Special handling for secondary data files, `logicalname=path,logicalname2=path2`. Overrides DataPath/LogPath. Currently needed for MVMultiIndex and WW.

#### DacPacPath

Location of the dacpacs and their .config files. The newest copy of the configured dacpac file is used. 'true'/'false' option values in the .config files are applied as booleans.

#### ReplaceSp, ReplaceVw, ReplaceFn

Reference replacement for stored procs, views and functions when Transform is REP. Format *'old1\|new1;old2\|new2'*. Every pair is applied to the same script.

#### PersistTable

Comma separated tables to keep through the restore. Constraint/FK support work in progress.

#### PreProcess

Comma separated function names (function\\Refresh-Functions.ps1) run before the restore. A misspelled name fails the step before any function runs.

#### PostProcess

Comma separated function names run after the restore.

## Advanced

### Restart

#### Background

In the **data** folder there is a data file per run, named for the request file plus a timestamp, e.g. **SBX\_20261007\_050000.xml**. Completed runs are moved to **data\\archive**. It is a PowerShell XML export of the refresh state and can be viewed/edited with notepad(++).

It holds the list of log backup jobs that were disabled (**DisabledJobs**) and one entry per database (**Refreshes**). The fields of interest per database are:

| Field          | Meaning                                                    |
| :------------- | :--------------------------------------------------------- |
| Status         | Pending, Running, Completed or Failed.                     |
| CompletedSteps | Names of the steps already done, in order.                 |
| FailedStep     | Step that failed on the last run.                          |
| Error          | Error message from the last failure.                       |

#### Skipping a step by hand

The most common case: the restore worked but joining the AG failed. Rather than redo the whole restore, finish it manually (add the DB to the AG in SSMS), then mark Restore as done:

1. Open the data .xml file in the data folder (make sure it is the right one if several refreshes are running).
1. Find the database's `<Obj N="CompletedSteps">` and add the step after the last `<S>` inside its `<LST>`:

    ```xml
    <Obj N="CompletedSteps" RefId="6">
      <TNRef RefId="2" />
      <LST>
        <S>PreBackup</S>
        <S>ExportPrincipals</S>
        <S>ExportSynonyms</S>
        <S>ExportData</S>
        <S>PreProcess</S>
        <S>Restore</S>
      </LST>
    </Obj>
    ```

1. Re-run the runner. It skips everything listed and continues at DatabaseSettings.

### Special Requests

Special requests are generally to restore an older backup. In this case the best method is to use the filter field on the request file.

If you were requested to restore an older full and diff backup that still exists on the backup share, you could set the filter like below.

  > \*FULL_20210618\*,\*DIFF_20210619\*

There are 2 things to be aware of here.

1. Make sure you know the correct file names and set the filter correctly for the files you want. You can use wildcards anywhere in the filter field, i.e. **\*FULL\*2021\*.bak**
1. If the request is for a FULL and DIFF, set the **UseDiff** switch on the **Run-\*.ps1** script or else it will still only grab the full.
