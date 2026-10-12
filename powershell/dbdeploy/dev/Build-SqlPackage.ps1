<#
.SYNOPSIS
    Creates a zip package of sql scripts to run with Deploy-SqlPackage, this 'builder' is a generic script.
.DESCRIPTION
    This will scrape the input folders for your chosen app and depending on which folder it's contained it, it will build the package for it.
.EXAMPLE
    Can be run cli with parameters or run via explorer and it will ask for inputs.
    PS C:\> Build-SqlPackage.ps1 -Env PROD 
.INPUTS
    Env: This is what environment you want to build for. This controls what TFS environment is refreshed.
    FilePath: This is the Excel request file. It should contain a 'File Path'
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
[CmdletBinding(DefaultParametersetName = "default")]  
param (
    [String]$Application,
    [String]$Environment,
    
    [Parameter(ParameterSetName = 'Generic')]
    [String]$InputFolder,
    
    [Parameter(ParameterSetName = 'Custom')]
    [String]$ExcelFile
)
@'
   _ _     _         _         
 _| | |_ _| |___ ___| |___ _ _ 
| . | . | . | -_| . | | . | | |
|___|___|___|___|  _|_|___|_  |
                |_|       |___|

'@

Set-Location $PSScriptRoot
$ProgressPreference = 'SilentlyContinue'

# static
$BuildFolder = "$PSScriptRoot\build"
$DeployFile = "$BuildFolder\deploy.json"
$DbConfigFolder = "$PSScriptRoot\config\db"
$BuildConfigFolder = "$PSScriptRoot\config\build"

#################################
# build config setup
#################################

