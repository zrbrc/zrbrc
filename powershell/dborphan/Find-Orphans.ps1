<#
.SYNOPSIS
    Find orphans on the server in the servers.txt file.
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>

Set-Location $PSScriptRoot

Import-Module dbatools
Import-Module ImportExcel

$ExcelFile = ".\Sql_Orphans_$(Get-Date -Format "yyyyMMdd_hhmm").xlsx"

# $credspath = "$env:LOCALAPPDATA\basetech.xml"
# if (Test-Path -Path $credspath -PathType Leaf) {
#     $basetech = Import-Clixml $credspath
#     Write-Output "Credentials imported from $credspath."
# }
# else {
#     $basetech = Get-Credential -Credential 'basetech'
#     $basetech | Export-Clixml $credspath
#     Write-Output "Account credentials stored to $credspath."
# }

# $instances = Get-Content '.\servers.txt'
$instances = @(
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15151',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150'
)
$table = @()

try {
    foreach ($instance in $instances) {
        $instance
        $row = Get-DbaDbOrphanUser -SqlInstance $instance #-SqlCredential $basetech
        $row | Add-Member -MemberType NoteProperty -Name 'IPPort' -Value $instance
        $table += $row
    }
}
catch { 
    break 
}
if ($table) {
    $table | Export-Excel -Path $ExcelFile

    Write-Output "excel created"
}