Import-Module SqlServer

Set-Location $PSScriptRoot

$target = Get-Content .\server.json | ConvertFrom-Json

$scripts = Get-ChildItem .\input -Filter *.sql

 foreach ($script in $scripts) {
    $sql = Get-Content $script.FullName | Out-String
    $output = Invoke-Sqlcmd -ServerInstance $target.Server -Query $sql -Verbose -ErrorAction Stop -OutputSqlErrors $true
    $output | Export-Csv ".\output\$($script.BaseName).csv" -NoTypeInformation
}

