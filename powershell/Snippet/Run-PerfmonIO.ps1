# how long to capture for
[int]$cap_time = Read-Host "How many seconds to capture"

# set output path
$output = 'M:\Management\Counters'

# gets all local drive to build counters on
$drives = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null }).Name

# what counters to capture
$drive_counters = (
    '\LogicalDisk(*)\Avg. Disk sec/Read',
    '\LogicalDisk(*)\Avg. Disk sec/Write',
    '\LogicalDisk(*)\Avg. Disk Write Queue Length',
    '\LogicalDisk(*)\Current Disk Queue Length',
    '\LogicalDisk(*)\Avg. Disk Bytes/Read',
    '\LogicalDisk(*)\Avg. Disk Bytes/Write',
    '\LogicalDisk(*)\Disk Reads/sec',
    '\LogicalDisk(*)\Disk Writes/sec'
)

$drive_counter_list = foreach ($d in $drives) {
    foreach ($c in $drive_counters) {
        $c.replace('*', ($d + ':'))
    }
}

if (!(Test-Path $output)) { New-Item $output -ItemType Directory}
$file = "M:\Management\Counters\sql_drive_counters_$(Get-Date -Format 'yyyyMMdd_hhmmss').blg"

$job = Start-Job -ArgumentList $drive_counter_list, $file -ScriptBlock {
    param($drive_counter_list, $file)
    Get-Counter -Counter $drive_counter_list -Continuous | Export-Counter -Path $file
}

"Capturing for $cap_time seconds ..."
Start-Sleep -Seconds $cap_time 

$job | Stop-Job
$job | Receive-Job

"DONE"

Invoke-Item $file