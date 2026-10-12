<#
.SYNOPSIS
    Queries the AG for some info.
.DESCRIPTION
    Queries the AG to grab details on it for tracking changes, outputs details to a log file.
.EXAMPLE
    PS C:\> .\Check-AgStatus.ps1
.INPUTS
    none
.OUTPUTS
    Log file.
.NOTES
    Run this script once and it will install itself as a scheduled task, then go and set the correct account to run under in 'Scheduled Tasks'. 

    Remember to make the account used to run the task a local admin to have 'Log on as batch job' rights and give it permissions on the target instance(s).

    From an elevated powershell prompt:
        
        Add-LocalGroupMember -Group 'Administrators' -Member 'dom*\sqladmin.metric'

    T-SQL for read permissions:

        CREATE LOGIN [domain\user.metric]
        FROM WINDOWS WITH
        DEFAULT_LANGUAGE = [us_english],
        DEFAULT_DATABASE = [master]
        GRANT CONNECT SQL to [domain\user.metric]
        GRANT VIEW ANY DEFINITION to [domain\user.metric]
        GRANT VIEW ANY DATABASE to [domain\user.metric]
        GRANT VIEW SERVER STATE to [domain\user.metric]
        GO

#>

$ErrorActionPreference = 'Stop'

try {
    $file = 'M:\Management\Reports\AG_Status_Log.txt'
    
    $name = 'Check AG Status'
    $description = 'Checks the AG status and output info to a log file.'
    $argument = "-ExecutionPolicy Bypass $PSCommandPath"
    $user = 'domain\user.metric'
    $password = 'gi6EN*IMb#'
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argument
    $trigger = New-ScheduledTaskTrigger -Daily -At 6AM

    if (-not (Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue)) {
        Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Description $description -User $user -Password $password -TaskPath '\DBA\'
    }

    $instancelist = @(
        # 'xx.xx.xx.xx,15150'
        # , 'xx.xx.xx.xx,15150'
        # , 'xx.xx.xx.xx,15150'
        'xx.xx.xx.xx,15150'
        , 'xx.xx.xx.xx,15150'
        , 'xx.xx.xx.xx,15150'
        , 'xx.xx.xx.xx,15150'
    )
    $instances = Get-SqlInstance -ServerInstance $instancelist

    $output = foreach ($instance in $instances) {
        foreach ($ag in $instance.AvailabilityGroups) {
            foreach ($replica in $ag.AvailabilityReplicas) {
                [PSCustomObject]@{
                    Instance                      = $instance.Name
                    AG                            = $ag.Name
                    Replica                       = $replica.Name
                    Role                          = $replica.Role
                    ConnectionModeInPrimaryRole   = $replica.ConnectionModeInPrimaryRole
                    ConnectionModeInSecondaryRole = $replica.ConnectionModeInSecondaryRole
                }
            }
        }
    }

    Get-Date -Format G | Out-File $file -Append
    $output | Where-Object { $_.Role -ne 'Unknown' } | Sort-Object Replica, AG, Role -Unique | Format-Table | Out-File $file -Append -Width 500
}
catch {
    $ErrorMessage = $_.Exception
    $ErrorMessage | Out-File $file -Append -Width 500
}