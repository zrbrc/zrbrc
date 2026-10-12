<#
.SYNOPSIS
    This will run the refresh for the environment.
.DESCRIPTION
    This will run the refresh for the environment for this file. The file should be named for the environment 
    or you can look at the RequestFile name down in the splat to tell.
.NOTES
    Comment/uncomment the lines below for the functionality you need.
#>

Set-Location $PSScriptRoot
$splat = @{
    RequestFile    = '.\request\LOCAL.txt'
    DbConfigFile   = '.\config\dbconfiglocal.csv'
    # BackupPath      = 'M:\Management\Backup'
    WorkingPath    = '.\' # local
    # Notify             = "$env:USERNAME" + '@domain.com'
    # UseDiff            = $true
    # SkipRestore        = $true
    # SkipPreProcessing  = $true
    # SkipPostProcessing = $true
    # Verbose            = $true
    LocalFile      = $true
    SkipPreBackup = $true
    SkipFostBackup = $true
    Verify         = $true
    CallingScript  = $PSCommandPath
}
& .\Refresh-Database.ps1 @splat