<#
  THIS NEEDS TO BE RUN IN THE DOMAIN OF THE INSTANCES--IT DOES AD WORK

.SYNOPSIS
  Creates a permission report for the instance(s).
.DESCRIPTION
  This script wil go to each instance, grab logins, members for 'WindowsGroups', server roles and members, server securables, database users, 
  database roles and member, and database securables.  It will then put it all that together into a report.
.EXAMPLE
    Get-SqlInstancePermissions.ps1 -ServerInstance 'instance1,14140','instance2,15150'
.INPUTS
  ServerInstance(string array)(mandatory): This is what instance or instances you want to query for info.
.OUTPUTS
  This will create 1 Excel file in the same folder that the script runs from. It will have a 'Report' worksheet and a bunch of other
  worksheets that contains all the basic data that was used to put together the report.
.NOTES
  This requires the ImportExcel module to export to Excel.

#>

$ServerInstance = @(
'ip.add.re.ss'
)

Set-Location $PSScriptRoot

try {
    Import-Module SqlServer
    Import-Module ImportExcel
}
catch {
    "Failed to load all modules."
    exit
}
function Get-SqlDbPermission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Database,
        [Parameter(Mandatory = $true)]$Principle
    )

    process { 
        # database permission
        foreach ($DbPermission in $Database.EnumDatabasePermissions($principle.Name)) {
            if ($DbPermission.PermissionState -eq "GrantWithGrant") {
                $WithGrant = " WITH GRANT OPTION"
                $Grant = "GRANT"
            }
            else {
                $WithGrant = ""
                $Grant = $DbPermission.PermissionState.ToString().ToUpper()
            }

            [PSCustomObject]@{
                Instance       = $Database.Parent.Name
                Database       = $Database.Name
                Grantee        = $DbPermission.Grantee
                Object         = ''
                PermissionType = $DbPermission.PermissionType
                Sql            = "$Grant $($DbPermission.PermissionType) TO [$($DbPermission.Grantee)]$WithGrant"
            }

        }
        
        # runs thru each object type specifically as the EnunObjectPermissions doesnt capture everything by default
        $ObjPermissions = New-Object System.Collections.ArrayList
        $null = $ObjPermissions.AddRange($Database.EnumObjectPermissions($principle.Name))
        foreach ($item in $Database.ApplicationRoles) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Database.Assemblies) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Database.Certificates) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Database.DatabaseRoles) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Database.FullTextCatalogs) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Database.FullTextStopLists) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Database.SearchPropertyLists) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Database.ServiceBroker.MessageTypes) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Database.RemoteServiceBindings) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Database.ServiceBroker.Routes) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Database.ServiceBroker.ServiceContracts) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Database.ServiceBroker.Services) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Database.AsymmetricKeys) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Database.SymmetricKeys) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Database.XmlSchemaCollections) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        
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
                Instance       = $Database.Parent.Name
                Database       = $Database.Name
                Grantee        = $ObjPermission.Grantee
                Object         = $object
                PermissionType = $ObjPermission.PermissionType
                Sql            = "$Grant $($ObjPermission.PermissionType) ON $object TO [$($ObjPermission.Grantee)]$WithGrant"
            }
        }
    }
}

function Get-SqlInstancePermission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Instance,
        [Parameter(Mandatory = $true)]$Principle
    )

    process { 
        # instance permission
        foreach ($ServerPermission in $Instance.EnumServerPermissions($l.Name)) {
            if ($ServerPermission.PermissionState -eq "GrantWithGrant") {
                $WithGrant = " WITH GRANT OPTION"
                $Grant = "GRANT"
            }
            else {
                $WithGrant = ""
                $Grant = $ServerPermission.PermissionState.ToString().ToUpper()
            }
        
            [PSCustomObject]@{
                Instance       = $i.Name
                Grantee        = $ServerPermission.Grantee
                Object         = ''
                PermissionType = $ServerPermission.PermissionType
                Sql            = "$Grant $($ServerPermission.PermissionType) TO [$($ServerPermission.Grantee)]$WithGrant"
            }
        }
        
        # runs thru each object type specifically as the EnunObjectPermissions doesnt capture everything by default
        $ObjPermissions = New-Object System.Collections.ArrayList
        $null = $ObjPermissions.AddRange($Instance.EnumObjectPermissions($principle.Name))
        foreach ($item in $Instance.ApplicationRoles) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Instance.Assemblies) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Instance.Certificates) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Instance.DatabaseRoles) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Instance.FullTextCatalogs) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Instance.FullTextStopLists) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Instance.SearchPropertyLists) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Instance.ServiceBroker.MessageTypes) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Instance.RemoteServiceBindings) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Instance.ServiceBroker.Routes) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Instance.ServiceBroker.ServiceContracts) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Instance.ServiceBroker.Services) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Instance.AsymmetricKeys) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Instance.SymmetricKeys) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        foreach ($item in $Instance.XmlSchemaCollections) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($principle.Name)) }
        
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
                Instance       = $Instance.Name
                Grantee        = $ObjPermission.Grantee
                Object         = $object
                PermissionType = $ObjPermission.PermissionType
                Sql            = "$Grant $($ObjPermission.PermissionType) ON $object TO [$($ObjPermission.Grantee)]$WithGrant"
            }
        }
    }
}

