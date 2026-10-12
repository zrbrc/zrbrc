Set-Location $PSScriptRoot

$task_script = '.\script.ps1'

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "'-file $task_script'"
$trigger = New-ScheduledTaskTrigger -Daily -At 6am

$splat = @{
    Cluster  = $cluster_name
    TaskName = 'Some Name'
    Action   = $action
    Trigger  = $trigger
}

Register-ScheduledTask $splat