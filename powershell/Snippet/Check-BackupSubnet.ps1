# get local ip
$LocalIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' } | Sort-Object -Property InterfaceIndex | Select-Object -ExpandProperty IPAddress -First 1)

# $BackupPath = '\\192.168.1.5\data\sync\Linux\unbound.conf'
$BackupPath = '\\maps.google.com\data\sync\Linux\unbound.conf'
$IPv4Regex = '((?:(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)\.){3}(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d))'

# do the below for each refresh, then check to see if we have a mapping for it already, we'll use the path as is for mapping table
$BackupServer = $BackupPath.Split('\')[2] # get just hostname\ip

# determine if its a hostname or ip, get ip if its hostname
if ($BackupServer -match $IPv4Regex) {
    "ip, using straight-up"
    $TargetIP = $BackupServer
}
else {
    "hostname, resolving"
    $TargetIP = (Resolve-DnsName $BackupServer -Type A).IPAddress
}

# check to see if we are running in the same subnet, should be same domain then
if (($LocalIP.Split('.')[0..2] -join '.') -eq ($TargetIP.Split('.')[0..2] -join '.')) {
    "Same subnet, dont map drive"
}
else {
    "different subnet, maps drive with creds"
}