Set-Location $PSScriptRoot

$server = 'LUNA\DE2019'

$instance = Get-SqlInstance -ServerInstance $server

$lsid = foreach ($login in $instance.Logins | Where-Object { $_.LoginType -eq 'SqlLogin' -and $_.IsSystemObject -eq $false -and $_.Name -notlike "NT*" -and $_.Name -notlike "##*" }) {
    $sid = '0x'
    $login.sid | ForEach-Object { $sid += ("{0:X}" -f $_).Padleft(2, '0') }
    [PSCustomObject]@{
        Instance = $Instance.Name
        Login    = $login.Name
        Sid      = $sid
    }
}

$usid = foreach ($db in $instance.Databases | Where-Object { $_.IsSystemObject -eq $false }) {
    foreach ($user in $db.Users | Where-Object { $_.LoginType -eq 'SqlLogin' -and $_.IsSystemObject -eq $false -and $_.Name -notlike "NT*" -and $_.Name -notlike "##*" }) {
        $sid = '0x'
        $user.sid | ForEach-Object { $sid += ("{0:X}" -f $_).Padleft(2, '0') }
        if ($user.Name -notin $lsid.Login) {
            $status = 'Login Missing'
        }
        elseif ($sid -notin $lsid.Sid) {
            $status = 'SID Mismatch'
        }
        else {
            continue
        }
        [PSCustomObject]@{
            Instance = $instance.Name
            Database = $db.Name
            User     = $user.Name
            Sid      = $sid
            Error    = $status
        }
    }
}
$usid | Format-Table
