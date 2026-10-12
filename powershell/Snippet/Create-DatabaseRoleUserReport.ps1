$instances = @(
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150'
)
$instancequery = 'SELECT SP1.name AS ServerRoleName, 
isnull (SP2.name, ''No members'') AS LoginName   
FROM sys.server_role_members AS SRM
RIGHT OUTER JOIN sys.server_principals AS SP1
  ON SRM.role_principal_id = SP1.principal_id
LEFT OUTER JOIN sys.server_principals AS SP2
  ON SRM.member_principal_id = SP2.principal_id
WHERE SP1.is_fixed_role = 1 -- Remove for SQL Server 2008
ORDER BY SP1.name'

$dbquery = 'SELECT DP1.name AS DatabaseRoleName, 
isnull (DP2.name, ''No members'') AS DatabaseUserName 
FROM sys.database_role_members AS DRM
RIGHT OUTER JOIN sys.database_principals AS DP1
ON DRM.role_principal_id = DP1.principal_id
LEFT OUTER JOIN sys.database_principals AS DP2
ON DRM.member_principal_id = DP2.principal_id
WHERE DP1.is_fixed_role = 1
ORDER BY DP1.name'

$output = foreach ($item in $instances) {

    $instance = Get-SqlInstance -ServerInstance $item

    $data = Invoke-SqlCmd -ServerInstance $instance -Database 'master' -Query $instancequery
    foreach ($row in $data) {
        [PSCustomObject]@{
            Instance  = $instance.Name
            Database  = '##ServerLevel'
            Role      = $row.ServerRoleName
            LoginUser = $row.LoginName
        }
    }
    foreach ($db in $instance.Databases | Where-Object { $_.IsAccessible -eq $true }) {
        $data = Invoke-SqlCmd -ServerInstance $instance -Database $db.Name -Query $dbquery
        foreach ($row in $data) {
            [PSCustomObject]@{
                Instance  = $instance.Name
                Database  = $db.Name
                Role      = $row.DatabaseRoleName
                LoginUser = $row.DatabaseUserName
            }
        }
    }
}
$output | Sort-Object Instance, Database, Role, LoginUser | Export-Excel -Path 'M:\Temp\Server-DB-Role-Users.xlsx'