$servers = @(
    # dev
    'host04domain.com'
    'hosteligodb03domain.com',
    'hosteligap03domain.com',
    'host3demap01domain.com',
    'host3demap02domain.com',
    'hostuvms01domain.com',
    'hostsftp01domain.com',
    'hostdecsswb01domain.com',
    'hostdecsswb02domain.com',
    'hostdecssap03domain.com',
    'hostdecssap04domain.com',
    'hostdecsswb01domain.com',
    'hostdecssap03domain.com',
    'hostdecssfp01domain.com',
    'hostdecssfp01domain.com',
    'hosteligap35domain.com'    
    # test
    # 'hosteligap25domain.com',
    # 'hosteligap26domain.com',
    # 'hostEligAP32domain.com',
    # 'hostname4n1domain.com',
    # 'hostname4n3domain.com',
    # 'hostel2ss01domain.com',
    # 'hostdemodb1domain.com',
    # 'hostdemodb2domain.com',
    # 'hostsftp01domain.com',
    # 'hosteligwb03domain.com',
    # 'hosteligwb04domain.com',
    # 'deptuadecsswb01',
    # 'deptuadecsswb02',
    # 'deptuadecssap03domain.com',
    # 'deptuadecssap04domain.com',
    # 'deptuadecssbat1domain.com',
    # 'hostfp02domain.com',
    # 'hostssisc1ls1domain.com',
    # 'hostdcssagdomain.com',
    # 'deptuvms01.domain.com'
    # prod
)
$javaversions = @()
$servers = $servers | Sort-Object -Unique
foreach ($server in $servers) {
    try {
    $java = Invoke-Command -ComputerName $server -ErrorAction Stop -ScriptBlock {
        $JavaFilter = { ($_.DisplayName -like "Java*" -and $_.Publisher -like "Oracle*" ) -or ($_.DisplayName -like "*JDK*" -and $_.Publisher -like "Microsoft*") }
    
        Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object -FilterScript $JavaFilter

    }
    $javaversions += [PSCustomObject]@{
        Server  = $server
        Java    = $java.DisplayName
        Version = $java.DisplayVersion
    }
}
catch {
    "failed {0}" -f $server
    continue
}
}
$javaversions = $javaversions | Sort-Object -Property Server
$javaversions | Format-Table

"Stats: Queried: {0} Returned: {1}" -f $servers.Count, $javaversions.Count
"Missed: {0}" -f ($servers | Where-Object { $_ -notin $javaversions.Server })

Get-Date