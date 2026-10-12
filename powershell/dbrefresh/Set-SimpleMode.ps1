<#
.SYNOPSIS
    Set Recovery Model for requested databases.
.DESCRIPTION
    This runs as an accessory script to the main fresh Run-* scripts. It runs after all refreshes are completed.
.EXAMPLE
    & .\Set-SimpleMode.ps1 -RequestFile $splat.RequestFile
.INPUTS
    RequestFile(mandatory). It uses this file to know what database were refreshed and to know to what to mark as Simple.
.NOTES
    This is part of the refresh process and uses the same input request file. 
    The is generally only needed for DEV/SIT that are not in an AG.
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ } )]
    [string]$RequestFile,

    [ValidateScript( { Test-Path $_ } )]
    [string]$DbConfigFile = ".\config\DbConfig.csv"
)

if (Get-Module SqlServer -ListAvailable) { 
    Import-Module SqlServer
}
else {
    Write-Output 'SqlServer module not found.'
    throw
}

$ErrorActionPreference = 'Stop'

$DbConfig = Get-Content -Path $DbConfigFile | Select-String '^[^#]' | ConvertFrom-Csv

$Requests = Get-Content -Path $RequestFile | Select-String '^[^#]' | ConvertFrom-Csv -Delimiter ';'

$RefreshData = @()

try {
    foreach ($Item in $Requests) {

        # find the index of this db in the dbconfig file
        $Index = ($DbConfig.TargetDb).IndexOf($Item.Database)
    
        # make sure we have the correct index and didnt just fall to the end
        if ($Item.Database -eq $DbConfig[$Index].TargetDb) {
        
            # creates base object from request and dbconfig files
            $RefreshObj = [PSCustomObject]@{
                Instance = $DbConfig[$Index].Listener
                TargetDb = $Item.Database
            }
        
            # checks the the DB exists so we can export data from it
            if (-not (Get-SqlDatabase -ServerInstance $RefreshObj.Instance -Database $RefreshObj.TargetDb)) {
                Write-Output "$($RefreshObj.TargetDb) does not exist on $($RefreshObj.Instance). Skipping."
                Continue
            }
        
            # adds the data row to table
            $RefreshData += $RefreshObj     
        } 
        else {
            Write-Output -Source $Source -Message "$($Item.Database) was not found in the config file. Skipping." -Type Error
            continue
        }
    }

    Write-Output "Setting Simple Recovery Model for each requested database currently in Full."

    foreach ($Refresh in $RefreshData) {

        $Database = Get-SqlDatabase -ServerInstance $Refresh.Instance -Database $Refresh.TargetDb
        if ($Database.RecoveryModel -eq 'Full') { 
            $Database.RecoveryModel = 'Simple' 
            $Database.Alter()
            "`t{0} simple mode set." -f $Database.Name
        }
    }
}
catch {
    $ErrorException = $_.Exception
    $ErrorException
    "[!] Simple mode failed for {0}." -f $Database.Name
    continue
}

Read-Host -Prompt "::: Script completed. Press ENTER to exit. ::"