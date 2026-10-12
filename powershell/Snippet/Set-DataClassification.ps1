# proof/demo

$iconn = Get-SqlInstance -ServerInstance 'xx.xx.xx.xx,15150'

$tables = $iconn.Databases['DSS_WorkerWeb_SBX'].Tables

$columns = foreach ($t in $tables) {
    $database = $T.Parent.Name
    $schema = $t.Schema
    $table = $t.Name
    foreach ($c in $t.Columns) {
        $column = $c.Name

        [PSCustomObject]@{
            Database = $database
            Schema = $schema
            Table = $table
            Column = $column
            Full = $schema + '.' + $table + '.' + $column
        }
    }
}

$SsnColumns = ($columns | Where-Object {$_.Column -like "*SSN*NUMB"}).Full


Get-SqlSensitivityRecommendations -ServerInstance 'xx.xx.xx.xx,15150' -Database 'DSS_WorkerWeb_SBX'

Set-SqlSensitivityClassification -ServerInstance 'xx.xx.xx.xx,15150' -Database 'DSS_WorkerWeb_SBX' -ColumnName 'R3UXTC.AliasSSN_T.SSN_NUMB' -InformationType 'SSN' -SensitivityLabel 'Confidential'

