Set-Location $PSScriptRoot

$start = Get-Date

if (-not (Test-Path -Path '.\temp')) { New-Item '.\temp' -ItemType Directory } else { Remove-Item -Path '.\temp\*.*' }

$data = @()

$zips = Get-ChildItem '.\DHSPRD\*.zip' #-Filter '*IDMZ2_PROD_DECSS_BAT_CLS1*'

foreach ($zip in $zips) {

    Expand-Archive -Path $zip.FullName -DestinationPath '.\temp'

    $xmlfiles = Get-ChildItem -Path ".\temp\*.xml"
    
    foreach ($file in $xmlfiles) {

        $node = $zip.Name.TrimEnd('_backup.zip')
        "{0} {1}" -f $node, $file.FullName

        [xml]$xml = Get-Content -Path $file.FullName

        $mus = ($xml.'object-stream'.'com.orsyp.ExportObjects'.mus.'com.orsyp.ExportMu'.mu | Where-Object { $_.nodeName -eq $node }).identifier.Name

        $tasks = $xml.'object-stream'.'com.orsyp.ExportObjects'.tasks.Task | Where-Object { $_.Identifier.muName -in $mus -and $_.active -eq $true }

        foreach ($task in $tasks) {

            foreach ($launch in $task.specificData.implicitData.'com.orsyp.api.task.TaskImplicitData') {
                try {
                    $row = [PSCustomObject]@{
                        Node      = $node
                        Area      = $file.Name.Split('.')[0].Split('_')[1].ToUpper()
                        TaskName  = $task.identifier.Name
                        TaskLabel = $task.Label
                        MU        = $task.identifier.muName
                        Schedule  = $launch.identifier.name
                    }

                    if ($null -ne $task.specificData.launchHourPatterns.'com.orsyp.api.task.LaunchHourPattern'.frequency) {
                        if ($task.specificData.launchHourPatterns.'com.orsyp.api.task.LaunchHourPattern'.frequency -ne '0') {
                            $row | Add-Member -MemberType NoteProperty -Name StartTime -Value ("Every {0} mins" -f $task.specificData.launchHourPatterns.'com.orsyp.api.task.LaunchHourPattern'.frequency) 
                        }
                        else {
                            $row | Add-Member -MemberType NoteProperty -Name StartTime -Value ("{0}:{1}" -f $task.specificData.launchHourPatterns.'com.orsyp.api.task.LaunchHourPattern'.StartTime.Substring(0, 2), $task.specificData.launchHourPatterns.'com.orsyp.api.task.LaunchHourPattern'.StartTime.Substring(2, 2))
                        }
                    }
                    elseif ($null -ne $launch.embeddedLaunchTime.launchTime) {
                        $row | Add-Member -MemberType NoteProperty -Name StartTime -Value ("{0}:{1}" -f $launch.embeddedLaunchTime.launchTime.Substring(0, 2), $launch.embeddedLaunchTime.launchTime.Substring(2, 2))
                    }
                    else {
                        $row | Add-Member -MemberType NoteProperty -Name StartTime -Value 'NONE'
                    }

                    $data += $row
                }
                catch {
                    "FAILED: $($task.Identifier.Name)"
                    continue
                }
            }
        }
        "Running Total: {0}" -f $data.Count
    }
    Remove-Item -Path ".\temp\*.*"
}

Invoke-Sqlcmd -ServerInstance 'xx.xx.xx.xx,15150' -Database 'db_DollarUniverse_SBX' -Query 'TRUNCATE TABLE Objects'
$data | Write-SqlTableData -ServerInstance 'xx.xx.xx.xx,15150' -DatabaseName 'db_DollarUniverse_SBX' -SchemaName 'dbo' -TableName 'Objects' -Force

"Elapsed Time: {0:n2} s" -f (New-TimeSpan -Start $start -End (Get-Date)).TotalSeconds