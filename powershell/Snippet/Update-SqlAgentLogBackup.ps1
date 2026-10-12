Start-Transcript

$path_to_set = "M:\Management\Backup"

$instances = @(
    'hostnamec2n1\SB2022_1'
)

foreach ($i in $instances) {

    $find = "SELECT sj.name, sjj.job_id, sjj.step_id, sjj.command FROM sysjobsteps sjj JOIN sysjobs sj on sj.job_id = sjj.job_id WHERE command LIKE 'EXECUTE%DatabaseBackup%BackupType%''LOG''%' AND step_name LIKE '%LOG%'"

    $jobs = Invoke-Sqlcmd -ServerInstance $i -Database 'msdb' -Query $find

    foreach ($j in $jobs) {
        $current_path = ($j.command | Select-String -Pattern "(@Directory.*?,)").Matches.Value
        $new_path = "@Directory = '$path_to_set',"
        
        $orig_command = $j.command.Replace("'", "''")
        $new_command = $j.command.Replace($current_path, $new_path).Replace("'", "''")
        
        $orig_sql = "EXEC msdb.dbo.sp_update_jobstep @job_id=N'$($j.job_id)', @step_id=$($j.step_id), `n@command=N'$orig_command'"
        $update_sql = "EXEC msdb.dbo.sp_update_jobstep @job_id=N'$($j.job_id)', @step_id=$($j.step_id), `n@command=N'$new_command'"
    
        "/* == {0} == {1} ===== */" -f $i, $j.name, $j.step_name
        "-- Original"
        $orig_sql

        "-- Updated"
        $update_sql

        # Invoke-Sqlcmd -ServerInstance $i -Database 'msdb' -Query $update_sql
    }
}

Stop-Transcript