<#
.SYNOPSIS
    Refreshes a group of databases from Prod backups to TEST, PT, SIT, DEV or SBX.
.DESCRIPTION
    For each database in the request file:
    pre backup, export roles/users/synonyms/tables, restore to every replica (parallel for AGs), re-join the AG,
    fix logical names/owner/filestream, put roles/users/synonyms/tables back, transform (dacpac or reference
    replace), post process, post backup, shrink log.

    Progress is saved after every step to <WorkingPath>\refresh\<date>\data\<request>_<time>.xml.
    Running the same request again the same day resumes where it stopped, unless the request file was changed.
    A failure stops only that database; the rest of the request keeps going.
.PARAMETER RequestFile
    Mandatory. List of target databases to refresh (Database;Transform;Filter).
.PARAMETER WorkingPath
    Mandatory. Root for logs, exports, trn and data files. A dated 'refresh' folder is created under it.
.PARAMETER DbConfigFile
    Database reference file. Defaults to .\config\DbConfig.csv.
.PARAMETER SettingsFile
    Environment settings (email, share account, job names, owners). Defaults to .\config\Settings.psd1.
.PARAMETER BackupPath
    Folder for the pre and post backups, overrides the 'folder of the last backup' logic.
.PARAMETER Notify
    Email addresses for failures and the final report.
.PARAMETER Verify
    Prompts before starting and before each database. Answer 'a' to stop prompting.
.PARAMETER LocalFile
    Use BakPath from the config as-is, no share mapping or credential. For same-domain files (DEV/SIT).
.PARAMETER UseDiff
    Restore full + diff instead of full only.
.PARAMETER SkipPreBackup
    Skip the diff/full backup before the restore.
.PARAMETER PreBackupCleanup
    Hours. Remove PRE refresh backups older than this after taking a new one.
.PARAMETER PreBackupForceFull
    Always take a full for the pre backup.
.PARAMETER SkipRolesUsers
    Skip exporting roles and users (restored ones are kept).
.PARAMETER SkipSynonyms
    Skip exporting synonyms (restored ones are kept).
.PARAMETER SkipPreProcess
    Skip preprocessing.
.PARAMETER SkipRestore
    Skip the restore and database settings. For testing.
.PARAMETER SkipTransform
    Skip dacpac / reference replacement.
.PARAMETER SkipPostProcess
    Skip postprocessing.
.PARAMETER SkipPostBackup
    Skip the full backup after the refresh.
.PARAMETER PostBackupCleanup
    Hours. Remove POST refresh backups older than this after taking a new one.
.PARAMETER SkipShrinkLog
    Skip the log shrink.
.PARAMETER SkipFileRename
    Skip renaming logical files.
.PARAMETER SkipDbOwner
    Skip setting the database owner.
.PARAMETER DbOwner
    Database owner, overrides DbOwnerByDomain in the settings file.
.PARAMETER SetSimpleRecovery
    Set SIMPLE recovery as the last step (non-AG only). Replaces Set-SimpleMode.ps1.
.PARAMETER Detailed
    Extra tables for troubleshooting (backup files, restore params, dacpac config). -Verbose does the same.
.PARAMETER CallingScript
    Informational only, shown in the run header. Kept so existing Run-*.ps1 callers keep working.
.OUTPUTS
    <WorkingPath>\refresh\<yyyyMMdd>\ log, export, trn, data, data\archive
.NOTES
    Version:        6.0
    Author:         Ryan Zerbe
    Creation Date:  2020-02
    Purpose/Change: Step engine, per-database failure isolation, validate-before-restore, tracked log job re-enable.
