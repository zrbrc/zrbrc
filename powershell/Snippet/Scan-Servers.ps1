$servers = @(
    # 'hostel2ap01',
    # 'hostel2ap02',
    # 'hostel2ap03',
    # 'hostel2ap04',
    # 'hostel2ap05',
    # 'hostel2ap06',
    # 'hostEligAP32',
    # 'hosteligap33',
    # 'hosteligap34',
    # 'hosteligap35',
    # 'hosteligap36',
    # 'hosteligap37',
    # 'hostdemap01',
    # 'hostdemap02',
    # 'hostdemap03',
    # 'hostdemap04',
    # 'depttrel2ap02',
    # 'hostname3n1',
    # 'hostname3n2',
    # 'hostdbcls1n1',
    # 'hostdbcls1n2',
    # 'hostel2ap17',
    # 'hostel2ap18',
    # 'hostel2ap19',
    # 'hostel2ap20',
    # 'hostel2ap21',
    # 'hostel2ap22',
    # 'hostname2n1',
    # 'hostname2n2',
    'hosteligap33',
    'hosteligap34',
    'hosteligdb04',
    'hosteligdb04' 
)

$table = foreach ($s in $servers) {
    $adobject = Get-ADComputer $s -Properties *
    $resolvedip = (Resolve-DnsName $s -ErrorAction SilentlyContinue).IPAddress
    if (Test-NetConnection $Hostname -ErrorAction SilentlyContinue) {
        [PSCustomObject]@{
            Hostname   = $s
            AD_IP      = $adobject.IPv4Address
            AD_OS      = $adobject.OperatingSystem
            ResolvedIP = $resolvedip
        }
    }
}

$table | ft