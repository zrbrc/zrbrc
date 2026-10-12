$servers = @(
    # el2
    'hostname10n1',
    'hostname10n2',
    'hostname1N1',
    'hostname1N3',
    'hostname1N5',
    'hostname3N1',
    'hostname3N2',
    'hostname6N1',
    'hostname6N2',
    'hostname8N1',
    'hostname8N2',
    'hostname8N3',
    'hostMCIDBC7N1',
    'hostMCIDBC7N2',
    'hostMCIDBC7N3'
)

$drives = $null

$drives = foreach ($s in $servers) {
    Invoke-Command -ComputerName $s -ScriptBlock { 
        Get-CimInstance -ClassName Win32_Volume | Where-Object { $_.Capacity -ge 0 -and $_.DriveLetter -eq 'M:' }
    }
}
 
$drives | Sort-Object @{Expression = { $_.FreeSpace / $_.Capacity } } | Format-Table PSComputerName, DriveLetter, 
@{Name = "Size_GB"; Expression = { [math]::Round($_.Capacity / 1GB, 2) } }, 
@{Name = "Free_GB"; Expression = { [math]::Round($_.FreeSpace / 1GB, 2) } },
@{Name = "Free_P"; Expression = { ($_.FreeSpace / $_.Capacity).ToString("P") } }