# report data
$Logins = New-Object System.Collections.ArrayList
$Groups = New-Object System.Collections.ArrayList
$ServerRoles = New-Object System.Collections.ArrayList
$ServerSecurables = New-Object System.Collections.ArrayList
$DatabaseRoles = New-Object System.Collections.ArrayList
$DatabaseSecurables = New-Object System.Collections.ArrayList
$AllData = New-Object System.Collections.ArrayList

foreach ($Instance in $ServerInstance) {
    "i:{0}" -f $Instance

    # try to connect to the instance
    try { 
        $i = Get-SqlInstance -ServerInstance $Instance -ErrorAction Stop
    }
    catch {
        Write-Output "Cannot connect to $Instance"
        continue
    }
    
    # get logins
    $il = foreach ($l in $i.Logins | Where-Object { $_.IsSystemObject -eq $false -and $_.Name -notlike 'NT *' -and $_.Name -notlike '##*' }) {
        $enabled = $null
        $logondate = $null
        
        if ($l.LoginType -eq 'WindowsUser') { 
            $user = ($l.Name.split('\'))[1]

        }
        elseif ($l.LoginType -eq 'SqlLogin') {
            $user = $l.Name
        }
        else {
            $user = $null
        }

        try {
            if ($user) {
                $adu = Get-ADUser $user -Properties Enabled, LastLogonDate
                $enabled = $adu.Enabled
                $logondate = $adu.LastLogonDate
            }
        }
        catch {
            $enabled = 'NO MATCH'
            $logondate = ''
        }
        [PSCustomObject]@{
            Instance         = $l.Parent.Name
            Name             = $l.Name
            LoginType        = $l.LoginType
            IsDisabled       = $l.IsDisabled
            DenyWindowsLogin = $l.DenyWindowsLogin
            AdEnabled        = $enabled
            AdLastLogonDate  = $logondate
        }
    } 

    # gets all groups that logins belong to on this instance, we later filter on only groups
    # that are on this server so we can tell if that login is getting permissions via a group
    $ig = foreach ($l in $il | Where-Object { $_.LoginType -eq 'WindowsUser' -and $_.Name -notlike '*$' }) {
        foreach ($group in (Get-AdUser $l.Name.Split('\')[1] -Properties *).MemberOf | ForEach-Object { $_.Split(',')[0].Split('=')[1] }) {
            [PSCustomObject]@{
                Instance = $i.Name
                Member   = $l.Name
                Name     = $group
            }
        }
    }

    
    # get server roles and members
    $ir = foreach ($r in $i.Roles) {
        foreach ($member in $r.EnumMemberNames()) {
            [PSCustomObject]@{
                Instance = $i.Name
                Role     = $r.Name
                Member   = $member
            } 
        }
    }

    # get server securables
    $is = foreach ($l in $il) {
        Get-SqlInstancePermission -Instance $i -Principle $l 
    }

    # get databases
    $dbs = $i.Databases | Where-Object { $_.IsAccessible -eq $true }

    $dbr = @()
    $dbp = @()

    foreach ($db in $dbs | Where-Object { $_.Parent.Name -eq $i.Name } ) {
        "  d:{0}" -f $db.Name
        foreach ($role in $db.Roles | Where-Object { $_.Name -ne 'public' } ) {
            "    r:{0}" -f $role.Name
            foreach ($member in $role.EnumMembers()) {
                "      m:{0}" -f $member
                $dbr += [PSCustomObject]@{
                    Instance = $i.Name
                    Database = $db.Name
                    Role     = $role.Name
                    Member   = $member
                }
            }
        }
        
        foreach ($user in $db.Users | Where-Object { $_.IsSystemObject -eq $false } ) {
            if ($user.Name -in $il.Name) {
                "    up:{0}" -f $user.Name
                $dbp += Get-SqlDbPermission -Database $db -Principle $user
            }
        }
        
        foreach ($role in $db.Roles | Where-Object { $_.IsFixedRole -eq $false -and $_.Name -ne 'public' } ) {
            "    rp:{0}" -f $role.Name
            $dbp += Get-SqlDbPermission -Database $db -Principle $role
        }
    }


    # bring all the data together
    Write-Output "Building report for instance ..."

    foreach ($l in $il) {

        "  l:{0}" -f $l.Name

        if ($l.IsDisabled -eq $true -or $l.DenyWindowsLogin -eq $true) { 
            $CanConnect = 'FALSE' 
        }
        else { 
            $CanConnect = 'TRUE' 
        }

        $serverlevel = [PSCustomObject]@{
            Instance    = $i.Name
            Login       = $l.Name
            LoginType   = $l.LoginType
            AdEnabled   = $l.AdEnabled
            AdLastLoginDate = $l.AdLastLogonDate
            MemberOf    = ($ig | Where-Object { $_.Member -eq $l.Name -and $_.Name -in ($il | Where-Object { $_.LoginType -eq 'WindowsGroup' } | ForEach-Object { $_.Name.Split('\')[1] } ) } ).Name -join ', '
            CanConnect  = $CanConnect
            Disabled    = $l.IsDisabled
            DenyConnect = $l.DenyWindowsLogin
            Database    = '.'
            Roles       = ($ir | Where-Object { $_.Member -eq $l.Name }).Role -join ', '
            Securables  = (($is | Where-Object { $_.Grantee -eq $l.Name }).PermissionType | Select-Object -Unique) -join ', '
        }
        $null = $AllData.Add($serverlevel)

        foreach ($db in $dbs) {
            if ($l.Name -notin $db.Users.Name) { continue }

            "    d:{0}" -f $db.Name

            $databaselevel = [PSCustomObject]@{
                Instance    = $i.Name
                Login       = $l.Name
                LoginType   = $l.LoginType
                AdEnabled   = $l.AdEnabled
                AdLastLoginDate = $l.AdLastLogonDate
                MemberOf    = ''
                CanConnect  = $CanConnect
                Disabled    = $l.IsDisabled
                DenyConnect = $l.DenyWindowsLogin
                Database    = $db.Name
                Roles       = ($dbr | Where-Object { $_.Member -eq $l.Name -and $_.Database -eq $db.Name }).Role -join ', '
                Securables  = ($dbp | Where-Object { $_.Grantee -eq $l.Name -and $_.Database -eq $db.Name }).PermissionType -join ', '
            }
            $null = $AllData.Add($databaselevel)
        }
    }

    # add to all instance objects
    $null = $Logins.Add($il)
    $null = $Groups.Add($ig)
    $null = $ServerRoles.Add($ir)
    $null = $ServerSecurables.Add($is)
    $null = $DatabaseRoles.Add($dbr)
    $null = $DatabaseSecurables.Add($dbp)
}

# $AllData | Format-Table -AutoSize

$ExcelFile = '.\InstancePermissions_' + (Get-Date -Format 'yyyMMdd_HHmmss') + '.xlsx'

"Export Report ..."
$AllData | Sort-Object Instance, Login, Database | Export-Excel -Path $ExcelFile -WorksheetName 'Report' -FreezeTopRow -AutoSize -AutoFilter

"Export _Logins ..."
$Logins | Export-Excel -Path $ExcelFile -WorksheetName '_Logins' -Append -FreezeTopRow -AutoSize

"Export _Groups ..."
$Groups | Export-Excel -Path $ExcelFile -WorksheetName '_Groups' -Append -FreezeTopRow -AutoSize

"Export _ServerRoles ..."
$ServerRoles | Export-Excel -Path $ExcelFile -WorksheetName '_ServerRoles' -Append -FreezeTopRow -AutoSize

"Export _Securables ..."
$ServerSecurables | Export-Excel -Path $ExcelFile -WorksheetName '_Securables' -Append -FreezeTopRow -AutoSize

"Export _DbRoles ..."
$DatabaseRoles | Export-Excel -Path $ExcelFile -WorksheetName '_DbRoles' -Append -FreezeTopRow -AutoSize

"Export _DbSecurables ..."
$DatabaseSecurables | Export-Excel -Path $ExcelFile -WorksheetName '_DbSecurables' -Append -FreezeTopRow -AutoSize