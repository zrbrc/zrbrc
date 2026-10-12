$server = Get-SqlInstance -ServerInstance 'hostname4n1\ts2016_1'

# enumerate server roles and members
$ServerRoles = $server.Roles
$roletable = foreach ($role in $ServerRoles) {
    foreach ($i in $role.EnumMemberNames() | Where-Object { $_ -notlike "NT*" }) {
        [PSCustomObject]@{
            Instance = $server.Name
            Role     = $role.name
            Login    = $i
        }
    }
}

# get windows groups, users, roles and permissions
$WindowGroups = $server.Logins | Where-Object { $_.LoginType -eq 'WindowsGroup' }
$grouptable = foreach ($group in $WindowGroups) {
    $perms = $server.EnumServerPermissions($group.Name)

    $users = Get-ADGroupMember $group.Name.Split('\')[1]
    foreach ($u in $users) {
        [PSCustomObject]@{
            Instance    = $server.Name
            Group       = $group.Name
            Login       = $u.SamAccountName
            ServerRoles = ($roletable | Where-Object { $_.Login -eq $group.Name } | Select-Object -ExpandProperty Role) -join ','
            Grants      = ($perms | Where-Object { $_.PermissionState -eq 'Grant' } | Select-Object -ExpandProperty PermissionType) -join ','
            Denys       = ($perms | Where-Object { $_.PermissionState -eq 'Deny' } | Select-Object -ExpandProperty PermissionType) -join ','
        }
    }
}
Write-Output "Windows Groups | Roles and Permissions"
$grouptable | Export-Excel -Path 'M:\Temp\WinGroups_hostname4n1-ts2016_1.xlsx'
# Invoke-Item 'E:\Temp\WindowsGroups.xlsx'