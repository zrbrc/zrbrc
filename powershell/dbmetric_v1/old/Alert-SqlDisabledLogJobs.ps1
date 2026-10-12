Get-Date -Format G

############################################################################
# init
#region ####################################################################

# email style
$CSS = @"
<style>
    table { font-size: 14px; border: 0px; } 
    td { padding: 4px; margin: 0px; border: 0; }
    th { background: #395870; background: linear-gradient(#49708f, #293f50); color: #fff; font-size: 14px; padding: 10px 15px; vertical-align: middle; }
    tbody tr:nth-child(even) { background: #f0f0f2; }
</style>
"@

# dba database
$Instance = 'hostnameCLS1LS1,15150'
$Database = 'DBA'
$Schema = 'dbo'

# input and log tables
$ServerTable = 'Servers_T'

# job name
$LogJobName = '*USER_DATABASES - LOG'

# get local ip, subnet and domain--we use this to filter each zone later on
$LocalIP = (Test-Connection $env:COMPUTERNAME -Count 1).IPV4Address.IPAddressToString
$LocalSubnet = (Get-NetIpAddress | Where-Object { $_.IpAddress -eq $LocalIP }).PrefixLength | Get-SubnetMask
$Domain = (Get-ADDomain).Name
#endregion

############################################################################
# get server list
#region ####################################################################

# gets the latest list of sql instances we created above.
$Query = "SELECT A.Timestamp, A.Domain, A.Servername, A.IP, A.Instance, A.Port 
          FROM $ServerTable AS A 
          INNER JOIN (SELECT Servername, IP, Instance, MAX(ID) as MAXID 
                      FROM $ServerTable 
                      GROUP BY Servername, IP, Instance) AS B ON B.MAXID = A.ID 
          ORDER BY Servername"
$Servers = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $Query
#endregion

$DisabledLogJobs = @()
foreach ($Server in $Servers) {
    try {
        # if subnet mask and domain dont match and the server details are older than 15 minutes, skip it
        if ( -not ((([System.Net.IPAddress]$LocalIP).Address -band $LocalSubnet.Address ) -eq 
                (([System.Net.IPAddress]$Server.IP).Address -band $LocalSubnet.Address) -and 
                $Server.Domain -eq $Domain -and
                $Server.Timestamp -gt (Get-Date).AddDays(-1) )) {
            "Skipping: {0} {1}" -f $Server.Servername, $Server.IP
            continue
        }
        "Connecting to {0}:{1} ..." -f $Server.Servername, $Server.Port

        $Instance = Get-SqlInstance -ServerInstance "$($Server.ServerName),$($Server.Port)"
    
        $DisabledLogJobs += $Instance.JobServer.Jobs | Where-Object { $_.Name -like $LogJobName -and $_.IsEnabled -eq $false -and $_.HasSchedule -eq $true } | Select-Object OriginatingServer, Name, IsEnabled, HasSchedule, LastRunOutcome, LastRunDate
    }
    catch {
        $ErrorException = $_.Exception
        "Failed to get jobs for {0}:{1}" -f $Server.Servername, $Server.Port
        $ErrorException
        continue
    }
}

# if we have disabled log jobs, display and then send via email
If ($DisabledLogJobs.count -gt 0) {
    
    $DisabledLogJobs | Format-Table

    $Email = @{
        To         = 'ryan.zerbe@delaware.gov', 'kevin.hudson@delaware.gov'
        From       = 'dept05sg_SQLAlerts@delaware.gov'
        Subject    = "SQL Server Alert System: 'Log Backup Jobs Disabled'"
        Body       = $DisabledLogJobs | ConvertTo-Html -As Table -Head $CSS | Out-String
        Smtp       = 'smtp.state.de.us'
        BodyAsHtml = $true
    }
    Send-MailMessage @Email
    "Email sent to: {0}" -f ($Email.To -join ',')
}
else {
    "No disabled log jobs."
}

Get-Date -Format G