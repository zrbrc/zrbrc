<# 

This can be installed remotely by using a command like below, just change the ComputerName to the target and change the file path to reflect where this file is locally.

Invoke-Command -ComputerName hostname4n1,hostname4n3 -FilePath m:\Management\Workspace\DBA\Powershell\du\Install-DollarUniverseServiceCheck.ps1

This script includes the embedded script that it will install remotely for the $U service check. It's in the $script variable. It installs the script 
(Check-DollarUniverseService) on the remote system to C:\Windows and creates a scheduled task to run every 15 minutes. The scheduled task/script 
will check for $U services, log the status, and send an email if it finds $U services that are not started that should be.

#>

# this is the script that will be installed on the remote system for the service check
$script = @'
try {
    $ErrorActionPreference = 'Stop'
        
    $logfile = 'C:\Windows\Check-DollarUniverseService.log'

    # if file gets above 25MB, empty it
    if (Test-Path -Path $logfile -PathType Leaf) {
        if ((Get-Item -Path $logfile).Length -gt 25000000) { $null = New-Item $logfile -Itemtype File -Force }
    }

    $emailsplat = @{
        To         = 'dept05sg_SQLAlerts@delaware.gov'
        From       = 'dept05sg_SQLAlerts@delaware.gov'
        SmtpServer = 'smtp.state.de.us' 
    }

    if (Get-Command -Name Get-Cluster) {

        if ($IOService = Get-ClusterResource -Name "*_IO_*") {
            $Cluster = Get-Cluster
            "{0} : {1} - {2} - {3}" -f (Get-Date), $Cluster.Name, $IOService.Name, $IOService.State | Tee-Object -Variable status 
                       
            if ($IOService.State -ne 'Online') {
                Send-MailMessage @emailsplat -Subject $status -Body '<EOM>' 
            }
        }
        elseif ($IOService = Get-Service -Name "*_IO_*") {
            "{0} : {1} - {2}" -f (Get-Date), $IOService.Name, $IOService.Status| Tee-Object -Variable status
                
            if ($IOService.Status -ne 'Running') {
                Send-MailMessage @emailsplat -Subject $status -Body '<EOM>' 
            }
        }
        else {
            "{0} : No Dollar Universe services found." -f (Get-Date) | Tee-Object -Variable status 
        }
    }
    else {
        if ($IOService = Get-Service -Name "*_IO_*") {
            "{0} : {1} - {2}" -f (Get-Date), $IOService.Name, $IOService.Status | Tee-Object -Variable status
            
            if ($IOService.Status -ne 'Running') {
                Send-MailMessage @emailsplat -Subject $status -Body '<EOM>' 
            }
        }
        else {
            "{0} : No Dollar Universe services found." -f (Get-Date) | Tee-Object -Variable status 
        }
    }
    $status | Out-File -FilePath $logfile -Append -Encoding UTF8
}
catch {
    throw $_
}
'@

# installs the script
$scriptpath = 'C:\Windows\Check-DollarUniverseService.ps1'
$script | Out-File -FilePath $scriptpath -Force

# creates the scheduled task
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-ExecutionPolicy Bypass -File $scriptpath"
$trigger = New-ScheduledTaskTrigger -Once -At "00:00" -RepetitionInterval "00:15"
Register-ScheduledTask -TaskName "Check Dollar Universe Service" -Action $action -Trigger $trigger -User 'NT AUTHORITY\SYSTEM' -Force