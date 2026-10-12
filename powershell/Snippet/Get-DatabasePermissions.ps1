Import-Module SqlServer

# instance and database to export for
$instance = 'LUNA\DE2019'
$dbname = 'random_db'

function Export-Permissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Principle,
        [Parameter(Mandatory = $true)]$Database
    )

    process { 
        # database permission
        foreach ($DbPermission in $database.EnumDatabasePermissions($principle.Name)) {
            if ($DbPermission.PermissionState -eq "GrantWithGrant") {
                $WithGrant = " WITH GRANT OPTION"
                $Grant = "GRANT"
            }
            else {
                $WithGrant = ""
                $Grant = $DbPermission.PermissionState.ToString().ToUpper()
            }

            [PSCustomObject]@{
                PermissionType = $DbPermission.PermissionType
                Object         = ''
                Grantee        = $DbPermission.Grantee
                Sql            = "$Grant $($DbPermission.PermissionType) TO [$($DbPermission.Grantee)]$WithGrant"
            }

        }
        
        # runs thru each object type specifically as the EnunObjectPermissions doesnt capture everything by default
        $ObjPermissions = New-Object System.Collections.ArrayList
        $null = $ObjPermissions.AddRange($database.EnumObjectPermissions($principle.Name))
        foreach ($item in $database.ApplicationRoles) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $database.Assemblies) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $database.Certificates) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $database.DatabaseRoles) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $database.FullTextCatalogs) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $database.FullTextStopLists) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $database.SearchPropertyLists) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $database.ServiceBroker.MessageTypes) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $database.RemoteServiceBindings) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $database.ServiceBroker.Routes) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $database.ServiceBroker.ServiceContracts) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $database.ServiceBroker.Services) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $database.AsymmetricKeys) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $database.SymmetricKeys) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $database.XmlSchemaCollections) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        
        # sets correct object types for grants
        foreach ($ObjPermission in $ObjPermissions) {
            switch ($objPermission.ObjectClass) {
                'ApplicationRole' { $object = 'APPLICATION ROLE::[{0}]' -f $ObjPermission.ObjectName }
                'AsymmetricKey' { $object = 'ASYMMETRIC KEY::[{0}]' -f $ObjPermission.ObjectName }
                'Certificate' { $object = 'CERTIFICATE::[{0}]' -f $ObjPermission.ObjectName }
                'DatabaseRole' { $object = 'ROLE::[{0}]' -f $ObjPermission.ObjectName }
                'FullTextCatalog' { $object = 'FULLTEXT CATALOG::[{0}]' -f $ObjPermission.ObjectName }
                'FullTextStopList' { $object = 'FULLTEXT STOPLIST::[{0}]' -f $ObjPermission.ObjectName }
                'MessageType' { $object = 'Message Type::[{0}]' -f $ObjPermission.ObjectName }
                'ObjectOrColumn' {
                    $object = 'OBJECT::[{0}].[{1}]' -f $ObjPermission.ObjectSchema, $ObjPermission.ObjectName
                    if ($null -ne $ObjPermission.ColumnName) { $object += '([{0}])' -f $ObjPermission.ColumnName }
                }
                'RemoteServiceBinding' { $object = 'REMOTE SERVICE BINDING::[{0}]' -f $ObjPermission.ObjectName }
                'Schema' { $object = 'SCHEMA::[{0}]' -f $ObjPermission.ObjectName }
                'SearchPropertyList' { $object = 'SEARCH PROPERTY LIST::[{0}]' -f $ObjPermission.ObjectName }
                'Service' { $object = 'SERVICE::[{0}]' -f $ObjPermission.ObjectName }
                'ServiceContract' { $object = 'CONTRACT::[{0}]' -f $ObjPermission.ObjectName }
                'ServiceRoute' { $object = 'ROUTE::[{0}]' -f $ObjPermission.ObjectName }
                'SqlAssembly' { $object = 'ASSEMBLY::[{0}]' -f $ObjPermission.ObjectName }
                'SymmetricKey' { $object = 'SYMMETRIC KEY::[{0}]' -f $ObjPermission.ObjectName }
                'User' { $object = 'USER::[{0}]' -f $ObjPermission.ObjectName }
                'UserDefinedType' { $object = 'TYPE::[{0}].[{1}]' -f $ObjPermission.ObjectSchema, $ObjPermission.ObjectName }
                'XmlNamespace' { $object = 'XML SCHEMA COLLECTION::[{0}]' -f $ObjPermission.ObjectName }
            }
            
            # creates grant statements
            if ($ObjPermission.PermissionState -eq "GrantWithGrant") {
                $WithGrant = " WITH GRANT OPTION"
                $Grant = "GRANT"
            }
            else {
                $WithGrant = ""
                $Grant = $ObjPermission.PermissionState.ToString().ToUpper()
            }

            [PSCustomObject]@{
                PermissionType = $ObjPermission.PermissionType
                Object         = $object
                Grantee        = $ObjPermission.Grantee
                Sql            = "$Grant $($ObjPermission.PermissionType) ON $object TO [$($ObjPermission.Grantee)]$WithGrant"
            }
        }
    }
}

$Table = @()

$db = Get-SqlDatabase -ServerInstance $instance -Database $dbname

$roles = $db.Roles | Where-Object { $_.Name -notin "public" }
if ($roles.count -ne 0) {
    foreach ($role in $roles) {
        $Table += Export-Permissions -Principle $role -Database $db
    }
}

$users = $db.Users | Where-Object { $_.IsSystemObject -ne $true }
if ($users.count -ne 0) {
    foreach ($user in $users) {
        $Table += Export-Permissions -Principle $user -Database $db
    }
}

$Table | Format-Table