.EXAMPLE
    .\Refresh-Database.ps1 -RequestFile .\request\SBX.txt -WorkingPath \\server\dbbackup -DbConfigFile .\config\DbConfigSbx.csv -SkipPostBackup
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path -Path $_ } )]
    [string]$RequestFile,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path -Path $_ } )]
    [string]$WorkingPath,

    [ValidateScript( { Test-Path -Path $_ } )]
    [string]$DbConfigFile = '.\config\DbConfig.csv',

    [ValidateScript( { Test-Path -Path $_ } )]
    [string]$SettingsFile = '.\config\Settings.psd1',

    # not validated, it may only be reachable from the SQL instance doing the backup
    [string]$BackupPath,

    [string[]]$Notify,
    [switch]$Verify,
    [switch]$LocalFile,
    [switch]$UseDiff,
    [switch]$SkipPreBackup,
    [int]$PreBackupCleanup,
    [switch]$PreBackupForceFull,
    [switch]$SkipRolesUsers,
    [switch]$SkipSynonyms,
    [switch]$SkipPreProcess,
    [switch]$SkipRestore,
    [switch]$SkipTransform,
    [switch]$SkipPostProcess,
    [switch]$SkipPostBackup,
    [int]$PostBackupCleanup,
    [switch]$SkipShrinkLog,
    [switch]$SkipFileRename,
    [switch]$SkipDbOwner,
    [string]$DbOwner,
    [switch]$SetSimpleRecovery,
    [switch]$Detailed,
    [string]$CallingScript
)

Set-Location -Path $PSScriptRoot
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'

# script scope state used by the helper functions
$MessageLog = New-Object -TypeName 'System.Collections.Generic.List[object]'
$ShowDetail = $Detailed.IsPresent -or $PSBoundParameters.ContainsKey('Verbose')
$ExitCode = 0

# helpers, steps and the pre/post process functions (Refresh-Functions.ps1 reads $script:Refresh and $script:StagingDB)
foreach ($FunctionFile in Get-ChildItem -Path '.\function' -Filter '*.ps1' -File) {
    . $FunctionFile.FullName
}

$Banner = @'
   _ _           ___             _
 _| | |_ ___ ___|  _|___ ___ ___| |_
| . | . |  _| -_|  _|  _| -_|_ -|   |
|___|___|_| |___|_| |_| |___|___|_|_|

'@
Write-Host -Object $Banner


####################################################################################################
# Initialization
####################################################################################################
$Source = 'Init'
try {
    $DateStamp = Get-Date -Format 'yyyyMMdd'
    $TimeStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $ReqName = (Get-Item -Path $RequestFile).BaseName

    # settings, StagingDB stays script scope for Refresh-Functions.ps1
    $Settings = Import-PowerShellDataFile -Path $SettingsFile
    $DacOptions = Import-PowerShellDataFile -Path '.\config\DacOptions.psd1'
    $StagingDB = $Settings.StagingDb

    # working folders
    $RefreshRoot = Join-Path -Path $WorkingPath -ChildPath ('refresh\{0}' -f $DateStamp)
    $Paths = @{
        Export  = Join-Path -Path $RefreshRoot -ChildPath 'export'
        Trn     = Join-Path -Path $RefreshRoot -ChildPath 'trn'
        Log     = Join-Path -Path $RefreshRoot -ChildPath 'log'
        Data    = Join-Path -Path $RefreshRoot -ChildPath 'data'
        Archive = Join-Path -Path $RefreshRoot -ChildPath 'data\archive'
    }
    foreach ($Folder in $Paths.Values) {
        if (-not (Test-Path -Path $Folder -PathType Container)) {
            $null = New-Item -Path $Folder -ItemType Directory
        }
    }

    # everything written to the host from here on goes to the log file
    $LogFile = Join-Path -Path $Paths.Log -ChildPath ('{0}_{1}.txt' -f $ReqName, $TimeStamp)
    $null = Start-Transcript -Path $LogFile
    Write-Log -Source $Source -Message ('Logging to {0}' -f $LogFile)

    # input files
    $Requests = @(Import-RefreshFile -Path $RequestFile -Delimiter ';')
    Write-Log -Source $Source -Message ('Loaded request file {0}, {1} database(s).' -f $RequestFile, $Requests.Count)

    $DbConfig = @(Import-RefreshFile -Path $DbConfigFile)
    Write-Log -Source $Source -Message ('Loaded db config file {0}.' -f $DbConfigFile)

    if ($Host.Name -eq 'ConsoleHost' -and [Environment]::UserInteractive) {
        Write-Log -Source $Source -Message (Disable-QuickEditMode)
    }

    # modules
    Write-Log -Source $Source -Message 'Loading modules, may take a minute.'
    Import-Module -Name dbatools.library
    Import-Module -Name dbatools
    foreach ($ConfigName in 'logging.errorlogenabled', 'logging.errorlogfileenabled', 'logging.messagelogenabled', 'logging.messagelogfileenabled') {
        Set-DbatoolsConfig -FullName $ConfigName -Value $false
    }

    # newer SQL clients encrypt by default, our environment is not set up for it
    if ((Get-DbatoolsConfigValue -FullName 'sql.connection.encrypt') -eq $true) {
        $null = Set-DbatoolsInsecureConnection
    }
    Write-Log -Source $Source -Message 'dbatools loaded and options set.'

    # share credential, not needed for same-domain files
    $Credential = $null
    if ($LocalFile) {
        Write-Log -Source $Source -Message 'LocalFile set, skipping share credential.'
    }
    else {
        $Credential = Get-RefreshCredential -Login $Settings.ShareAccount -SecretsPath $Settings.SecretsPath
        Write-Log -Source $Source -Message ('Share credential loaded for {0}.' -f $Credential.UserName)
    }

    # owner applied after restore
    if ($PSBoundParameters.ContainsKey('DbOwner')) {
        $Owner = $DbOwner
    }
    elseif ($Settings.DbOwnerByDomain.ContainsKey($env:USERDOMAIN)) {
        $Owner = $Settings.DbOwnerByDomain[$env:USERDOMAIN]
    }
    else {
        $Owner = '{0}\{1}' -f $env:USERDOMAIN, $env:USERNAME
    }

    # backup types to restore, values used by Get-DbaBackupInformation
    if ($UseDiff) {
        $BackupType = @('Full', 'Differential')
    }
    else {
        $BackupType = @('Full')
    }
}
catch {
    Write-Log -Source $Source -Message $_.Exception.Message -Level Crit
    Write-Log -Source $Source -Message 'Initialization failed.' -Level Crit
    if ([Environment]::UserInteractive) {
        $null = Read-Host -Prompt '::: Initialization failed. Press ENTER to exit. ::'
    }
    try { $null = Stop-Transcript } catch { }
    exit 2
}


