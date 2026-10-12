<#
.SYNOPSIS
    Scans subnet to find RDP sessions.
.DESCRIPTION
    This will get a list of 'servers' from AD for current domain, filter based on the current 
    server's subnet and then scan all the matching IPs to see what RDP session exist, 
    active and disconnected. For example, if you were to run this on xx.xx.xx.xx (domTEST),
    it will get a list of all domTEST Servers and then filter based on '172.31.231*'.
.EXAMPLE
    PS C:\> .\Get-RdpSession.ps1
.INPUTS
    None
.OUTPUTS
    Console Output
.NOTES
    This will display the IP as it progresses thru the list, it will show not found for servers that
    dont respond to a ping and thus not query those servers for RDP session.

    This requires the AD module be installed, which should be on all servers.
#>
filter Invoke-FastPing { (New-Object System.Net.NetworkInformation.Ping).Send($_, 5) }

$data = @()
$filter = ((Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.ifIndex -ne 1 } | Sort-Object -Property InterfaceIndex | Select-Object -First 1).IPAddress.Split('.')[0..2] -join '.') + '*'
$servers = Get-ADComputer -Properties IPv4Address  -Filter ('(OperatingSystem -Like "*SERVER*") -AND (Enabled -Eq "True")') | Where-Object { $_.IPv4Address -like $filter } | Sort-Object -Unique

foreach ($server in $servers) {
    if (($server.Name | Invoke-FastPing).Status -eq 'Success') {
        Write-Output "quser: $($server.Name) $($server.IPv4Address)"
        $Sessions = quser /server:$($server.Name) 2>$null
        foreach ($Session in $Sessions | Select-Object -Skip 1) {
            $data += [PSCustomObject]@{
                User        = $Session.SubString(1, 20).Trim()
                Hostname    = $server.Name
                IP          = [system.version]$server.IPv4Address # set as a version to make it sort correctly
                SessionName = $Session.SubString(23, 17).Trim()
                ID          = $Session.SubString(42, 2).Trim()
                State       = $Session.SubString(46, 6).Trim()
            }            
        }
    }
    else {
        Write-Output "dead:  $($server.Name) $($server.IPv4Address)"
    }
}
$data | Sort-Object -Property User, IP | Format-Table
Read-Host "Press ENTER to continue"