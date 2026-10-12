<#
.SYNOPSIS
    Sends an email with the latest logon error.
.DESCRIPTION
    This will get the latest event id 4625 from the windows security log, parse the details, 
    getting domain, username, and source and send and email the the DBA group.

    This is installed as a SQL Agent job of Powershell type.

    A Sql alert needs to be created to trigger this for error number 17806.

    Names do not matter, just make sure the alert triggers the SSA job.
#>

$Output = Get-EventLog -LogName Security -InstanceId 4625 -Newest 1

if ($Output) {
    Write-Output "Found logon error, creating email ..."

    $Body = [PSCustomObject]@{
        Timestamp   = (Get-Date -Format 'yyyy/MM/dd HH:mm:ss')
        Username    = $Output.ReplacementStrings[5]
        Domain      = $Output.ReplacementStrings[6]
        Source      = $Output.ReplacementStrings[13]
        SourceIP    = $Output.ReplacementStrings[14]
    }

    $Email = @{
        To         = 'deptdg_BaseTech_DBA@delaware.gov'
        From       = 'dept05sg_SQLAlerts@delaware.gov'
        Subject    = "SQL Server Alert System: 'Unknown user name or bad password' occured on $($env:USERDNSDOMAIN.TrimEnd(".dept"))\$($env:COMPUTERNAME)"
        Body       = $Body | ConvertTo-Html -Fragment -As List | Out-String
        Smtp       = 'smtp.state.de.us'
        BodyAsHtml = $true
    }

    Send-MailMessage @Email

    Write-Output "Email sent."
}