<#
.SYNOPSIS
    Refresh plan, step engine and the individual refresh steps.
.DESCRIPTION
    Every step function takes -Refresh (one database's refresh object) and -Context (settings, paths, switches).
    A step either finishes or throws. A throw fails only that database; the main loop moves on to the next one.
.NOTES
    Dot-sourced by Refresh-Database.ps1, so $script: here is the main script's scope.
#>

####################################################################################################
# Plan and state
####################################################################################################

function Get-RefreshReplica {
    <#
    .SYNOPSIS
        Returns Name/Role for every replica in the AG, or the listener as a single primary when no AG is set.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )

    if (-not $Config.AG) {
        return [PSCustomObject]@{
            Name = $Config.Listener
            Role = 'Primary'
        }
    }

    $Ag = Get-DbaAvailabilityGroup -SqlInstance $Config.Listener -AvailabilityGroup $Config.AG -EnableException
    if (-not $Ag) {
        throw ('Availability group {0} not found on {1}.' -f $Config.AG, $Config.Listener)
    }

    foreach ($Replica in $Ag.AvailabilityReplicas) {
        [PSCustomObject]@{
            Name = $Replica.Name
            Role = $Replica.Role.ToString()
        }
    }
}


function Get-RefreshPlan {
    <#
    .SYNOPSIS
        Builds one refresh object per requested database from the request file and DbConfig file.
    .DESCRIPTION
        A database that is missing from the config, missing on the instance, or whose AG cannot be read is logged
        as an error and left out. The others still run.

        Note: we check the DB and AG exist, not that the DB is currently in the AG. The DbConfig AG column decides
        the end state. If a previous run failed, it is easier to recover with the DB only on the primary; the
        refresh still restores to every replica and joins the AG afterwards.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Request,

        [Parameter(Mandatory = $true)]
        [object[]]$DbConfig,

        [Parameter(Mandatory = $true)]
        [string[]]$BackupType,

        [Parameter(Mandatory = $true)]
        [string]$DbOwner
    )

    # index config rows by target database, keys are case-insensitive
    $ConfigIndex = @{}
    foreach ($Row in $DbConfig) {
        if ($ConfigIndex.ContainsKey($Row.TargetDB)) {
            Write-Log -Source 'Gather' -Message ('{0} is listed more than once in the config file, using the first entry.' -f $Row.TargetDB) -Level Warn
            continue
        }
        $ConfigIndex[$Row.TargetDB] = $Row
    }

    foreach ($Item in $Request) {

        $TargetDb = $Item.Database

        if (-not $ConfigIndex.ContainsKey($TargetDb)) {
            Write-Log -Source 'Gather' -Message ('{0} was not found in the config file. Skipping.' -f $TargetDb) -Level Error
            continue
        }

        $Config = $ConfigIndex[$TargetDb]

        try {
            # the database must exist so we can export from it
            if (-not (Get-DbaDatabase -SqlInstance $Config.Listener -Database $TargetDb -EnableException)) {
                Write-Log -Source 'Gather' -Message ('{0} does not exist on {1}. Skipping.' -f $TargetDb, $Config.Listener) -Level Error
                continue
            }

            $Replicas = @(Get-RefreshReplica -Config $Config)
            if ($Replicas.Count -eq 0) {
                Write-Log -Source 'Gather' -Message ('An AG was set for {0}, but no replicas were found. Skipping.' -f $TargetDb) -Level Error
                continue
            }

            $FileMapping = $null
            if ($Config.FileMapping) {
                $FileMapping = ConvertTo-FileMapping -String $Config.FileMapping
            }

            $BakFilter = '*'
            if ($Item.Filter) {
                $BakFilter = $Item.Filter
            }

            [PSCustomObject]@{
                # progress
                Status         = 'Pending'
                CompletedSteps = @()
                CurrentStep    = $null
                FailedStep     = $null
                Error          = $null
                TimeTaken      = $null

                # where
                Listener       = $Config.Listener
                IsAg           = [bool]$Config.AG
                Ag             = $Config.AG
                Replicas       = $Replicas
                Primary        = ($Replicas | Where-Object { $_.Role -eq 'Primary' } | Select-Object -First 1).Name
                Secondary      = @($Replicas | Where-Object { $_.Role -eq 'Secondary' } | ForEach-Object { $_.Name })

                # what
                SourceDb       = $Config.SourceDB
                TargetDb       = $TargetDb
                SourceDbEnv    = '_' + $Config.SourceDB.Split('_')[-1]
                TargetDbEnv    = '_' + $TargetDb.Split('_')[-1]
                DataPath       = $Config.DataPath
                LogPath        = $Config.LogPath
                BakPath        = $Config.BakPath
                BakFilter      = $BakFilter
                BackupType     = $BackupType
                FileMapping    = $FileMapping
                DbOwner        = $DbOwner

                # transforms and processing
                TransformType  = $Item.Transform
                DacpacPath     = $Config.DacPacPath
                ReplaceSp      = $Config.ReplaceSp
                ReplaceFn      = $Config.ReplaceFn
                ReplaceVw      = $Config.ReplaceVw
                PersistTable   = $Config.PersistTable
                PreProcess     = $Config.PreProcess
                PostProcess    = $Config.PostProcess

                # export files, filled in by the export steps
                RoleFile       = $null
                UserFile       = $null
                SynonymFile    = $null
            }
        }
        catch {
            Write-Log -Source 'Gather' -Message ('{0} - failed to gather refresh data: {1} Skipping.' -f $TargetDb, $_.Exception.Message) -Level Error
        }
    }
}


function New-RefreshState {
    <#
    .SYNOPSIS
        Creates the object saved to the data .xml file for restarts.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RequestFile,

        [AllowNull()]
        [object[]]$DisabledJobs
    )

    [PSCustomObject]@{
        Version      = 2
        RequestFile  = $RequestFile
        Created      = Get-Date
        DisabledJobs = @($DisabledJobs | Where-Object { $null -ne $_ })
        Refreshes    = @()
    }
}


function Save-RefreshState {
    <#
    .SYNOPSIS
        Writes the refresh state to the data file. Called after every step.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Context.State | Export-Clixml -Path $Context.DataFile -Depth 10
}


function Invoke-RefreshStep {
    <#
    .SYNOPSIS
        Runs one step for one database: skips it if already completed, honours the Skip flag, records completion and checkpoints.
    .EXAMPLE
        Invoke-RefreshStep -Refresh $Refresh -Step @{ Name = 'Restore'; Function = 'Invoke-RestoreStep'; Skip = $false } -Context $Context
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Step,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Source = $Refresh.TargetDb

    if (@($Refresh.CompletedSteps) -contains $Step.Name) {
        Write-Log -Source $Source -Message ('# SKIP : {0} (completed in a previous run)' -f $Step.Name)
        return
    }

    $Refresh.CurrentStep = $Step.Name
    Write-Log -Source $Source -Message ('# START: {0}' -f $Step.Name)

    if ($Step.Skip) {
        Write-Log -Source $Source -Message ('{0} skipped by request.' -f $Step.Name) -Level Warn
    }
    else {
        & $Step.Function -Refresh $Refresh -Context $Context
    }

    $Refresh.CompletedSteps = @($Refresh.CompletedSteps) + $Step.Name
    Write-Log -Source $Source -Message ('# END  : {0}' -f $Step.Name)

    Save-RefreshState -Context $Context
}


