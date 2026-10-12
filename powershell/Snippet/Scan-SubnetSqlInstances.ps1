$instances = [System.Data.Sql.SqlDataSourceEnumerator]::Instance.GetDataSources() | Where-Object { $_.ServerName -like '*DB*' } | ForEach-Object {
    [PSCustomObject]@{
        Server    = $_.ServerName
        Instance  = $_.InstanceName
        IsCluster = $_.IsClustered
        Version   = $_.Version
    }
}
$instances

