<#
.SYNOPSIS
    Syncs Roles, Logins and Permissions.

.DESCRIPTION
    Syncs Roles, Logins and Permissions.
    It will create any missing logins and it will sync the password for Sql logins.
    It will grant or revoke (if requested) any permissions on the source to the destination.
    
.PARAMETER Source
    String. Mandatory. A SQL connection in the format of 'ip,port', 'hostname,port', or 'hostname\instance'.
.PARAMETER Destination
    String. Mandatory. A SQL connection in the format of 'ip,port', 'hostname,port', or 'hostname\instance'.
.PARAMETER RevokePermissions
    Switch. Optional. This will revoke permissions on the destination that are not found on the target.
.PARAMETER SyncPassword
    Switch. Optional. This will make passwords sync if an existing SqlLogin.
.PARAMETER WhatIf
    Switch. Optional. This will show what will happen without performing any work.
    
.EXAMPLE
    PS C:\> .\Sync-Logins.ps1 -Source 'ip,port' -Destination 'ip,port'

    This will sync all server role memberships, logins, and permissions from 231.242 to 231.243.

.NOTES
    This will not make any changes on the Source server and it will not drop any logins on the target.
    It only makes changes to the target; creating logins, syncing passwords, updating server role 
    membership, or adding permissions as needed. This will NOT remove/revoke any permissions by default.
    If you want to revoke permissions, pass the -RevokePermissions switch.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$Source,
    [Parameter(Mandatory = $true)]
    [array]$Destination,
    [switch]$RevokePermissions,
    [switch]$SyncPassword,
    [switch]$WhatIf
)

Import-Module SqlServer
$ErrorActionPreference = 'Stop'

$ExcludeLogins = 'sa'

$RoleFilter = { $_.Name -ne 'sysadmin' }
$RoleMemberFilter = { $_ -notlike "NT*" -and $_ -notlike "##*" -and $_ -notin $ExcludeLogins }
$LoginFilter = { $_.Name -notin $ExcludeLogins -and $_.Name -notlike "NT*" -and $_.Name -notlike "##*" -and $_.IsSystemObject -eq $false }

# make sure we can reach the source server, else exit
try {
    $SourceServer = Get-SqlInstance -ServerInstance $Source
}
catch {
    Write-Output "$Source unreachable. Exiting."
    $_.Exception.Message
    exit
}

# source server roles
$SourceRoles = $SourceServer.Roles | Where-Object $RoleFilter

# source server logins
$SourceLogins = $SourceServer.Logins | Where-Object $LoginFilter

# source server permissions
$SourcePerms = $SourceServer.EnumServerPermissions()