####################################################################################################
# Shared helpers
####################################################################################################

function Get-RefreshDatabase {
    <#
    .SYNOPSIS
        Fresh SMO database object from the primary replica.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh
    )

    $Database = Get-DbaDatabase -SqlInstance $Refresh.Primary -Database $Refresh.TargetDb -EnableException
    if (-not $Database) {
        throw ('{0} not found on {1}.' -f $Refresh.TargetDb, $Refresh.Primary)
    }

    $Database
}


function Get-LatestBackup {
    <#
    .SYNOPSIS
        Latest disk full and diff backup of the target database across all replicas (in case of a failover).
        Auto-seed history is excluded by DeviceType.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $HistorySplat = @{
        SqlInstance     = @($Refresh.Replicas | ForEach-Object { $_.Name })
        Database        = $Refresh.TargetDb
        IncludeCopyOnly = $true
        Type            = 'Full', 'Differential'
        Since           = (Get-Date).AddDays(-$Context.Settings.BackupHistoryDays)
    }
    $History = @(Get-DbaDbBackupHistory @HistorySplat | Where-Object { $_.DeviceType -eq 'Disk' })

    [PSCustomObject]@{
        Full = $History | Where-Object { $_.Type -eq 'Full' } | Sort-Object -Property Start -Descending | Select-Object -First 1
        Diff = $History | Where-Object { $_.Type -eq 'Differential' } | Sort-Object -Property Start -Descending | Select-Object -First 1
    }
}


function Get-BackupFolder {
    <#
    .SYNOPSIS
        -BackupPath if passed, else the folder of the given backup history entry (handles striped backups).
    #>
    [CmdletBinding()]
    param(
        [AllowNull()]
        $Backup,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    if ($Context.BackupPath) {
        return $Context.BackupPath
    }

    if ($Backup) {
        return Split-Path -Path ($Backup.Path | Select-Object -First 1) -Parent
    }

    return $null
}


function Invoke-RefreshBackup {
    <#
    .SYNOPSIS
        Takes the PRE or POST refresh backup and optionally removes older refresh backups of the same kind.
    .EXAMPLE
        Invoke-RefreshBackup -Refresh $Refresh -Context $Context -Type Full -Tag 'POST' -Folder '\\server\share\db' -CleanupHours 48
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Full', 'Diff')]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        [ValidateSet('PRE', 'POST')]
        [string]$Tag,

        [Parameter(Mandatory = $true)]
        [string]$Folder,

        [int]$CleanupHours
    )

    $Source = $Refresh.TargetDb

    if ($Context.BackupPath) {
        Write-Log -Source $Source -Message ('BackupPath set: {0}' -f $Context.BackupPath)
    }

    $BackupSplat = @{
        SqlInstance     = $Refresh.Listener
        Database        = $Refresh.TargetDb
        Type            = $Type
        Path            = $Folder
        FilePath        = ('dbname-{0}-backuptype-timestamp.bak' -f $Tag)
        ReplaceInName   = $true
        CompressBackup  = $true
        EnableException = $true
    }
    if ($Type -eq 'Full') {
        $BackupSplat.FileCount = $Context.Settings.FullBackupFileCount
    }

    Write-Log -Source $Source -Message ('Performing {0} {1} backup to {2} ...' -f $Tag, $Type.ToLower(), $Folder)
    $Result = Backup-DbaDatabase @BackupSplat
    Write-Log -Source $Source -Message ('{0} {1} backup completed: {2}' -f $Tag, $Type.ToLower(), ($Result.BackupPath -join ', '))

    # only needed where Ola is not cleaning up the folder
    if ($CleanupHours -gt 0) {
        $Filter = '{0}-{1}-{2}-*' -f $Refresh.TargetDb, $Tag, $Type.ToUpper()
        $Cutoff = (Get-Date).AddHours(-$CleanupHours)

        Write-Log -Source $Source -Message ('Cleaning up {0} files older than {1} hours ...' -f $Filter, $CleanupHours)

        $OldFiles = @(Get-ChildItem -Path $Folder -Filter $Filter -File | Where-Object { $_.LastWriteTime -lt $Cutoff })
        foreach ($File in $OldFiles) {
            Remove-Item -Path $File.FullName
            Write-Log -Source $Source -Message ('Removed {0}' -f $File.FullName)
        }

        Write-Log -Source $Source -Message ('Cleanup completed, {0} file(s) removed.' -f $OldFiles.Count)
    }
}


function Invoke-ProcessList {
    <#
    .SYNOPSIS
        Runs the comma separated pre/post process function names from the config file, in order.
        The functions live in function\Refresh-Functions.ps1 and read $script:Refresh / $script:StagingDB.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$List,

        [Parameter(Mandatory = $true)]
        [string]$Kind
    )

    $Source = $Refresh.TargetDb

    $Names = @(([string]$List).Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($Names.Count -eq 0) {
        Write-Log -Source $Source -Message ('No {0} defined.' -f $Kind)
        return
    }

    # fail before running anything if a name is misspelled
    foreach ($Name in $Names) {
        if (-not (Get-Command -Name $Name -CommandType Function -ErrorAction SilentlyContinue)) {
            throw ('{0} function {1} not found in the function folder.' -f $Kind, $Name)
        }
    }

    Write-Log -Source $Source -Message ('Running {0} ...' -f $Kind)
    foreach ($Name in $Names) {
        Write-Log -Source $Source -Message ('Executing {0}.' -f $Name)
        $Output = & $Name
        if ($Output) {
            Write-Table -InputObject $Output
        }
    }
}


####################################################################################################
# Restore helpers
####################################################################################################

