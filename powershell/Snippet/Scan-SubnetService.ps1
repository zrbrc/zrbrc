function Get-SubnetMask {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Int]$Prefix
    )

    $subnet = ''
    for ($i = 0 ; $i -lt 32; $i++) {
        if ($i -lt $prefix) {
            $subnet += '1'
        }
        else {
            $subnet += '0'
        }
    }
    "{0}.{1}.{2}.{3}" -f [Convert]::ToInt32(($subnet.Substring(0, 8)), 2), [Convert]::ToInt32(($subnet.Substring(8, 8)), 2), [Convert]::ToInt32(($subnet.Substring(16, 8)), 2), [Convert]::ToInt32(($subnet.Substring(24, 8)), 2)
}


$Servers = Get-ADComputer -Filter * -Properties * | Where-Object { $_.OperatingSystem -like "Windows Server *" }

[System.Net.IPAddress]$LocalIP = (Test-Connection $env:COMPUTERNAME -Count 1).IPV4Address.IPAddressToString
[System.Net.IPAddress]$LocalSubnet = (Get-NetIpAddress | Where-Object { $_.IpAddress -eq $LocalIP }).PrefixLength | Get-SubnetMask

foreach ( $Server in $Servers | Where-Object { $_.IPv4Address -ne $null } ) {
    if ((($LocalIP.Address -band $LocalSubnet.Address) -eq (([System.Net.IPAddress]$Server.IPv4Address).Address -band $LocalSubnet.Address)) -and 
        $Server.LastLogonDate -gt (Get-Date).AddDays(-60) ) {
        
        
        
        if ( (Get-Service -Name 'spooler' -ComputerName $Server.Name | Where-Object { $_.Status -eq "Running" }).count -gt 0 ) {
            "ENABLED {0} {1}" -f $Server.Name, $Server.IPv4Address
        }
        else {
            "Dis-Unk {0} {1}" -f $Server.Name, $Server.IPv4Address
        }
    }
}

