<#
.SYNOPSIS
    Sql Functions
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>

function Export-SqlDbPermission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Database,
        [Parameter(Mandatory = $true)]$Principal
    )

    process { 
        # sql array to return
        $sql = @()
    
        # set scripter options
        $scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter $Database.Parent
        $scripter.Options.AllowSystemObjects = $false
        $scripter.Options.IncludeHeaders = $true
        $scripter.Options.Permissions = $true
        $scripter.Options.IncludeIfNotExists = $true
        $scripter.Options.IncludeDatabaseRoleMemberships = $true

        # scripts header and if not exist create
        $scripter.EnumScript($Principal) | ForEach-Object { $sql += $_ }
        
        # scripts database permission
        foreach ($DbPermission in $Database.EnumDatabasePermissions($Principal.Name)) {
            if ($DbPermission.PermissionState -eq "GrantWithGrant") {
                $WithGrant = " WITH GRANT OPTION"
                $Grant = "GRANT"
            }
            else {
                $WithGrant = ""
                $Grant = $DbPermission.PermissionState.ToString().ToUpper()
            }
            $sql += "$Grant $($DbPermission.PermissionType) TO [$($DbPermission.Grantee)]$WithGrant"
        }
        
        # runs thru each object type specifically as the EnunObjectPermissions doesnt capture everything by default
        $ObjPermissions = New-Object System.Collections.ArrayList
        $null = $ObjPermissions.AddRange($Database.EnumObjectPermissions($Principal.Name))
        foreach ($item in $Database.ApplicationRoles) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        foreach ($item in $Database.Assemblies) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        foreach ($item in $Database.Certificates) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        foreach ($item in $Database.DatabaseRoles) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        foreach ($item in $Database.FullTextCatalogs) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        foreach ($item in $Database.FullTextStopLists) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        foreach ($item in $Database.SearchPropertyLists) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        foreach ($item in $Database.ServiceBroker.MessageTypes) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        foreach ($item in $Database.RemoteServiceBindings) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        foreach ($item in $Database.ServiceBroker.Routes) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        foreach ($item in $Database.ServiceBroker.ServiceContracts) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        foreach ($item in $Database.ServiceBroker.Services) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        foreach ($item in $Database.AsymmetricKeys) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        foreach ($item in $Database.SymmetricKeys) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        foreach ($item in $Database.XmlSchemaCollections) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($Principal.Name)) }
        
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
            $sql += "$Grant $($ObjPermission.PermissionType) ON $object TO [$($ObjPermission.Grantee)]$WithGrant"
        }
        $sql += "GO"
        $sql
    }
}

function Export-SqlDbObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Database,
        [Parameter(Mandatory = $true)]$Object,
        [switch]$ScriptDrops
    )

    process {
        # create scripter object to export
        $scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter $Database.Parent
        $scripter.Options.IncludeHeaders = $true
        
        $sql = @()
        foreach ($obj in $Object) {
            # script drops
            if ($PSBoundParameters.ContainsKey('ScriptDrops')) {   
                $scripter.Options.ScriptDrops = $true 
                foreach ($script in $($scripter.EnumScript($obj))) {
                    $sql += $script
                    $sql += "GO`n"
                }
            }
            # scripts creates
            $scripter.Options.ScriptDrops = $false
            foreach ($script in $($scripter.EnumScript($obj))) {
                $sql += $script
                $sql += "GO`n"
            }
        }
        $sql
    }
}