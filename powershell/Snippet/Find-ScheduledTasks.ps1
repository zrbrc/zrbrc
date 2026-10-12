$servers = @(
    'hostDBCL1N1',
    'hostDBCL1N3',
    'hostname4N1',
    'hostname4N3',
    'hostDBCLS2N1',
    'hostDBCLS2N2',
    'hostname6N1',
    'hostname6N2',
    'hostSPDBC9N1',
    'hostSPDBC9N2',
    'hostnameCLS6N1',
    'hostnameCLS6N1',
    'hostnameCLS6N1',
    'hostnameCLS6N1',
    'hostnameCLS6N2',
    'hostnameCLS6N2',
    'hostnameCLS6N2',
    'hostnameCLS6N2',
    'hostMCIDBC1N1',
    'hostMCIDBC1N2',
    'hostMCIDBC1N3',
    'hostMCDBC1N1',
    'hostMCDBC1N2',
    'hostMCDBC1N3',
    'hostnameC2N1',
    'hostnameC2N2',
    'hostname10N1',
    'hostname10N2',
    'hostname5N1',
    'hostname5N2',
    'hostname5N3',
    'hostname8N1',
    'hostname8N2',
    'hostname8N3',
    'hostname8N4'
)

$table = foreach ($s in $servers | Sort-Object -Unique) {
    $ses = New-CimSession -ComputerName hostDBCL1N1
    $task = Get-ScheduledTask -CimSession $ses -TaskPath '\Microsoft\Windows\ClusterAwareUpdating\' -ErrorAction SilentlyContinue 
    [PSCustomObject]@{
        Server   = $s
        TaskName = $task.TaskName
        Trigger  = $task.Triggers.StartBoundary
    }
}

$table | Format-Table