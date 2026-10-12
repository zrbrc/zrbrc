<#
.SYNOPSIS
    Takes a csv of Instance, Database, User and scripts out db perms for backup purposes. This can be run across domains,
    it will ask for basetech login credentials on first launch and then store them locally @ "$env:LOCALAPPDATA\basetech.xml".
    If you need to reset the creds, delete that file.
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> .\Script-UserPermissions.ps1 -FilePath 'C:\path\to\csv\file.txt
.INPUTS
    CSV file, in the format of:
        
        Instance;Database;User

.OUTPUTS
    T-SQL on the console.

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ -PathType Leaf })] 
    [System.IO.FileInfo]
    $FilePath
)

Set-Location $PSScriptRoot

$previnstance = $null

# $credspath = "$env:LOCALAPPDATA\basetech.xml"
# if (Test-Path -Path $credspath -PathType Leaf) {
#     $basetech = Import-Clixml $credspath
#     Write-Output "Credentials imported from $credspath."
# }
# else {
#     $basetech = Get-Credential -Credential 'basetech'
#     $basetech | Export-Clixml $credspath
#     Write-Output "Account credentials stored to $credspath."
# }

function Export-UserPermissions {
    param(
        [Parameter(Mandatory = $true)]$UserSmo,
        [Parameter(Mandatory = $true)]$DatabaseSmo
    )

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
    $scripter.EnumScript($UserSmo) | ForEach-Object { $sql += $_ }
        
    # scripts database permission
    foreach ($DbPermission in $DatabaseSmo.EnumDatabasePermissions($UserSmo.Name)) {
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
    $null = $ObjPermissions.AddRange($DatabaseSmo.EnumObjectPermissions($UserSmo.Name))
    foreach ($item in $DatabaseSmo.ApplicationRoles) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
    foreach ($item in $DatabaseSmo.Assemblies) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
    foreach ($item in $DatabaseSmo.Certificates) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
    foreach ($item in $DatabaseSmo.DatabaseRoles) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
    foreach ($item in $DatabaseSmo.FullTextCatalogs) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
    foreach ($item in $DatabaseSmo.FullTextStopLists) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
    foreach ($item in $DatabaseSmo.SearchPropertyLists) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
    foreach ($item in $DatabaseSmo.ServiceBroker.MessageTypes) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
    foreach ($item in $DatabaseSmo.RemoteServiceBindings) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
    foreach ($item in $DatabaseSmo.ServiceBroker.Routes) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
    foreach ($item in $DatabaseSmo.ServiceBroker.ServiceContracts) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
    foreach ($item in $DatabaseSmo.ServiceBroker.Services) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
    foreach ($item in $DatabaseSmo.AsymmetricKeys) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
    foreach ($item in $DatabaseSmo.SymmetricKeys) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
    foreach ($item in $DatabaseSmo.XmlSchemaCollections) { $null = $ObjPermissions.AddRange($item.EnumObjectPermissions($UserSmo.Name)) }
        
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
    $sql += "GO`n"
    Write-Output $sql
}

if (Get-Module SqlServer -ListAvailable) { 
    Import-Module SqlServer
}
else {
    Write-Output "SqlServer module not found, please install and run again."
    exit 
}

$outsql = @()
$outsql += "RAISERROR(N'Oops! No, don''t just hit F5. Run these pieces one at a time as needed per instance.', 20, 1) WITH LOG"
$outsql += "GO`n"

$records = Import-Csv $FilePath -Delimiter ';' | Sort-Object -Property Instance, Database, User

# loop thru the users in the input file
foreach ($record in $records) {
    $record
    
    try {

        #instead of getting a new instance SMO, we user sorted file and see if we can use the one from the previous user
        if ($record.Instance -ne $previnstance) {
            $i = Get-SqlInstance -ServerInstance $record.Instance #-Credential $basetech
            $outsql += "/* = = = $($record.Instance) = = = = = = = = = = = = = = = = = = = = = = = = = = */"
        }

        # same as above, see if we are going against same db
        $db = $i.Databases[($record.Database)]

        # create output header and get permissions via function
        $outsql += "USE [$($db.Name)]"
        $outsql += 'GO'
        $outsql += Export-UserPermissions -DatabaseSmo $db -UserSmo $db.Users[($record.User)]
    
        $previnstance = $record.Instance
    }
    catch {
        $ErrorMessage = $_.Exception
        $ErrorMessage
        continue
    }
}

$outsql | Out-File -FilePath ".\output_$(Get-Date -Format "yyyyMMdd_hhmm").sql"