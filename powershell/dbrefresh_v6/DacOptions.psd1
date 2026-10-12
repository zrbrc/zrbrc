<#
    Default DeployOptions applied to every dacpac publish.
    Per-database options and variables from the dacpac .config files are applied on top of these.
#>
@{
    BlockOnPossibleDataLoss     = $false
    DropObjectsNotInSource      = $false
    DropPermissionsNotInSource  = $false
    DropRoleMembersNotInSource  = $false
    DoNotAlterReplicatedObjects = $false
    DoNotDropObjectTypes        = @('Permissions', 'RoleMembership', 'Users', 'Logins', 'LinkedServers', 'ServerRoleMembership', 'DatabaseRoles', 'ServerRoles', 'FileTables', 'Filegroups', 'Sequences')
    ExcludeObjectTypes          = @('FileTables')
    IgnoreNotForReplication     = $true
    IgnorePermissions           = $true
    IgnoreQuotedIdentifiers     = $true
    IgnoreRoleMembership        = $true
    IgnoreUserSettingsObjects   = $true
    GenerateSmartDefaults       = $true
    ScriptRefreshModule         = $true
    IncludeTransactionalScripts = $true
    CreateNewDatabase           = $false
    ScriptDatabaseOptions       = $false
    UnmodifiableObjectWarnings  = $false
}
