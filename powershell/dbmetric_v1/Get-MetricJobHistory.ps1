<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
Set-Location $PSScriptRoot
. .\config\Config.ps1
. .\function\Functions.ps1

$logname = '.\log\Jobs_' + (Get-Date -Format 'yyyyMMdd_hhmmss') + '.txt'
Start-Transcript -Path $logname

if (Get-Module dbatools -ListAvailable) { 
    Import-Module dbatools
}
else {
    throw 'dbatools module not found.'
    exit
}
if (Get-Module SqlServer -ListAvailable) { 
    Import-Module SqlServer
}
else {
    throw 'SqlServer module not found.'
    exit
}

# test DBA target instance 
if (-not (Get-SqlInstance -ServerInstance $Instance)) {
    throw 'Cant connect to DBA instance.'
    exit
}

$RunlogDT = New-Object System.Data.DataTable
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([Int])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'RunTime', ([DateTime])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([String])))
$RunlogDT.Columns.Add((New-Object System.Data.DataColumn 'Metric', ([String])))

$JobsDT = New-Object System.Data.DataTable
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([Int])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'SqlInstance', ([string])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'JobName', ([String])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'JobId', ([String])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'InstanceId', ([Int])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'StartDate', ([DateTime])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'EndDate', ([DateTime])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'RunDuration', ([Int])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'Status', ([String])))
$JobsDT.Columns.Add((New-Object System.Data.DataColumn 'Message', ([String])))

"Start: {0}" -f (Get-Date -Format g)

# gets local subnet to determine if we should try to scan the target, if out of subnet we skip it later
[System.Net.IPAddress]$LocalSubnet = (Get-NetIpAddress | Where-Object { $_.IpAddress -eq $LocalIP }).PrefixLength | Get-SubnetMask

# gets the latest list of sql instances we created above.
$Query = "SELECT * FROM $ServerTable WHERE History_CD = 0 ORDER BY Servername"
$Servers = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $Query

# get runlog for metric
$Query = "SELECT MAX(RunTime) as LastRunTime, ServerName FROM $RunlogTable WHERE Metric = 'Jobs' GROUP BY ServerName"
$LastRun = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $Query

foreach ($Server in $Servers) {
    try {
        $JobsDT.Clear()

        # if subnet mask and domain dont match and the server details are older than 15 minutes, skip it
        if ( -not ((([System.Net.IPAddress]$LocalIP).Address -band $LocalSubnet.Address ) -eq 
                (([System.Net.IPAddress]$Server.IP).Address -band $LocalSubnet.Address) -and 
                $Server.Domain -eq $Domain -and
                $Server.Timestamp -gt (Get-Date).AddDays(-1) )) {
            "Skipping: {0} {1}" -f $Server.Servername, $Server.IP
            continue
        }
    
        if (-not ($StartTime = $LastRun | Where-Object { $_.ServerName -eq $Server.Servername } | Select-Object -ExpandProperty LastRunTime )) {
            $StartTime = (Get-Date).AddHours(-24)
        }

        "Sql Server: {0} Last Run: {1} UTC" -f $Server.Servername, $StartTime

        $Jobs = Get-DbaAgentJobHistory -SqlInstance "$($Server.Servername),$($Server.Port)" -StartDate $StartTime -EndDate $Now -ExcludeJobSteps -EnableException

        foreach ($Job in $Jobs) {
            $JobsRow = $JobsDT.NewRow()
            $JobsRow['SqlInstance'] = $Job.SqlInstance
            $JobsRow['JobName'] = $Job.JobName
            $JobsRow['JobId'] = $Job.JobID
            $JobsRow['InstanceId'] = $Job.InstanceID
            $JobsRow['StartDate'] = [DateTime]$Job.StartDate
            $JobsRow['EndDate'] = [DateTime]$Job.EndDate
            $JobsRow['RunDuration'] = [Int]$Job.RunDuration
            $JobsRow['Status'] = $Job.Status
            $JobsRow['Message'] = $Job.Message
            $JobsDT.Rows.Add($JobsRow)
        }

        $RunlogRow = $RunlogDT.NewRow()
        $RunlogRow['Runtime'] = $Now
        $RunlogRow['ServerName'] = $Server.Servername
        $RunlogRow['Metric'] = $JobsName
        $RunlogDT.Rows.Add($RunlogRow)

        if ($JobsDT.Rows.count -gt 0) {
            "Writing {0} new job records." -f $JobsDT.Rows.count
            Write-SqlTableData -InputData $JobsDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $JobsTable
        }
    }
    catch {
        $ErrorException = $_.Exception
        "`t`t {0} failed." -f $Server.Servername
        $ErrorException
        continue
    }
}

if ($RunlogDT.Rows.Count -gt 0) {
    Write-SqlTableData -InputData $RunlogDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $RunlogTable
}
"End:   {0}" -f (Get-Date -Format g)