function Connect-BackupShare {
    <#
    .SYNOPSIS
        Maps each backup share inside SQL Server (xp_cmdshell net use) using the share account.
        Skips the mapping when the share is already reachable, so the password is only sent when needed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        [Parameter(Mandatory = $true)]
        [string]$BakPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context,

        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    # several paths may be passed, separated by '|'
    foreach ($Path in $BakPath.Split('|')) {

        # '\\server\share\folder\path' -> '\\server\share', the first two split items are empty
        $ShareRoot = $Path.Split('\')[0..3] -join '\'

        if (Test-DbaPath -SqlInstance $Instance -Path $ShareRoot -EnableException) {
            Write-Log -Source $Source -Message ('{0} - {1} already accessible.' -f $Instance, $ShareRoot)
            continue
        }

        if ($null -eq $Context.Credential) {
            throw ('{0} - {1} is not accessible and no share credential is loaded (LocalFile set?).' -f $Instance, $ShareRoot)
        }

        # single quotes are doubled for the T-SQL string literal
        $UserName = $Context.Credential.UserName
        $Password = $Context.Credential.GetNetworkCredential().Password.Replace("'", "''")
        $Query = "EXEC xp_cmdshell 'net use {0} /user:{1} {2}'" -f $ShareRoot, $UserName, $Password

        $Output = @(Invoke-DbaQuery -SqlInstance $Instance -Query $Query -EnableException | Select-Object -ExpandProperty output | Where-Object { $_ })

        if ($Output -notcontains 'The command completed successfully.') {
            throw ('{0} - {1} failed to authenticate: {2}' -f $Instance, $ShareRoot, ($Output -join ' '))
        }

        if (-not (Test-DbaPath -SqlInstance $Instance -Path $ShareRoot -EnableException)) {
            throw ('{0} - authenticated, but {1} is not accessible.' -f $Instance, $ShareRoot)
        }

        Write-Log -Source $Source -Message ('{0} - authenticated to {1}.' -f $Instance, $ShareRoot)
    }
}


function Find-RefreshBackupFile {
    <#
    .SYNOPSIS
        Backup files (up to one folder deep) for the source database, filtered by backup type and the request file filter.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        [Parameter(Mandatory = $true)]
        $Refresh
    )

    $Files = foreach ($Path in $Refresh.BakPath.Split('|')) {
        Get-DbaFile -SqlInstance $Instance -Path $Path -Depth 2 -FileType 'bak' -EnableException | Select-Object -ExpandProperty Filename
    }

    if (-not $Files) { return }

    # filter is comma separated wildcards against the full path, e.g. '*FULL_20210618*,*DIFF_20210619*'
    $Patterns = @($Refresh.BakFilter.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $BackupTypes = @($Refresh.BackupType)

    $Files | Get-DbaBackupInformation -SqlInstance $Instance -EnableException | Where-Object {
        $_.Database -eq $Refresh.SourceDb -and
        $_.Type -in $BackupTypes -and
        (Test-NameMatch -Name $_.Path -Pattern $Patterns)
    }
}


function Get-LogBackupJob {
    <#
    .SYNOPSIS
        Agent jobs matching the LogJobInclude settings and not LogJobExclude.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Settings = $Context.Settings

    Get-DbaAgentJob -SqlInstance $Instance -EnableException | Where-Object {
        (Test-NameMatch -Name $_.Name -Pattern $Settings.LogJobInclude) -and
        -not (Test-NameMatch -Name $_.Name -Pattern $Settings.LogJobExclude)
    }
}


function Suspend-LogBackupJob {
    <#
    .SYNOPSIS
        Disables enabled, scheduled log backup jobs, records them in the state file, then waits for any running one to finish.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Instance,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context,

        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $Jobs = @(Get-LogBackupJob -Instance $Instance -Context $Context)
    $ToDisable = @($Jobs | Where-Object { $_.HasSchedule -eq $true -and $_.Enabled -eq $true })

    foreach ($Job in $ToDisable) {
        $null = Set-DbaAgentJob -SqlInstance $Instance -Job $Job.Name -Disabled -EnableException

        # remember exactly what we disabled so it is re-enabled even after a failure or restart
        $AlreadyRecorded = @($Context.State.DisabledJobs | Where-Object { $_.Instance -eq $Instance -and $_.Job -eq $Job.Name })
        if ($AlreadyRecorded.Count -eq 0) {
            $Record = [PSCustomObject]@{
                Instance = $Instance
                Job      = $Job.Name
            }
            $Context.State.DisabledJobs = @($Context.State.DisabledJobs) + $Record
        }

        Write-Log -Source $Source -Message ('{0} - disabled job {1}.' -f $Instance, $Job.Name)
    }

    if ($ToDisable.Count -eq 0) {
        Write-Log -Source $Source -Message ('{0} - no log backup jobs to disable.' -f $Instance)
    }

    Save-RefreshState -Context $Context

    if ($Jobs.Count -eq 0) { return }

    # make sure no log backup is mid-run before restoring
    Write-Log -Source $Source -Message ('{0} - checking for a running log backup ...' -f $Instance)
    $Deadline = (Get-Date).AddMinutes($Context.Settings.LogJobWaitMinutes)
    $JobNames = @($Jobs | ForEach-Object { $_.Name })

    while ($true) {
        $Running = @(Get-DbaAgentJob -SqlInstance $Instance -Job $JobNames -EnableException | Where-Object { $_.CurrentRunStatus -eq 'Executing' })
        if ($Running.Count -eq 0) { break }

        if ((Get-Date) -gt $Deadline) {
            throw ('{0} - log backup job(s) {1} still running after {2} minutes.' -f $Instance, ($Running.Name -join ', '), $Context.Settings.LogJobWaitMinutes)
        }

        Start-Sleep -Seconds 5
    }
}


function Resume-LogBackupJob {
    <#
    .SYNOPSIS
        Re-enables log backup jobs on each instance unless a database there is still restoring.
    .DESCRIPTION
        Re-enables the jobs this run (or an earlier run of this request) recorded as disabled, plus any matching job
        disabled with a run in the last 3 days. The second rule catches jobs another refresh disabled when two
        request files run against the same instances in parallel.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Instance,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Source = 'Cleanup'
    $Cutoff = (Get-Date).AddDays(-3)

    foreach ($Server in ($Instance | Sort-Object -Unique)) {
        try {
            # another refresh may be running, or a restore failed part way
            $Restoring = @(Get-DbaDatabase -SqlInstance $Server -ExcludeSystem -Status 'Restoring' -EnableException)
            if ($Restoring.Count -gt 0) {
                Write-Log -Source $Source -Message ('{0} - log backup jobs left disabled, database(s) restoring: {1}' -f $Server, ($Restoring.Name -join ', ')) -Level Warn
                continue
            }

            $Recorded = @($Context.State.DisabledJobs | Where-Object { $_.Instance -eq $Server } | ForEach-Object { $_.Job })

            $ToEnable = @(Get-LogBackupJob -Instance $Server -Context $Context | Where-Object {
                    $_.HasSchedule -eq $true -and
                    $_.Enabled -eq $false -and
                    ($_.Name -in $Recorded -or $_.LastRunDate -gt $Cutoff)
                })

            foreach ($Job in $ToEnable) {
                $null = Set-DbaAgentJob -SqlInstance $Server -Job $Job.Name -Enabled -EnableException
                Write-Log -Source $Source -Message ('{0} - enabled job {1}.' -f $Server, $Job.Name)
            }

            # forget what we re-enabled
            $Context.State.DisabledJobs = @($Context.State.DisabledJobs | Where-Object { $_.Instance -ne $Server })
        }
        catch {
            Write-Log -Source $Source -Message ('{0} - failed to re-enable log backup jobs: {1}' -f $Server, $_.Exception.Message) -Level Warn
        }
    }
}


function New-RestoreParam {
    <#
    .SYNOPSIS
        Restore-DbaDatabase splat for one replica.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        $Replica
    )

    $RestoreParams = @{
        SqlInstance         = $Replica.Name
        DatabaseName        = $Refresh.TargetDb
        WithReplace         = $true
        ReplaceDbNameInFile = $true
        EnableException     = $true
    }

    # secondaries stay restoring so they can join the AG
    if ($Replica.Role -eq 'Secondary') {
        $RestoreParams.NoRecovery = $true
    }

    # file mapping for secondary data files, else default paths
    if ($Refresh.FileMapping -and $Refresh.FileMapping.Count -gt 0) {
        $RestoreParams.FileMapping = $Refresh.FileMapping
    }
    else {
        $RestoreParams.DestinationDataDirectory = $Refresh.DataPath
        $RestoreParams.DestinationLogDirectory = $Refresh.LogPath
    }

    $RestoreParams
}


