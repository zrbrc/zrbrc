<#
.SYNOPSIS
    This will create T-SQL to fix an orphaned Sql login.
.DESCRIPTION
    This will create T-SQL to fix an orphaned login. This will compare Name and Sid between a Login and User, if there is a 
    mismatch with the Sid, it gathers password, permissions, grants for the login and Sid from the user. Then generates 
    T-SQL to drop and recreate the login. 
.EXAMPLE
    PS C:\> .\Fix-Orphan.ps1 -Instance 'localhost,15150' -Database 'random_db' -User 'random_user1'
    This creates the sql to drop and recreate login 'random_user1' if there is a Sid mismatch, if not, it will state so and
    do nothing.
.INPUTS
    Instance (Mandatory)(string): 'localost,15150' or 'localhost\instancename'.
.INPUTS
    Database (Optional)(string): 'databasename' If not supplied will do all non-system DBs.
.INPUTS
    User (Optional)(string): 'username' If not supplied will do all non-system accounts.
.NOTES
    This is only trying to recreate the login based on the User details from the database, its possible each DB users may
    be out of sync too, so that scenario needs to be taken into account. If there is a user created without a login, it 
    will be skipped as we cannot use the user SID to create the login.
#>
param(
    [Parameter(Mandatory = $true)][String]$Instance,
    [String[]]$Database,
    [String[]]$User
)
$scripted = @()
$outsql = @()

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
    $logins = $i.Logins
}
catch {
    Write-Output "Cannot connect to $Instance."
    exit
}

# find dbs
$dbs = $i.Databases | Where-Object { ($_.Name -in $Database -or !$Database) -and $_.IsSystemObject -eq $false }

if (!$dbs) {
    Write-Output "No databases found matching criteria."
    exit
}

foreach ($db in $dbs) {
    Write-Output "db: $($db.name)"

    $users = $db.Users | Where-Object { ($_.Name -in $User -or !$User) -and $_.IsSystemObject -eq $false }

    if (!$users) {
        continue
    }

    foreach ($u in $users | Where-Object { $_.Name -notin $Scripted }) {
        
        # checks for matching login
        if ($logins | Where-Object { $_.Name -eq $u.Name }) {
            
            # user sid
            $usid = '0x'
            $u.Sid | ForEach-Object { $usid += ("{0:X}" -f $_).Padleft(2, '0') }

            if ($usid.Length -ne 34) {
                Write-Output "$($u.Name) created with out a login--cannot create script"
                continue
            }

            # login object
            $l = $logins[($u.Name)]
    
            # login sid
            $lsid = '0x'
            $l.Sid | ForEach-Object { $lsid += ("{0:X}" -f $_).Padleft(2, '0') }

            # compares sids
            if ($usid -ne $lsid) {

                # get policies from current login
                if ($l.PasswordPolicyEnforced -eq $false) { $checkPolicy = "OFF" }
                else { $checkPolicy = "ON" }

                if (!$l.PasswordExpirationEnabled) { $checkExpiration = "OFF" }
                else { $checkExpiration = "ON" }

                # get hashed password
                $sql = "SELECT CAST(CONVERT(VARCHAR(256), CAST(LOGINPROPERTY(name,'PasswordHash') AS VARBINARY(256)), 1) AS NVARCHAR(max)) AS hashedpass FROM sys.server_principals WHERE principal_id = $($l.Id)"
                $hashedPass = $i.ConnectionContext.ExecuteScalar($sql)

                # script drop and create login
                $outsql += "`n/****** Login: [$($l.Name)] Script Date: $(Get-Date) ******/"
                $outsql += "DROP LOGIN [$($l.Name)]"
                $outsql += 'GO'
                $outsql += "CREATE LOGIN [$($l.Name)]"
                $outsql += "WITH PASSWORD = $hashedPass HASHED,"
                $outsql += "SID = $usid,"
                $outsql += "CHECK_POLICY = $checkPolicy,"
                $outsql += "CHECK_EXPIRATION = $checkExpiration,"
                $outsql += "DEFAULT_LANGUAGE = [$($l.Language)],"
                $outsql += "DEFAULT_DATABASE = [$($l.DefaultDatabase)]"
                $outsql += 'GO'
                
                # script server roles
                foreach ($role in $i.Roles) {
                    $members = $role.EnumMemberNames()
                    if ($members -contains $u.Name ) {
                        $outsql += "ALTER SERVER ROLE [$($role.Name)] ADD MEMBER [$($u.Name)]"
                    }
                }
                
                # script server grants
                $perms = $i.EnumServerPermissions($u.Name)
                foreach ($perm in $perms) {
                    if ($perm.PermissionState -eq "GrantWithGrant") {
                        $WithGrant = " WITH GRANT OPTION"
                        $Grant = "GRANT"
                    }
                    else {
                        $WithGrant = ""
                        $Grant = $perm.PermissionState.ToString().ToUpper()
                    }
                    $outsql += "$Grant $($perm.PermissionType) to [$($u.Name)]$WithGrant"
                }
                $outsql += 'GO'
                $scripted += $u.Name
            }
        }
    }
}
$outsql