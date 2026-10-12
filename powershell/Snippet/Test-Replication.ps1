# https://www.sqlservercentral.com/articles/script-sql-server-replication-with-powershell

$s = Get-SqlInstance -ServerInstance 'LUNA\DE2019'
$s.ReplicationDatabases
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Rmo')

$RmoPath = 'C:\Program Files\Microsoft SQL Server\150\SDK\Assemblies\Microsoft.SqlServer.Replication.dll'
Add-Type -Path $RmoPath

$repl = New-Object Microsoft.SqlServer.Replication.ReplicationServer $s.Name

$repl.ReplicationDatabases | Where-Object {$_.HasPublications -eq $true}