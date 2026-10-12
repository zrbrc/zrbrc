#Requires -runasadministrator

# FILL IN THE PASSWORD ON THE LAST LINE BEFORE RUNNING

$actions = New-ScheduledTaskAction -Execute 'powershell' -Argument '-NoProfile -ExecutionPolicy Bypass -File "D:\Scripts\MSSQL\dbmetric\Get-MetricBackupHistory.ps1"' -WorkingDirectory 'D:\Scripts\MSSQL\dbmetric'
$trigger = New-ScheduledTaskTrigger -Daily -At '7:00 AM'
$task = New-ScheduledTask -Action $actions -Principal $principal -Trigger $trigger
Register-ScheduledTask 'Get_Backup_History' -InputObject $task -TaskPath "\Basetech\MSSQL\" -User 'state\sqladmin.dept' -Password ''


# export and import something like below

#export all to single task files
Get-ScheduledTask -TaskPath '\Basetech\MSSQL\' | % { $_ | Export-ScheduledTask | Out-File ".\$($_.TaskName).xml" }

Register-ScheduledTask -Xml (get-content '.\Update_SQLInstance_List.xml' | Out-String) -TaskName 'temp' -TaskPath '\basetech\' -User 'state\sqladmin.dept' -Password '' 

### this doesnt really do much different, less control overall--cant control working folder of job and cant control location in scheduled task manager, also didnt transcribe anything
# $option = New-ScheduledJobOption # default options are fine, not setting anything extra
$trigger = New-JobTrigger -Weekly -At "8:00 PM" -DaysOfWeek Sunday
Register-ScheduledJob -Name 'Get_Backup_History_psjob' -FilePath 'D:\Scripts\MSSQL\dbmetric\Get-MetricBackupHistory.ps1' -Trigger $trigger -Credential 'state\sqladmin.dept'