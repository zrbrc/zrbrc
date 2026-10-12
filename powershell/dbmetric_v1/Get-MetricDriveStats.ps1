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

$logname = '.\log\DriveStats_' + (Get-Date -Format 'yyyyMMdd_hhmmss') + '.txt'
Start-Transcript -Path $logname

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

$DrivesDT = New-Object System.Data.DataTable
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([int])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'RunTimeStamp', ([DateTime])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([string])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'ServerIp', ([string])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'DriveLetter', ([string])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'DriveLabel', ([string])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'SizeGB', ([decimal])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'FreeGB', ([decimal])))
$DrivesDT.Columns.Add((New-Object System.Data.DataColumn 'FreePercent', ([decimal])))

"Start: {0}" -f (Get-Date -Format g)

# gets local subnet to determine if we should try to scan the target, if out of subnet we skip it later
$LocalSubnet = (Get-NetIpAddress | Where-Object { $_.IpAddress -eq $LocalIP }).PrefixLength | Get-SubnetMask

# gets the latest list of sql instances we created above.
$Query = "SELECT DISTINCT Servername, IP, Domain, Timestamp FROM $ServerTable WHERE History_CD = 0 ORDER BY Servername"
$Servers = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $Query

# get runlog for metric
$Query = "SELECT MAX(RunTime) as LastRunTime, ServerName FROM $RunlogTable WHERE Metric = 'Drive' GROUP BY ServerName"
$LastRun = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $Query
$Now = Get-Date

foreach ($Server in $Servers) {
    try {
        $DrivesDT.Clear()

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
        $Drives = Get-CimInstance -Class CIM_LogicalDisk -ComputerName $Server.Servername | Where-Object { $_.DriveType -eq '3' }
        
        foreach ($Drive in $Drives) {
            $DrivesRow = $DrivesDT.NewRow()
            $DrivesRow['RunTimeStamp'] = $Now
            $DrivesRow['ServerName'] = $Server.Servername
            $DrivesRow['ServerIp'] = $Server.IP
            $DrivesRow['DriveLetter'] = ($Drive.DeviceId -replace ':', '')
            $DrivesRow['DriveLabel'] = $Drive.VolumeName
            $DrivesRow['SizeGB'] = [math]::Round(($Drive.Size / 1024 / 1024 / 1024), 2)
            $DrivesRow['FreeGB'] = [math]::Round(($Drive.FreeSpace / 1024 / 1024 / 1024), 2)
            $DrivesRow['FreePercent'] = [math]::Round((($Drive.FreeSpace / $Drive.Size) * 100), 2)
            $DrivesDT.Rows.Add($DrivesRow)
        }

        $RunlogRow = $RunlogDT.NewRow()
        $RunlogRow['Runtime'] = $Now
        $RunlogRow['ServerName'] = $Server.Servername
        $RunlogRow['Metric'] = $DriveStatsName
        $RunlogDT.Rows.Add($RunlogRow)

        if ($DrivesDT.Rows.count -gt 0) {
            "Writing {0} new drive stats records." -f $DrivesDT.Rows.count
            Write-SqlTableData -InputData $DrivesDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $DriveStatsTable
        }
    }
    catch {
        $ErrorException = $_.Exception
        "`t`t {0} Blitz execution failed." -f $Server.Servername
        $ErrorException
        continue
    }
}

if ($RunlogDT.Rows.Count -gt 0) {
    Write-SqlTableData -InputData $RunlogDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $RunlogTable
}
"End:   {0}" -f (Get-Date -Format g)