####################################################################################################
# Sanity check
####################################################################################################
if ($Verify) {
    $Answer = Read-Choice -Prompt ('{0}[?] Did you verify the regularly scheduled Full/Diff backups are completed on the instance(s)? (y)es/(n)o ' -f [Environment]::NewLine) -Choice 'Y', 'N'
    if ($Answer -ne 'Y') {
        $null = Stop-Transcript
        exit 0
    }
}

Write-Table -InputObject $PSBoundParameters -Title 'P A S S E D  P A R A M E T E R S'


####################################################################################################
# Plan: resume today's run of this request, or gather fresh
####################################################################################################
$Source = 'Gather'
Write-Log -Source $Source -Message ('# START: {0}' -f $Source)

$State = $null
$CarryJobs = @()
$DataFile = Join-Path -Path $Paths.Data -ChildPath ('{0}_{1}.xml' -f $ReqName, $TimeStamp)

$Existing = Get-ChildItem -Path $Paths.Data -Filter ('{0}_{1}*.xml' -f $ReqName, $DateStamp) -File | Sort-Object -Property LastWriteTime | Select-Object -Last 1

if ($Existing) {
    $Previous = Import-Clixml -Path $Existing.FullName

    # old version files are a bare array of refresh objects with no Version
    $IsCurrentVersion = ($Previous -isnot [array]) -and ($Previous.Version -eq 2)

    if (-not $IsCurrentVersion) {
        Write-Log -Source $Source -Message ('{0} is from an older version of this script and cannot be resumed, starting anew.' -f $Existing.Name) -Level Warn
    }
    else {
        # never lose track of log jobs a previous run disabled
        $CarryJobs = @($Previous.DisabledJobs)

        $Incomplete = @($Previous.Refreshes | Where-Object { $_.Status -ne 'Completed' })

        if ($Incomplete.Count -eq 0) {
            Write-Log -Source $Source -Message 'No resumable refreshes found, starting anew.'
        }
        elseif ((Get-Item -Path $RequestFile).LastWriteTime -gt $Existing.LastWriteTime) {
            Write-Log -Source $Source -Message 'Request file has been updated since the last run, starting anew.'
        }
        else {
            $State = $Previous
            $DataFile = $Existing.FullName
            Write-Log -Source $Source -Message ('Resuming from {0}' -f $DataFile)

            Write-Table -InputObject $Incomplete -Property TargetDb, Status, FailedStep, TransformType, BakFilter -Title 'R E S U M E D  D A T A B A S E S'
        }
    }
}

