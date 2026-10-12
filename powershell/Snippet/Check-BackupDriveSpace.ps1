$servers = @(
    'hostname10n1,Y:',
    'hostname10n2,Y:',
    'hostname1N1,Y:',
    'hostname1N3,Y:',
    'hostMCIDBC7N1,Y:',
    'hostMCIDBC7N2,Y:',
    'deptbkel2dom,E:'

)

$drives = foreach ($s in $servers) {
    $h, $d = $s.split(',')
    Invoke-Command -ComputerName $h -ArgumentList $d -ScriptBlock {
        param($d)
        $d = $d.Split('|')
        Get-CimInstance -ClassName Win32_Volume | Where-Object { $_.Capacity -ge 0 -and $_.DriveLetter -in $d }
    }
}

$drives | ForEach-Object {
    [PSCustomObject]@{
        Name   = $_.PSComputerName
        Drive  = $_.DriveLetter
        SizeGB = [math]::Round($_.Capacity / 1GB, 2)
        FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
        Free  = ($_.FreeSpace / $_.Capacity).ToString("P")
    }
} | Format-Table