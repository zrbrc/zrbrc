
<#
.SYNOPSIS
    Scripts database roles, users, and permissions.
.NOTES
    This will create roles if necessary.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Instance,
    
    [Parameter(Mandatory = $true)]
    [string[]]$Database,
    
    [string[]]$User
)

function Export-SqlDbPermission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Database,
        [Parameter(Mandatory = $true)]$Principal
    )

    process { 
        # sql array to return
        $sql = @()
    
        # if this is a user, lets drop it before we create it so we dont have mismatched SIDS, this makes it easier so we dont need to drop anything before, if needed
		if ($null -ne $Principal.LoginType) {
			# set scripter options
			$scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter $Database.Parent
			$scripter.Options.AllowSystemObjects = $false
			$scripter.Options.IncludeHeaders = $true
			$scripter.Options.ScriptDrops = $true
            $scripter.Options.IncludeIfNotExists = $true
	
			# scripts drops
			$scripter.EnumScript($Principal) | ForEach-Object { $sql += $_ }
		}
	
        # set scripter options
        $scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter $Database.Parent
        $scripter.Options.AllowSystemObjects = $false
        $scripter.Options.Permissions = $true
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

Set-Location $PSScriptRoot

if (Get-Module SqlServer -ListAvailable) { 
	Write-Output "Loading SqlServer module ..."
    Import-Module SqlServer
}
else {
    Write-Output "SqlServer module not found, please install and run again."
    exit 
}  

# try to connect to instance
try {
    $i = Get-SqlInstance -ServerInstance $Instance -ErrorAction Stop
}
catch {
    "Cannot connect to {0}." -f $Instance
    exit
}

if (!$Database) {
    [array]$Database = (Read-Host "Database(s) (comma seperated)? (blank for all)").Split(',')
}

$Databases = $i.Databases | Where-Object { ($_.Name -in $Database -or !$Database) -and $_.IsSystemObject -eq $false -and $_.IsAccessible -eq $true }
if (!$Databases) {
    "No user databases found on [{0}]." -f $i.Name
    exit
}

foreach ($db in $Databases) {
    $outsql = @()
    $outsql += "`r`n/* --- START ---------- */"
    $outsql += "USE [$($db.Name)]"
	$outsql += "GO"
    
    $dbroles = $db.Roles | Where-Object { $_.IsFixedRole -ne $true -and $_.Name -notin "public" }

    if ($dbroles.count -ne 0) {
	    
        "{0} exporting {1} roles ..." -f $db.Name, $dbroles.count

        $dbroleParentSql = @()
        $dbroleSql = @()
                
        foreach ($dbrole in $dbroles) {
            "  - {0}" -f $dbrole.Name
                    
            $ParentRole = $false

            foreach ($Member in $dbrole.EnumMembers()) {
                if ($Member -in $dbroles.Name) {
                    $ParentRole = $true
                }
            }

            if ($ParentRole) {
                $dbroleParentSql += Export-SqlDbPermission -Database $db -Principal $dbrole 
            }
            else {
                $dbroleSql += Export-SqlDbPermission -Database $db -Principal $dbrole 
            }
        }

        if ($dbroleSql -or $dbroleParentSql) {
            $outsql += $dbroleParentSql + $dbroleSql
        }
    }
    else {
        "{0} no roles exported." -f $db.Name
    }

    $dbusers = $db.Users | Where-Object { $_.IsSystemObject -eq $false -and $_.Name -notlike "##*"}

    if ($dbusers.count -ne 0) {
        "{0} exporting {1} users ..." -f $db.Name, $dbusers.count
		
		$dbusersql =@()
		
        foreach ($dbuser in $dbusers) {
            "  - {0}" -f $dbuser.Name
			
            $dbusersql += Export-SqlDbPermission -Database $db -Principal $dbuser 
        }
		
		if ($dbusersql) {
			$outsql += $dbusersql
		}
    }
    else {
        "{0} no users exported." -f $db.Name
    }
    $outfile = '.\' + $db.Name + '_roles_users_' + (Get-Date -Format "yyyyMMdd_hhmmss") + '.sql'
    $outsql += "/* --- END ------------ */" 
    $outsql | Out-File $outfile -Encoding utf8
	$outsql
	"Saved to: {0}" -f $outfile
}