try {
    $PSBoundParameters
    Add-Type -AssemblyName 'System.Windows.Forms'
    
    # create build folder
    if (-not (Test-Path -Path $BuildFolder)) { $null = New-Item -Path $BuildFolder -ItemType Directory }
    
    # load the all db configs
    $DbConfig = @()
    Get-ChildItem -Path $DbConfigFolder -File -Filter '*.json' | ForEach-Object { $DbConfig += Get-Content $_.FullName | ConvertFrom-Json }

    [array]$Applications = $DbConfig | Sort-Object -Property Application -Unique
    if (-not ($PSBoundParameters.ContainsKey('Application'))) {
        $continue = $false
        do {
            $i = 0
            "Applications:"
            $Applications | ForEach-Object { "  {0}  {1}" -f $i++, $_.Application }
            [int]$WhatApp = Read-Host "[?] Which application?"

            if ($null -ne $WhatApp -and $WhatApp -lt $Applications.Count) {
                $Application = $Applications[$WhatApp].Application
                $continue = $true
            }
            else {
                Write-Output '[!] That is not a valid choice, try again.'
                continue 
            }
            
        } until ($continue -eq $true)
    }
    elseif (-not ($Applications.Application -contains $Application)) {
        "That is not a valid Application parameter, try again!"
        exit
    }

    [array]$Environments = $DbConfig | Where-Object { $_.Application -eq $Application }  | Sort-Object -Property Rank, Environment -Unique
    if (-not ($PSBoundParameters.ContainsKey('Environment'))) {
        $continue = $false
        do {
            $Environment = @()
            $Invalid = 0

            $i = 0
            Write-Output "`nEnvironments:"
            $Environments | ForEach-Object { "  {0}  {1}" -f $i++, $_.Environment }
            [array]$WhatEnv = (Read-Host "[?] Which environments (comma seperated)?").Split(',')

            foreach ($item in $WhatEnv) {
                if ($null -ne ($item -as [int]) -and $item -ne '' -and [int]$item -lt $Environments.Count) {
                    $Environment += $Environments[$item].Environment
                    $continue = $true
                }
                else {
                    $Invalid++
                }
            }
            
            if ($Invalid -gt 0) {
                Write-Output '[!] That is not a valid choice, try again.'
                continue 
            }

        } until ($continue -eq $true)
    }
    elseif (-not ($Environments.Environment -contains $Environment)) {
        Write-Output "That's not a valid Environment parameter, try again!"
        exit
    }

    $BuildConfig = $Dbconfig | Where-Object { $_.Application -eq $Application -and $_.Environment -in $Environment }
    $BuildConfig | Format-List

    # this is for custom build scenarios
    switch ($Application) {
        # start decss custom build process
        "DECSS" {
            $DecssConfigFile = "$BuildConfigFolder\$Application.json"

            Write-Host 'Loading ImportExcel module, please hold...'
            if (Get-Module ImportExcel -ListAvailable) { 
                Import-Module ImportExcel
                Write-Output 'ImportExcel module loaded.'
            }
            else {
                Install-Module ImportExcel -Scope CurrentUser
                Write-Output 'ImportExcel module installed.'
            }
            
            # see if we have a decss config file and load it, else find tf.exe and ask for tfs code root and then create it.
            if (Test-Path $DecssConfigFile -PathType Leaf) {
                $DecssConfig = Get-Content -Path $DecssConfigFile | ConvertFrom-Json
                $TfExe = $DecssConfig.TfExePath
                $TfsDecssRootPath = $DecssConfig.TfsDecssRootPath
            }
            else {
                Write-Output 'Searching for tf.exe ...'
                $TfExe = (Get-ChildItem -Path $ProgramFiles -Filter 'tf.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -Last 1).FullName
                if (-not $TfExe) { 
                    Write-Output 'tf.exe cannot be found, please verify you have Visual Studio or Team Explorer installed and try again'
                    exit 
                }
                else {
                    Write-Output 'tf.exe found.'
                }

                $continue = $false
                do {
                    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog
                    $FBD.RootFolder = 'MyComputer'
                    $FBD.Description = 'Choose the DECSS TFS root folder...'
                    $FBD.ShowDialog() | Out-Null
                    if ($TfsDecssRootPath = $FBD.SelectedPath) { $continue = $true }
                } until ($continue -eq $true)

                if ($TfExe -and $TfsDecssRootPath ) {
                    [PSCustomObject]@{
                        TfExePath        = $TfExe
                        TfsDecssRootPath = $TfsDecssRootPath
                    } | ConvertTo-Json | Out-File -FilePath $DecssConfigFile -Encoding UTF8
                }
            }
                
            # validate config file info
            if (-not (Test-Path $TfExe) -or -not (Test-Path $TfsDecssRootPath)) { 
                Remove-item -Path $DecssConfigFile
                Write-Output '[!] A configuration error was detected, please run the script again and it will ask to redefine the values.'
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
                    $answer = $null
                    $answer = Read-Host "[?] Is this correct? $($ExcelFile.Split('\')[-1]) (y/n)"
                    if ($answer.ToUpper() -eq 'Y') { $continue = $true }
                } until ($continue -eq $true)
            }
            elseif (-not (Test-Path $ExcelFile)) {
                'Bad excel file parameter, try again.'
                exit 
            }

            $TfsEnvironment = $BuildConfig.TfsEnvironment | Sort-Object -Unique

            # update local tfs files for requested environment
            Write-Output "`nPerforming GET on TFS for $($TfsEnvironment.ToUpper())"
            $TfParms = @('get', "$TfsDecssRootPath\DECSS Source $($TfsEnvironment)\DecssDB", '/recursive')
            # & $TfExe $TfParms
            # if ($?) {
            #     Write-Output 'GET completed.'
            # }
            # else {
            #     Remove-item -Path $DecssConfigFile
            #     Write-Output "[!] Something is wrong with your TFS config/path. Please run again and choose correct DECSS TFS source code path."
            #     exit
            # }
    
exit

            # import excel data, get list of local files paths, and verify they exist
            Write-Output "`nGetting list of files from Excel."
            $ExcelData = Import-Excel -Path $ExcelFile

            # get file count, creates the list of valid file paths, this corrects the '/' to '\' for windows paths that comes from tfs
            $FileCount = $ExcelData.'File Path'.Count
            [Array]$Files = ($ExcelData.'File Path'.Replace('$/', "$TfsDecssRootPath\") | Resolve-Path).Path

            # make sure we found some files on the filesystem
            if ($Files.Count -eq 0) { 
                Write-Output '[!] No data found in the Excel file, please check the column name is ''File Path''.'
                exit
            }

            # make sure the excel file count matches the validated file count on the filesystem
            if ($FileCount -ne $Files.count) {
                Write-Output '[!] Invalid files found in Excel file. This could be be caused by missing files if TFS GET failed.'
                exit
            }

            $Files | Format-Table
            Write-Output "Found $($Files.Count) valid files."

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

            $Files += $ExcelFile
                
            break
        }
        # end decss custom build process
        default { 
            # this for a generic build scenario--passing .sql files from a folder
            if (-not ($PSBoundParameters.ContainsKey('InputFolder'))) {
                $continue = $false 
                do {
                    # display a folder picker for decss tfs path
                    $FBD = New-Object System.Windows.Forms.FolderBrowserDialog
                    $FBD.RootFolder = 'MyComputer'
                    $FBD.Description = 'Choose the path to your .sql files to build ...'
                    $FBD.ShowDialog() | Out-Null
                    if ($InputFolder = $FBD.SelectedPath) { 
                        $continue = $true
                    }
                } until ($continue -eq $true)
            }
            elseif (-not (Test-Path -Path $InputFolder)) {
                "That's not a valid InputFolder parameter, try again!"
                exit
            }
            Write-Output "Input Folder: $InputFolder"

            # gets list of sql files from input folder, searches subfolders and sorts based on folder\file name, if execution sequence matters, number them accordingly
            # since this is zipping all files into 1 folder without subfolder, names will collide if they are the same
            [Array]$Files = (Get-ChildItem -Path $InputFolder -Filter '*.sql' -Recurse | Sort-Object Directory, Name).FullName

            if ($Files.Count -eq 0) { 
                "I didnt find any .sql files at that path."
                exit
            }

            Write-Output "Creating deploy file ..."

            $i = 10  
            # loops thru targets and files, sets order/priority based on order incoming from file list
            # we could have multiple targets for each file
            $Deploy = foreach ($item in $BuildConfig) { 
                foreach ($file in $Files) {
                    [PSCustomObject] @{
                        Application = $Application
                        Instance    = $item.Instance
                        Database    = $item.Database
                        SqlFile     = $file.Split("\")[-1]
                        Type        = 'SQL'
                        Priority    = $i
                        Status      = 'NONE'
                        Comment     = ''
                    }
                    $i += 10
                }
            }
        }
    }

    if ($Deploy.count -eq 0) {
        Write-Output '[!] Deploy object is empty, nothing to output.'
        exit
    }

    $Deploy | ConvertTo-Json | Out-File -FilePath $DeployFile -Encoding UTF8

    Write-Output "Creating build package ..."
        
    # creates a random id to tag the output file with
    $Id = -join ((65..90) + (97..122) | Get-Random -Count 6 | ForEach-Object { [char]$_ })

    $Files += (Resolve-Path -Path $DeployFile).Path
    $ZipFile = "$($BuildFolder)\$($Application)_$($Environment)_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$($Id).zip"

    Compress-Archive -Path $Files -DestinationPath $ZipFile

    Remove-Item $DeployFile

    Write-Output "Build package complete: $ZipFile"
    Invoke-Item (Get-Item $ZipFile).Directory
}
catch {
    $Exception = $_
    Write-Output "! Error during build."
    Write-Output $Exception
}

Read-Host "::: ENTER ::"