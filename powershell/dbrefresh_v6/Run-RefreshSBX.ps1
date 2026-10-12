<#
.SYNOPSIS
    Runs the SBX refresh.
.DESCRIPTION
    Thin runner: set the parameters for this environment and call Refresh-Database.ps1.
    Logging (transcript) is handled by Refresh-Database.ps1 under <WorkingPath>\refresh\<date>\log.
.NOTES
    Comment/uncomment the lines below for the functionality you need.
    Exits with Refresh-Database.ps1's exit code: 0 = success, 1 = completed with errors, 2 = initialization failed.
#>
Set-Location -Path $PSScriptRoot

$Splat = @{
    RequestFile        = '.\request\SBX.txt'
    DbConfigFile       = '.\config\DbConfigSbx.csv'
    WorkingPath        = '\\xx.xx.xx.xx\dbbackup'   # domtest EL2
    DbOwner            = 'irmsa'
    SkipPostBackup     = $true
    # SettingsFile       = '.\config\Settings.psd1'
    # Verify             = $true
    # Notify             = '{0}@delaware.gov' -f $env:USERNAME
    # BackupPath         = '\\server\share\folder'
    # LocalFile          = $true
    # UseDiff            = $true
    # SkipPreBackup      = $true
    # PreBackupForceFull = $true
    # PreBackupCleanup   = 48
    # SkipRolesUsers     = $true
    # SkipSynonyms       = $true
    # SkipPreProcess     = $true
    # SkipRestore        = $true
    # SkipTransform      = $true
    # SkipPostProcess    = $true
    # PostBackupCleanup  = 48
    # SkipShrinkLog      = $true
    # SkipFileRename     = $true
    # SkipDbOwner        = $true
    # SetSimpleRecovery  = $true
    # Detailed           = $true
    CallingScript      = $PSCommandPath
}

& .\Refresh-Database.ps1 @Splat
$RefreshExitCode = $LASTEXITCODE

# keep the window open when run by hand, never block a scheduled run
if ([Environment]::UserInteractive) {
    $null = Read-Host -Prompt '::: ENTER ::'
}

exit $RefreshExitCode
