Set-Location $PSScriptRoot

$DBAInstance = 'xx.xx.xx.xx,15150'

$Servers = Read-SqlTableData -ServerInstance $DBAInstance -Database 'DBA' -SchemaName 'dbo' -TableName 'Servers_T'

# get domain we are running in 
$Domain = $env:USERDOMAIN

# get ip for server we are running on
$IPAddress = (Test-Connection $env:COMPUTERNAME -Count 1 | Select-Object -First 1).IPV4Address.IPAddressToString

# determine our network zone
switch -Wildcard ($IPAddress) {
    "172.31.23*" { $Zone = 'EL2' }
    "172.31.45.*" { $Zone = 'IMDZ3' }
    "172.31.121.*" { $Zone = 'IDEV' }
    default { $Zone = $null }
}

$query =  Get-Content -Path '.\Install-sp_Blitz-All.sql' | Out-String

foreach ($server in $Servers | Where-Object { $_.Domain -eq $Domain -and $_.DMZ -eq $Zone -and $_.Type -eq 2 }) {
    "$($server.HostName)"

    # Invoke-DbaQuery -SqlInstance "$($server.HostName),$($server.SqlServerPort)" -Database 'master' -Query $query
    
}


