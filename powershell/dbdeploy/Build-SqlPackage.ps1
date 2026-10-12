<#
.SYNOPSIS
    Creates a zip package of sql scripts to run with Deploy-SqlPackage, this 'builder' is specific to  environment.
.DESCRIPTION
    Thic script will take an input Excel file with a list of sql file to build for, the sql files are updated on disk from TFS. Initial TFS
    setup needs to be performed before this process will work. See instructions in document folder for how-to.
.EXAMPLE
    Can be run cli with parameters or run via explorer and it will ask for inputs.
    PS C:\> Build-SqlPackage.ps1 -Env PROD -FilePath C:\Temp\Prod_build_files.xlsx
.INPUTS
    Env: This is what environment you want to build for. This controls what TFS environment is refreshed.
    FilePath: This is the Excel request file. It should contain a 'File Path'
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
param (
    [Alias('E')][String]$Env,
    [Alias('F')][String]$FilePath
)
@'
   _ _     _         _         
 _| | |_ _| |___ ___| |___ _ _ 
| . | . | . | -_| . | | . | | |
|___|___|___|___|  _|_|___|_  |
                |_|       |___|

'@

Set-Location $PSScriptRoot

# static
$Application = ''
$Environments = @{'D' = 'DEV'; 'U' = 'UIT'; 'S' = 'SIT'; 'T' = 'UAT'; 'P' = 'PROD'; }
$BuildPath = '.\build'
$DeployFile = "$BuildPath\deploy.json"
$ProgramFiles = 'C:\Program Files (x86)\'
$ConfigFile = '.\config\deployconfig.json'
$DbConfigFile = '.\config\dbdeployconfig.json'

#################################
# config setup and loading
#################################
try {
    # loads assembly for file/folder picker and ImportExcel Module
    Add-Type -AssemblyName 'System.Windows.Forms'
    Write-Host 'Loading ImportExcel module, please hold...'
    if (Get-Module ImportExcel -ListAvailable) { 
        Import-Module ImportExcel
        Write-Output 'ImportExcel module loaded.'
    }
    else {
        if (Find-Module -Name ImportExcel | Install-Module -Scope CurrentUser -Confirm:$false) {
            Write-Output 'ImportExcel module installed.'
        }
        else {
            Write-Output '[!] ImportExcel module could not be installed--cannot continue.'
            exit 
        }
    }

    # see if we have a config.xml file, if we do, load it, if not find tf.exe and ask for tfs code root and then create config.xml
    if (Test-Path $ConfigFile -PathType Leaf) {
        # import existing config
        $Config = Get-Content -Path $ConfigFile | ConvertFrom-Json
        $TfExe = $Config.TfExePath
        $TfsRootPath = $Config.TfsRootPath
    }
    else {
        # find tf.exe
        Write-Output 'Searching for tf.exe, please hold...'
        $TfExe = Get-ChildItem -Path $ProgramFiles -Filter 'tf.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -Last 1
        if (-not $TfExe) { 
            Write-Output 'tf.exe cannot be found, please verify you have Visual Studio or Team Explorer installed and try again'
            exit 
        }
        else {
            Write-Output 'tf.exe found.'
        }
        
        # display a folder picker for  tfs path
        $folderbrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderbrowser.RootFolder = 'MyComputer'
        $folderbrowser.Description = 'Choose the  TFS root folder...'
        $folderbrowser.ShowDialog() | Out-Null
        if (-not ($TfsRootPath = $folderbrowser.SelectedPath)) { 
            Write-Output 'You didnt choose a folder.'
            exit
        }
        else {
            Write-Output ' TFS root set.'
        }
    
        if ($TfExe -and $TfsRootPath ) {
            [PSCustomObject]@{
                TfExePath        = $TfExe
                TfsRootPath = $TfsRootPath
            } | ConvertTo-Json | Out-File -FilePath $ConfigFile -Encoding UTF8
        }
    }
    
    # validate config file info
    if (-not (Test-Path $TfExe) -or -not (Test-Path $TfsRootPath)) { 
        Write-Output '[!] A configuration error was detected, please run the script again and it will ask to redefine the values.'
        Remove-item -Path $ConfigFile
        exit
    }

    # load the dbconfig
    $DbConfig = Get-Content $DbConfigFile | ConvertFrom-Json

    # create build folder
    if (-not (Test-Path -Path $BuildPath)) { $null = New-Item -Path $BuildPath -ItemType Directory }
}
catch {
    $ErrorMessAge = $_.Exception.MessAge
    Write-Output $ErrorMessAge
    Read-Host 'Error during config! Press ENTER to close'
    Remove-item -Path $ConfigFile
    exit
}


