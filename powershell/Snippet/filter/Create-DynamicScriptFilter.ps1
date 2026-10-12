Set-Location $PSScriptRoot

$files = Get-ChildItem '.\files' -filter '*.txt'

# $files

$filter = '*f*1*,*f*2*'

$namefilter = ( $filter.Split(',') | ForEach-Object { '$_.Name -like "' + $_ + '"' } ) -join ' -or '

$scriptfilter = [scriptblock]::Create("`$_.Date -lt (Get-Date).AddDays(-1) -and ($namefilter)")

$files | Where-Object -FilterScript $scriptfilter 
$scriptfilter 