function Restore-ReplicaParallel {
    <#
    .SYNOPSIS
        Restores to every replica at once with background jobs, shows progress, and throws if any job failed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [object[]]$Plan,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Source = $Refresh.TargetDb

    # each job is a new session, so connection settings are applied again inside it
    $RestoreScript = {
        param($RestoreParams, $BakFiles)

        Import-Module -Name dbatools
        Set-DbatoolsConfig -FullName 'sql.connection.trustcert' -Value $true
        Set-DbatoolsConfig -FullName 'sql.connection.encrypt' -Value $false

        $BakFiles | Restore-DbaDatabase @RestoreParams
    }

    $Jobs = foreach ($Item in $Plan) {
        $RestoreParams = New-RestoreParam -Refresh $Refresh -Replica $Item
        Write-Table -InputObject $RestoreParams -DetailOnly

        $JobSplat = @{
            Name         = ('{0}_{1}' -f $Item.Name, $Refresh.TargetDb)
            ScriptBlock  = $RestoreScript
            ArgumentList = @($RestoreParams, $Item.BakFiles)
        }
        Start-Job @JobSplat

        Write-Log -Source $Source -Message ('{0} - restore job started.' -f $Item.Name)
    }

    Write-Log -Source $Source -Message 'Restore job(s) submitted, waiting for completion ...'

    # wait, with a progress line every RestoreProgressSeconds
    $SinceProgress = 0
    $Instances = @($Plan | ForEach-Object { $_.Name })

    while (@($Jobs | Where-Object { $_.State -in 'NotStarted', 'Running' }).Count -gt 0) {
        Start-Sleep -Seconds 10
        $SinceProgress += 10

        if ($SinceProgress -ge $Context.Settings.RestoreProgressSeconds) {
            $SinceProgress = 0
            $Restores = Get-DbaEstimatedCompletionTime -SqlInstance $Instances | Where-Object { $_.Command -eq 'RESTORE DATABASE' -and $_.Text -like ('*{0}*' -f $Refresh.TargetDb) }
            foreach ($Restore in $Restores) {
                Write-Host -Object ('{0} - {1} Percent: {2:n2}% Left: {3}' -f $Restore.SqlInstance, $Refresh.TargetDb, $Restore.PercentComplete, $Restore.EstimatedTimeToGo)
            }
        }
    }

    # collect output and failures
    $Failures = @()
    foreach ($Job in $Jobs) {
        $JobErrors = $null
        $Output = Receive-Job -Job $Job -ErrorAction SilentlyContinue -ErrorVariable JobErrors

        if ($Output) {
            Write-Table -InputObject $Output -List
        }

        if ($Job.State -eq 'Failed' -or $JobErrors) {
            $Reason = $Job.ChildJobs[0].JobStateInfo.Reason
            if ($Reason) {
                $Message = $Reason.Message
            }
            else {
                $Message = ($JobErrors | ForEach-Object { $_.ToString() }) -join ' '
            }
            $Failures += '{0}: {1}' -f $Job.Name, $Message
            Write-Log -Source $Source -Message ('{0} restore job failed: {1}' -f $Job.Name, $Message) -Level Error
        }

        Remove-Job -Job $Job -Force
    }

    if ($Failures.Count -gt 0) {
        throw ('Restore failed on {0} replica(s).' -f $Failures.Count)
    }

    Write-Log -Source $Source -Message 'Initial restores completed.'
}


####################################################################################################
# Transform helpers
####################################################################################################

function ConvertTo-DacValue {
    <#
    .SYNOPSIS
        Converts 'true'/'false' text from a .config file to a boolean. Assigning the text directly would make 'false' true.
    #>
    [CmdletBinding()]
    param(
        [AllowNull()]
        $Value
    )

    if ($Value -is [string] -and $Value -match '^(true|false)$') {
        return [System.Convert]::ToBoolean($Value)
    }

    $Value
}


function Get-DacpacConfig {
    <#
    .SYNOPSIS
        Parses every *.config under the dacpac path into one entry per <dacpac> element.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    foreach ($ConfigFile in Get-ChildItem -Path $Path -Filter '*.config' -Recurse -File) {

        [xml]$Xml = Get-Content -Path $ConfigFile.FullName -Raw

        # deploy options shared by every dacpac in this file
        $Options = @{}
        foreach ($Option in @($Xml.deployments.options.option)) {
            if ($null -eq $Option) { continue }
            $Options[$Option.Key] = $Option.Value
        }

        foreach ($Dacpac in @($Xml.deployments.dacpac)) {
            if ($null -eq $Dacpac) { continue }

            [PSCustomObject]@{
                App       = $ConfigFile.Directory.Name
                Filename  = $Dacpac.name
                Database  = $Dacpac.db
                Instance  = $Dacpac.instance
                Variables = @($Dacpac.variables.variable | Where-Object { $null -ne $_ })
                Options   = $Options
            }
        }
    }
}


