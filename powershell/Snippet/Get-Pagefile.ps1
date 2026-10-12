# comment out the lines you dont want, we cant query them all from the same zone
$computers = @(
    # assist test EL2
    'hostDBCL1N1',
    'hostDBCL1N3',
    'hostMCIDBC1N1',
    'hostMCIDBC1N2',
    'hostMCIDBC1N3',
    'hostname4N1',
    'hostname4N3',
    'hostnameCLS6N1',
    'hostnameCLS6N2',
    'hostMCDBC1N1',
    'hostMCDBC1N2',
    'hostMCDBC1N3'
    # # assist prod EL2
    # 'hostname1N1',
    # 'hostname1N3',
    # 'hostname1N5',
    # 'hostMCIDBC7N1',
    # 'hostMCIDBC7N2',
    # 'hostMCIDBC7N3'
    # # dept test IDMZ3
    # 'hostname2N3',
    # 'hostname5N2',
    # 'hostname5N3',
    # # decss test IDMZ3
    # 'hostname8N1',
    # 'hostname8N2',
    # 'hostname8N3',
    # 'hostname8N4',
    # 'hostDCSSC2N1',
    # 'hostDCSSC2N2',
    # 'hostDCSSC2N3',
    # 'hostDCSSC2N4'
    # # dept prod IDMZ3
    # 'hostname4N3',
    # 'hostname4N5',
    # 'hostname5N1',
    # 'hostname5N2',
    # 'hostname5N3',
    # 'hostname5N4',
    # 'hostname5N5',
    # 'hostname5N6',
    # # decss prod IDMZ3
    # 'hostDCSSC1N1',
    # 'hostDCSSC1N2',
    # 'hostDCSSC1N3',
    # 'hostDCSSC1N4'
)
    
$table = foreach ($computer in $computers) {
    $output = Get-CimInstance -Class Win32_PageFileUsage -ComputerName $computer | Select-Object Name, AllocatedBaseSize
    foreach ($o in $output) {
        [PSCustomObject]@{
            Server         = $computer
            PagefilePath   = $o.Name
            CurrentUsageGB = ($o.CurrentUsage / 1024)
            PeakUsageGB    = ($o.PeakUsage / 1024)
            SizeGB         = ($o.AllocatedBaseSize / 1024)
        }
    }
} 
$table | Format-Table