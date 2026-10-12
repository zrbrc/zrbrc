<#
.SYNOPSIS
    Generic sql execute loop
.DESCRIPTION
    Will run thru a loop of instances and stores output.
.NOTES
    DONT NOT EDIT THIS. Make a copy and make your change in your own workspace.
#>
Import-Module dbatools

$Instances = @('xx.xx.xx.xx,15150')

Write-Output "`n[$(Get-Date -Format "HH:mm:ss")] Start.`n"
$StartMs = Get-Date

# loop thru instances and stores all the output to the $table variable
$table = foreach ($i in $instances) {
    
    # do some work here
    Get-DbaDiskSpace -ComputerName $i

}
$table

$EndMs = Get-Date
Write-Output "`n[$(Get-Date -Format "HH:mm:ss")] Time Taken: $(New-TimeSpan -Start $StartMs -End $EndMs)`n"