function Invoke-DacpacTransform {
    <#
    .SYNOPSIS
        Publishes the newest dacpac configured for the target database with default + per-config options and variables.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Source = $Refresh.TargetDb

    if (-not $Refresh.DacpacPath) {
        Write-Log -Source $Source -Message 'DAC transform requested, but no DacpacPath is set in the config file.' -Level Warn
        return
    }

    $Entries = @(Get-DacpacConfig -Path $Refresh.DacpacPath | Where-Object { $_.Database -eq $Refresh.TargetDb })
    Write-Log -Source $Source -Message ('Parsed config at {0}.' -f $Refresh.DacpacPath)
    Write-Table -InputObject $Entries -Property App, Filename, Database, Instance -DetailOnly

    if ($Entries.Count -eq 0) {
        throw ('Dacpac config not found for {0}.' -f $Refresh.TargetDb)
    }

    $FileNames = @($Entries | Select-Object -ExpandProperty Filename | Sort-Object -Unique)
    if ($FileNames.Count -gt 1) {
        throw ('More than one dacpac configured for {0}: {1}' -f $Refresh.TargetDb, ($FileNames -join ', '))
    }

    # newest copy of the file anywhere under the dacpac path
    $DacpacFile = Get-ChildItem -Path $Refresh.DacpacPath -Filter $FileNames[0] -Recurse -File | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
    if (-not $DacpacFile) {
        throw ('Dacpac file {0} not found for {1}.' -f $FileNames[0], $Refresh.TargetDb)
    }
    Write-Log -Source $Source -Message ('Using dacpac file: {0}' -f $DacpacFile.FullName)

    # default options from config\DacOptions.psd1
    $DacOptions = New-DbaDacOption -Type Dacpac -Action Publish -EnableException
    foreach ($Key in $Context.DacOptions.Keys) {
        $DacOptions.DeployOptions.$Key = $Context.DacOptions[$Key]
    }
    Write-Log -Source $Source -Message 'Default DeployOptions set.'

    # SqlCmd variables, duplicate keys (dupe config files) are skipped
    $VariableTable = foreach ($Entry in $Entries) {
        foreach ($Variable in $Entry.Variables) {
            if ($DacOptions.DeployOptions.SqlCommandVariableValues.ContainsKey($Variable.name)) {
                Write-Log -Source $Source -Message ('SqlCommandVariableValues already contains key: {0}.' -f $Variable.name) -Level Warn
                continue
            }
            $DacOptions.DeployOptions.SqlCommandVariableValues.Add($Variable.name, $Variable.value)
            [PSCustomObject]@{
                Name  = $Variable.name
                Value = $Variable.value
            }
        }
    }
    if ($VariableTable) {
        Write-Table -InputObject $VariableTable -Title ('Deploy Variables for {0}' -f $Refresh.TargetDb)
    }

    # deploy options from the .config files override the defaults
    $OptionTable = foreach ($Entry in $Entries) {
        foreach ($Key in $Entry.Options.Keys) {
            $Value = ConvertTo-DacValue -Value $Entry.Options[$Key]
            $DacOptions.DeployOptions.$Key = $Value
            [PSCustomObject]@{
                Key   = $Key
                Value = $Value
            }
        }
    }
    if ($OptionTable) {
        Write-Table -InputObject $OptionTable -Title ('Deploy Options for {0}' -f $Refresh.TargetDb)
    }

    Write-Log -Source $Source -Message 'Deploying dacpac ...'
    $PublishSplat = @{
        SqlInstance     = $Refresh.Listener
        Database        = $Refresh.TargetDb
        DacOption       = $DacOptions
        Path            = $DacpacFile.FullName
        EnableException = $true
    }
    $Result = Publish-DbaDacPackage @PublishSplat
    Write-Table -InputObject $Result -List -DetailOnly
    Write-Log -Source $Source -Message 'Dacpac published.'
}


function Update-ObjectReference {
    <#
    .SYNOPSIS
        Scripts drop + create for the objects, applies every old|new replacement to the whole script, and runs it.
        Original and updated scripts are kept in the export folder.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context,

        [AllowEmptyCollection()]
        [object[]]$Object,

        [Parameter(Mandatory = $true)]
        [string]$Pairs,

        [Parameter(Mandatory = $true)]
        [string]$Tag,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $Source = $Refresh.TargetDb

    if (-not $Object -or $Object.Count -eq 0) {
        Write-Log -Source $Source -Message ('No {0} to update.' -f $Label)
        return
    }

    Write-Log -Source $Source -Message ('Exporting and updating {0} {1} ...' -f $Object.Count, $Label)

    $Options = New-DbaScriptingOption -EnableException
    $Options.AllowSystemObjects = $false
    $Options.IncludeHeaders = $true

    # drops first, then creates
    $Options.ScriptDrops = $true
    $Drops = $Object | Export-DbaScript -ScriptingOptionsObject $Options -Passthru -EnableException

    $Options.ScriptDrops = $false
    $Creates = $Object | Export-DbaScript -ScriptingOptionsObject $Options -Passthru -EnableException

    $OriginalSql = (@($Drops) + @($Creates)) -join [Environment]::NewLine

    # apply every pair to the same text
    $UpdatedSql = $OriginalSql
    foreach ($Pair in Split-ReplacePair -String $Pairs) {
        $UpdatedSql = $UpdatedSql.Replace($Pair.Old, $Pair.New)
    }

    $OriginalFile = Join-Path -Path $Context.Paths.Export -ChildPath ('{0}_{1}_{2}.sql' -f $Refresh.TargetDb, $Tag, $Context.TimeStamp)
    $UpdatedFile = Join-Path -Path $Context.Paths.Export -ChildPath ('{0}_{1}_upd_{2}.sql' -f $Refresh.TargetDb, $Tag, $Context.TimeStamp)
    Set-Content -Path $OriginalFile -Value $OriginalSql -Encoding UTF8
    Set-Content -Path $UpdatedFile -Value $UpdatedSql -Encoding UTF8

    $null = Invoke-DbaQuery -SqlInstance $Refresh.Primary -Database $Refresh.TargetDb -Query $UpdatedSql -EnableException

    Write-Log -Source $Source -Message ('{0} imported. Scripts: {1}' -f $Label, $UpdatedFile)
}


####################################################################################################
# Steps
####################################################################################################

function Invoke-PreBackupStep {
    <#
    .SYNOPSIS
        Diff backup to the folder of the last diff, else full to the folder of the last full. -PreBackupForceFull forces a full.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Latest = Get-LatestBackup -Refresh $Refresh -Context $Context

    if ($Latest.Diff -and -not $Context.PreBackupForceFull) {
        $Type = 'Diff'
        $Folder = Get-BackupFolder -Backup $Latest.Diff -Context $Context
    }
    elseif ($Latest.Full -or $Context.PreBackupForceFull) {
        $Type = 'Full'
        $Folder = Get-BackupFolder -Backup $Latest.Full -Context $Context
    }
    else {
        $Folder = $null
    }

    if (-not $Folder) {
        throw ('Could not determine where to back up {0}: no backup history in the last {1} days and no -BackupPath.' -f $Refresh.TargetDb, $Context.Settings.BackupHistoryDays)
    }

    Invoke-RefreshBackup -Refresh $Refresh -Context $Context -Type $Type -Tag 'PRE' -Folder $Folder -CleanupHours $Context.PreBackupCleanup
}


