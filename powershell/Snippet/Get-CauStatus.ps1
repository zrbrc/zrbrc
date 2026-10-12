$servers = @(
    'hostdbcl1n1',
    'hostdbcl1n3',
    'hostDBCLS2N1',
    'hostDBCLS2N2',
    'hostELIGAP02',
    'hosteligdb01',
    'hostMCIDBC1N1',
    'hostMCIDBC1N2',
    'hostMCIDBC1N3',
    'hostssisrs01',
    'hostnamec2n1',
    'hostnamec2n2',
    'depttreligdb01',
    'hostname10n1',
    'hostname10n2',
    'hostname4n1',
    'hostname4n3',
    'hostname6N1',
    'hostname6N2',
    'hostELIGAP18',
    'hostSPDBC9N1',
    'hostSPDBC9N2',
    'hostssisrs02',
    'hostnameCLS6N1',
    'hostnameCLS6N2',
    'hostMCDBC1N1',
    'hostMCDBC1N2',
    'hostMCDBC1N3',
    'hostOBT01',
    'hostOMCIDB01'
)

$table = foreach ($s in $servers) {
    try {
        Get-CauReport $s -Last -ErrorAction SilentlyContinue
    }
    catch {
        Get-Hotfix $s
    }
}

$table | Sort-Object -Unique Status, StartTimestamp | Format-Table 