<#
.SYNOPSIS
    This will script out a SQL Instances settings.
.DESCRIPTION
    This will script out, SQL Agent(operators, alerts, schedules, and jobs), sp_configure settings, db mail settings, 
    audits and audit specs, and linked server. Linker servers will not have passwords.
.EXAMPLE
    Execute in via CLI, ISE, or VSCode
.INPUTS
    None - set instance name below.
.OUTPUTS
    Sql files to current directory.
.NOTES
    General notes
#>

$instance = Get-SqlInstance -ServerInstance 'xx.xx.xx.xx,15150'

$scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter $instance
# $scripter.Options.IncludeHeaders = $true

# audits and audits specs
$sql = @()
$instance.Audits | ForEach-Object { $sql += $scripter.EnumScript($_) }
$instance.ServerAuditSpecifications | ForEach-Object { $sql += $scripter.EnumScript($_) }
$sql | out-file ".\$($instance.InstanceName)_Audits_$(Get-Date -Format 'yyyyMMdd_HHss').sql"

# sp_configure
$sql = @()
$sql += "EXEC sp_configure 'show advanced options' , 1"
$sql += "RECONFIGURE WITH OVERRIDE"
$instance.Configuration.ShowAdvancedOptions.ConfigValue = $true
$instance.Configuration.Alter($true)
$instance.Configuration.Properties | ForEach-Object { $sql += "EXEC sp_configure '$($_.DisplayName)', '$($_.ConfigValue)'" }
$sql | out-file ".\$($instance.InstanceName)_Configuration_$(Get-Date -Format 'yyyyMMdd_HHss').sql"

# dbmail
$sql = @()
$instance.Mail | ForEach-Object { $sql += $scripter.EnumScript($_) }
$instance.Mail.ConfigurationValues | ForEach-Object { $sql += $scripter.EnumScript($_) }
$instance.Mail.Accounts.MailServers | ForEach-Object { $sql += $scripter.EnumScript($_) }
$instance.Mail.Profiles | ForEach-Object { $sql += $scripter.EnumScript($_) }
$sql | out-file ".\$($instance.InstanceName)_Mail_$(Get-Date -Format 'yyyyMMdd_HHss').sql"

# linked servers
$sql = @()
$instance.LinkedServers | ForEach-Object { $sql += $scripter.EnumScript($_) }
$sql | out-file ".\$($instance.InstanceName)_LinkedServers_$(Get-Date -Format 'yyyyMMdd_HHss').sql"

# sql agent
$sql = @()
$instance.JobServer.Operators | ForEach-Object { $sql += $scripter.EnumScript($_) }
$instance.JobServer.Alerts | ForEach-Object { $sql += $scripter.EnumScript($_) }
$instance.JobServer.SharedSchedules | ForEach-Object { $sql += $scripter.EnumScript($_) }
$instance.JobServer.Jobs | ForEach-Object { $sql += $scripter.EnumScript($_) }
$sql | out-file ".\$($instance.InstanceName)_SqlAgent_$(Get-Date -Format 'yyyyMMdd_HHss').sql"