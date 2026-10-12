$servers = @(
    'hostname4n1',
    'hostname4n2',
    'hostname4n3',
    'hostssisc3n1',
    'hostssisc3n2',
    'hostname4n1',
    'hostname4n2',
    'hostssisc3n1',
    'hostssisc3n2'
)

foreach ($s in $servers) {
    $r = Resolve-DnsName -Name $s | ForEach-Object { Resolve-DnsName -Name $_.Name -DnsOnly } | Select-Object -First 1
    
    if ($r) {
        $i = $r.IPAddress.ToString()
        "DNS good {0} -> {1}" -f $s, $i
    }
    else {
        "[!] DNS missing: {0}" -f $s
        continue
    }

    $rn = Resolve-DnsName -Name $i -DnsOnly

    if ($rn.NameHost -eq $r.Name) {
        "`tReverse DNS good: {0} -> {1}`n" -f $i, $rn.NameHost
    }
    else {
        "`t[!] Reverse DNS missing or doesnt resolve: {0} -> {1}`n" -f $rn.IPAddress, $r.Name 
    }
}
