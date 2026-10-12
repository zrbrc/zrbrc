# this checks the recycle bin size for all users, if you want it to clear all the recycle bins, set $Clear to true, can uncomment the set below or run via cli.
param (
    [switch]$Clear #= $true
)

$LocalDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -notlike '\\*' -and $_.Used -gt 0 }

"Checking all drives recycle bins..."
$bins = foreach ( $local in $LocalDrives) {
    $path = $local.Root + '$Recycle.Bin'
    $result = Get-ChildItem $path -Exclude "desktop.ini" -Force -Recurse -File
    $result = $result | ForEach-Object { $_.Length } | Measure-Object -Sum
    [PSCustomObject]@{
        Path   = $path
        Count  = $result.Count
        SizeMB = [math]::Round($result.Sum / 1MB, 3)
    } 
}
$bins

if ($Clear) {
    "Clearing all recycle bins."
    foreach ($bin in $bins) {
        Get-ChildItem $bin.Path -Force | Remove-Item -Recurse -Force
    }
}