#################################
# main process
#################################
try {
    # creates a random tag to apply to zip name
    $Id = -join ((65..90) + (97..122) | Get-Random -Count 6 | ForEach-Object { [char]$_ })

    # if we didnt pass the environment parameter, ask for it, if we did, check if its valid
    if (-not ($PSBoundParameters.ContainsKey('Env'))) {
        do {
            Write-Output "`n= = = B U I L D  K I T = = ="
            $Environments | Format-Table -Property @{Name = 'Code'; Expression = { $_.Name } }, @{Name = 'Environment'; Expression = { $_.Value } } -AutoSize
            $buildenv = Read-Host "[?] Please enter an environment code to build for or CTRL-C to exit"
            if ($Env = $Environments[$buildenv]) {
                $answer = Read-Host "[?] Is this correct? $Env (y/n)"
            }
        } until ($answer -eq 'y')
    }
    elseif (-not $Environments.ContainsValue($Env)) {
        Write-Output 'Bad environment parameter, try again.'
        exit
    }
    
    # if we didnt pass excel file parameter, ask for it, if we did, check if its valid
    if (-not ($PSBoundParameters.ContainsKey('ExcelFile'))) {
        do {
            Write-Output "`n[!] Please choose your Excel file when the file chooser opens..."
            $openfile = New-Object System.Windows.Forms.OpenFileDialog
            $openfile.filter = "XLSX (*.xlsx)| *.xlsx"
            $openfile.InitialDirectory = $PSScriptRoot
            $openfile.ShowDialog() | Out-Null
            $ExcelFile = $openfile.FileName
            $answer = Read-Host "[?] Is this correct? $ExcelFile (y/n)"
        } until ($answer -eq 'y')
    }
    elseif (-not (Test-Path $ExcelFile)) {
        Write-Output 'Bad excel file parameter, try again.'
        exit
    }
            
    # update local tfs files for requested environment
    Write-Output "`nPerforming GET on TFS for $Env"
    $TfParms = @('get', "$TfsRootPath\ Source $($Env)\DB", '/recursive')
    & $TfExe $TfParms | Out-Default
    Write-Output 'GET completed.'
        
    # import excel data, get list of local files paths, and verify they exist
    Write-Output "`nGetting list of files from Excel."
    $ExcelData = Import-Excel -Path $ExcelFile

    # get files count, creates the list of valid file paths, this also corrects the '/' to '\' for windows paths
    $FileCount = $ExcelData.'File Path'.Count
    $Files = @()
    $Files += $ExcelData.'File Path'.Replace('$/', 'D:\\ROOT\') | Resolve-Path | Select-Object -ExpandProperty Path

    # if we validated some files, create the deploy.xml
    if ($Files.Count -gt 0) { 

        # compares count vs valid count to make sure they match, else exits
        if ($FileCount -eq $Files.count) {
            Write-Output "`nFound $($Files.Count) valid files."
            $Files | Format-Table
        }
        else {
            Write-Output "`nInvalid files found in Excel file, exiting."
            exit
        }

        # create deploy xml file
        Write-Output "`nCreating deploy.xml."
        $Deploy = @()
        foreach ($file in $Files) {

            # this get the folder name for the scripts, this corresponds to which database in --Online, Reporting, E/C Portal
            $TfsFolder = $file.Split('\')[5]
                   
            # sets the priority and type for each script
            # note: when using switch -wildcard, it keeps looking after finding a match and uses last match, 
            # so this needs a break in each to not continue or could change order of matching, used the former here
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

            # grabs the targets for this tfs folder, in UAT\Online, we may have TIMEWARP and Online, so we want to capture both of those
            $targets = $DbConfig | Where-Object { $_.Environment -eq $Env -and $_.TfsFolder -eq $TfsFolder } 
            $obj = foreach ($t in $targets) { 
                [PSCustomObject] @{
                    Application = $Application
                    Instance    = $t.Instance
                    Database    = $t.Database
                    SqlFile     = $file.Split("\")[-1]
                    Type        = $Type
                    Priority    = $Priority
                    Status      = 'NONE'
                    Comment     = ''
                }
            }
            $Deploy += $obj
        }

        # exports deploy to xml
        $Deploy | ConvertTo-Json | Out-File -FilePath $DeployFile -Encoding UTF8

        Write-Output "`nCreating build package."
        
        # adds the excel and deploy.xml to file list and then compresses them all to a zip--these are '$null =' so they are quiet
        # this cleans up any files used during the process so only the zip file is left at the end
        $Files += $ExcelFile
        $Files += Resolve-Path -Path $DeployFile | Select-Object -ExpandProperty Path
        Compress-Archive -Path $Files -DestinationPath "$($BuildPath)\$($Application)_$($Env)_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$($Id)"
        Remove-Item $DeployFile

        Write-Output "`nBuild is complete."
    }
    else {
        Write-Output 'No data found in the Excel file, please check the column name is ''File Path''.'; exit; 
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Output $ErrorMessage
}
Read-Host "`nPress ENTER to continue"