function Invoke-ExportPrincipalStep {
    <#
    .SYNOPSIS
        Scripts the current roles and users (with permissions and memberships) so they survive the restore.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Source = $Refresh.TargetDb
    $Database = Get-RefreshDatabase -Refresh $Refresh

    $Options = New-DbaScriptingOption -EnableException
    $Options.AllowSystemObjects = $false
    $Options.IncludeHeaders = $true
    $Options.Permissions = $true
    $Options.IncludeIfNotExists = $true
    $Options.IncludeDatabaseRoleMemberships = $true

    # roles
    $Roles = @($Database.Roles | Where-Object { $_.IsFixedRole -ne $true -and $_.Name -ne 'public' -and $_.Name -notlike 'aspnet*' })
    if ($Roles.Count -gt 0) {
        $RoleFile = Join-Path -Path $Context.Paths.Export -ChildPath ('{0}_roles_{1}.sql' -f $Refresh.TargetDb, $Context.TimeStamp)

        $RoleSplat = @{
            SqlInstance            = $Refresh.Listener
            Database               = $Refresh.TargetDb
            ScriptingOptionsObject = $Options
            ExcludeFixedRole       = $true
            FilePath               = $RoleFile
            EnableException        = $true
        }
        $null = Export-DbaDbRole @RoleSplat

        $Refresh.RoleFile = $RoleFile
        Write-Log -Source $Source -Message ('{0} role(s) exported to {1}' -f $Roles.Count, $RoleFile)
    }
    else {
        Write-Log -Source $Source -Message 'No roles to export.'
    }

    # users
    $Users = @($Database.Users | Where-Object { $_.IsSystemObject -ne $true })
    if ($Users.Count -gt 0) {
        $UserFile = Join-Path -Path $Context.Paths.Export -ChildPath ('{0}_users_{1}.sql' -f $Refresh.TargetDb, $Context.TimeStamp)

        $UserSplat = @{
            SqlInstance            = $Refresh.Listener
            Database               = $Refresh.TargetDb
            ScriptingOptionsObject = $Options
            FilePath               = $UserFile
            EnableException        = $true
        }
        $null = Export-DbaUser @UserSplat

        $Refresh.UserFile = $UserFile
        Write-Log -Source $Source -Message ('{0} user(s) exported to {1}' -f $Users.Count, $UserFile)
    }
    else {
        Write-Log -Source $Source -Message 'No users to export.'
    }
}


function Invoke-ExportSynonymStep {
    <#
    .SYNOPSIS
        Scripts the current synonyms so they survive the restore.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Source = $Refresh.TargetDb
    $Database = Get-RefreshDatabase -Refresh $Refresh

    $Synonyms = @($Database.Synonyms)
    if ($Synonyms.Count -eq 0) {
        Write-Log -Source $Source -Message 'No synonyms to export.'
        return
    }

    $Options = New-DbaScriptingOption -EnableException
    $Options.AllowSystemObjects = $false
    $Options.IncludeHeaders = $true

    $SynonymFile = Join-Path -Path $Context.Paths.Export -ChildPath ('{0}_synonyms_{1}.sql' -f $Refresh.TargetDb, $Context.TimeStamp)
    $null = $Synonyms | Export-DbaScript -ScriptingOptionsObject $Options -FilePath $SynonymFile -EnableException

    $Refresh.SynonymFile = $SynonymFile
    Write-Log -Source $Source -Message ('{0} synonym(s) exported to {1}' -f $Synonyms.Count, $SynonymFile)
}


function Invoke-ExportDataStep {
    <#
    .SYNOPSIS
        Copies the PersistTable tables to the staging database as '<TargetDb>-<table>'.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Source = $Refresh.TargetDb
    $StagingDb = $Context.Settings.StagingDb

    $Tables = @(([string]$Refresh.PersistTable).Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($Tables.Count -eq 0) {
        Write-Log -Source $Source -Message 'No tables to persist.'
        return
    }

    # quietly create the staging database if needed
    if (-not (Get-DbaDatabase -SqlInstance $Refresh.Primary -Database $StagingDb -EnableException)) {
        $null = New-DbaDatabase -SqlInstance $Refresh.Primary -Name $StagingDb -EnableException
        Write-Log -Source $Source -Message ('Created staging database {0} on {1}.' -f $StagingDb, $Refresh.Primary)
    }

    Write-Log -Source $Source -Message 'Copying tables ...'
    foreach ($Table in $Tables) {
        $DestinationTable = '{0}-{1}' -f $Refresh.TargetDb, $Table

        $CopySplat = @{
            SqlInstance         = $Refresh.Primary
            Database            = $Refresh.TargetDb
            Table               = $Table
            DestinationDatabase = $StagingDb
            DestinationTable    = $DestinationTable
            AutoCreateTable     = $true
            Truncate            = $true
            KeepIdentity        = $true
            KeepNulls           = $true
            EnableException     = $true
        }
        $Result = Copy-DbaDbTableData @CopySplat

        Write-Log -Source $Source -Message ('{0} copied to {1}.{2} ({3} rows).' -f $Table, $StagingDb, $DestinationTable, $Result.RowsCopied)
    }
}


function Invoke-PreProcessStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    Invoke-ProcessList -Refresh $Refresh -List $Refresh.PreProcess -Kind 'preprocessing'
}


function Invoke-RestoreStep {
    <#
    .SYNOPSIS
        Restores the database to every replica and joins the AG.
    .DESCRIPTION
        1. Validate every replica first: share access and backup files. Nothing is changed if this fails.
        2. Disable log backup jobs on every replica and wait for running ones.
        3. Remove the database from the AG.
        4. Restore: parallel jobs for an AG, inline for a standalone.
        5. AG only: log backup on the primary, restore it to the secondaries, join the AG.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Source = $Refresh.TargetDb

    # 1. validate every replica before touching anything
    $Plan = foreach ($Replica in $Refresh.Replicas) {

        if ($Context.LocalFile) {
            Write-Log -Source $Source -Message ('{0} - using backup path as-is: {1}' -f $Replica.Name, $Refresh.BakPath)
        }
        else {
            Connect-BackupShare -Instance $Replica.Name -BakPath $Refresh.BakPath -Context $Context -Source $Source
        }

        $BakFiles = @(Find-RefreshBackupFile -Instance $Replica.Name -Refresh $Refresh)
        if ($BakFiles.Count -eq 0) {
            throw ('{0} - backup files not found for {1} (filter: {2}, type: {3}).' -f $Replica.Name, $Refresh.SourceDb, $Refresh.BakFilter, ($Refresh.BackupType -join ', '))
        }

        Write-Log -Source $Source -Message ('{0} - {1} backup set(s) found:' -f $Replica.Name, $BakFiles.Count)
        foreach ($BakFile in $BakFiles) {
            Write-Host -Object ("`t{0}" -f ($BakFile.FullName -join ', '))
        }
        Write-Table -InputObject $BakFiles -List -DetailOnly

        [PSCustomObject]@{
            Name     = $Replica.Name
            Role     = $Replica.Role
            BakFiles = $BakFiles
        }
    }

    # 2. pause log backups
    foreach ($Item in $Plan) {
        Suspend-LogBackupJob -Instance $Item.Name -Context $Context -Source $Source
    }

    # 3. remove from the AG
    if ($Refresh.IsAg) {
        $Database = Get-DbaDatabase -SqlInstance $Refresh.Primary -Database $Refresh.TargetDb -EnableException
        if ($Database -and $Database.AvailabilityGroupName) {
            Write-Log -Source $Source -Message ('Removing {0} from {1} ...' -f $Refresh.TargetDb, $Refresh.Ag)
            $null = Remove-DbaAgDatabase -SqlInstance $Refresh.Primary -AvailabilityGroup $Refresh.Ag -Database $Refresh.TargetDb -Confirm:$false -EnableException
        }
    }

    # 4. restore
    if ($Refresh.IsAg) {
        Restore-ReplicaParallel -Refresh $Refresh -Plan $Plan -Context $Context
    }
    else {
        $Item = $Plan[0]
        $RestoreParams = New-RestoreParam -Refresh $Refresh -Replica $Item
        Write-Table -InputObject $RestoreParams -DetailOnly

        Write-Log -Source $Source -Message ('{0} - restoring ...' -f $Item.Name)
        $Result = $Item.BakFiles | Restore-DbaDatabase @RestoreParams
        Write-Table -InputObject $Result -List
        Write-Log -Source $Source -Message ('{0} - restore completed.' -f $Item.Name)
    }

    # 5. AG: catch secondaries up with a log backup and join
    if ($Refresh.IsAg) {
        Write-Log -Source $Source -Message ('{0} - creating log backup ...' -f $Refresh.Primary)
        $LogBackup = Backup-DbaDatabase -SqlInstance $Refresh.Listener -Database $Refresh.TargetDb -Type Log -Path $Context.Paths.Trn -CompressBackup -EnableException

        foreach ($Secondary in $Refresh.Secondary) {
            Write-Log -Source $Source -Message ('{0} - restoring log backup ...' -f $Secondary)
            $null = Restore-DbaDatabase -SqlInstance $Secondary -Database $Refresh.TargetDb -Path $LogBackup.Path -NoRecovery -Continue -EnableException
        }

        Write-Log -Source $Source -Message ('Adding {0} to {1} ...' -f $Refresh.TargetDb, $Refresh.Ag)
        $null = Add-DbaAgDatabase -SqlInstance $Refresh.Primary -AvailabilityGroup $Refresh.Ag -Database $Refresh.TargetDb -SeedingMode Manual -EnableException
        Write-Log -Source $Source -Message ('{0} joined to {1}.' -f $Refresh.TargetDb, $Refresh.Ag)
    }
}


