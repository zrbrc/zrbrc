<#
.SYNOPSIS
    Deploys a zip package contains SQL files.
.DESCRIPTION
    Thic script will take an input Excel file with a list of sql file to build for, the sql files are updated on disk from TFS. Initial TFS
    setup needs to be performed before this process will work. See instructions in document folder for how-to.
.PARAMETER Env 
    Optional: You can pass the environmental code via cli.
.PARAMETER DeployZip 
    Optional: You can pass the environmental code via cli.
.PARAMETER Force
    Optional: This will force the use of the files in the zip and overwrite any existing similarly named files.
.EXAMPLE
    Can be run cli with parameters or run via explorer and it will ask for inputs.
    PS C:\> Build-DecssSqlPackage.ps1 -Env PROD -FilePath C:\Temp\Prod_build_files.xlsx
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
    [Alias('Z')][String]$DeployZip,
    [switch]$Force
)
@'
   _ _     _         _         
 _| | |_ _| |___ ___| |___ _ _ 
| . | . | . | -_| . | | . | | |
|___|___|___|___|  _|_|___|_  |
                |_|       |___|

'@

Set-Location $PSScriptRoot

$archive = '.\archive'
$temp = '.\temp'
    
Write-Output "[i] Loading SqlServer module."
if (Get-Module SqlServer -ListAvailable) { 
    Import-Module SqlServer
    Write-Output "[i] SqlServer module loaded."
}
else {
    Write-Output "[!] SqlServer module not found, please install and run again."
    exit 
}

