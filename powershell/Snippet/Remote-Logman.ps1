Get-Date

Invoke-Command -ComputerName deptbkel2dom -ScriptBlock {

    if (!(Test-Path 'c:\temp\logman')) { New-Item 'c:\temp\logman' }

    $jobs = @()
    $failed = $false

    $jobs += Start-Job -ScriptBlock {
        $ErrorActionPreference = 'Stop'

        $logman_delete = @(
            'delete',
            'PerfLog-Short1'
        )

        $logman_create = @(
            'create',
            'counter',
            'PerfLog-Short1',
            '-o',
            "c:\temp\logman\$($env:COMPUTERNAME)_PerfLog-Short1_$(Get-Date -Format 'yyyyMMdd_HHmmss').blg",
            '--v',
            '-f',
            'bincirc',
            '-max',
            '500',
            '-c',
            '\LogicalDisk(*)\*',
            '\Memory\*',
            '\.NET CLR Memory(*)\*',
            '\Cache\*',
            '\Network Interface(*)\*',
            '\Paging File(*)\*',
            '\PhysicalDisk(*)\*',
            '\Processor(*)\*',
            '\Processor Information(*)\*',
            '\Process(*)\*',
            '\Thread(*)\*',
            '\Redirector\*',
            '\Server\*',
            '\System\*',
            '\Server Work Queues(*)\*',
            '\Terminal Services\*',
            '-si',
            '00:00:01'
        )
     
        $logman_start = @(
            'start',
            'PerfLog-Short1'
        )
     
        $logman_stop = @(
            'stop',
            'PerfLog-Short1'
        )
    
        try {
            & logman.exe $logman_delete
            & logman.exe $logman_create
            & logman.exe $logman_start

            Start-Sleep -Seconds 10
        
            & logman.exe $logman_stop
        }
        catch {
            throw
        }
    }

    $jobs += Start-Job -ScriptBlock {
        $ErrorActionPreference = 'Stop'

        $storport_start = @(
            'create',
            'trace',
            'drivers_storage',
            '-ow',
            '-o',
            "c:\temp\logman\$($env:COMPUTERNAME)_drivers_storage_$(Get-Date -Format 'yyyyMMdd_HHmmss').etl",
            '-p',
            'Microsoft-Windows-StorPort',
            '0xffffffffffffffff',
            '0xff',
            '-nb',
            '16',
            '16',
            '-bs',
            '1024 ',
            '-mode',
            'Circular',
            '-f',
            'bincirc',
            '-max',
            '4096',
            '-ets'
        )
     
        $storport_stop = @(
            'stop',
            'drivers_storage',
            '-ets'
        )
        try {
            & logman.exe $storport_start

            Start-Sleep -Seconds 10

            & logman.exe $storport_stop
        }
        catch {
            throw
        }
    }

    # wait for jobs to complete and then get output
    $jobs | Wait-Job
    $jobs | Receive-Job

    foreach ($j in $jobs) {
        $j | Receive-Job
        if ($j.State -like 'Failed') {
            $failed = $true
        }
        $j | Remove-Job
    }
    if ($failed) { throw }
}
Get-Date