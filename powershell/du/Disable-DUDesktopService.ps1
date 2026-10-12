<# 
for just local server

$s = Get-Service -Name "*_uni_desktop"
$s | Where-Object { $_.Status -eq 'Running' } | Stop-Service -Verbose
$s | Where-Object { $_.StartType -ne 'Disabled' } | Set-Service -StartupType Disabled -Verbose
$s.Name
$s | % { sc.exe delete $_.Name }

#>

$servers = @(
    # test el2
    'hosteligap05domain.com',
    'hosteligap25domain.com',
    'hosteligap26domain.com',
    'hostname4n1domain.com',
    'hostname4n3domain.com',
    'hostel2ss01domain.com',
    'hostsftp01domain.com',
    'hostssap01domain.com',
    'hostssap02domain.com',
    'hosteligwb03domain.com',
    'hosteligwb04domain.com',
    'host3ap01domain.com',
    'host3ap02domain.com'
)

foreach ($server in $servers) {

    Invoke-Command -ComputerName $server -ScriptBlock {

        try {
            "[+] $env:COMPUTERNAME"
            $s = Get-Service -Name "*_uni_desktop"
            
            if ($s.count -eq 1) {
                $s.name

                $s | Stop-Service
                $s | Set-Service -StartupType Disabled

                # $s | Remove-Service
    
                if ($LASTEXITCODE -ne 0) {
                    "`n[!] Operatiom Failed"
                }
                else {
                    "`n[+] DONE"
                }
            }
            else {
                "`n[i] DU desktop service not found or too many found, no work done."
            }
        }
        catch {
            $_
        }
    }
}