# main try block
try {
    # loads assembly for file/folder picker and ImportExcel Module
    Add-Type -AssemblyName 'System.Windows.Forms'

    # if we didnt pass excel file parameter, ask for it, if we did, check if its valid
    if (-not $PSBoundParameters.ContainsKey($DeployZip)) {
        $proceed = $false 
        do {
            Write-Output "`n[!] Please choose deploy zip when the file chooser opens..."
            $openfile = New-Object System.Windows.Forms.OpenFileDialog
            $openfile.filter = "ZIP (*.zip)| *.zip"
            $openfile.InitialDirectory = $PSScriptRoot
            $openfile.ShowDialog() | Out-Null
            $DeployZip = $openfile.FileName
            if ($DeployZip) {
                $answer = Read-Host "[?] Is this correct? $DeployZip (y/n)"
                if ($answer -eq 'y') {
                    $proceed = $true
                }
            }
        } until ($proceed -eq $true)
    }
    elseif (-not (Test-Path $DeployZip)) {
        Write-Output "Bad deploy zip parameter, try again."
        exit
    }
    
    # create archive, log, folder if doesnt exist
    if (-not (Test-Path -Path $archive -PathType Container)) { $null = New-Item -Path $archive -ItemType Directory }
    if (-not (Test-Path -Path $temp -PathType Container)) { $null = New-Item -Path $temp -ItemType Directory }
    
    # gets file object
    $DeployZipFile = Get-ChildItem -Path $DeployZip
    $Base = "$temp\$($DeployZipFile.BaseName)"
    
    # start logging
    $LogFile = "$temp\LOG_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    Start-Transcript -Path $LogFile
    Write-Output "[i] Working directory: $((Get-Location).Path)"
        
    # check if we already have a similarly named zip archived
    if ((Get-ChildItem $archive -Filter "*$($DeployZipFile.BaseName)*" ).Count -ne 0) {
        if ($Force.IsPresent) {
            Write-Output "[i] Found a matching zip file in archive, but -Force switch set, continuing."
        }
        else {
            $answer = Read-Host "[?] Found a matching zip file in archive, did this already deploy, do you want to deploy it anyway? (y/n)"
            if ($answer -ne 'y') { 
                Write-Output "[!] Not deploying any changes, exiting!"
                Start-Sleep -Seconds 5
                exit
            }
        }
    }
    
    # check to see if we have an extracted zip that we didnt clean up b/c of a deploy error, can choose to use those files or not
    if (Test-Path -Path $Base) {
        if ($Force.IsPresent) {
            Write-Output "[i] Found a matching folder in temp, but -Force switch set, re-extracting files from zip."
            Expand-Archive -Path $DeployZipFile -DestinationPath $Base -Force
        }
        else {
            $answer = Read-Host "[?] Found a matching folder in temp, use existing files for deploy? (y/n)"
            if ($answer -ne 'y') {
                Write-Output "[i] Re-extracting files from zip."
                Expand-Archive -Path $DeployZipFile -DestinationPath $Base -Force
            }
        }
    }
    else {
        Write-Output "[i] Extracting files from zip."
        Expand-Archive -Path $DeployZipFile -DestinationPath $Base -Force
    }
    
    # starts doing work
    Write-Output "`n[$(Get-Date -Format 'HH:mm:ss')] Deploying $($DeployZipFile.Name)."
    
    # import deploy details
    $DeployFile = "$Base\deploy.json"
    $Deploy = Get-Content -Path $DeployFile | ConvertFrom-Json

    # run each deploy script
    foreach ($item in $Deploy | Sort-Object Priority, SqlFile) {
            
        # if its already completed, dont run it and state as so
        if ($item.Status -eq 'Completed') {
            Write-Output "`n[$(Get-Date -Format 'HH:mm:ss')] $($item.Sqlfile) already completed."
        }
        else {
            # run the scripts
            $Instance = $item.Instance
            $Database = $item.Database

            # convert relative path to full path to use with dbatools call
            $SqlScript = (Resolve-Path "$Base\$($item.Sqlfile)").Path
            
            Write-Output "`n[$(Get-Date -Format 'HH:mm:ss')] Executing : $Database : $SqlScript"
            $StartTime = Get-Date

            # if this is a select, it will display the output nicely
            if ($item.Type -eq 'select') {
                $dataset = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query (Get-Content $SqlScript | Out-String) -OutputSqlErrors $true  -ErrorAction Stop
                $dataset | Format-Table
            }
            else {
                Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query (Get-Content $SqlScript | Out-String) -Verbose -OutputSqlErrors $true  -ErrorAction Stop
            }

            $EndTime = Get-Date
            Write-Output "[$(Get-Date -Format 'HH:mm:ss')] Done"

            Write-Output "Time taken: $(New-TimeSpan -Start $StartTime -End $EndTime)`n" 
            
            $Item.Status = 'Completed'
        }
    }
}
catch {
    $Item.Status = 'Failed'
    Write-Output "[!] There was a problem executing $($item.Sqlfile)."
    $ErrorMessage = $_.Exception.Message
    Write-Output $ErrorMessage 
}

# displays and stores the status of the run to support retries
$Deploy | Sort-Object Priority, SqlFile | Select-Object Status, SqlFile | Format-Table -AutoSize
$Deploy | ConvertTo-Json | Out-File -FilePath $DeployFile -Encoding UTF8

Stop-Transcript

# if we had some errors, leave the deploy where it is, else move to archive
if ($Deploy.Status -contains 'Failed') {   
    Write-Output '[!] Not all files completed, please check log.'
}
else {
    Write-Output 'Updating and archiving deploy zip.'

    # adds updated deploy.xml and log file to zip
    Compress-Archive -path $DeployFile -DestinationPath $DeployZipFile -Update
    Compress-Archive -path $LogFile -DestinationPath $DeployZipFile -Update

    # moves the files to archive folder and adds another timestamp as the execution time
    $null = Move-Item -Path $DeployZipFile -Destination "$($archive)\$($DeployZipFile.BaseName)_$(Get-Date -Format 'yyyyMMdd_HHmmss')$($DeployZipFile.Extension)"
    
    # removes temp extracted files and log file after successfull completion
    $null = Remove-Item -Path $Base -Recurse -Force
    $null = Remove-Item -Path $LogFile -Force
}

Read-Host "`n[#] Script finished. Press ENTER to continue."
