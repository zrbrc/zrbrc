$server = 'deptbkdb02domain.com'
$capture_ip = 'xx.xx.xx.xx'
$output = "c:\temp\trace_" + (Get-Date -Format "yyyyMMdd_hhss") + '.etl'
$seconds = 600

Invoke-Command -ComputerName $server -ScriptBlock {

    netsh trace start capture=yes IPv4.Address=$using:capture_ip tracefile=$using:output maxsize=0 filemode=single

    "`nCapturing for {0} seconds ...`n" -f $using:seconds

    Start-Sleep $using:seconds

    netsh trace stop

}