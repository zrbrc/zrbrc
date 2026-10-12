<#
.SYNOPSIS
    Creates a zip package of sql scripts to run with Deploy-SqlPackage, this 'builder' is specific to DECSS environment.
.DESCRIPTION
    Thic script will take an input Excel file with a list of sql file to build for, the sql files are updated on disk from TFS. Initial TFS
    setup needs to be performed before this process will work. See instructions in document folder for how-to.
.EXAMPLE
    Can be run cli with parameters or run via explorer and it will ask for inputs.
    PS C:\> Build-DecssSqlPackage.ps1 -Env PROD -FilePath C:\Temp\Prod_build_files.xlsx
.INPUTS
    Env: This is what environment you want to build for. This controls what TFS environment is refreshed.
    FilePath: This is the Excel request file. It should contain a 'File Path'
.OUTPUTS
    Output (if any)
.NOTES
    General notes: This will do a version check using TFS before any execution. If TFS cannot be contacted, it will skip the version check and just continue.
#>
param (
    [string]$Application = 'DECSS',
    [array]$Environment,

    [ValidateScript( { Test-Path $_ } )]
    [String]$ExcelFile,

    [switch]$SkipVersionCheck
)

@"
   _ _     _         _         
 _| | |_ _| |___ ___| |___ _ _ 
| . | . | . | -_| . | | . | | |
|___|___|___|___|  _|_|___|_  |
                |_|       |___|

"@

Set-Location $PSScriptRoot

# static
$BuildPath = '.\build'
$DeployFile = "$BuildPath\deploy.json"
$ProgramFiles = 'C:\Program Files (x86)'
$ProgramFiles64 = 'C:\Program Files'
$ConfigFile = '.\config\decssconfig.json'
$DbConfigFile = '.\config\dbconfig.json'

#################################
# config setup and loading
#################################
try {
    # loads assembly for file/folder picker and ImportExcel Module
    Add-Type -AssemblyName 'System.Windows.Forms'
    Write-Host 'Loading ImportExcel module ...'
    if (Get-Module ImportExcel -ListAvailable) { 
        Import-Module ImportExcel
        Write-Output 'ImportExcel module loaded.'
    }
    else {
        Install-Module ImportExcel -Scope CurrentUser
        Write-Output 'ImportExcel module installed.'
    }

    # see if we have a config.xml file, if we do, load it, if not find tf.exe and ask for tfs code root and then create config.xml
    if (Test-Path $ConfigFile -PathType Leaf -ErrorAction Stop) {
        # import existing config
        $Config = Get-Content -Path $ConfigFile | ConvertFrom-Json
        $TfExe = $Config.TfExePath
        $TfsDecssRootPath = $Config.TfsDecssRootPath
    }
    else {
        # find tf.exe
        Write-Output 'Searching for tf.exe, please hold ...'
        $TfExe = (Get-ChildItem -Path $ProgramFiles,$ProgramFiles64 -Filter 'tf.exe' -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1).FullName
        if (-not $TfExe) { 
            Write-Output 'tf.exe cannot be found, please verify you have Visual Studio or Team Explorer installed and try again'
            throw 
        }
        else {
            Write-Output 'tf.exe found.'
        }
        
        # display a folder picker for decss tfs path
        Write-Output 'Choose the DECSS TFS root folder when the folder browser opens.'

        $folderbrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderbrowser.RootFolder = 'MyComputer'
        $folderbrowser.Description = 'Choose the DECSS TFS root folder...'
        $folderbrowser.ShowDialog() | Out-Null
        if (-not ($TfsDecssRootPath = $folderbrowser.SelectedPath)) { 
            Write-Output 'You didnt choose a folder.'
            throw 
        }
        else {
            Write-Output 'DECSS TFS root set.'
        }
    
        if ($TfExe -and $TfsDecssRootPath ) {
            [PSCustomObject]@{
                TfExePath        = $TfExe
                TfsDecssRootPath = $TfsDecssRootPath
            } | ConvertTo-Json | Out-File -FilePath $ConfigFile -Encoding UTF8
        }
    }
    
    # validate config file info
    if (-not (Test-Path $TfExe) -or -not (Test-Path $TfsDecssRootPath)) { 
        Remove-item -Path $ConfigFile
        Write-Output '[!] A configuration error was detected, please run the script again and it will ask to redefine the values.'
        throw 
    }

    # load the dbconfig
    $DbConfig = Get-Content $DbConfigFile -ErrorAction Stop | ConvertFrom-Json

    # create build folder
    if (-not (Test-Path -Path $BuildPath)) { $null = New-Item -Path $BuildPath -ItemType Directory }
}
catch {
    $Exception = $_
    Write-Output "[!] Error during config."
    Write-Output $Exception
    Remove-item -Path $ConfigFile
    Read-Host '::: ENTER ::'
    exit
}

