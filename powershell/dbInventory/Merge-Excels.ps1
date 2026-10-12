Set-Location $PSScriptRoot

$files = Get-ChildItem -Path '.\20240403' -Filter '*.xlsx'

$data = @()

foreach ($f in $files) {
    $data += Import-Excel $f.FullName -WorksheetName 'Instances'

}

$data | Export-Excel '.\All_db_Instances_20240403.xlsx'
$data | ForEach-Object {"{0},{1}" -f $_.IP, $_.Port} | Sort-Object -Unique | Out-File '.\All_db_Servers.txt'