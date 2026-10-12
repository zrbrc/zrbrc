# $san = Read-Host "Do you want to add a dept.state.us SAN entry? (y/N)"
$san = 'n'

# find resources belonging to MSSQL
$ag_owner = (Get-Cluster | Get-ClusterResource | Where-Object { $_.ResourceType -eq "SQL Server Availability Group" } | Select-Object -ExpandProperty OwnerGroup).Name

$ag_res = Get-ClusterResource | Where-Object { $_.OwnerGroup -in $ag_owner } 

$ag_res_name = $ag_res | Where-Object { $_.ResourceType -eq "Network Name" }
$ag_res_ip = $ag_res | Where-Object { $_.ResourceType -eq "IP Address" }

$ag_dns = ($ag_res_name | ForEach-Object { ($_ | Get-ClusterParameter -Name DnsName, DnsSuffix | Select-Object -ExpandProperty Value) -join '.' }) -join ','
$ag_ip = ($ag_res_ip | ForEach-Object { $_ | Get-ClusterParameter -Name Address | Select-Object -ExpandProperty Value }) -join ','


$local_name = [System.Net.Dns]::GetHostByName($env:computerName).Hostname
$local_ip = (Resolve-DnsName $local_name -DnsOnly).IP4Address

# custom object for all individual pieces
$t = [PSCustomObject]@{
    ServerFqdn  = $local_name
    ServerNaked = $local_name.Split('.')[0]
    AgFqdn      = $ag_dns
    AgNaked     = ($ag_dns.Split(',') | ForEach-Object { $_.Split('.')[0] }) -join ','
    IPs         = $local_ip, $ag_ip -join ','
}

$AltDns = ($t.ServerNaked, $t.AgFqdn, $t.AgNaked) -join ','
$StateAltDns = ($local_name.Split('.')[0] + '.domain.com') + ',' + (($ag_dns.Split(',') | ForEach-Object { $_.Split('.')[0] + '.domain.com' }) -join ',')

if ($san.ToUpper() -eq "Y") {
    $AltDns = $AltDns + ',' + $StateAltDns 
}

$servers = [PSCustomObject]@{
    SubjectName  = 'CN=' + $t.ServerFqdn
    AltDns       = $AltDns
    AltIp        = $t.Ips
    FriendlyName = 'SQL Server'
}

$servers | fl *
