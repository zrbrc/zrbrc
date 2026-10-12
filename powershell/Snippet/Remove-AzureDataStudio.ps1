$servers = @(
    'hostDBCL1N1',
    'hostDBCL1N3',
    'hostDBCLS2N1',
    'hostDBCLS2N2',
    'hostELIGAP02',
    'hostELIGDB01',
    'hostMCIDBC1N1',
    'hostMCIDBC1N2',
    'hostMCIDBC1N3',
    'hostnameC2N1',
    'hostnameC2N2',
    'deptTRELIGDB01',
    'hostname10N1',
    'hostname10N2',
    'hostname4N1',
    'hostname4N3',
    'hostname6N1',
    'hostname6N2',
    'hostELIGAP18',
    'hostSPDBC9N1',
    'hostSPDBC9N2',
    'hostnameCLS6N1',
    'hostnameCLS6N2',
    'hostMCDBC1N1',
    'hostMCDBC1N2',
    'hostMCDBC1N3'
)

foreach ($s in $servers) {

    Invoke-Command -ComputerName $s -ScriptBlock {
        # get uninstall string and remove it
        if ($ads = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -eq 'Azure Data Studio' }) {
            "Found it: {0}" -f $env:COMPUTERNAME
                        
            Start-Process -FilePath $ads.UninstallString -Wait -ArgumentList '/SILENT'

            "-- removed."
        }
        else {
            "ADS not found: {0}" -f $env:COMPUTERNAME
        }
    }
}