#################################
# main process
#################################
try {
    # this is a specific process for DECSS, so setting it as such
    [array]$Environments = $DbConfig | Where-Object { $_.Application -eq $Application }  | Sort-Object Rank, Environment -Unique

    # if we didnt pass the environment parameter, ask for it, if we did, check if its valid
    if (-not $PSBoundParameters.ContainsKey('Environment')) {
        
        $continue = $false
        do {

            # $Environment = @()
            $TfsEnvironment = @()
            $Invalid = 0

            Write-Output "`n= = = D E C S S  B U I L D = = ="
            $i = 0
            $Environments | ForEach-Object { "  {0}`t{1}`t{2}" -f $i++, $_.TfsEnvironment, $_.Environment }

            [array]$WhatEnv = (Read-Host "[?] Which environments (comma seperated)?").Split(',')

            foreach ($item in $WhatEnv) {
                if ($null -ne ($item -as [int]) -and $item -ne '' -and [int]$item -lt $Environments.Count) {
                    $Environment += $Environments[$item].Environment
                    $TfsEnvironment += $Environments[$item].TfsEnvironment
                }
                else {
                    $Invalid++
                }
            }
            
            if ($Invalid -gt 0) {
                Write-Output '[!] That is not a valid choice, try again.'
                continue 
            }

            $answer = Read-Host "[?] Continue? $($Environment -join ', ') (y/n)"
            if ($answer.ToUpper() -eq 'Y') { $continue = $true }

        } until ($continue -eq $true)
    }
    elseif ($Environments.Environment -notcontains $Environment) {
        Write-Output 'Bad environment parameter, try again.'
        Read-Host '::: ENTER ::'
        exit 
    }

    # if we didnt pass excel file parameter, ask for it, if we did, check if its valid
    if (-not ($PSBoundParameters.ContainsKey('ExcelFile'))) {
        $continue = $false
        do {
            Write-Output '[?] Please choose Excel file when the file chooser dialog opens ... '
            $openfile = New-Object System.Windows.Forms.OpenFileDialog
            $openfile.filter = "XLSX (*.xlsx)| *.xlsx"
            $openfile.InitialDirectory = $PSScriptRoot
            $openfile.ShowDialog() | Out-Null
            $ExcelFile = $openfile.FileName
            $answer = Read-Host "[?] Continue? $($ExcelFile.Split('\')[-1]) (y/n)"
            if ($answer.ToUpper() -eq 'Y') { $continue = $true }
        } until ($continue -eq $true)
    }
    elseif (-not (Test-Path $ExcelFile)) {
        'Bad excel file parameter, try again.'
        Read-Host '::: ENTER ::'
        exit 
    }
    
    $TfsEnvironment = $TfsEnvironment | Sort-Object -Unique
    Write-Output "`nPerforming GET on TFS for $(($TfsEnvironment -join ', ').ToUpper()) to build for $(($Environment -join ', ').ToUpper())."

    # update TFS source code for each environement requested
    foreach ($item in $TfsEnvironment) {
        $TfParms = @('get', "$TfsDecssRootPath\DECSS Source $($TfsEnvironment)\DecssDB", '/recursive')
        & $TfExe $TfParms
        if ($?) {
            Write-Output "GET completed for $item."
        }
        else {
            Write-Output "[!] Failed to update TFS source code for $item. Please run again and choose correct DECSS TFS source code path."
            Remove-item -Path $ConfigFile
            Read-Host '::: ENTER ::'
            exit
        }
    }

    # import excel data, get list of local files paths, and verify they exist
    Write-Output "`nGetting list of files from Excel."
    $ExcelData = Import-Excel -Path $ExcelFile

    # get files count, creates the list of valid file paths, this also corrects the '/' to '\' for windows paths
    $FileCount = $ExcelData.'File Path'.Count
    [Array]$Files = ($ExcelData.'File Path'.Replace('$/', "$TfsDecssRootPath\") | Resolve-Path).Path

    # make sure we found some files on the filesystem
    if ($Files.Count -eq 0) { 
        Write-Output '[!] No data found in the Excel file, please check the column name is ''File Path''.'
        Read-Host '::: ENTER ::'
        exit
    }

    # make sure the excel file count matches the validated file count on the filesystem
    if ($FileCount -ne $Files.count) {
        Write-Output '[!] Invalid files found in Excel file. This could be be caused by missing files if TFS GET failed.'
        Read-Host '::: ENTER ::'
        exit
    }

    # shows files
    $Files | Format-Table
    Write-Output "Found $($Files.Count) valid files."
    
    # what are we builing for
    $BuildConfig = $DbConfig | Where-Object { $_.Environment -in $Environment -and $_.Application -eq $Application } 
    
    Write-Output "`nCreating deploy file ..."
    $Deploy = foreach ($file in $Files) {

        # this gets the folder name of the scripts, this corresponds to which database (Online, Reporting, E/C Portal) we will execute against
        $Area = $file.Replace($TfsDecssRootPath, '').Split('\')[3]

        foreach ($item in $BuildConfig | Where-Object { $_.Area -eq $Area }) {

            # sets the priority and type for each script
            # note: switch doesnt stop at the first match, since we are using -wildcard, we need to make it break after the first match
            switch -wildcard ($file) {
                "*DBCR*" {
                    $Type = 'DBCR'
                    $Priority = '1'
                    break
                }                
                "*Function*" {
                    $Type = 'Function'
                    $Priority = '2'
                    break
                }                
                "*Stored Procedures\Batch*" {
                    $Type = 'Stored Procedures-Batch'
                    $Priority = '3'
                    break
                }                
                "*Stored Procedures\Online*" {
                    $Type = 'Stored Procedures-Online'
                    $Priority = '4'
                    break
                }                
                "*Stored Procedures*" {
                    $Type = 'Stored Procedures'
                    $Priority = '5'
                    break
                }                
                "*DML-Script*" {
                    $Type = 'DML-Script'
                    $Priority = '6'
                }                
                "*Ref-Incremental-Scripts*" {
                    $Type = 'Ref-Incremental-Scripts'
                    $Priority = '7'
                    break
                }                
                "*Views*" {
                    $Type = 'Views'
                    $Priority = '8'
                    break
                }
                default {
                    $Type = 'OTHER'
                    $Priority = '99'
                }
            }

            [PSCustomObject] @{
                Application = $Application
                Instance    = $item.Instance
                Database    = $item.Database
                SqlFile     = $file.Split("\")[-1]
                Type        = $Type
                Priority    = $Priority
                Status      = 'NONE'
                Comment     = ''
            }
        }
    }

    # if deploy object is empty, dont do anything
    if ($Deploy.count -eq 0) {
        Write-Output '[!] Deploy object is empty, nothing to output.'
        Read-Host '::: ENTER ::'
        exit
    }

    $Deploy | ConvertTo-Json | Out-File -FilePath $DeployFile -Encoding UTF8

    Write-Output "`nCreating deploy package ..."
        
    # adds the excel and deploy file to the list and then compresses them all to a zip--these are '$null =' so they are quiet
    # this cleans up any files used during the process so only the zip file is left at the end
    $Files += $ExcelFile
    $Files += (Resolve-Path -Path $DeployFile).Path

    # creates a random id to tag the zip file with
    $Id = -join ((65..90) + (97..122) | Get-Random -Count 6 | ForEach-Object { [char]$_ })
    $ZipFile = "$($BuildPath)\$($Application)_$(($Environment.ToUpper() -join '-'))_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$($Id).zip"
    Compress-Archive -Path $Files -DestinationPath $ZipFile

    # remove deploy file after we add it to the zip
    Remove-Item $DeployFile

    Write-Output "Deploy package complete: $ZipFile"
    Invoke-Item (Get-Item $ZipFile).Directory
}
catch {
    $Exception = $_
    Write-Output '[!] Error during build.'
    Write-Output $Exception
}
Read-Host '::: ENTER ::'