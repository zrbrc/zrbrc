<#
.SYNOPSIS
  Refreshes a group of databases--Prod to TEST, PT, SIT, or DEV.
.DESCRIPTION
  Some more words go here.
.PARAMETER CallingFile
  Mandatory. This is a string of the file that called this script. This is used to determine when the calling script was last updated. Used for internal processing.
.PARAMETER WorkingPath
  Mandatory. This is where all the output files will be generated; logs, exports, trn, etc. This was changed to be set manually as it was too difficult to
  funcitonally choose a location with all of our environments.
.PARAMETER RequestFile
  Mandatory. This is a list of the target dbs that you want restored/refreshed.
.PARAMETER DbConfigFile
  Optional. This is a path to the Db Config File. It is optional as it will use the default file unless passed something to override it.
.PARAMETER Notify
  Optional. This will send notifitcations via email for errors, completions, and a final report.
.PARAMETER UseDiff
  Optional. This will bring in diffs for the restore process, else it will only use fulls.
.PARAMETER SkipPreBackup
  Optional. This will skip the diff or full before the restores.
.PARAMETER SkipPostBackup
  Optional. This will skip the full after the restores.
.PARAMETER SkipRestore
  Optional. This will skip the restore and only do checking and post-processing. For testing purposes mainly.
.PARAMETER SkipPreProcessing
  Optional. This will skip pre processing.
.PARAMETER SkipPostProcessing
  Optional. This will skip post processing.
.PARAMETER LocalFile
  Optional. This will make the process use the backup paths as is and not create a mapping with credentials to the path. Good for using files in the same domain/zone.
.PARAMETER ShrinkLog
  Optional. This will shrink the log files as the last step.
.PARAMETER Verify
  Optional. This will force the confirmation for each DB before making changes. You can answer 'a' to skip remaining prompts when running.
.PARAMETER BackupPath
  Optional. This is for pre and post backups, if you want to override the latest backup path logic and set your own.
.PARAMETER Verbose
  Optional. This is a standard PS parameter, but it will also show some extra output for debugging purposes.
.OUTPUTS
  Log and working files are stored at $RefreshRootDated, see line 120 for value.
.NOTES
  Version:        5.0
  Author:         Ryan Zerbe
  Creation Date:  2020-02
  Purpose/Change: New Features, Restart, MessageLog, Data Gather First.
.EXAMPLE
  .\Refresh-Database.ps1 -RequestFile .\Request\Refreshes.txt -Notify ryan@gmail.com
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ } )]
    [string]$CallingScript,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ } )]
    [string]$WorkingPath,

    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ } )]
    [string]$RequestFile,

    [ValidateScript( { Test-Path $_ } )]
    [string]$DbConfigFile = '.\config\DbConfig.csv',

    # [ValidateScript( { Test-Path $_ } )] 
    # we are assuming you know the path. It may not be accessible from where the script is executing, 
    # but is from the instance where the backup will happen, so we are not validating the path.
    [string]$BackupPath,
       
    [array]$Notify,
    [switch]$Verify,
    [switch]$LocalFile,
    [switch]$UseDiff,
    [switch]$SkipPreBackup,
    [switch]$SkipRolesUsers,
    [switch]$SkipSynonyms,
    [switch]$SkipPreProcess,
    [switch]$SkipRestore,
    [switch]$SkipTransform,
    [switch]$SkipPostProcess,
    [switch]$SkipPostBackup,
    [switch]$SkipShrinkLog,
    [switch]$SkipFileRename,
    [switch]$SkipDbOwner
)

@"
   _ _           ___             _   
 _| | |_ ___ ___|  _|___ ___ ___| |_ 
| . | . |  _| -_|  _|  _| -_|_ -|   |
|___|___|_| |___|_| |_| |___|___|_|_|

"@

#Requires -Module dbatools,SqlServer

####################################################################################################
# Step A: Initialization
####################################################################################################
try {
    Set-Location $PSScriptRoot
    $ProgressPreference = 'SilentlyContinue'
    Write-Output 'Initializing ...'
    $DateStamp = Get-Date -Format 'yyyyMMdd'
    $TimeStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $Source = 'Init'
 
    # filters for log backups we want to disable/enable during refresh process, can be full name or wildcard
    $SSAExcludeFilter = ''
    $SSAIncludeFilter = @('DatabaseBackup - USER_DATABASES - LOG', 'DatabaseBackup - USER_DATABASES - LOG - NUL')

    # initialize some variables
    $RefreshData = @()
    $DpPaths = @()
    $Dacpacs = @()

    # default email settings
    $emailsplat = @{
        From       = 'email@domain.com'
        SmtpServer = 'smtp.domain.com' 
    }

    # set include files and test path
    $HtmlHeadFile = (Get-Item -Path ".\include\HtmlHeader.ps1").FullName
    $DacOptionsFile = (Get-Item -Path ".\include\DacOptions.ps1").FullName
    
    <# F U N C T I O N S #>
    Write-Output 'Importing functions ...'
    Get-ChildItem -Path '.\function' -Filter '*.ps1' | ForEach-Object {
        . $_.FullName
    }

    # staging db for persisting data
    $StagingDB = 'Refresh_Staging'

    # set full working path, appends refresh and datestamp
    $RefreshRootDated = $WorkingPath + '\refresh\' + $DateStamp
    
    # set and create working folders
    $LogPath = $RefreshRootDated + '\log'
    $ExportPath = $RefreshRootDated + '\export'
    $TrnPath = $RefreshRootDated + '\trn'
    $RefreshDataPath = $RefreshRootDated + '\data'
    $RefreshDataArchivePath = $RefreshDataPath + '\archive'
    
    Write-MessageLog -Source $Source -Message "Creating working folders ..." -Type Info
    if (-not (Test-Path $LogPath -PathType Container)) { $null = New-Item -Path $LogPath -ItemType Directory }
    if (-not (Test-Path $ExportPath -PathType Container)) { $null = New-Item -Path $ExportPath -ItemType Directory }
    if (-not (Test-Path $TrnPath -PathType Container)) { $null = New-Item -Path $TrnPath -ItemType Directory }
    if (-not (Test-Path $RefreshDataPath -PathType Container)) { $null = New-Item -Path $RefreshDataPath -ItemType Directory }
    if (-not (Test-Path $RefreshDataArchivePath -PathType Container)) { $null = New-Item -Path $RefreshDataArchivePath -ItemType Directory }
    
    # loads requestfile
    $Requests = Get-Content -Path $RequestFile | Select-String '^[^#]' | ConvertFrom-Csv -Delimiter ';'
    Write-MessageLog -Source $Source -Message "Loaded $RequestFile request file." -Type Info
    
    # sets req name and data file names
    $ReqName = (Get-Item -Path $RequestFile).BaseName
    $DataFile = $RefreshDataPath + '\' + $ReqName + '_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.xml'

    # loads db config file
    $DbConfig = Get-Content -Path $DbConfigFile | Select-String '^[^#]' | ConvertFrom-Csv
    Write-MessageLog -Source $Source -Message "Loaded $DbConfigFile db config file." -Type Info

    # disable quick edit mode
    Write-MessageLog -Source $Source -Message (Disable-QuickEditMode) -Type Info

    # check for and import all needed modules
    Write-MessageLog -Source $Source -Message 'Loading modules, may take a minute.' -Type Info
    if (Get-Module dbatools -ListAvailable) { 
        Import-Module dbatools
    }
    else {
        Write-MessageLog -Source $Source -Message 'dbatools module not found.' -Type Crit
        throw
    }

    if (Get-Module SqlServer -ListAvailable) { 
        Import-Module SqlServer
    }
    else {
        Write-MessageLog -Source $Source -Message 'SqlServer module not found.' -Type Crit
        throw
    }

    # start logging
    $LogFile = $LogPath + '\' + $ReqName + '_' + $TimeStamp + '.txt'
    Write-MessageLog -Source $Source -Message (Start-Transcript -Path $LogFile) -Type Info
}
catch {
    $ErrorException = $_.Exception
    Write-MessageLog -Source $Source -Message $ErrorException.Message -Type Crit
    Write-MessageLog -Source $Source -Message 'Error during initialization.' -Type Crit
    $MessageLog | Select-Object -Property Date, Time, Type, Message | Format-Table -AutoSize | Out-String -Width 500
    Read-Host '::: Initization failed. Press ENTER to exit. ::'
    throw
}

####################################################################################################
# Step B: Creates Credential Object for shared path
####################################################################################################
try {
    $Source = 'Credential'
    if ($LocalFile) {
        Write-MessageLog -Source $Source -Message 'Skipping credential routine.' -Type Info
    }
    else {
        $SqlAdminRefresh = 'domain\sqladmin.refresh'
        $SqlAdminRefreshPw = Get-SecuredPassword -Login $SqlAdminRefresh
    }
}
catch {
    $ErrorException = $_.Exception
    Write-MessageLog -Source $Source -Message $ErrorException.Message -Type Crit
    Write-MessageLog -Source $Source -Message 'Error during shared path credential routine.' -Type Crit
    $MessageLog | Select-Object -Property Date, Time, Type, Message | Format-Table -AutoSize | Out-String -Width 500
    throw
}

####################################################################################################
# Sanity Check
####################################################################################################

# verify no backups are running
if ($Verify) {
    do {                
        $Continue = Read-Host "`n`n[?] Did you verify the regularly scheduled Full/Diff backups are completed on the instance(s)? (y)es/(n)o "
    } until ($Continue.ToUpper() -in 'Y', 'N')
    if ($Continue.ToUpper() -ne 'Y') { exit }
}

