$nodes = get-cluster | Get-ClusterNode 
# $nodes = @('hostname5ls1domain.com','hostname5ls2domain.com','hostname5ls3domain.com')
$table = foreach ($node in $nodes) {
    $hostname = Resolve-DnsName ($node.Name + '.' + $env:USERDNSDOMAIN) -DnsOnly
    # $hostname = Resolve-DnsName $node -DnsOnly

    $ip = Resolve-DnsName $hostname.IP4Address -DnsOnly

    # $ipres = Resolve-DnsName $ip.NameHost -DnsOnly

    if ($hostname.Name -eq $ip.NameHost <# -and $hostname.IP4Address -eq $ipres.IP4Address #> ) { $matches = $true } else { $matches = $false }

    [PSCustomObject]@{
        Hostname    = $hostname.Name
        IP          = $hostname.IP4Address
        PTR         = $ip.NameHost
        # PTRHostname = $ipres.IP4Address
        Matches     = $matches
    }  
}
$table | Format-Table