Set-Location $PSScriptRoot

Import-Module dbatools

# update this path to the servers.txt file, full or relative path should work
# $servertxt = "..\Inventory\servers.txt"

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

# comment either line, use 231.242 for testing
# $Instances = Get-Content -Path $servertxt | Sort-Object
$Instances = @('xx.xx.xx.xx,15150')

Write-Output "`n[$(Get-Date -Format "HH:mm:ss")] Start.`n"
$StartMs = Get-Date

# simple query for schedules
# $QueryText = "select @@SERVERNAME as Server, sysschedules.name, enabled, sql_logins.name, date_modified, schedule_id from msdb.dbo.sysschedules left join sys.sql_logins On sql_logins.sid=sysschedules.owner_sid"

# this is a better query that queries jobs and their schedules
$QueryText = "SELECT SJ.name AS JobName, CASE WHEN SJ.enabled = 1 THEN 'Enable' ELSE 'Disable' END AS JobStatus, SJ.description AS JobDescription, SS.name AS JobScheduleName, CASE WHEN SS.enabled = 1 THEN 'Enable' WHEN SS.enabled = 0 THEN 'Disable' ELSE 'Not Schedule' END AS JobScheduleStatus, SS.active_start_date AS ActiveStartDate, SS.active_end_date AS ActiveEndDate, SS.active_start_time AS ActiveStartTime, SS.active_end_time AS ActiveEndTime FROM dbo.sysjobs AS SJ LEFT JOIN dbo.sysjobschedules AS SJS ON SJ.job_id = SJS.job_id LEFT JOIN dbo.sysschedules AS SS ON SJS.schedule_id = SS.schedule_id"

# loop thru instances
$table = foreach ($i in $instances) {
    
    # do some work here
    Invoke-DbaQuery -SqlInstance $i -SqlCredential $basetech -Query $QueryText -Database msdb

}
$table | fl

$EndMs = Get-Date
Write-Output "`n[$(Get-Date -Format "HH:mm:ss")] Time Taken: $(New-TimeSpan -Start $StartMs -End $EndMs)`n"