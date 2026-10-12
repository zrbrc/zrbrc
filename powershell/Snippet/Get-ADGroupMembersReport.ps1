$groups = @(
    'deptSG_TS_Elig_BTS_Admins',
    'deptsg_TS_Elig_BTS_AppUsers',
    'deptSG_TS_Elig_BTS_Operators',
    'deptSG_TS_Elig_BTS_IsoHost',
    'deptSG_ts_Elig_BTS_SSOAdmins'
)

$table = foreach ($group in $groups) {
    $members = Get-ADGroupMember $group
    foreach ($member in $members) {
        $user = Get-ADUser $member.SamAccountName -Properties *
        [PSCustomObject]@{
            Group         = $group
            Member        = $member.SamAccountName
            Enabled       = $user.Enabled
            CanonicalName = $user.CanonicalName
        }
    }
}
$table | Sort-Object Group, Member | Format-Table