if ($null -eq $State) {
    Write-Table -InputObject $Requests -Title 'R E Q U E S T E D  D A T A B A S E S'
}

if ($Verify) {
    $Answer = Read-Choice -Prompt '[?] Is this correct? (y)es/(n)o ' -Choice 'Y', 'N'
    if ($Answer -ne 'Y') {
        $null = Stop-Transcript
        exit 0
    }
}

if ($null -eq $State) {
    $State = New-RefreshState -RequestFile (Resolve-Path -Path $RequestFile).Path -DisabledJobs $CarryJobs

    Write-Log -Source $Source -Message 'Gathering data for refresh ...'
    $PlanSplat = @{
        Request    = $Requests
        DbConfig   = $DbConfig
        BackupType = $BackupType
        DbOwner    = $Owner
    }
    $State.Refreshes = @(Get-RefreshPlan @PlanSplat)
}

Write-Table -InputObject $State.Refreshes -Property Status, Listener, SourceDb, TargetDb, IsAg, TransformType -Title 'A L L  R E F R E S H  D A T A' -DetailOnly
Write-Log -Source $Source -Message ('# END  : {0}' -f $Source)

# everything the steps need
$Context = @{
    Settings           = $Settings
    DacOptions         = $DacOptions
    Paths              = $Paths
    TimeStamp          = $TimeStamp
    DataFile           = $DataFile
    State              = $State
    Credential         = $Credential
    LocalFile          = $LocalFile.IsPresent
    BackupPath         = $BackupPath
    PreBackupForceFull = $PreBackupForceFull.IsPresent
    PreBackupCleanup   = $PreBackupCleanup
    PostBackupCleanup  = $PostBackupCleanup
    SkipFileRename     = $SkipFileRename.IsPresent
    SkipDbOwner        = $SkipDbOwner.IsPresent
}
Save-RefreshState -Context $Context


####################################################################################################
# Steps, in order. Names are what the data file records in CompletedSteps.
####################################################################################################
$Steps = @(
    @{ Name = 'PreBackup';        Function = 'Invoke-PreBackupStep';        Skip = $SkipPreBackup.IsPresent }
    @{ Name = 'ExportPrincipals'; Function = 'Invoke-ExportPrincipalStep';  Skip = $SkipRolesUsers.IsPresent }
    @{ Name = 'ExportSynonyms';   Function = 'Invoke-ExportSynonymStep';    Skip = $SkipSynonyms.IsPresent }
    @{ Name = 'ExportData';       Function = 'Invoke-ExportDataStep';       Skip = $false }
    @{ Name = 'PreProcess';       Function = 'Invoke-PreProcessStep';       Skip = $SkipPreProcess.IsPresent }
    @{ Name = 'Restore';          Function = 'Invoke-RestoreStep';          Skip = $SkipRestore.IsPresent }
    @{ Name = 'DatabaseSettings'; Function = 'Invoke-DatabaseSettingStep';  Skip = $SkipRestore.IsPresent }
    @{ Name = 'ImportPrincipals'; Function = 'Invoke-ImportPrincipalStep';  Skip = $false }
    @{ Name = 'ImportSynonyms';   Function = 'Invoke-ImportSynonymStep';    Skip = $false }
    @{ Name = 'ImportData';       Function = 'Invoke-ImportDataStep';       Skip = $false }
    @{ Name = 'Transform';        Function = 'Invoke-TransformStep';        Skip = $SkipTransform.IsPresent }
    @{ Name = 'PostProcess';      Function = 'Invoke-PostProcessStep';      Skip = $SkipPostProcess.IsPresent }
    @{ Name = 'PostBackup';       Function = 'Invoke-PostBackupStep';       Skip = $SkipPostBackup.IsPresent }
    @{ Name = 'ShrinkLog';        Function = 'Invoke-ShrinkLogStep';        Skip = $SkipShrinkLog.IsPresent }
)

