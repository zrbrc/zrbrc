<#
.SYNOPSIS
    Generic sql execute loop
.DESCRIPTION
    Will run thru a loop of instances and stores output.
.NOTES
    DONT NOT EDIT THIS. Make a copy and make your change in your own workspace.
#>
Import-Module dbatools

# uses stored credentials or creates new
$credspath = "$env:LOCALAPPDATA\basetech.xml"
if (Test-Path -Path $credspath -PathType Leaf) {
    $basetech = Import-Clixml $credspath
    Write-Output "Credentials imported from $credspath."
}
else {
    $basetech = Get-Credential -Credential 'basetech'
    $basetech | Export-Clixml $credspath
    Write-Output "Account credentials stored to $credspath."
}

$Instances = @('xx.xx.xx.xx,15150')

Write-Output "`n[$(Get-Date -Format "HH:mm:ss")] Start.`n"
$StartMs = Get-Date

# loop thru instances and stores all the output to the $table variable
$table = foreach ($i in $instances) {
    
    # do some work here
    Get-DbaAgentJobHistory -SqlInstance $i -SqlCredential $basetech -StartDate '2020-04-21' -EndDate '2020-04-22'

}
$table | Export-Excel -Path '.\jobs_report.xlsx'

$EndMs = Get-Date
Write-Output "`n[$(Get-Date -Format "HH:mm:ss")] Time Taken: $(New-TimeSpan -Start $StartMs -End $EndMs)`n"