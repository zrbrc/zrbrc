# $cred = Get-Credential

$servers = @(
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150'
)

$table = foreach ($s in $servers) {
    try {
        $out = Invoke-Sqlcmd -ServerInstance $s -Query 'SELECT @@SERVERNAME, @@VERSION' -TrustServerCertificate -Credential $cred

        $instancename = $out.Column1.Trim()
        $sql, $rest = ($out.Column2.Split([Environment]::NewLine)[0, 3]).Trim()
        $sqledition, $os = ($rest -split ' on ').trim()
        [PSCustomObject]@{
            InstanceName = $instancename
            IP           = $s
            SqlVersion   = $sql
            SqlEdition   = $sqledition
            OSVersion    = $os
        }
    }
    catch {
        "FAILED: {0}" -f $s
    }
}

$table | Sort-Object InstanceName | Format-Table *
