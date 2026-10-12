$computers = @(
    # assist test
    'hostname4n1',
    'hostname4n3',
    'depttreligdb01',
    'hostdbcl1n1',
    'hostdbcl1n3'
    # decss test
    # 'hostdcssc2n1',
    # 'hostdcssc2n2',
    # 'hostdcssc2n3',
    # 'hostdcssc2n4'
    # assist prod
    # 'hostname1n1',
    # 'hostname1n3',
    # 'hostname1n5'
    # decss prod
    # 'hostdcssc1n1',
    # 'hostdcssc1n2',
    # 'hostdcssc1n3',
    # 'hostdcssc1n4'
)
    
$table = foreach ($computer in $computers) {
    $output = Get-CimInstance -Class Win32_PageFileUsage -ComputerName $computer | Select-Object Name, AllocatedBaseSize
    [PSCustomObject]@{
        Server         = $computer
        PagefilePath   = $output.Name
        CurrentUsageGB = ($output.CurrentUsage / 1024)
        PeakUsageGB    = ($output.PeakUsage / 1024)
        SizeGB         = ($output.AllocatedBaseSize / 1024)
    }
} 
$table | Format-Table