# sync for each destination 
foreach ($Dest in $Destination) {

    # make sure we can reach the destination, else skip it
    try {
        $DestServer = Get-SqlInstance -ServerInstance $Dest
    }
    catch {
        Write-Output "$Dest unreachable. Skipping."
        $_.Exception.Message
        continue
    }

    Write-Output "Syncing from $($SourceServer.Name) to $($DestServer.Name)"
    
    # sync server roles and members
    foreach ($SourceRole in $SourceRoles) {
        
        # get matching destination role
        $RoleName = $SourceRole.Name
        $DestRole = $DestServer.Roles[$RoleName]
        
        # if destination role exists get info on roles
        if ($null -ne $DestRole) {
            
            # gets source role memebers
            $SourceRoleMembers = $SourceRole.EnumMemberNames() | Where-Object $RoleMemberFilter
    
            # gets members of destination role
            $DestRoleMembers = $DestRole.EnumMemberNames() | Where-Object $RoleMemberFilter
            
            # if member is in source and not in destination, add to destination role
            foreach ($SourceRoleMember in $SourceRoleMembers) {
                if ($DestRoleMembers -notcontains $SourceRoleMember) {
                    if ($WhatIf.IsPresent) {
                        Write-Output "WhatIf: Adding $SourceRoleMember to $($DestRole.Name) on $($DestServer.Name)."
                    }
                    else {
                        try {
                            $DestRole.AddMember($SourceRoleMember)
                            Write-Output "Added $SourceRoleMember to $($DestRole.Name) on $($DestServer.Name)."
                        }
                        catch {
                            Write-Output "!Failed to add $SourceRoleMember to $($DestRole.Name) on $($DestServer.Name)."
                            $_.Exception.Message
                            continue
                        }
                    } 
                }
            }
            
            # if member is not source and is in destination, remove from destination role
            if ($RevokePermissions.IsPresent) {
                foreach ($DestRoleMember in $DestRoleMembers) {
                    if ($SourceRoleMembers -notcontains $DestRoleMember) { 
                        if ($WhatIf.IsPresent) {
                            Write-Output "WhatIf: Removing $SourceRoleMember from $($DestRole.Name) on $($DestServer.Name)."
                        }
                        else {
                            try {
                                Write-Output "Removing $SourceRoleMember from $($DestRole.Name) on $($DestServer.Name)."
                                $DestRole.DropMember($DestRoleMember)
                            }
                            catch {
                                Write-Output "!Failed to remove $DestRoleMember from $($DestRole.Name) on $($DestServer.Name)."
                                $_.Exception.Message
                                continue
                            }
                        }
                    }
                }
            }

        }
        else {
            Write-Output "$($SourceRole.Name) not found on destination. Skipping."
        }
    }

    # gotta close because enum repeatedly causes problems with the datareader
    $null = $SourceServer.ConnectionContext.SqlConnectionObject.Close()
    $null = $DestServer.ConnectionContext.SqlConnectionObject.Close()

    $DestLogins = $DestServer.Logins | Where-Object $LoginFilter
    
    $DestPerms = $DestServer.EnumServerPermissions()
    
    foreach ($SourceLogin in $SourceLogins) {
        
        # if source doesnt exist on destination, create it
        if ($SourceLogin.Name -notin $DestLogins.Name) {
            if ($WhatIf.IsPresent) { 
                Write-Output "WhatIf: Creating $($SourceLogin.Name) on $($DestServer.Name)."
            }
            else {
                try {
                    $DestLogin = New-Object Microsoft.SqlServer.Management.Smo.Login($DestServer, $SourceLogin.Name)
                    $DestLogin.LoginType = $SourceLogin.LoginType
                    $DestLogin.DefaultDatabase = $SourceLogin.DefaultDatabase
                    $DestLogin.Language = $SourceLogin.Language
                    
                    if ($SourceLogin.LoginType -eq 'SqlLogin') {
                        $HashedPassSql = "SELECT CAST(CONVERT(VARCHAR(256), CAST(LOGINPROPERTY(name,'PasswordHash') AS VARBINARY(256)), 1) AS NVARCHAR(max)) AS hashedpass FROM sys.server_principals WHERE principal_id = $($SourceLogin.id)"
                        $hashedPassDt = $SourceServer.Databases['master'].ExecuteWithResults($HashedPassSql)
                        $hashedPass = $hashedPassDt.Tables[0].Rows[0].Item(0)
                        
                        $DestLogin.Set_Sid($SourceLogin.Get_Sid())
                        $DestLogin.PasswordPolicyEnforced = $SourceLogin.PasswordPolicyEnforced
                        $DestLogin.PasswordExpirationEnabled = $SourceLogin.PasswordExpirationEnabled
                        $DestLogin.Create($hashedPass, [Microsoft.SqlServer.Management.Smo.LoginCreateOptions]::IsHashed)
                    }
                    else {
                        $DestLogin.Create()
                    }
                    Write-Output "Created $($SourceLogin.LoginType) $($SourceLogin.Name) on $($DestServer.Name)."
                }
                catch {
                    Write-Output "!Failed to create $($SourceLogin.Name) on $($DestServer.Name)."
                    $_.Exception.Message
                    continue
                }
            }
        }
        elseif ($SourceLogin.LoginType -eq 'SqlLogin') {
            if ($SyncPassword.IsPresent) {
                if ($WhatIf.IsPresent) { 
                    Write-Output "WhatIf: Syncing $($SourceLogin.Name) password to $($DestServer.Name)."
                }
                else {
                    try {
                        $HashedPassSql = "SELECT CAST(CONVERT(VARCHAR(256), CAST(LOGINPROPERTY(name,'PasswordHash') AS VARBINARY(256)), 1) AS NVARCHAR(max)) AS hashedpass FROM sys.server_principals WHERE principal_id = $($SourceLogin.id)"
                        $hashedPassDt = $SourceServer.Databases['master'].ExecuteWithResults($HashedPassSql)
                        $hashedPass = $hashedPassDt.Tables[0].Rows[0].Item(0)

                        $AlterSql = "ALTER LOGIN [$($SourceLogin.Name)] WITH CHECK_POLICY = OFF; ALTER LOGIN [$($SourceLogin.Name)] WITH PASSWORD = $hashedPass HASHED; ALTER LOGIN [$($SourceLogin.Name)] WITH CHECK_POLICY = ON"
                        $DestServer.ConnectionContext.ExecuteScalar($AlterSql)
                        Write-Output "Synced $($SourceLogin.Name) password to $($DestServer.Name)."
                    }
                    catch {
                        Write-Output "!Failed to update password for $($SourceLogin.Name) on $($DestServer.Name)."
                        $_.Exception.Message
                        continue
                    }
                }
            }
        }

        # gotta close because enum repeatedly causes problems with the datareader
        $null = $SourceServer.ConnectionContext.SqlConnectionObject.Close()
        $null = $DestServer.ConnectionContext.SqlConnectionObject.Close()

        # add permissions from source to destination
        foreach ($SourcePerm in $SourcePerms | Where-Object { $_.Grantee -eq $SourceLogin.Name }) {
            if ($WhatIf.IsPresent) { 
                Write-Output "WhatIf: $($SourcePerm.PermissionState) $($SourcePerm.PermissionType) to $($SourceLogin.Name) on $($DestServer.Name)."
            }
            else {
                try {
                    $SourcePermState = $SourcePerm.PermissionState

                    if ($SourcePermState -eq "GrantWithGrant") {
                        $GrantWithGrant = $true;
                        $SourcePermState = "grant"
                    }
                    else {
                        $grantWithGrant = $false
                    }

                    $PermSet = New-Object Microsoft.SqlServer.Management.Smo.ServerPermissionSet($SourcePerm.PermissionType)
                    $DestServer.PSObject.Methods[$SourcePermState].Invoke($PermSet, $SourceLogin.Name, $GrantWithGrant)
                    Write-Output "$($SourcePerm.PermissionState) $($SourcePerm.PermissionType) to $($SourceLogin.Name) on $($DestServer.Name)."
                }
                catch {
                    Write-Output "!Failed to $($SourcePerm.PermissionState) $($SourcePerm.PermissionType) to $($SourceLogin.Name) on $($DestServer.Name)."
                    $_.Exception.Message
                    continue
                }
            }

            # remove permissions from destination not on source
            if ($RevokePermissions.IsPresent) {
                foreach ($DestPerm in $DestPerms | Where-Object { $_.Grantee -eq $SourceLogin.Name }) {
                    $DestPermState = $DestPerm.PermissionState

                    # looks for a matching source perm and if not found revokes it
                    $SourcePerm = $SourcePerms | Where-Object { $_.PermissionType -eq $DestPerm.PermissionType -and $_.PermissionState -eq $DestPermState }

                    if ($null -eq $SourcePerm) {
                        if ($DestPermState -eq "GrantWithGrant") {
                            $GrantWithGrant = $true;
                            $DestPermState = "grant"
                        }
                        else {
                            $grantWithGrant = $false
                        }

                        if ($WhatIf.IsPresent) { 
                            Write-Output "WhatIf: Revoke $($DestPerm.PermissionType) from $($SourceLogin.Name) on $($DestServer.Name)."
                        }
                        else {
                            try {
                                $PermSet = New-Object Microsoft.SqlServer.Management.Smo.ServerPermissionSet($DestPerm.PermissionType)
                                $DestServer.PSObject.Methods['Revoke'].Invoke($PermSet, $SourceLogin.Name, $false, $GrantWithGrant)
                                Write-Output "Revoke $($DestPerm.PermissionType) from $($SourceLogin.Name) on $($DestServer.Name)."
                            }
                            catch {
                                Write-Output "!Failed to Revoke $($DestPerm.PermissionType) from $($SourceLogin.Name) on $($DestServer.Name)."
                                $_.Exception.Message
                                continue
                            }
                        }
                    }

                } # foreach dest permission
            } # if revoke permissions
        } # foreach source perm
    } # foreach source login

} # foreach destination

