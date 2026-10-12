Import-Module SqlServer

Get-ChildItem SQLSERVER:\SQL\$($env:ComputerName) | Foreach-Object { Get-ChildItem -Path "$($_.PSPath)\AvailabilityGroups" | ForEach-Object { Get-ChildItem "$($_.PSPath)\AvailabilityReplicas" | Format-Table -AutoSize } }