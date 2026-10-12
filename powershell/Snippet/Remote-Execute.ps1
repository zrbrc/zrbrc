$servers = @(
    "$env:COMPUTERNAME", #localhost
    'deptbkdb02'
)

$jobs = @()

foreach ($s in $servers) {

    $jobs += Invoke-Command -ComputerName $s -AsJob -ScriptBlock {
            
        $file = "c:\temp\trace_$($env:COMPUTERNAME)_" + (Get-Date -Format "yyyyMMdd_hhmmss") + '.etl'
        $seconds = 6

        "`n[+{0}] Starting trace ..." -f (Get-Date -Format "yyyy-MM-dd hh:mm:ss")
        netsh trace start capture=yes tracefile=$file maxsize=2048

        "[+{0}] Sleeping ..." -f (Get-Date -Format "yyyy-MM-dd hh:mm:ss")
        Start-Sleep $seconds

        "[+{0}] Stopping trace ..." -f (Get-Date -Format "yyyy-MM-dd hh:mm:ss")
        netsh trace stop

        "[+{0}] Completed.`n" -f (Get-Date -Format "yyyy-MM-dd hh:mm:ss")

    }
}

"`nWaiting for jobs to complete ...`n"
$jobs | Wait-Job | Receive-Job
$jobs | Remove-Job