function Invoke-DatabaseSettingStep {
    <#
    .SYNOPSIS
        Filestream directory name, logical file names (_PROD to _TEST) and owner.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Source = $Refresh.TargetDb
    $Database = Get-RefreshDatabase -Refresh $Refresh

    # filestream directory name and read-only non-transacted access
    $HasFilestream = @($Database.FileGroups | Where-Object { $_.FileGroupType -eq 'FileStreamDataFileGroup' }).Count -gt 0
    if ($HasFilestream -and $Database.FilestreamDirectoryName -ne '') {
        Write-Log -Source $Source -Message ('Filestream file group found: {0}.' -f $Database.DefaultFileStreamFileGroup)

        $Database.FilestreamDirectoryName = $Database.Name
        $Database.FilestreamNonTransactedAccess = 1
        $Database.Alter()
        $Database.Refresh()

        Write-Log -Source $Source -Message ('Filestream directory name set to {0}, read-only mode.' -f $Database.FilestreamDirectoryName)
    }

    # logical names, only when refreshing across environments
    if ($Context.SkipFileRename) {
        Write-Log -Source $Source -Message 'Logical name rename skipped by request.' -Level Warn
    }
    elseif ($Refresh.SourceDb -ne $Refresh.TargetDb) {
        $Pattern = '*{0}*' -f $Refresh.SourceDbEnv
        $Files = @($Database.FileGroups | ForEach-Object { $_.Files }) + @($Database.LogFiles)

        foreach ($File in ($Files | Where-Object { $_.Name -like $Pattern })) {
            $NewName = $File.Name.Replace($Refresh.SourceDbEnv, $Refresh.TargetDbEnv)
            $File.Rename($NewName)
            Write-Log -Source $Source -Message ('Logical name updated: {0}' -f $NewName)
        }
    }

    # owner, only set on the primary
    if ($Context.SkipDbOwner) {
        Write-Log -Source $Source -Message 'DbOwner change skipped by request.' -Level Warn
    }
    else {
        $Database.SetOwner($Refresh.DbOwner)
        Write-Log -Source $Source -Message ('Owner set to {0}.' -f $Refresh.DbOwner)
    }
}


function Invoke-ImportPrincipalStep {
    <#
    .SYNOPSIS
        Drops user schemas/views from prod, hands user-owned schemas to dbo, then replaces roles and users with the exported ones.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Source = $Refresh.TargetDb
    $Database = Get-RefreshDatabase -Refresh $Refresh

    # views in 'DOMAIN\user' schemas
    $Views = @($Database.Views | Where-Object { $_.Schema -like '*\*' })
    foreach ($View in $Views) {
        $ViewName = '{0}.{1}' -f $View.Schema, $View.Name
        $View.Drop()
        Write-Log -Source $Source -Message ('Dropped view {0}.' -f $ViewName)
    }
    if ($Views.Count -eq 0) {
        Write-Log -Source $Source -Message 'No unneeded views to drop.'
    }

    # 'DOMAIN\user' schemas
    $UserSchemas = @($Database.Schemas | Where-Object { $_.Name -like '*\*' })
    foreach ($Schema in $UserSchemas) {
        $SchemaName = $Schema.Name
        $Schema.Drop()
        Write-Log -Source $Source -Message ('Dropped schema {0}.' -f $SchemaName)
    }
    if ($UserSchemas.Count -eq 0) {
        Write-Log -Source $Source -Message 'No unneeded schemas to drop.'
    }

    # schemas owned by users go to dbo so the users can be dropped
    $UserNames = @($Database.Users | Where-Object { $_.IsSystemObject -ne $true } | ForEach-Object { $_.Name })
    $UserOwnedSchemas = @($Database.Schemas | Where-Object { $_.IsSystemObject -eq $false -and $_.Owner -in $UserNames })
    foreach ($Schema in $UserOwnedSchemas) {
        $Schema.Owner = 'dbo'
        $Schema.Alter()
        Write-Log -Source $Source -Message ('Schema {0} owner changed to dbo.' -f $Schema.Name)
    }

    # roles, only replaced when we have an export to put back
    if (-not $Refresh.RoleFile) {
        Write-Log -Source $Source -Message 'No role export, restored roles kept.' -Level Warn
    }
    elseif (-not (Test-Path -Path $Refresh.RoleFile)) {
        Write-Log -Source $Source -Message ('Role file {0} not found, restored roles kept.' -f $Refresh.RoleFile) -Level Warn
    }
    else {
        $Roles = @($Database.Roles | Where-Object { $_.IsFixedRole -ne $true -and $_.Name -ne 'public' -and $_.Name -notlike 'aspnet*' })
        foreach ($Role in $Roles) {

            # a role that owns schemas or has members cannot be dropped
            foreach ($Schema in @($Database.Schemas | Where-Object { $_.Owner -eq $Role.Name })) {
                $Schema.Owner = 'dbo'
                $Schema.Alter()
                Write-Log -Source $Source -Message ('Schema {0} owner changed to dbo.' -f $Schema.Name)
            }
            foreach ($Member in @($Role.EnumMembers())) {
                $Role.DropMember($Member)
            }

            $RoleName = $Role.Name
            $Role.Drop()
            Write-Log -Source $Source -Message ('Dropped role {0}.' -f $RoleName)
        }

        $null = Invoke-DbaQuery -SqlInstance $Refresh.Listener -Database $Refresh.TargetDb -File $Refresh.RoleFile -EnableException
        Write-Log -Source $Source -Message 'Exported roles added.'
    }

    # users, only replaced when we have an export to put back
    if (-not $Refresh.UserFile) {
        Write-Log -Source $Source -Message 'No user export, restored users kept.' -Level Warn
    }
    elseif (-not (Test-Path -Path $Refresh.UserFile)) {
        Write-Log -Source $Source -Message ('User file {0} not found, restored users kept.' -f $Refresh.UserFile) -Level Warn
    }
    else {
        $Users = @($Database.Users | Where-Object { $_.IsSystemObject -ne $true })
        foreach ($User in $Users) {
            $UserName = $User.Name
            $User.Drop()
            Write-Log -Source $Source -Message ('Dropped user {0}.' -f $UserName)
        }

        $null = Invoke-DbaQuery -SqlInstance $Refresh.Listener -Database $Refresh.TargetDb -File $Refresh.UserFile -EnableException
        Write-Log -Source $Source -Message 'Exported users added.'
    }
}


