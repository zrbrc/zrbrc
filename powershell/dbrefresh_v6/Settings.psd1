<#
    Environment settings for Refresh-Database.ps1.
    Everything that used to be hardcoded in the main script lives here.
#>
@{
    # notification email
    Email                  = @{
        From       = 'dept05sg_SQLAlerts@delaware.gov'
        SmtpServer = 'smtp.state.de.us'
    }

    # account SQL Server uses (via xp_cmdshell net use) to reach the cross-domain backup share
    ShareAccount           = 'domain\user.refresh'

    # where the encrypted credential file is kept
    SecretsPath            = 'C:\Secrets'

    # staging database used to persist table data across the restore
    StagingDb              = 'Refresh_Staging'

    # log backup jobs disabled during restores, names or wildcards
    LogJobInclude          = @('DatabaseBackup - USER_DATABASES - LOG', 'DatabaseBackup - USER_DATABASES - LOG - NUL')
    LogJobExclude          = @()

    # minutes to wait for a running log backup to finish before failing the database
    LogJobWaitMinutes      = 30

    # default database owner by the domain the script runs in, falls back to the running user
    DbOwnerByDomain        = @{
        domDEV  = 'domain\user'
        domTEST = 'domain\user.test'
    }

    # stripes for full backups
    FullBackupFileCount    = 4

    # days of backup history searched to find the existing backup folder
    BackupHistoryDays      = 14

    # how often restore progress is shown while parallel restores run, seconds
    RestoreProgressSeconds = 300

    # css for the html email report
    HtmlHead               = @'
<title>Refresh Report</title>
<style>
body { background-color:#FFFFFF; font-family:Tahoma; font-size:10pt; }
td, th { border:1px solid black; border-collapse:collapse; }
th { color:white; background-color:black; }
table, tr, td, th { padding-left: 3px; padding-right: 7px; }
</style>
'@
}