# display what was requested
Write-Output "`n= = =  P A S S E D  P A R A M E T E R S  = = ="
$PSBoundParameters | Format-Table -AutoSize | Out-String -Width 500
Write-Output "= = =  R E Q U E S T E D  D A T A B A S E S  = = ="
$Requests | Format-Table -AutoSize | Out-String -Width 500

# sanity check for testing and manual runs
if ($Verify) {
    do {                
        $Continue = Read-Host "[?] Is this correct? (y)es/(n)o "
    } until ($Continue.ToUpper() -in 'Y', 'N')
    if ($Continue.ToUpper() -ne 'Y') { Exit }
}

####################################################################################################
# Step C: Data gather loop
####################################################################################################
try {
    $Source = 'Gather'
    Write-MessageLog -Source $Source -Message "# START: $Source" -Type Info
    
    # this looks for a data folder and file with todays date
    Write-MessageLog -Source $Source -Message "Checking for existing data file ..." -Type Info
    
    # if we found a file
    if ($RestartDataFile = Get-ChildItem -Path $RefreshDataPath -Filter ($ReqName + '_' + (Get-Date -Format 'yyyyMMdd') + '*.xml') -File | Sort-Object LastWriteTime | Select-Object -Last 1) {
        Write-MessageLog -Source $Source -Message 'Data file with today''s date found, checking for incomplete refreshes ...' -Type Info
        
        # load refresh data
        $RefreshData = Import-Clixml -Path $RestartDataFile.FullName
        
        # if we have incomplete refreshes, use this file and restart, else initialize RefreshData so below process can populate it with new data.
        if ($RefreshData | Where-Object { $_.Status -eq 'NONE' }) {
            
            # if the request file or the runner calling script was updated since refresh data file was created, consider this a new refresh request.
            if (((Get-Item -Path $RequestFile -ErrorAction SilentlyContinue).LastWriteTime -gt $RestartDataFile.LastWriteTime) -or 
                ((Get-Item -Path $CallingScript -ErrorAction SilentlyContinue).LastWriteTimee -gt $RestartDataFile.LastWriteTime)) {
                Write-MessageLog -Source $Source -Message 'Request file or runner script has been updated starting anew.' -Type Info
                $RefreshData = @()
            }
            else {
                $Datafile = $RestartDataFile.FullName
                Write-MessageLog -Source $Source -Message "Attempting to restart using: $DataFile." -Type Info
            }
        }
        else {
            Write-MessageLog -Source $Source -Message 'No resumable refreshes found, starting anew.' -Type Info
            $RefreshData = @()
        }
    }
    else {
        Write-MessageLog -Source $Source -Message "No existing data file found, starting anew." -Type Info
    }
    
    # if no refreshes were found above, start anew, just a check to make sure we dont have data we may overwrite
    if ($RefreshData.Count -eq 0) {
        Write-MessageLog -Source $Source -Message 'Gathering data for refresh ...' -Type Info
        foreach ($Item in $Requests) {

            # find the index of this db in the dbconfig file
            $Index = ($DbConfig.TargetDb).IndexOf($Item.Database)
            
            # make sure we have the correct index and didnt just fall to the end
            if ($Item.Database -eq $DbConfig[$Index].TargetDb) {
                
                # creates base object from request and dbconfig files
                $RefreshObj = [PSCustomObject]@{
                    Status        = 'NONE'
                    LastCompleted = 0
                    TimeTaken     = $null
                    Listener      = $DbConfig[$Index].Listener
                    SourceDb      = $DbConfig[$Index].SourceDb
                    TargetDb      = $Item.Database
                    DataPath      = $DbConfig[$Index].DataPath
                    LogPath       = $DbConfig[$Index].LogPath
                    BakPath       = $DbConfig[$Index].BakPath
                    TransformType = $Item.Transform
                    DacpacPath    = $DbConfig[$Index].DacPacPath
                    ReplaceSp     = $DbConfig[$Index].ReplaceSp
                    ReplaceFn     = $DbConfig[$Index].ReplaceFn
                    ReplaceVw     = $DbConfig[$Index].ReplaceVw
                    PreProcess    = $DbConfig[$Index].PreProcess
                    PostProcess   = $DbConfig[$Index].PostProcess
                    PersistTable  = $DbConfig[$Index].PersistTable
                    RoleFile      = $null
                    UserFile      = $null
                    SynonymFile   = $null
                }
                
                # are we using diffs for restore, this sets a value for the type of backup we are looking for, this a value from a dbatools cmdlet
                if ($PSBoundParameters.ContainsKey('UseDiff')) {
                    $RefreshObj | Add-Member -MemberType NoteProperty -Name 'BackupType' -Value 'Database', 'Database Differential'
                }
                else {
                    $RefreshObj | Add-Member -MemberType NoteProperty -Name 'BackupType' -Value 'Database'
                }

                # sets backup file filter so we can filter on a specific date if needed
                if ($Item.Filter) { 
                    $RefreshObj | Add-Member -MemberType NoteProperty -Name 'BakFilter' -Value $Item.Filter
                } 
                else { 
                    $RefreshObj | Add-Member -MemberType NoteProperty -Name 'BakFilter' -Value '*'
                }

                $RefreshObj | Add-Member -MemberType NoteProperty -Name 'SourceDbEnv' -Value ('_' + ($RefreshObj.SourceDB).Split('_')[-1])
                $RefreshObj | Add-Member -MemberType NoteProperty -Name 'TargetDbEnv' -Value ('_' + ($RefreshObj.TargetDB).Split('_')[-1])

                <#
                Note: Below we are checking if the DB and AG exist, but not that the DB is in the AG, that logic to control the end result
                of the DB being in the AG is done by the input dbconfig file. This is a shortcut in case there is an error. If we have
                a failure at some point, its much easier to recover just 1 replica than putting it back in the AG. The refresh process will
                still do restores to both replicas and after put the DB in the AG.
                #>

                # checks the the DB exists so we can export data from it
                if (-not (Get-DbaDatabase -SqlInstance $RefreshObj.Listener -Database $RefreshObj.TargetDb -EnableException)) {
                    Write-MessageLog -Source $Source -Message "$($RefreshObj.TargetDb) does not exist on $($RefreshObj.Listener). Skipping." -Type Error
                    Continue
                }
                
                # if an AG, gets replica info--else sets as not AG and treats the 'listener' as a standalone.
                if ($DbConfig[$Index].Ag) {
                    $AgName = $DbConfig[$Index].Ag
                    $reps = (Get-SqlInstance -ServerInstance $RefreshObj.Listener).AvailabilityGroups[$AgName].AvailabilityReplicas | Select-Object Name, Role

                    if ($reps) {
                        # fix this here to save right
                        $repobj = foreach ($rep in $reps) {
                            [PSCustomObject]@{
                                Name = $rep.Name
                                Role = $rep.Role.ToString()
                            }
                        }
                        $RefreshObj | Add-Member -MemberType NoteProperty -Name 'IsAg' -Value $true
                        $RefreshObj | Add-Member -MemberType NoteProperty -Name 'Ag' -Value $DbConfig[$Index].Ag
                        $RefreshObj | Add-Member -MemberType NoteProperty -Name 'Replicas' -Value $repobj
                        $RefreshObj | Add-Member -MemberType NoteProperty -Name 'Primary' -Value ($repobj | Where-Object { $_.Role -eq 'Primary' }).Name
                        $RefreshObj | Add-Member -MemberType NoteProperty -Name 'Secondary' -Value ($repobj | Where-Object { $_.Role -eq 'Secondary' }).Name
                    }
                    else {
                        Write-MessageLog -Source $Source -Message "An AG was set for $($Item.Database), but no replicas were found. Skipping." -Type Error
                        continue
                    }
                }
                else {
                    $repobj = [PSCustomObject]@{
                        Name = $DbConfig[$Index].Listener
                        Role = 'Primary'
                    }
                    $RefreshObj | Add-Member -MemberType NoteProperty -Name 'IsAg' -Value $false
                    $RefreshObj | Add-Member -MemberType NoteProperty -Name 'Replicas' -Value $repobj
                    $RefreshObj | Add-Member -MemberType NoteProperty -Name 'Primary' -Value ($repobj | Where-Object { $_.Role -eq 'Primary' }).Name
                }
                
                # checks for passed FileMappings and create a hashtable to pass to restore cmdlet,
                # hashtable is expected input for restore cmdlet when moving secondary data files
                if ($DbConfig[$Index].FileMapping) {
                    $FileMapArray = ($DbConfig[$Index].FileMapping).Split(',')
                    $FileHash = @{ }
                    foreach ($Item in $FileMapArray) {
                        $tmpKey = $Item.Split('=')[0]
                        $tmpValue = $Item.Split('=')[1]
                        $FileHash.Add($tmpKey.Trim(), $tmpValue.Trim())
                    }
                    $RefreshObj | Add-Member -MemberType NoteProperty -Name 'FileMapping' -Value $FileHash
                }
            
                # set owner details for post restore
                switch ($env:USERDOMAIN) {
                    'APPSDEV' {
                        $RefreshObj | Add-Member -MemberType NoteProperty -Name 'DbOwner' -Value 'APPSDEV\sqladmin'
                    }
                    'APPSTEST' {
                        $RefreshObj | Add-Member -MemberType NoteProperty -Name 'DbOwner' -Value 'APPSTEST\sqladmin.test'
                    }
                    default {
                        $RefreshObj | Add-Member -MemberType NoteProperty -Name 'DbOwner' -Value "$env:USERDOMAIN\$env:USERNAME"
                    }
                }
                
                # adds the data row to table
                $RefreshData += $RefreshObj     
            } 
            else {
                Write-MessageLog -Source $Source -Message "$($Item.Database) was not found in the config file. Skipping." -Type Error
                continue
            }
        }
    }

    # this will display all data gathered, but only when the verbose switch is passed,
    # else we only see the data for each refresh as it processes
    if ($VerbosePreference -eq 'Continue') {
        Write-Output "`n= = = A L L  R E F R E S H  D A T A = = ="
        $RefreshData | Format-Table -Property Status, LastCompleted, Listener, SourceDb, TargetDb -AutoSize | Out-String -Width 500
    }
    Write-MessageLog -Source $Source -Message "# END  : $Source" -Type Info
}
catch {
    $ErrorException = $_.Exception
    Write-MessageLog -Source $Source -Message $ErrorException.Message -Type Crit
    Write-MessageLog -Source $Source -Message 'Error during data gather routine.' -Type Crit
    $MessageLog | Select-Object -Property Date, Time, Type, Message | Format-Table -AutoSize | Out-String -Width 500
    throw
}