if ($SetSimpleRecovery) {
    $Steps += @{ Name = 'RecoveryModel'; Function = 'Invoke-RecoveryModelStep'; Skip = $false }
}


####################################################################################################
# Main loop. A failure stops that database only.
####################################################################################################
try {
    $ApproveAll = -not $Verify

    foreach ($Refresh in @($State.Refreshes | Where-Object { $_.Status -ne 'Completed' })) {

        Write-Table -InputObject $Refresh -Property TargetDb, SourceDb, Listener, Ag, Primary, Secondary, BakPath, BakFilter, BackupType, TransformType, PersistTable, PreProcess, PostProcess, CompletedSteps -List -Title 'R E F R E S H  D E T A I L S'
        Write-Table -InputObject $Refresh.FileMapping -DetailOnly

        # per-database confirmation
        if (-not $ApproveAll) {
            $Answer = Read-Choice -Prompt '[?] Continue? (y)es/(n)o/(a)ll ' -Choice 'Y', 'N', 'A'
            if ($Answer -eq 'N') {
                Write-Log -Source 'Verify' -Message ('Skipping {0}.' -f $Refresh.TargetDb) -Level Warn
                continue
            }
            if ($Answer -eq 'A') {
                $ApproveAll = $true
            }
        }

        $StartTime = Get-Date
        $Refresh.Status = 'Running'
        $Refresh.FailedStep = $null
        $Refresh.Error = $null

        try {
            foreach ($Step in $Steps) {
                Invoke-RefreshStep -Refresh $Refresh -Step $Step -Context $Context
            }

            $Elapsed = New-TimeSpan -Start $StartTime -End (Get-Date)
            $Refresh.Status = 'Completed'
            $Refresh.CurrentStep = $null
            $Refresh.TimeTaken = [int]$Elapsed.TotalSeconds
            Write-Log -Source $Refresh.TargetDb -Message ('### {0} refreshed in {1:hh\:mm\:ss} ###' -f $Refresh.TargetDb, $Elapsed)
        }
        catch {
            $Refresh.Status = 'Failed'
            $Refresh.FailedStep = $Refresh.CurrentStep
            $Refresh.Error = $_.Exception.Message

            Write-Log -Source $Refresh.TargetDb -Message $_.Exception.Message -Level Crit
            Write-Log -Source $Refresh.TargetDb -Message ('Failed during {0}, skipping the rest of this refresh. Re-run to resume from this step.' -f $Refresh.FailedStep) -Level Crit

            if ($Notify) {
                $MailSplat = @{
                    To            = $Notify
                    Subject       = ('Refresh failed - {0} : {1}' -f $Refresh.TargetDb, $Refresh.FailedStep)
                    Body          = $_.Exception.Message
                    EmailSettings = $Settings.Email
                }
                Send-RefreshMail @MailSplat
            }
        }
        finally {
            Save-RefreshState -Context $Context
        }
    }
}
finally {
    ################################################################################################
    # Cleanup: always re-enable log backups and save state, even after Ctrl+C or an unexpected error
    ################################################################################################
    $Source = 'Cleanup'
    Write-Log -Source $Source -Message ('# START: {0}' -f $Source)

    # instances we disabled jobs on, plus every replica we restored to
    $Touched = @($State.DisabledJobs | ForEach-Object { $_.Instance })
    $Touched += @($State.Refreshes | Where-Object { @($_.CompletedSteps) -contains 'Restore' -or $_.FailedStep -eq 'Restore' } | ForEach-Object { $_.Replicas } | ForEach-Object { $_.Name })

    if ($Touched.Count -gt 0) {
        Resume-LogBackupJob -Instance $Touched -Context $Context
    }

    Save-RefreshState -Context $Context
    Write-Log -Source $Source -Message ('Refresh data saved to {0}' -f $DataFile)

    $Incomplete = @($State.Refreshes | Where-Object { $_.Status -ne 'Completed' })
    if ($State.Refreshes.Count -gt 0 -and $Incomplete.Count -eq 0 -and $State.DisabledJobs.Count -eq 0) {
        Move-Item -Path $DataFile -Destination $Paths.Archive -Force
        Write-Log -Source $Source -Message 'Refresh data archived.'
    }

    Write-Log -Source $Source -Message ('# END  : {0}' -f $Source)
}