function Invoke-ImportSynonymStep {
    <#
    .SYNOPSIS
        Replaces the restored synonyms with the exported ones.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Source = $Refresh.TargetDb

    if (-not $Refresh.SynonymFile) {
        Write-Log -Source $Source -Message 'No synonyms persisted.'
        return
    }

    if (-not (Test-Path -Path $Refresh.SynonymFile)) {
        Write-Log -Source $Source -Message ('Synonym file {0} not found, restored synonyms kept.' -f $Refresh.SynonymFile) -Level Warn
        return
    }

    $Database = Get-RefreshDatabase -Refresh $Refresh
    $Synonyms = @($Database.Synonyms)
    foreach ($Synonym in $Synonyms) {
        $Synonym.Drop()
    }
    Write-Log -Source $Source -Message ('Dropped {0} restored synonym(s).' -f $Synonyms.Count)

    $null = Invoke-DbaQuery -SqlInstance $Refresh.Listener -Database $Refresh.TargetDb -File $Refresh.SynonymFile -EnableException
    Write-Log -Source $Source -Message 'Exported synonyms added.'
}


function Invoke-ImportDataStep {
    <#
    .SYNOPSIS
        Copies the persisted tables back from staging, keeping identity values and nulls.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Source = $Refresh.TargetDb
    $StagingDb = $Context.Settings.StagingDb

    $Tables = @(([string]$Refresh.PersistTable).Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($Tables.Count -eq 0) {
        Write-Log -Source $Source -Message 'No data persisted.'
        return
    }

    Write-Log -Source $Source -Message 'Importing tables ...'
    foreach ($Table in $Tables) {
        $SourceTable = '{0}-{1}' -f $Refresh.TargetDb, $Table

        $CopySplat = @{
            SqlInstance         = $Refresh.Primary
            Database            = $StagingDb
            Table               = $SourceTable
            DestinationDatabase = $Refresh.TargetDb
            DestinationTable    = $Table
            Truncate            = $true
            KeepIdentity        = $true
            KeepNulls           = $true
            EnableException     = $true
        }
        $Result = Copy-DbaDbTableData @CopySplat

        Write-Log -Source $Source -Message ('{0}.{1} copied to {2} ({3} rows).' -f $StagingDb, $SourceTable, $Table, $Result.RowsCopied)
    }
}


function Invoke-TransformStep {
    <#
    .SYNOPSIS
        DAC = publish dacpac, REP = replace environment references in procs/functions/views, blank = nothing.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Source = $Refresh.TargetDb

    switch ($Refresh.TransformType) {
        'DAC' {
            Invoke-DacpacTransform -Refresh $Refresh -Context $Context
        }
        'REP' {
            $Database = Get-RefreshDatabase -Refresh $Refresh

            if ($Refresh.ReplaceSp) {
                $Procedures = @($Database.StoredProcedures | Where-Object { $_.IsSystemObject -eq $false })
                Update-ObjectReference -Refresh $Refresh -Context $Context -Object $Procedures -Pairs $Refresh.ReplaceSp -Tag 'sp' -Label 'stored procedures'
            }

            if ($Refresh.ReplaceFn) {
                $Functions = @($Database.UserDefinedFunctions | Where-Object { $_.IsSystemObject -eq $false })
                Update-ObjectReference -Refresh $Refresh -Context $Context -Object $Functions -Pairs $Refresh.ReplaceFn -Tag 'fn' -Label 'functions'
            }

            if ($Refresh.ReplaceVw) {
                $Views = @($Database.Views | Where-Object { $_.IsSystemObject -eq $false })
                Update-ObjectReference -Refresh $Refresh -Context $Context -Object $Views -Pairs $Refresh.ReplaceVw -Tag 'vw' -Label 'views'
            }
        }
        default {
            Write-Log -Source $Source -Message 'No transform requested.'
        }
    }
}


function Invoke-PostProcessStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    Invoke-ProcessList -Refresh $Refresh -List $Refresh.PostProcess -Kind 'postprocessing'
}


function Invoke-PostBackupStep {
    <#
    .SYNOPSIS
        Full backup to -BackupPath or the folder of the last full.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Latest = Get-LatestBackup -Refresh $Refresh -Context $Context
    $Folder = Get-BackupFolder -Backup $Latest.Full -Context $Context

    if (-not $Folder) {
        throw ('Could not determine the full backup location for {0}.' -f $Refresh.TargetDb)
    }

    Invoke-RefreshBackup -Refresh $Refresh -Context $Context -Type Full -Tag 'POST' -Folder $Folder -CleanupHours $Context.PostBackupCleanup
}


function Invoke-ShrinkLogStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    Write-Log -Source $Refresh.TargetDb -Message 'Shrinking log ...'
    $Result = Invoke-DbaDbShrink -SqlInstance $Refresh.Listener -Database $Refresh.TargetDb -FileType Log -ExcludeIndexStats -EnableException
    Write-Table -InputObject $Result -DetailOnly
    Write-Log -Source $Refresh.TargetDb -Message 'Log shrink completed.'
}


function Invoke-RecoveryModelStep {
    <#
    .SYNOPSIS
        Sets SIMPLE recovery when the database is in FULL. Replaces Set-SimpleMode.ps1. Skipped for AG databases.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Refresh,

        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    $Source = $Refresh.TargetDb

    if ($Refresh.IsAg) {
        Write-Log -Source $Source -Message 'In an AG, recovery model must stay FULL. Skipping.' -Level Warn
        return
    }

    $Database = Get-RefreshDatabase -Refresh $Refresh
    if ($Database.RecoveryModel -ne 'Full') {
        Write-Log -Source $Source -Message ('Recovery model already {0}.' -f $Database.RecoveryModel)
        return
    }

    $null = Set-DbaDbRecoveryModel -SqlInstance $Refresh.Primary -Database $Refresh.TargetDb -RecoveryModel Simple -Confirm:$false -EnableException
    Write-Log -Source $Source -Message 'Recovery model set to SIMPLE.'
}
