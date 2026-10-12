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

$RequestFile = '.\request\SBX.txt'
$WorkingPath = '\\xx.xx.xx.xx\dbbackup' # domtest EL2

. .\include\Init.ps1

$splat = @{
    DbConfigFile      = '.\config\DbConfigSbx.csv'
    RequestFile       = $RequestFile
    WorkingPath       = $WorkingPath
    # Verify            = $true
    # Notify            = "$env:USERNAME" + '@delaware.gov'
    DbOwner           = 'irmsa'
    # LocalFile       = $true
    # UseDiff         = $true
    # SkipPreBackup   = $true
    # SkipRolesUsers  = $true
    # SkipSynonyms    = $true
    # SkipPreProcess  = $true
    # SkipRestore     = $true
    # SkipTransform   = $true
    # SkipPostProcess = $true
    SkipPostBackup  = $true
    # SkipShrinkLog   = $true
    # Verbose        = $true
    CallingScript     = $PSCommandPath
}
& .\Refresh-Database.ps1 @splat | Tee-Object $LogFile

Read-Host "::: ENTER ::"