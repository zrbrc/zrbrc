$sql = "SELECT sj.name, sjs.step_name, sjs.command FROM msdb..sysjobs AS sj JOIN msdb..sysjobsteps AS sjs ON sj.job_id = sjs.job_id WHERE sj.enabled = 1 AND sjs.command LIKE 'EXEC%DatabaseBackup%'"

$data = Invoke-Sqlcmd -ServerInstance 'xx.xx.xx.xx,15150' -Query $sql

$table  = foreach ($row in $data) {

    $ht = @{}

    foreach ($i in $row.command.Split('@') | Where-Object {$_ -notlike "EXEC*"}){
        $key, $value = $i.Split('=')
        $key = $key.Trim()
        $value = $value.Trim().Trim(",")
        $ht.Add($key, $value)
    }
    
    [PSCustomObject]@{
        NameStep = $row.name + '\' + $row.step_name
        CleanupTime = $ht['CleanupTime']
        LogToTable = $ht['LogToTable'].Trim("'")
        Databases = $ht['Databases'].Trim("'")
    }
}

$table | ft
