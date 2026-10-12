<#
.SYNOPSIS
  Exports Roles and Users of a database to T-SQL.
.DESCRIPTION
  Exports Roles and Users of a database to T-SQL. Set Instances and DBs to export in the $targets variable below.
.PARAMETER

.NOTES
  Version:        1.0
  Author:         Ryan Zerbe
  Creation Date:  2020-01
.EXAMPLE
#>

Import-Module dbatools
Set-Location $PSScriptRoot

function Export-Permissions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$PrincipalSmo,
        [Parameter(Mandatory = $true)]$DatabaseSmo
    )

    process { 
        # sql array to return
        $sql = @()
    
        # set scripter options
        $scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter $DatabaseSmo.Parent
        $scripter.Options.AllowSystemObjects = $false
        $scripter.Options.IncludeHeaders = $true
        $scripter.Options.Permissions = $true
        $scripter.Options.IncludeIfNotExists = $true
        $scripter.Options.IncludeDatabaseRoleMemberships = $true

        # scripts header and if not exist create
        $scripter.EnumScript($PrincipalSmo) | ForEach-Object { $sql += $_ }
        
        # scripts database permission
        foreach ($_Permission in $DatabaseSmo.EnumDatabasePermissions($PrincipalSmo.Name)) {
            if ($_Permission.PermissionState -eq "GrantWithGrant") {
                $WithGrant = " WITH GRANT OPTION"
                $Grant = "GRANT"
            }
            else {
                $WithGrant = ""
                $Grant = $_Permission.PermissionState.ToString().ToUpper()
            }
            $sql += "$Grant $($_Permission.PermissionType) TO [$($_Permission.Grantee)]$WithGrant"
        }
        
        # runs thru each object type specifically as the EnunObjectPermissions doesnt capture everything by default
        $ObjPermissions = New-Object System.Collections.ArrayList
        $null = $ObjPermissions.AddRange($DatabaseSmo.EnumObjectPermissions($PrincipalSmo.Name))
        foreach ($Instancetem in $DatabaseSmo.ApplicationRoles) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        foreach ($Instancetem in $DatabaseSmo.Assemblies) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        foreach ($Instancetem in $DatabaseSmo.Certificates) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        foreach ($Instancetem in $DatabaseSmo.DatabaseRoles) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        foreach ($Instancetem in $DatabaseSmo.FullTextCatalogs) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        foreach ($Instancetem in $DatabaseSmo.FullTextStopLists) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        foreach ($Instancetem in $DatabaseSmo.SearchPropertyLists) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        foreach ($Instancetem in $DatabaseSmo.ServiceBroker.MessageTypes) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        foreach ($Instancetem in $DatabaseSmo.RemoteServiceBindings) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        foreach ($Instancetem in $DatabaseSmo.ServiceBroker.Routes) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        foreach ($Instancetem in $DatabaseSmo.ServiceBroker.ServiceContracts) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        foreach ($Instancetem in $DatabaseSmo.ServiceBroker.Services) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        foreach ($Instancetem in $DatabaseSmo.AsymmetricKeys) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        foreach ($Instancetem in $DatabaseSmo.SymmetricKeys) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        foreach ($Instancetem in $DatabaseSmo.XmlSchemaCollections) { $null = $ObjPermissions.AddRange($Instancetem.EnumObjectPermissions($PrincipalSmo.Name)) }
        
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
        Write-Output $sql
    }
}

# uses stored credentials or creates new
$sa = "$env:LOCALAPPDATA\sa.xml"
if (Test-Path -Path $sa -PathType Leaf) {
    $sa = Import-Clixml $sa
    Write-Output "Credentials imported from $sa."
}
else {
    $sa = Get-Credential -Credential 'sa'
    $sa | Export-Clixml $sa
    Write-Output "Account credentials stored to $sa."
}

$targets = 'jupiter.home.lan,1433'

Get-DbaDatabase -SqlInstance $targets -SqlCredential $sa -EnableException -ExcludeSystem | ForEach-Object {
    Write-Output "`n$($_.Name)"

    $RoleUserFile = ".\$($_.Name)_$(Get-Date -Format "yyyyMMdd_HHmm")_roles_users.sql" 

    $roles = $_.Roles | Where-Object { $_.IsFixedRole -ne $true -and $_.Name -notin "public" }
    if ($roles.count -ne 0) {
        Write-Output "  - Roles"
        $HeaderSql = @()
        $HeaderSql += "/* ROLES */"
        $HeaderSql += "USE [$($_.Name)]"
        $HeaderSql += "GO"
        
        $RoleSql = @()
        foreach ($role in $roles) {
            $RoleSql += Export-Permissions -PrincipalSmo $role -DatabaseSmo $_
            Write-Output "    - $($Role.Name)"
        }
        $HeaderSql + $RoleSql | Out-File -FilePath $RoleUserFile -Encoding UTF8 -Append
    }
    
    $users = $_.Users | Where-Object { $_.IsSystemObject -eq $false -and $_.Name -notlike "##*" }
    if ($users.count -ne 0) {
        Write-Output "  - Users"
        $HeaderSql = @()
        $HeaderSql += "/* USERS */"
        $HeaderSql += "USE [$($_.Name)]"
        $HeaderSql += "GO"
        
        $UserSql = @()
        foreach ($user in $users) {
            $UserSql += Export-Permissions -PrincipalSmo $user -DatabaseSmo $_
            Write-Output "    - $($User.Name)"
        }
        $HeaderSql + $UserSql | Out-File -FilePath $RoleUserFile -Encoding UTF8 -Append
    }
    Write-Output "$RoleUserFile"
}