####################################################################################################
# Reporting
####################################################################################################
$Source = 'Report'

$Summary = @($State.Refreshes | Select-Object -Property TargetDb, Status, FailedStep, @{ Name = 'Minutes'; Expression = { [math]::Round(([int]$_.TimeTaken) / 60, 1) } }, Error)
Write-Table -InputObject $Summary -Title 'R E F R E S H  S U M M A R Y'

Write-Table -InputObject $MessageLog -Property Date, Time, Type, Source, Message -Title 'L O G  S U M M A R Y' -DetailOnly

$Errors = @($MessageLog | Where-Object { $_.ErrorLevel -le 2 })
if ($Errors.Count -gt 0) {
    $ExitCode = 1
    Write-Table -InputObject $Errors -Property Time, Type, Source, Message -Title 'E R R O R  S U M M A R Y'
}

# restore history for what completed
$RestoreDetails = @()
$Completed = @($State.Refreshes | Where-Object { $_.Status -eq 'Completed' })
if ($Completed.Count -gt 0) {
    try {
        $CompletedInstances = @($Completed | ForEach-Object { $_.Replicas } | ForEach-Object { $_.Name } | Sort-Object -Unique)
        $CompletedDbs = @($Completed | ForEach-Object { $_.TargetDb })

        $HistorySplat = @{
            SqlInstance     = $CompletedInstances
            Since           = (Get-Date).AddDays(-1)
            RestoreType     = 'Database', 'Differential'
            EnableException = $true
        }
        $RestoreDetails = @(Get-DbaDbRestoreHistory @HistorySplat |
                Where-Object { $_.Database -in $CompletedDbs } |
                Select-Object -Property SqlInstance, Database, Date, RestoreType |
                Sort-Object -Property SqlInstance, Database, Date, RestoreType)

        Write-Table -InputObject $RestoreDetails -Title 'R E S T O R E  D E T A I L S'
    }
    catch {
        Write-Log -Source $Source -Message ('Could not read restore history: {0}' -f $_.Exception.Message) -Level Warn
    }
}

# email report
if ($Notify) {
    $Fragments = @()
    $Fragments += $Summary | ConvertTo-Html -Fragment -PreContent '<h3>Refresh Summary</h3>' | Out-String
    if ($Errors.Count -gt 0) {
        $Fragments += $Errors | Select-Object -Property Date, Time, Type, Source, Message | ConvertTo-Html -Fragment -PreContent '<h3>Errors</h3>' | Out-String
    }
    if ($RestoreDetails.Count -gt 0) {
        $Fragments += $RestoreDetails | ConvertTo-Html -Fragment -PreContent '<h3>Restore Details</h3>' | Out-String
    }

    if ($Errors.Count -gt 0) {
        $Subject = 'Refresh Error Report - {0} : {1}' -f $ReqName, (Get-Date -Format 'yyyy-MM-dd')
    }
    else {
        $Subject = 'Refresh Report - {0} : {1}' -f $ReqName, (Get-Date -Format 'yyyy-MM-dd')
    }

    $MailSplat = @{
        To            = $Notify
        Subject       = $Subject
        Body          = (ConvertTo-Html -Head $Settings.HtmlHead -Body ($Fragments -join '') | Out-String)
        EmailSettings = $Settings.Email
        BodyAsHtml    = $true
    }
    Send-RefreshMail @MailSplat
}

if ($Verify) {
    if ($ExitCode -ne 0) {
        $null = Read-Host -Prompt '::: Script completed with errors. Please review log. Press ENTER to exit. ::'
    }
    else {
        $null = Read-Host -Prompt '::: Script completed. Press ENTER to exit. ::'
    }
}

$null = Stop-Transcript
exit $ExitCode
