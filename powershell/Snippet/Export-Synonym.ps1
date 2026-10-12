Set-Location $PSScriptRoot

if (Test-Path -Path .\sa.xml) {
    $cred = Import-Clixml -Path .\sa.xml
}
else {
    $cred = Get-Credential -Credential 'sa'
    $cred | Export-Clixml -Path .\sa.xml
}

$db = Get-SqlDatabase -ServerInstance 'jupiter.home.lan,1401' -Credential $cred -Database 'random_db' 

$syns = $db.Synonyms

$scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter $db.Parent
$scripter.Options.IncludeHeaders = $true

# script drops
$sql = foreach ($obj in $syns) {
    $scripter.Options.ScriptDrops = $true 
    $scripter.EnumScript($obj)
    "GO"
    $scripter.Options.ScriptDrops = $false
    $scripter.EnumScript($obj)
    "GO"
}
$sql