$RefreshData | Export-Clixml -Path $DataFile

####################################################################################################
# main process
####################################################################################################
try {
    :refresh foreach ($Refresh in $RefreshData | Where-Object { $_.Status -ne 'COMPLETED' }) {

        ####################################################################################################
        # Display refresh details
        ####################################################################################################
        $StartTime = Get-Date
        Write-Output "`n= = =  R E F R E S H  D E T A I L S  = = ="
        $Refresh | Format-List | Out-String -Width 500
        if ($VerbosePreference -eq 'Continue') { $Refresh.FileMapping | Format-Table -AutoSize | Out-String -Width 500 }

        # some inits for the refresh
        $HeaderSql = @()
        $HeaderSql += "USE [$($Refresh.TargetDb)]"
        $HeaderSql += 'GO'
        
        # sanity check for each refresh
        if ($Verify) {
            if ($Continue -ne 'a') {
                do {                
                    $Continue = Read-Host "[?] Continue? (y)es/(n)o/(a)ll "
                } until ($Continue.ToUpper() -in 'Y', 'N', 'A')
                if ($Continue.ToUpper() -eq 'N') {
                    Write-MessageLog -Source 'Verify' "Skipping $($Refresh.TargetDb)." -Type Warn
                    continue refresh
                }
            }
        }
        
        # get database SMO
        $Database = Get-DbaDatabase -SqlInstance $Refresh.Primary -Database $Refresh.TargetDb -EnableException

        # get last 2 weeks of backup history, diff and full, will be used later
        # getting from each replica in case a failover happened and current primary doesnt have the history
        $BackupHitory = Get-DbaDbBackupHistory -SqlInstance $Refresh.Replicas.Name -Database $Refresh.TargetDb -IncludeCopyOnly -Type Full, Differential -Since (Get-Date).AddDays(-14)

        # get just the latest of each backup type, we grab this info before bc the incoming restore might have a Prod backup path and that wont work in test
        $LastDiff = $BackupHitory | Where-Object { $_.Type -eq 'Differential' } | Sort-Object Start -Descending | Select-Object -First 1
        $LastFull = $BackupHitory | Where-Object { $_.Type -eq 'Full' } | Sort-Object Start -Descending | Select-Object -First 1

        ####################################################################################################
        # Step 1: Performs diff or full backup, can be skipped with switch
        ####################################################################################################
        $StepName = '1-Diff Backup'
        if ($Refresh.LastCompleted -lt 1) {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# START: $StepName" -Type Info
                
            # skip diff backup if requested
            if ($SkipPreBackup) {
                Write-MessageLog -Source $Refresh.TargetDb -Message "Pre-backup being skipped." -Type Warn
            }
            else {
                # if we explicitly set a path, then use for diff, else try a diff, else try a full, if none, fail
                if ($PSBoundParameters.ContainsKey('BackupPath')) {
                    Write-MessageLog -Source $Refresh.TargetDb -Message "BackupPath set: $BackupPath" -Type Verbose
                    $BakPath = $BackupPath

                    Write-MessageLog -Source $Refresh.TargetDb -Message "Performing diff backup of $($Refresh.TargetDb) to $BakPath." -Type Info
                    Backup-SqlDatabase -ServerInstance $Refresh.Listener -Database $Refresh.TargetDb -Incremental -BackupFile ($BakPath + '\' + $Refresh.TargetDB + '-DIFF-' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.bak') -CompressionOption On -Verbose -ErrorAction Stop
                    Write-MessageLog -Source $Refresh.TargetDb -Message "Diff backup completed on $($Refresh.TargetDb)." -Type Info
                }
                elseIf ($LastDiff) {
                    $BakPath = Split-Path -Path $LastDiff.Path -Parent

                    Write-MessageLog -Source $Refresh.TargetDb -Message "Performing diff backup of $($Refresh.TargetDb) to $BakPath." -Type Info
                    Backup-SqlDatabase -ServerInstance $Refresh.Listener -Database $Refresh.TargetDb -Incremental -BackupFile ($BakPath + '\' + $Refresh.TargetDB + '-DIFF-' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.bak') -CompressionOption On -Verbose -ErrorAction Stop
                    Write-MessageLog -Source $Refresh.TargetDb -Message "Diff backup completed on $($Refresh.TargetDb)." -Type Info
                }
                elseif ($LastFull) {
                    $BakPath = Split-Path -Path $LastFull.Path -Parent

                    Write-MessageLog -Source $Refresh.TargetDb -Message "Couldn't determine diff backup location, performing full." -Type Warn

                    Write-MessageLog -Source $Refresh.TargetDb -Message "Performing full backup of $($Refresh.TargetDb) to $BakPath." -Type Info
                    Backup-SqlDatabase -ServerInstance $Refresh.Listener -Database $Refresh.TargetDb -BackupFile ($BakPath + '\' + $Refresh.TargetDB + '-FULL-' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.bak') -CompressionOption On -Verbose -ErrorAction Stop
                    Write-MessageLog -Source $Refresh.TargetDb -Message "Full backup completed on $($Refresh.TargetDb)." -Type Info
                }
                else {
                    Write-MessageLog -Source $Refresh.TargetDb -Message "Couldn't determine diff or full backup location, skipping rest of refresh process for $($Refresh.TargetDb)." -Type Error
                    continue refresh
                }
            }

            $Refresh.LastCompleted = 1
            Write-MessageLog -Source $Refresh.TargetDb -Message "# END  : $StepName" -Type Info
        }
        else {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# SKIP : $StepName" -Type Info
        }

        $RefreshData | Export-Clixml -Path $DataFile
        
        ####################################################################################################
        # Step 2: Export Principals
        ####################################################################################################
        $StepName = '2-Export Roles and Users'
        if ($Refresh.LastCompleted -lt 2) {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# START: $StepName" -Type Info

            if ($SkipRolesUsers) {
                Write-MessageLog -Source $Refresh.TargetDb -Message "Role and Users being skipped." -Type Warn
            }
            else {
                # capture roles and permissions other than public
                $Roles = $Database.Roles | Where-Object { $_.IsFixedRole -ne $true -and $_.Name -notin "public" }
                if ($Roles.count -ne 0) {
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'Exporting roles ...' -Type Info

                    $RoleParentSql = @()
                    $RoleSql = @()
                    $RoleFile = $ExportPath + '\' + $Refresh.TargetDb + '_roles_' + $TimeStamp + '.sql'
                
                    foreach ($Role in $Roles) {
                    
                        # default to not a parent role
                        $ParentRole = $false

                        # this is special check for nested roles, we need to script out the parent roles first, this handles that
                        # by checking to see if the member is another role, we cant add a child role to the parent role until
                        # the parent role exists, this handles that sequencing
                        foreach ($Member in $Role.EnumMembers()) {
                            if ($Member -in $Roles.Name) {
                                $ParentRole = $true
                            }
                        }

                        if ($ParentRole) {
                            Write-Output "`tParent Role: $($Role.Name)"
                            $RoleParentSql += Export-SqlDbPermission -Database $Database -Principal $Role 
                        }
                        else {
                            Write-Output "`t$($Role.Name)"
                            $RoleSql += Export-SqlDbPermission -Database $Database -Principal $Role 
                        }
                    }

                    # if we had roles to export, save to file and add info to RefreshData
                    if ($RoleSql -or $RoleParentSql) {
                        $HeaderSql + $RoleParentSql + $RoleSql | Out-File -FilePath $RoleFile -Encoding UTF8
                        Write-MessageLog -Source $Refresh.TargetDb -Message "Roles exported to $RoleFile." -Type Info
                        $Refresh.RoleFile = $RoleFile
                    }
                }
                else {
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'No roles exported.' -Type Info
                }
                
                # creates sql for users, permissions, and role membership
                $Users = $Database.Users | Where-Object { $_.IsSystemObject -eq $false -and $_.Name -notlike "##*" -and $_.Name -notlike "domain\*" }
                if ($Users.count -ne 0) {
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'Exporting users ...' -Type Info
                    $UserFile = $ExportPath + '\' + $Refresh.TargetDb + '_users_' + $TimeStamp + '.sql'
                
                    $UserSql = @()
                    foreach ($User in $Users) {
                        $UserSql += Export-SqlDbPermission -Database $Database -Principal $User 
                        Write-Output "`t$($User.Name)"
                    }

                    # if we had users to export, save to file and add info to RefreshData
                    if ($UserSql) {
                        $HeaderSql + $UserSql | Out-File -FilePath $UserFile -Encoding UTF8
                        Write-MessageLog -Source $Refresh.TargetDb -Message "Users exported to $UserFile." -Type Info
                        $Refresh.UserFile = $UserFile
                    }
                }
                else {
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'No users exported.' -Type Info
                }
            }

            $Refresh.LastCompleted = 2
            Write-MessageLog -Source $Refresh.TargetDb -Message "# END  : $StepName" -Type Info
        }
        else {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# SKIP : $StepName" -Type Info
        }

        $RefreshData | Export-Clixml -Path $DataFile
        
        ####################################################################################################
        # Step 3: Export Synonyms
        ####################################################################################################
        $StepName = '3-Export Synonyms'
        if ($Refresh.LastCompleted -lt 3) {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# START: $StepName" -Type Info
            
            if ($SkipSynonyms) {
                Write-MessageLog -Source $Refresh.TargetDb -Message "Synonyms being skipped." -Type Warn
            }
            else {
                $Synonyms = $Database.Synonyms
                if ($Synonyms.count -ne 0) {
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'Exporting synonyms ...' -Type Info
                    $SynonymFile = $ExportPath + '\' + $Refresh.TargetDb + '_synonyms_' + $TimeStamp + '.sql'

                    Export-SqlDbObject -Database $Database -Object $Synonyms | Out-File $SynonymFile
                    $Refresh.SynonymFile = $SynonymFile
                }
            }

            $Refresh.LastCompleted = 3
            Write-MessageLog -Source $Refresh.TargetDb -Message "# END  : $StepName" -Type Info
        } 
        else {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# SKIP : $StepName" -Type Info
        }

        $RefreshData | Export-Clixml -Path $DataFile
        
        ####################################################################################################
        # Step 4: Export data to persist
        ####################################################################################################
        $StepName = '4-Export Data'
        if ($Refresh.LastCompleted -lt 4) {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# START: $StepName" -Type Info

            # if a table was requested to persist,copy to staging file
            if ($Refresh.PersistTable) {
                
                # checks if staging database exists, if not, quietly creates it
                if (-not (Get-DbaDatabase -SqlInstance $Refresh.Primary -Database $StagingDB)) {
                    $null = New-DbaDatabase -SqlInstance $Refresh.Primary -Database $StagingDB -EnableException
                }
                
                Write-MessageLog -Source $Refresh.TargetDb -Message 'Copying tables ...' -Type Info
                
                $tables = ($Refresh.PersistTable).Split(',')
                
                foreach ($table in $tables) {
                    $DestTable = $Refresh.TargetDB + '-' + $table
                    Copy-DbaDbTableData -SqlInstance $Refresh.Primary -Database $Refresh.TargetDB -Table $table -DestinationDatabase $StagingDB -DestinationTable $DestTable -AutoCreateTable -Truncate -EnableException

                    Write-MessageLog -Source $Refresh.TargetDb -Message "$table copied to $DestTable." -Type Info
                }
            }

            $Refresh.LastCompleted = 4
            Write-MessageLog -Source $Refresh.TargetDb -Message "# END  : $StepName" -Type Info
        } 
        else {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# SKIP : $StepName" -Type Info
        }
        
        $RefreshData | Export-Clixml -Path $DataFile

        ####################################################################################################
        # Step 5: Pre-process data
        ####################################################################################################
        $StepName = '5-Preprocess Data'
        if ($Refresh.LastCompleted -lt 5) {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# START: $StepName" -Type Info

            # if pre processing requested to be skipped
            if ($SkipPreProcess) {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'Preprocessing being skipped.' -Type Info
            }
            else {
                # if we have any pre-processing
                if ($Refresh.PreProcess) {
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'Running preprocessing ...'  -Type Info
                    $PreList = ($Refresh.PreProcess).Split(',')
                    foreach ($item in $PreList) {
                        Write-MessageLog -Source $Refresh.TargetDb -Message "Executing $item." -Type Info
                        & $item
                    }
                }
            }

            $Refresh.LastCompleted = 5
            Write-MessageLog -Source $Refresh.TargetDb -Message "# END  : $StepName" -Type Info
        }
        else {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# SKIP : $StepName" -Type Info
        }

        $RefreshData | Export-Clixml -Path $DataFile

        ####################################################################################################
        # Step 6: Restore DBs to replicas
        ####################################################################################################
        $StepName = '6-Restore Database'
        if ($Refresh.LastCompleted -lt 6) {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# START: $StepName" -Type Info

            # skips restore and its related processes if you set the switch
            if ($SkipRestore) {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'Restore being skipped.' -Type Info
            }
            else {

                # if DB is in Ag remove it
                if ($Refresh.IsAg) {

                    if ($Database.Parent.VersionMajor -ge 13) {
                        # set AG seeding mode to manual in case we auto seeded something previously and its still set to auto.
                        foreach ($Replica in $Refresh.Replicas) {
                            Write-MessageLog -Source $Refresh.TargetDb -Message "$($Replica.Name) set to manual seeding mode." -Type Verbose
                            $null = Set-SqlAvailabilityReplica -Path ('SQLSERVER:\SQL\' + $Refresh.Primary + '\AvailabilityGroups\' + $Refresh.Ag + '\AvailabilityReplicas\' + $Replica.Name.Replace('\', '%5C')) -SeedingMode Manual -ErrorAction Stop  <# -ConnectionModeInPrimaryRole AllowAllConnections -ConnectionModeInSecondaryRole AllowNoConnections #>
                        }
                    }
                
                    # drop database from AG if needed
                    if ($Database.AvailabilityGroupName) {
                        Write-MessageLog -Source $Refresh.TargetDb -Message "Removing $($Refresh.TargetDb) from $($Refresh.Ag) ..." -Type Info
                        $null = Remove-SqlAvailabilityDatabase -Path ('SQLSERVER:\SQL\' + $Refresh.Primary + '\AvailabilityGroups\' + $Refresh.Ag + '\AvailabilityDatabases\' + $Refresh.TargetDB) -ErrorAction Stop
                    }
                }

                # set default job status
                $JobFailed = $false
                $Jobs = @()

                Write-MessageLog -Source $Refresh.TargetDb -Message "Starting restores ..." -Type Info
                foreach ($Replica in $Refresh.Replicas) {

                    # use path as from dbconfig file
                    if ($LocalFile) {
                        $ShareRoot = $Refresh.BakPath
                        Write-MessageLog -Source $Refresh.TargetDb -Message "Using local path $ShareRoot from DB Config file." -Type Info
                    }
                    else {
                        # converts '\\server\share\folder\path\backup\full' to just '\\server\share', splits the string by '\' and then rejoins first 4 sections with '\', hint first 2 splits are empty :)
                        $ShareRoot = ($Refresh.BakPath).Split('\')[0..3] -join '\'
                        
                        $result = Invoke-DbaQuery -SqlInstance $Replica.Name -Query "exec xp_cmdshell 'net use $ShareRoot /user:$SqlAdminRefresh $SqlAdminRefreshPw'" | Select-Object -ExpandProperty output -First 1

                        # check output from net use and verify if it worked
                        if ($result -eq 'The command completed successfully.') {

                            # test that share path
                            if (Test-DbaPath -SqlInstance $Replica.Name -Path $ShareRoot -EnableException) {
                                Write-MessageLog -Source $Refresh.TargetDb -Message "$($Replica.Name) - Authenticated to $ShareRoot successfully." -Type Info
                            }
                            else {
                                Write-MessageLog -Source $Refresh.TargetDb -Message "$($Replica.Name) - Authenticated correctly, but the path $ShareRoot is not valid. Skipping this restore." -Type Error
                                continue refresh
                            }
                        }
                        else {
                            Write-MessageLog -Source $Refresh.TargetDb -Message "$($Replica.Name) - $ShareRoot failed to authenticate. Skipping this restore." -Type Error
                            continue refresh
                        }
                    }

                    # find bak files up to 1 folder deep
                    $Files = Get-DbaFile -SqlInstance $Replica.Name -Path $Refresh.BakPath -Depth 2 -FileType 'bak' -EnableException | Select-Object -ExpandProperty Filename

                    # builds a dynamic filter script based on backup type and filename filter specified in the request file
                    $FilterFilename = ( ($Refresh.BakFilter).Split(',') | ForEach-Object { '$_.Path -like "' + $_ + '"' } ) -join ' -or '
                    $FilterScript = [scriptblock]::Create("`$_.Database -eq `$Refresh.SourceDB -and `$_.Type -in `$Refresh.BackupType -and ($FilterFilename)")

                    if ($VerbosePreference -eq 'Continue') { $FilterScript | Out-String -Width 500 }
                    
                    # picks the backup files we want and gets their details
                    $BakFiles = $Files | Get-DbaBackupInformation -SqlInstance $Replica.Name -EnableException | Where-Object -FilterScript $filterscript
                
                    if ($VerbosePreference -eq 'Continue') { $BakFiles | Format-List | Out-String -Width 500 }

                    # if no bak files were found, skip this restore
                    if ($BakFiles.count -eq 0) {
                        Write-MessageLog -Source $Refresh.TargetDb -Message "$($Replica.Name) - Backup files not found for $($Refresh.TargetDb). Skipping this restore." -Type Error
                        continue refresh
                    }
            
                    # disable any LOG backup job that is--enabled, has schedule, notlike 'exclude', like 'include'
                    $SSAJobs = Get-DbaAgentJob -SqlInstance $Replica.Name -EnableException | Where-Object { $_.HasSchedule -eq $true -and $_.Enabled -eq $true -and $_.Name -in $SSAIncludeFilter -and $_.Name -notlike $SSAExcludeFilter }

                    if ($VerbosePreference -eq 'Continue') { $SSAJobs | Format-List | Out-String -Width 500 }

                    if ($SSAJobs.count -ne 0) {
                        foreach ($SSAJob in $SSAJobs) {
                            $null = Set-DbaAgentJob -SqlInstance $Replica.Name -Job $SSAJob -Disabled -EnableException
                            Write-MessageLog -Source $Refresh.TargetDb -Message "$($Replica.Name) - Disabled job $($SSAJob.Name)." -Type Info
                        }
                    }
                    else {
                        Write-MessageLog -Source $Refresh.TargetDb -Message "$($Replica.Name) - No SSA Jobs to disable." -Type Info
                    }

                    # make sure all log backups are completed before we continue
                    Write-MessageLog -Source $Refresh.TargetDb -Message "$($Replica.Name) - Checking for running log backup ..." -Type Info

                    do {
                        $LogJobs = Get-DbaAgentJob -SqlInstance $Replica.Name -EnableException | Where-Object { $_.Name -in $SSAIncludeFilter -and $_.Name -notlike $SSAExcludeFilter }
                                        
                        Start-Sleep 3
                    } until (($LogJobs | Where-Object { $_.CurrentRunStatus -eq 'Executing' }).count -eq 0)

                    # Set Jobname, unneeded, but helpful
                    Write-MessageLog -Source $Refresh.TargetDb -Message "$($Replica.Name) - Restoring $($Refresh.TargetDb)." -Type Info
                    Write-Output "`t$($BakFiles.FullName -join "`n`t")"

                    # create variable splat for restore
                    $RestoreParams = @{
                        SqlInstance         = $Replica.Name
                        DatabaseName        = $Refresh.TargetDb
                        WithReplace         = $true
                        ReplaceDbNameInFile = $true
                        EnableException     = $true
                    }

                    # if secondary we dont recover db
                    if ($Replica.Role -eq 'Secondary') {
                        $RestoreParams.NoRecovery = $true
                    }

                    # if secondary files set the mapping else use default paths
                    if ($Refresh.FileMapping) {
                        $RestoreParams.FileMapping = $Refresh.FileMapping
                    }
                    else {
                        $RestoreParams.DestinationDataDirectory = $Refresh.DataPath
                        $RestoreParams.DestinationLogDirectory = $Refresh.LogPath
                    }
                    
                    if ($VerbosePreference -eq 'Continue') { $RestoreParams | Format-Table -AutoSize | Out-String -Width 500 }

                    if ($Refresh.IsAg) {
                        # start the restore jobs using splat we built above, we are captureing the jobs here so we can check for just their completion below.
                        $Jobs += Start-Job -Name ($Replica.Name + '_' + $Refresh.TargetDb) -ArgumentList $RestoreParams, $BakFiles -ScriptBlock {
                            param($RestoreParams, $BakFiles)
                            $BakFiles | Restore-DbaDatabase @RestoreParams
                        }
                    }
                    else {
                        $BakFiles | Restore-DbaDatabase @RestoreParams
                    }
                }

                if ($Refresh.IsAg) {
                    if ($VerbosePreference -eq 'Continue') { $Jobs | Format-List | Out-String -Width 500 }
                
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'Restore job(s) submitted, waiting for completion ...' -Type Info

                    # waits for jobs to complete

                    # checks status of the restore jobs on each instance
                    $sleep = 0
                    do {
                        # waits 30 ticks before it gets a restore status with 10sec sleeps between ticks = 5mins
                        if ($sleep -ge 30) {
                            $Restores = Get-DbaEstimatedCompletionTime -SqlInstance $Refresh.Replicas.Name | Where-Object { $_.Command -eq 'RESTORE DATABASE' -and $_.Text -like "*$($Refresh.TargetDb)*" }
                            foreach ($item in $Restores) {
                                "{0} - {1} Percent: {2:n2}% Left: {3}" -f $item.SqlInstance, $Refresh.TargetDb, $item.PercentComplete, $item.EstimatedTimeToGo
                            }
                            $sleep = 0 # rest sleep tick after outputting info
                        }
                        Start-Sleep -Seconds 10 # sleep for 10 sec
                        $sleep++
                    } while ( $Jobs | Get-Job | Where-Object { $_.State -eq 'Running' } )

                    if ($VerbosePreference -eq 'Continue') { $Jobs | Format-List | Out-String -Width 500 }

                    foreach ($j in $Jobs) {
                        $j | Receive-Job | Format-List | Out-String -Width 500 # receives output of jobs to display
                        if ($j.State -like 'Failed') {
                            # checks for failed jobs
                            Write-MessageLog -Source $Refresh.TargetDb -Message "$($j.Name) restore job failed." -Type Error
                            Write-MessageLog -Source $Refresh.TargetDb -Message $j.Error -Type Error
                            $JobFailed = $true
                        }
                        $null = $j | Remove-Job # removes job from the queue and surpresses output
                    }
            
                    # if a job failed, we will not continue with the rest of the process for this DB
                    if ($JobFailed -eq 'True') {
                        Write-MessageLog -Source $Refresh.TargetDb -Message "Restore of $($Refresh.TargetDb) failed, skipping rest of resfresh process for this DB." -Type Error
                        continue refresh
                    }
                    else {
                        Write-MessageLog -Source $Refresh.TargetDb -Message "Initial restores completed for $($Refresh.TargetDb)." -Type Info
                    }

                    Write-MessageLog -Source $Refresh.TargetDb -Message "$($Refresh.Primary) - Creating log backup of $($Refresh.TargetDb)." -Type Info
                    $TrnFilePath = $TrnPath + '\' + $Refresh.TargetDB + '-LOG-' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.trn'
                    Backup-SqlDatabase -ServerInstance $Refresh.Listener -Database $Refresh.TargetDb -BackupAction Log -BackupFile $TrnFilePath -CompressionOption On -Verbose

                    # restore log backup to secondaries
                    foreach ($Secondary in $Refresh.Secondary) {
                        Write-MessageLog -Source $Refresh.TargetDb -Message "$($Secondary) - Restoring log backup of $($Refresh.TargetDb)." -Type Info
                        Restore-SqlDatabase -ServerInstance $Secondary -Database $Refresh.TargetDb -BackupFile $TrnFilePath -RestoreAction Log -NoRecovery -Verbose
                    }
                    
                    # adds db to ag per instance as needed
                    foreach ($Replica in $Refresh.Replicas | Sort-Object Role ) {
                        Write-MessageLog -Source $Refresh.TargetDb -Message "$($Replica.Name) - Adding $($Refresh.TargetDB) to $($Refresh.Ag)." -Type Info
                        Add-SqlAvailabilityDatabase -Path ('SQLSERVER:\SQL\' + $Replica.Name + '\AvailabilityGroups\' + $Refresh.Ag) -Database $Refresh.TargetDB -ErrorAction Stop
                    }
                }
            }

            $Refresh.LastCompleted = 6
            Write-MessageLog -Source $Refresh.TargetDb -Message "# END  : $StepName" -Type Info
        }
        else {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# SKIP : $StepName" -Type Info
        }
        
        $RefreshData | Export-Clixml -Path $DataFile

        # get database SMO
        $Database = Get-DbaDatabase -SqlInstance $Refresh.Primary -Database $Refresh.TargetDb -EnableException

        ####################################################################################################
        # Step 7: Set logical names, filestream directory name, and owner
        ####################################################################################################
        $StepName = '7-Filestream, LogicalName, Owner'
        if ($Refresh.LastCompleted -lt 7) {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# START: $StepName" -Type Info

            # if we skipped the restore, no point in doing this work, can be done easier other ways, can also causing locking issues
            if ($SkipRestore) {
                Write-MessageLog -Source $Refresh.TargetDb -Message "FileStream, LogicalName, and Owner being skipped." -Type Warn
            }
            else {
                # see if we have a filestream directory to update
                if ($Database.FileGroups | Where-Object { $_.FileGroupType -eq 'FileStreamDataFileGroup' }) {
                    if ($Database.FilestreamDirectoryName -ne '') {
                        Write-MessageLog -Source $Refresh.TargetDb -Message "Filestream File group found: $($Database.DefaultFileStreamFileGroup)."  -Type Info

                        # set directory name and ReadOnly
                        $Database.FilestreamDirectoryName = $Database.Name
                        $Database.FilestreamNonTransactedAccess = 1
                
                        # might not need this, going to keep here in case
                        # $sessions = $Database.Parent.EnumProcesses() | Where-Object { $_.Database -eq $Database.Name }
                        # foreach ($session in $sessions) {
                        #     $Database.Parent.KillProcess($session.spid)
                        # }

                        $Database.Alter()
                        $Database.Refresh()
                        Write-MessageLog -Source $Refresh.TargetDb -Message "Filestream Directory Name set to: $($Database.FilestreamDirectoryName), ReadOnly mode." -Type Info
                    }
                }

                if ($SkipFileRename) {
                    Write-MessageLog -Source $Refresh.TargetDb -Message "LogicalName rename being skipped." -Type Warn
                }
                else {
                    # if we arent refreshing cross environment, no we should need to change anything
                    if ($Refresh.SourceDB -ne $Refresh.TargetDB) {

                        # rename logical file, ie _PROD to _TEST
                        foreach ($df in $Database.FileGroups.Files | Where-Object { $_.Name -like "*$($Refresh.SourceDbEnv)*" }) {
                            $df.Rename($df.Name.Replace($Refresh.SourceDbEnv, $Refresh.TargetDbEnv))

                            Write-MessageLog -Source $Refresh.TargetDb -Message "Logical name updated: $($df.Name)" -Type Info
                        }                    
                    
                        foreach ($lf in $Database.LogFiles | Where-Object { $_.Name -like "*$($Refresh.SourceDbEnv)*" }) {
                            $lf.Rename($lf.Name.Replace($Refresh.SourceDbEnv, $Refresh.TargetDbEnv))

                            Write-MessageLog -Source $Refresh.TargetDb -Message "Logical name updated: $($lf.Name)" -Type Info
                        }
                    }
                }

                if ($SkipDbOwner) {
                    Write-MessageLog -Source $Refresh.TargetDb -Message "DbOwner change being skipped." -Type Warn
                }
                else {
                    # db owner should be the same as the original replaced DB, but just in case we set it again, note this will not set secondary owner
                    $Database.SetOwner($Refresh.DbOwner)
                    Write-MessageLog -Source $Refresh.TargetDb -Message "Owner set to $($Refresh.DbOwner)." -Type Info
                }
            }

            $Refresh.LastCompleted = 7
            Write-MessageLog -Source $Refresh.TargetDb -Message "# END  : $StepName" -Type Info
        }
        else {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# SKIP : $StepName" -Type Info
        }

        $RefreshData | Export-Clixml -Path $DataFile

        ####################################################################################################
        # Step 8: Remove un-needed schemas, add views, add roles, add users and add persisted
        ####################################################################################################
        $StepName = '8-Persist Roles and Users'
        if ($Refresh.LastCompleted -lt 8) {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# START: $StepName" -Type Info

            # remove un-needed user schema views
            $Views = $Database.Views | Where-Object { $_.Schema -like "*\*" }
            if ($Views.count -ne 0) {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'Dropping unneeded views ...' -Type Info
                foreach ($View in $Views) { 
                    $View.Drop() 
                    Write-Output "`t$($View.Schema).$($View.Name)"
                }
            }
            else {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'No unneeded views to drop.' -Type Info
            }

            # remove un-needed user schemas
            $UserSchemas = $Database.Schemas | Where-Object { $_.Name -like "*\*" }
            if ($UserSchemas.count -ne 0) {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'Dropping unneeded schema ...' -Type Info
                foreach ($UserSchema in $UserSchemas) {
                    $UserSchema.Drop()
                    Write-Output "`t$($UserSchema.Name)"
                }
            }
            else {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'No unneeded schemas to drop.' -Type Info
            }
            
            # set owner schemas to dbo
            $UserOwnedSchemas = $Database.Schemas | Where-Object { $_.IsSystemObject -eq $false -and $_.Owner -in ($Database.Users | Where-Object { $_.IsSystemObject -eq $false }).Name } 
            if ($UserOwnedSchemas.count -ne 0) {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'Changing user owned schemas to dbo ...' -Type Info
                foreach ($UserOwnedSchema in $UserOwnedSchemas) {
                    $UserOwnedSchema.Owner = 'dbo'
                    $UserOwnedSchema.Alter()
                    Write-Output "`t$($UserOwnedSchema.Name)"
                }
            }
            else {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'No user ownded schemas to change.' -Type Info
            }

            # remove restored roles and add exported roles, we only do this is we have roles to add back, we may have skipped it above
            if ($Refresh.RoleFile) {
                if (Test-Path -Path $Refresh.RoleFile) { 
                    $Roles = $Database.Roles | Where-Object { $_.IsFixedRole -ne $true -and $_.Name -ne 'public' -and $_.Name -notlike "aspnet*" }
                    if ($Roles.count -ne 0) {
                        Write-MessageLog -Source $Refresh.TargetDb -Message 'Dropping roles ...' -Type Info
                        foreach ($Role in $Roles) {

                            # check to see if this role owns any schemas, if it does, set it to dbo so we can drop it
                            $OwnedSchemas = $Database.Schemas | Where-Object { $_.Owner -eq $Role.Name }
                            if ($OwnedSchemas) {
                                foreach ($Schema in $OwnedSchemas) {
                                    $Schema.Owner = $Schema.Name
                                    $Schema.Alter()
                                    Write-Output "`t$($Schema.Name) change ownership to $($Schema.Name)."
                                }
                            }
                            $Role.Drop()
                            Write-Output "`t$($Role.Name)"
                        }
                    }
                    Invoke-DbaQuery -SqlInstance $Refresh.Listener -Database $Refresh.TargetDb -File $Refresh.RoleFile -EnableException
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'Exported roles added.' -Type Info
                }
                else {
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'Role file not a valid path.' -Type Warn
                }                
            }
            else {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'No roles imported.' -Type Warn
            }
            
            # remove restored users and add exported users, we only do this if we have users to add back, we may have skipped it above
            if ($Refresh.UserFile) {
                if (Test-Path -Path $Refresh.UserFile) { 
                    $Users = $Database.Users | Where-Object { $_.IsSystemObject -eq $false }
                    if ($Users.count -ne 0) {
                        Write-MessageLog -Source $Refresh.TargetDb -Message 'Dropping users ...' -Type Info
                        foreach ($User in $Users) {
                            $User.Drop()
                            Write-Output "`t$($User.Name)"
                        }
                    }
                    Invoke-DbaQuery -SqlInstance $Refresh.Listener -Database $Refresh.TargetDb -File $Refresh.UserFile -EnableException
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'Exported users added.' -Type Info
                }
                else {
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'User file not a valid path.' -Type Warn
                }
            }
            else {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'No users imported.' -Type Warn
            }
        
            $Refresh.LastCompleted = 8
            Write-MessageLog -Source $Refresh.TargetDb -Message "# END  : $StepName" -Type Info
        }
        else {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# SKIP : $StepName" -Type Info
        }

        $RefreshData | Export-Clixml -Path $DataFile

        ####################################################################################################
        # Step 9: Add Synonyms
        ####################################################################################################
        $StepName = '9-Persist Synonyms'
        if ($Refresh.LastCompleted -lt 9) {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# START: $StepName" -Type Info

            # drop restored synonyms and add exported synonyms, we only do this if we have users to add back, we may have skipped it above
            if ($Refresh.SynonymFile) {
                if (Test-Path -Path $Refresh.SynonymFile) {
                    $Synonyms = $Database.Synonyms
                    if ($Synonyms.count -ne 0) {
                        Write-MessageLog -Source $Refresh.TargetDb -Message 'Dropping synonyms ...' -Type Info
                        foreach ($Synonym in $($Synonyms)) {
                            $Synonym.Drop()
                        }
                    }
                    Invoke-DbaQuery -SqlInstance $Refresh.Listener -Database $Refresh.TargetDb -File $Refresh.SynonymFile -EnableException
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'Exported synonyms added.' -Type Info
                }
                else {
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'Synonym file not a valid path.' -Type Warn
                }
            }
            else {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'No synonyms persisted.' -Type Info
            }

            $Refresh.LastCompleted = 9
            Write-MessageLog -Source $Refresh.TargetDb -Message "# END  : $StepName" -Type Info
        }
        else {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# SKIP : $StepName" -Type Info
        }

        $RefreshData | Export-Clixml -Path $DataFile

        ####################################################################################################
        # Step 10: Add persisted data 
        ####################################################################################################
        $StepName = '10-Persist Data'
        if ($Refresh.LastCompleted -lt 10) {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# START: $StepName" -Type Info
            
            # remove restored table data and add exported tabel data
            if ($Refresh.PersistTable) {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'Importing tables ...' -Type Info
                $tables = ($Refresh.PersistTable).Split(',')
                
                foreach ($table in $tables) {
                    $SourceTable = "$($Refresh.TargetDB)-$table"
                    Copy-DbaDbTableData -SqlInstance $Database.Parent -Database $StagingDB -Table $SourceTable -DestinationDatabase $Refresh.TargetDB -DestinationTable $table -Truncate -EnableException
                    
                    Write-MessageLog -Source $Refresh.TargetDb -Message "$SourceTable copied to $table." -Type Info
                }
            }
            else {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'No data persisted.' -Type Info
            }
 
            $Refresh.LastCompleted = 10
            Write-MessageLog -Source $Refresh.TargetDb -Message "# END  : $StepName" -Type Info
        }
        else {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# SKIP : $StepName" -Type Info
        }

        $RefreshData | Export-Clixml -Path $DataFile

        ####################################################################################################
        # Step 11: Tranformations--DACPAC or Rename objects
        ####################################################################################################
        $StepName = '11-Transform'
        if ($Refresh.LastCompleted -lt 11) {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# START: $StepName" -Type Info

            if ($SkipTransform) {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'Transformations being skipped.' -Type Warn
            }
            else {
                # switch for which transformation to perform if any
                switch ($Refresh.TransformType) {
                    'DAC' {

                        if ($Refresh.DacpacPath) {

                            # checks if we already parsed this path, if we already did, skip it
                            # this saves time to not re-parse paths for each app path, 
                            # but if something gets updated it wont be reflected during a run
                            if ($DpPaths -notcontains $Refresh.DacpacPath) {

                                # gets .config and .dacpac files to process
                                $XmlList = Get-ChildItem -Path $Refresh.DacpacPath -Filter '*.config' -Recurse | Select-Object Name, Directory, FullName
                                $DacList = Get-ChildItem -Path $Refresh.DacpacPath -Filter '*.dacpac' -Recurse | Select-Object Name, Directory, FullName

                                foreach ($Xml in $XmlList) {
                                    # get content
                                    [XML]$XmlFile = Get-Content $Xml.FullName
                        
                                    # dacpac options
                                    $do = $null # clear options in case it carries over
                                    foreach ($o in $XmlFile.deployments.options) {
                                        $do = [PSCustomObject]@{
                                            Key   = $o.option.Key
                                            Value = $o.option.Value
                                        }
                                    }
                        
                                    # dacpac setings and variables
                                    foreach ($d in $XmlFile.deployments.dacpac) {
                                        $dp = [PSCustomObject]@{
                                            App       = ($Xml.FullName).Split('\')[-2]
                                            Filename  = $d.name
                                            Database  = $d.db
                                            Instance  = $d.instance
                                            Variables = $d.variables.variable
                                            Options   = $do
                                        }
                                        $Dacpacs += $dp
                                    }
                                }
                                # adds this path to the array of processed paths so we dont process the same path again
                                $DpPaths += $Refresh.DacpacPath
                                Write-MessageLog -Source $Refresh.TargetDb -Message "Parsed config at $($Refresh.DacpacPath)." -Type Info
                            }
                            else {
                                Write-MessageLog -Source $Refresh.TargetDb -Message 'This dacpac config path already parsed.' -Type Info
                            }

                            if ($VerbosePreference -eq 'Continue') { $Dacpacs | Format-Table -AutoSize | Out-String -Width 500 }
                        
                            # gets filename of dacpac for the database we are currently working with
                            if ($Filename = $Dacpacs | Where-Object { $_.Database -eq $Refresh.TargetDb } | Select-Object -ExpandProperty Filename | Sort-Object -Unique) {
                                # gets the dacpac file and uses the newest one
                                if ($DacpacFile = $DacList | Where-Object { $_.Name -eq $Filename } | Sort-Object LastWriteTime | Select-Object -ExpandProperty Fullname -First 1 ) {
                                    Write-MessageLog -Source $Refresh.TargetDb -Message "Using dacpac file: $DacpacFile." -Type Info
                        
                                    # new dacpac publish object and some default options
                                    $DacOptions = New-DbaDacOption -Type Dacpac -Action Publish 
                                    . $DacOptionsFile 
                                    Write-MessageLog -Source $Refresh.TargetDb -Message 'Default DeployOptions set.' -Type Info
                                
                                    $table = @()
                                    # loops thru all the dacpac SqlCommandVaribles for the DB and an object to pass to the publish cmdlet, if the key already exists (dupe config file) skips it
                                    foreach ($var in ($Dacpacs | Where-Object { $_.Database -eq $Refresh.TargetDb }).Variables) {
                                        if ($null -ne $var) {
                                            if ($DacOptions.DeployOptions.SqlCommandVariableValues.ContainsKey($var.name)) {
                                                Write-MessageLog -Source $Refresh.TargetDb -Message "SqlCommandVariableValues already contains key: $($var.name)." -Type Warn
                                            }
                                            else {
                                                $DacOptions.DeployOptions.SqlCommandVariableValues.Add($var.name, $var.value)
                                                $obj = [PSCustomObject]@{
                                                    Name  = $var.Name
                                                    Value = $var.Value
                                                }
                                                $table += $obj
                                            }
                                        }
                                    }
                                    if ($table.count -ne 0) {
                                        Write-MessageLog -Source $Refresh.TargetDb -Message "Deploy Variables for $($Refresh.TargetDb)." -Type Info
                                    ($table | Format-Table -Property @{Expression = '   ' }, Name, Value -HideTableHeaders  -AutoSize | Out-String -Width 500).Trim("`n", "`r")
                                    }
                            
                                    $table = @()
                                    # loops thru all the dacpac deploy options for the DB and an object to pass to the publish cmdlet
                                    foreach ($opt in $Dacpacs | Where-Object { ($_.Database -eq $Refresh.TargetDb -and $null -ne $_.Options) }) {
                                        $DacOptions.DeployOptions.$($opt.Options.Key) = $($opt.Options.Value)
                                        $obj = [PSCustomObject]@{
                                            Key   = $opt.Options.Key
                                            Value = $opt.Options.Value
                                        }
                                        $table += $obj
                                    }
                                    if ($table.count -ne 0) {
                                        Write-MessageLog -Source $Refresh.TargetDb -Message "Deploy Options for $($Refresh.TargetDb)." -Type Info
                                    ($table | Format-Table -Property @{Expression = ' - ' }, Key, Value -HideTableHeaders -AutoSize | Out-String -Width 500).Trim("`n", "`r")
                                    }
                    
                                    # applies dacpac
                                    Write-MessageLog -Source $Refresh.TargetDb -Message "Deploying dacpac on $($Refresh.TargetDb)." -Type Info
                                    Publish-DbaDacPackAge -SqlInstance $Refresh.Listener -Database $Refresh.TargetDb -DacOption $DacOptions -Path $DacpacFile -EnableException
                                    Write-MessageLog -Source $Refresh.TargetDb -Message 'Dacpac published.' -Type Info
                                }
                                else {
                                    Write-MessageLog -Source $Refresh.TargetDb -Message "Dacpac file $Filename not found for $($Refresh.TargetDb)." -Type Error
                                    continue refresh
                                }
                            }
                            else {
                                Write-MessageLog -Source $Refresh.TargetDb -Message "Dacpac config not found for $($Refresh.TargetDb)." -Type Error
                                continue refresh
                            }
                        }
                        else {
                            Write-MessageLog -Source $Refresh.TargetDb -Message "DAC TransformType set, but no DacpacPath set for $($Refresh.TargetDb)." -Type Warn
                        }
                    }
                    'REP' {
                        # export and update objects
                        if ($Refresh.ReplaceSp) {
                            if ($sp = $Database.StoredProcedures | Where-Object { $_.IsSystemObject -eq $false }) {
                                Write-MessageLog -Source $Refresh.TargetDb -Message "Exporting and updating Stored Procedures ..." -Type Info

                                $sql = Export-SqlDbObject -Database $Database -Object $sp -ScriptDrops | Tee-Object -FilePath ($ExportPath + '\' + $Refresh.TargetDb + '_sp_' + (Get-Date -Format "yyyyMMdd_HHmm") + '.sql')
                                $sqlrepl = Split-DoubleList -String $Refresh.ReplaceSp | ForEach-Object { $sql.Replace($_.Old, $_.New) } | Tee-Object -FilePath ($ExportPath + '\' + $Refresh.TargetDb + '_sp_upd_' + (Get-Date -Format "yyyyMMdd_HHmm") + '.sql')

                                $Database | Invoke-DbaQuery -Query ( $sqlrepl | Out-String )

                                Write-MessageLog -Source $Refresh.TargetDb -Message "Stored Procedures imported." -Type Info
                            }
                        }
                    
                        if ($Refresh.ReplaceFn) {
                            if ($fn = $Database.UserDefinedFunctions | Where-Object { $_.IsSystemObject -eq $false }) {
                                Write-MessageLog -Source $Refresh.TargetDb -Message "Exporting and updating Functions ..." -Type Info

                                $sql = Export-SqlDbObject -Database $Database -Object $fn -ScriptDrops | Tee-Object -FilePath ($ExportPath + '\' + $Refresh.TargetDb + '_fn_' + (Get-Date -Format "yyyyMMdd_HHmm") + '.sql')
                                $sqlrepl = Split-DoubleList -String $Refresh.ReplaceFn | ForEach-Object { $sql.Replace($_.Old, $_.New) } | Tee-Object -FilePath ($ExportPath + '\' + $Refresh.TargetDb + '_fn_upd_' + (Get-Date -Format "yyyyMMdd_HHmm") + '.sql')
                        
                                $Database | Invoke-DbaQuery -Query ( $sqlrepl | Out-String )

                                Write-MessageLog -Source $Refresh.TargetDb -Message "Functions imported." -Type Info
                            }
                        }
                    
                        if ($Refresh.ReplaceVw) {
                            if ($vw = $Database.Views | Where-Object { $_.IsSystemObject -eq $false }) {
                                Write-MessageLog -Source $Refresh.TargetDb -Message "Exporting and updating Functions ..." -Type Info

                                $sql = Export-SqlDbObject -Database $Database -Object $vw -ScriptDrops | Tee-Object -FilePath ($ExportPath + '\' + $Refresh.TargetDb + '_vw_' + (Get-Date -Format "yyyyMMdd_HHmm") + '.sql')
                                $sqlrepl = Split-DoubleList -String $Refresh.ReplaceVw | ForEach-Object { $sql.Replace($_.Old, $_.New) } | Tee-Object -FilePath ($ExportPath + '\' + $Refresh.TargetDb + '_vw_upd_' + (Get-Date -Format "yyyyMMdd_HHmm") + '.sql')
     
                                $Database | Invoke-DbaQuery -Query ( $sqlrepl | Out-String )

                                Write-MessageLog -Source $Refresh.TargetDb -Message "Views imported." -Type Info
                            }
                        }
                    }
                    default { Write-MessageLog -Source $Refresh.TargetDb -Message 'No transform options passed.' -Type Info }
                }
            }

            $Refresh.LastCompleted = 11
            Write-MessageLog -Source $Refresh.TargetDb -Message "# END  : $StepName" -Type Info
        }
        else {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# SKIP : $StepName" -Type Info
        }

        $RefreshData | Export-Clixml -Path $DataFile
        
        ####################################################################################################
        # Step 12: Post-process
        ####################################################################################################
        $StepName = '12-Postprocess Data'
        if ($Refresh.LastCompleted -lt 12) {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# START: $StepName" -Type Info

            # if post processing requested to be skipped
            if ($SkipPostProcess) {
                Write-MessageLog -Source $Refresh.TargetDb -Message 'Postprocessing being skipped.'  -Type Warn
            }
            else { 
                # if any post processing was requested
                if ($Refresh.PostProcess) {
                    $PostList = ($Refresh.PostProcess).Split(',')
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'Running postprocessing ...' -Type Info
                    foreach ($item in $PostList) {
                        Write-MessageLog -Source $Refresh.TargetDb -Message "Executing $item." -Type Info
                        & $item
                    }
                }
                else {
                    Write-MessageLog -Source $Refresh.TargetDb -Message 'No postprocess options passed.' -Type Info
                }
            }

            $Refresh.LastCompleted = 12
            Write-MessageLog -Source $Refresh.TargetDb -Message "# END  : $StepName" -Type Info
        }
        else {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# SKIP : $StepName" -Type Info
        }

        $RefreshData | Export-Clixml -Path $DataFile

        ####################################################################################################
        # Step 13: Perform full backup
        ####################################################################################################
        $StepName = '13-Full Backup'
        if ($Refresh.LastCompleted -lt 13) {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# START: $StepName" -Type Info

            # skip full backup if requested 
            if ($SkipPostBackup) {
                Write-MessageLog -Source $Refresh.TargetDb -Message "Full Backup being skipped." -Type Warn
            }
            else {
                # if we explicitly set a path, then use for full, else try a full, if none, fail
                if ($PSBoundParameters.ContainsKey('BackupPath')) {
                    Write-MessageLog -Source $Refresh.TargetDb -Message "BackupPath set: $BackupPath" -Type Verbose
                    $BakPath = $BackupPath
                }
                elseif ($LastFull) {
                    $BakPath = Split-Path -Path $LastFull.Path -Parent
                }
                else {
                    Write-MessageLog -Source $Refresh.TargetDb -Message "Couldn't determine full backup location, skipping rest of refresh for $($Refresh.TargetDb)." -Type Error
                    continue refresh
                }

                Write-MessageLog -Source $Refresh.TargetDb -Message "Performing full backup of $($Refresh.TargetDb) to: $BakPath." -Type Info
                Backup-SqlDatabase -ServerInstance $Refresh.Listener -Database $Refresh.TargetDb -BackupFile ($BakPath + '\' + $Refresh.TargetDB + '-FULL-' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.bak') -CompressionOption On -Verbose
                Write-MessageLog -Source $Refresh.TargetDb -Message "Full backup completed of $($Refresh.TargetDb)." -Type Info
            }

            $Refresh.LastCompleted = 13
            Write-MessageLog -Source $Refresh.TargetDb -Message "# END  : $StepName" -Type Info
        }
        else {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# SKIP : $StepName" -Type Info
        }        

        $RefreshData | Export-Clixml -Path $DataFile
        
        ####################################################################################################
        # Step 14: Shrink log file
        ####################################################################################################
        $StepName = '14-Shrink Log'
        if ($Refresh.LastCompleted -lt 14) {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# START: $StepName" -Type Info
            
            # run shrink if requested 
            if ($SkipShrinkLog) {
                Write-MessageLog -Source $Refresh.TargetDb -Message "Shrink Log being skipped." -Type Info
            }
            else {
                Write-MessageLog -Source $Refresh.TargetDb -Message "Shrinking $($Refresh.TargetDb) ..." -Type Info
                Invoke-DbaDbShrink -SqlInstance $Refresh.Listener -Database $Refresh.TargetDb -FileType Log -ExcludeIndexStats
            }
            
            $Refresh.LastCompleted = 14
            Write-MessageLog -Source $Refresh.TargetDb -Message "# END  : $StepName" -Type Info
        }
        else {
            Write-MessageLog -Source $Refresh.TargetDb -Message "# SKIP : $StepName" -Type Info
        }        

        $RefreshData | Export-Clixml -Path $DataFile
        
        ####################################################################################################
        # COMPLETED
        ####################################################################################################
        $Refresh.Status = 'COMPLETED'
        
        $Elapsed = New-TimeSpan -Start $StartTime -End (Get-Date)
        $Refresh.TimeTaken = $Elapsed.TotalSeconds

        Write-MessageLog -Source $Refresh.TargetDb -Message "### $($Refresh.TargetDb) refreshed in $Elapsed ###" -Type Info
        
        $RefreshData | Export-Clixml -Path $DataFile
        
    }
}
catch {
    $ErrorException = $_.Exception
    Write-MessageLog -Source $Refresh.TargetDb -Message $ErrorException.Message -Type Crit
    Write-MessageLog -Source $Refresh.TargetDb -Message "Error during $StepName." -Type Crit
    if ($PSBoundParameters.ContainsKey('Notify')) { Send-MailMessage @emailsplat -To $Notify -Subject $StepName -Body $ErrorException.Message }
}
    
####################################################################################################
# save data, cleanup, reporting
####################################################################################################
try {
    $Source = 'Cleanup'
    Write-MessageLog -Source $Source -Message "# START: $Source" -Type Info
    
    # where did we complete work
    $RefreshedInstances = ($RefreshData | Where-Object { $_.Status -eq "Completed" }).Replicas.Name | Sort-Object -Unique

    # incomplete count--using 2x below, so saving to variable
    $IncompleteRefreshCount = ( $RefreshData | Where-Object { $_.Status -ne 'COMPLETED' } ).Count
    
    # if we have refresh data to save
    if ($RefreshData.Count -ne 0) {

        # save data file
        $RefreshData | Export-Clixml -Path $DataFile
        Write-MessageLog -Source $Source -Message "Refresh data saved to: $DataFile" -Type Info

        # if nothing is left incomplete archive data file
        if ($IncompleteRefreshCount -eq 0) {
            Move-Item -Path $DataFile -Destination $RefreshDataArchivePath
            Write-MessageLog -Source $Source -Message "Refresh data archived." -Type Info
        }
        
        # show all the refresh data
        if ($VerbosePreference -eq 'Continue') {
            Write-Output "`n= = = R E F R E S H  D A T A = = ="
            $RefreshData | Format-Table -Property Status, LastCompleted, Listener, TargetDb -AutoSize | Out-String -Width 500
        }
    }
    else {
        Write-MessageLog -Source $Source -Message 'No refresh data to store.' -Type Warn
    }

    # if all refreshes completed
    if ($IncompleteRefreshCount -eq 0) {

        # on each instance we completed a refresh
        foreach ($Instance in $RefreshedInstances) {

            # check to see if any DBs are still restoring--another job could be running or a failure
            $RestoringDB = Get-DbaDatabase -SqlInstance $Instance -ExcludeSystem -Status 'Restoring'

            # if no DBs are currently restoring, we are safe to enable LOG backups
            if ($RestoringDB.Count -eq 0) {

                # this checks for log backups with the following criteria to re-enable:
                # has schedule, disabled, last ran within 3 days, matches 'include' names, doesnt 'match' exclude name
                # if this job has not run recently, we probably wont want to enable it anyway
                $SSAJobs = Get-DbaAgentJob -SqlInstance $Instance -EnableException | Where-Object { $_.HasSchedule -eq $true -and $_.Enabled -eq $false -and $_.LastRunDate -gt ((Get-Date).AddDays(-3)) -and $_.Name -in $SSAIncludeFilter -and $_.Name -notlike $SSAExcludeFilter }
                foreach ($SSAJob in $SSAJobs) {
                    $null = Set-DbaAgentJob -SqlInstance $Instance -Job $SSAJob -Enabled -EnableException
                    Write-MessageLog -Source $Source -Message "$($SSAJob.SqlInstance) - Enabled job $($SSAJob.Name)." -Type Info
                }
            } 
            else {
                Write-MessageLog -Source $Source -Message "$Instance - LOG Backup job not re-enabled, a database is in Restoring state." -Type Info
            }
        }
    }
}
catch {
    $ErrorException = $_.Exception
    Write-MessageLog -Source $Source -Message $ErrorException.Message -Type Warn
}

Write-MessageLog -Source $Source -Message "# END  : $Source" -Type Info

if ($VerbosePreference -eq 'Continue') {
    Write-Output "`n= = =  L O G  S U M M A R Y  = = ="
    $MessageLog | Format-Table -AutoSize | Out-String -Width 500
}

# see if we had any errors
$ErrorCrit = $MessageLog | Where-Object { $_.ErrorLevel -le 2 }

# if we had errors(didnt complete), display errors, else display restores
if ($ErrorCrit.count -ne 0) {

    Write-Output "`n= = =  E R R O R  S U M M A R Y  = = ="
    $ErrorCrit | Where-Object { $_.ErrorLevel -le 3 } | Format-Table -AutoSize | Out-String -Width 500

    if ($PSBoundParameters.ContainsKey('Notify')) {
        Write-MessageLog -Source $Source -Message 'Creating error report to email.' -Type Info
        . $HtmlHeadFile
        $Body = $ErrorCrit | ConvertTo-Html -Head $Head | Out-String
        Send-MailMessage @emailsplat -To $Notify -Subject "Refresh Error Report - $ReqName : $(Get-Date -Format 'yyyy-MM-dd')" -Body $Body -BodyAsHtml
    }

    if ($Verify) { Read-Host -Prompt "::: Script completed with errors. Please review log. Press ENTER to exit. ::" }

    throw
}
else {
    if ($RefreshedInstances.count -ne 0) {

        $DbList = $Requests | Select-Object -ExpandProperty Database
        $LastRestoreDetails = Get-DbaDbRestoreHistory -SqlInstance $RefreshedInstances -Database $DbList -Since ((Get-Date).AddHours(-12)) -EnableException | Where-Object { $_.RestoreType -in 'Database', 'Differential' } | Select-Object -Property SqlInstance, Database, RestoreType, Date | Sort-Object SqlInstance, Date

        Write-Output "`n= = =  R E S T O R E  D E T A I L S  = = ="
        $LastRestoreDetails | Format-Table -AutoSize | Out-String -Width 500
        
        if ($PSBoundParameters.ContainsKey('Notify')) {
            Write-MessageLog -Source $Source -Message 'Creating refresh report to email.' -Type Info
            . $HtmlHeadFile # pulls in some css for Html email report
            $Body = $LastRestoreDetails | ConvertTo-Html -Head $Head | Out-String
            Send-MailMessage @emailsplat -To $Notify -Subject "Refresh Report - $ReqName : $(Get-Date -Format 'yyyy-MM-dd')" -Body $Body -BodyAsHtml
        }
    }
    
    if ($Verify) { Read-Host -Prompt "::: Script completed. Press ENTER to exit. ::" }
    
    Stop-Transcript
}
# completed
