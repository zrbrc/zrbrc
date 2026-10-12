$user = 'ryan.zerbe'

$good = [System.Collections.ArrayList]@()

# get DCs and find which are accessible from our location
$dc = Get-ADDomainController -filter *
foreach ($d in $dc) {
    if ((New-Object System.Net.Sockets.TcpClient).ConnectAsync($d.Hostname, 9389).Wait(100)) { 
        $good += $d
    }
    else {
        continue
    }
}

# query ADs for user info
$table = [System.Collections.ArrayList]@()

foreach ($g in $good) {
    $u = Get-ADUser $user -Server $g.Hostname -Property LastLogon, LastLogonDate, LastLogonTimestamp 
    $u | Add-Member -MemberType NoteProperty -Name 'DcHostname' -Value $g.Hostname -Force 
    $table += $u
}

# display info
$table | Foreach-Object {
    [PSCustomObject]@{
        Name                             = $_.SamAccountName
        DCHostname                       = $_.DCHostname
        'LastLogon(no repl)'             = if ($_.LastLogon) { $_.LastLogon } else { '' }
        'LastLogon(no repl,calcd)'       = if ($_.LastLogon) { [datetime]::FromFileTime($_.LastLogon) } else { '' }
        'LastLogonTimestamp(repl)'       = if ($_.LastLogonTimestamp) { $_.LastLogonTimestamp } else { '' }
        'LastLogonDate(repl,auto-calcd)' = if ($_.LastLogonDate) { $_.LastLogonDate } else { '' }
    }
} | Sort-Object 'LastLogon(no repl)' | Format-Table
