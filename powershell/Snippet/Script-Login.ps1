<#
.SYNOPSIS
.DESCRIPTION
.EXAMPLE
.INPUTS
.INPUTS
.INPUTS
.NOTES
#>
param(
    [Parameter(Mandatory = $true)][String]$Instance,
    [String[]]$Login
)

$outsql = @()
$outsql += "`nUSE master`nGO`n"

if (Get-Module SqlServer -ListAvailable) { 
    Import-Module SqlServer
}
else {
    Write-Output "SqlServer module not found, please install and run again."
    exit 
}  

# try to connect to instance and get its logins
try {
    $i = Get-SqlInstance -ServerInstance $Instance -ErrorAction Stop
}
catch {
    Write-Output "Cannot connect to $Instance."
    exit
}

$logins = $i.Logins | Where-Object { ($_.Name -in $Login -or !$Login) -and $_.IsSystemObject -eq $false -and $_.Name -notlike 'NT *' -and $_.Name -notlike '##*' }
if (!$logins) {
    Write-Output "No logins found matching criteria on [$($i.Name)]."
    exit
}

foreach ($l in $logins) {
    $outsql += "/****** Login: [$($l.Name)] Instance: [$($i.Name)] Script Date: $(Get-Date) ******/"
    $outsql += "CREATE LOGIN [$($l.Name)]"
    
    if ($l.LoginType -eq 'SqlLogin') {
        $sql = "SELECT CAST(CONVERT(VARCHAR(256), CAST(LOGINPROPERTY(name,'PasswordHash') AS VARBINARY(256)), 1) AS NVARCHAR(max)) AS hashedpass FROM sys.server_principals WHERE principal_id = $($l.Id)"
        $hashedPass = $i.ConnectionContext.ExecuteScalar($sql)
        $outsql += "WITH PASSWORD = $hashedPass HASHED," 
        
        $lsid = '0x'
        $l.Sid | ForEach-Object { $lsid += ("{0:X}" -f $_).Padleft(2, '0') }
        $outsql += "SID = $lsid,"

        if ($l.PasswordPolicyEnforced -eq $false) { $checkPolicy = "OFF" }
        else { $checkPolicy = "ON" }
        $outsql += "CHECK_POLICY = $checkPolicy,"

        if (!$l.PasswordExpirationEnabled) { $checkExpiration = "OFF" }
        else { $checkExpiration = "ON" }
        $outsql += "CHECK_EXPIRATION = $checkExpiration,"
    }
    else {
        $outsql += 'FROM WINDOWS WITH'
    }

    $outsql += "DEFAULT_LANGUAGE = [$($l.Language)],"
    $outsql += "DEFAULT_DATABASE = [$($l.DefaultDatabase)]"

    # script server roles
    foreach ($role in $i.Roles) {
        $members = $role.EnumMemberNames()
        if ($members -contains $l.Name ) {
            $outsql += "ALTER SERVER ROLE [$($role.Name)] ADD MEMBER [$($l.Name)]"
        }
    }
        
    # script server grants
    $perms = $i.EnumServerPermissions($l.Name)
    foreach ($perm in $perms) {
        if ($perm.PermissionState -eq "GrantWithGrant") {
            $WithGrant = " WITH GRANT OPTION"
            $Grant = "GRANT"
        }
        else {
            $WithGrant = ""
            $Grant = $perm.PermissionState.ToString().ToUpper()
        }
        $outsql += "$Grant $($perm.PermissionType) to [$($l.Name)]$WithGrant"
    }

    if ($l.IsDisabled -eq $true) {
        $outsql += "ALTER LOGIN [$($l.Name)] DISABLE"
    }

    $outsql += "GO`n"
}
$outsql