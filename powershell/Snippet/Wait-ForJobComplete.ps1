$jobs = @()

foreach ($i in 1..10) {

    while (($jobs | Get-Job | Where-Object { $_.State -eq 'Running' }).count -ge 5 ) {
        "Waiting for other jobs to complete ..."
        Start-Sleep -Seconds 2
    }

    $jobs += Start-Job -Name $i -ArgumentList $i -ScriptBlock {
        param ($i)
        Start-Sleep -Seconds $i
        Test-NetConnection -ComputerName hostname4n1
    }
    "Job $i submitted."
}

"Waiting for all jobs to complete ..."
$jobs | Get-Job | Wait-job

foreach ($j in $jobs | Get-job) {
    "Job {0}" -f $j.Name
    $j | Receive-Job
}