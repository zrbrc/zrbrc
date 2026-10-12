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

$logname = '.\log\Blitz_' + (Get-Date -Format 'yyyyMMdd_hhmmss') + '.txt'
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

$BlitzDT = New-Object System.Data.DataTable
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([int])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'Runtime', ([DateTime])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([String])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'Priority', ([Int])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'FindingsGroup', ([String])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'Finding', ([String])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'DatabaseName', ([String])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'Details', ([String])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'QueryPlan', ([String])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'QueryPlanFiltered', ([String])))
$BlitzDT.Columns.Add((New-Object System.Data.DataColumn 'CheckID', ([Int])))

"Start: {0}" -f (Get-Date -Format g)

# gets local subnet to determine if we should try to scan the target, if out of subnet we skip it later
$LocalSubnet = (Get-NetIpAddress | Where-Object { $_.IpAddress -eq $LocalIP }).PrefixLength | Get-SubnetMask

# gets the latest list of sql instances we created above.
$Query = "SELECT * FROM $ServerTable WHERE History_CD = 0 ORDER BY Servername"
$Servers = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $Query

# get runlog for metric
$Query = "SELECT MAX(RunTime) as LastRunTime, ServerName FROM $RunlogTable WHERE Metric = 'Blitz' GROUP BY ServerName"
$LastRun = Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $Query

foreach ($Server in $Servers) {
    try {
        $BlitzDT.Clear()

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

        $Blitzes = Invoke-Sqlcmd -ServerInstance "$($Server.Servername),$($Server.Port)" -Database master -Query 'EXEC sp_Blitz'
        
        foreach ($Blitz in $Blitzes) {
            $BlitzRow = $BlitzDT.NewRow()
            $BlitzRow['Runtime'] = $now
            $BlitzRow['ServerName'] = $Server.Servername
            $BlitzRow['Priority'] = $Blitz.Priority
            $BlitzRow['FindingsGroup'] = $Blitz.FindingsGroup
            $BlitzRow['Finding'] = $Blitz.Finding
            $BlitzRow['DatabaseName'] = $Blitz.DatabaseName
            $BlitzRow['Details'] = $Blitz.Details
            $BlitzRow['QueryPlan'] = $Blitz.QueryPlan
            $BlitzRow['QueryPlanFiltered'] = $Blitz.QueryPlanFiltered
            $BlitzRow['CheckID'] = $Blitz.CheckID
            $BlitzDT.Rows.Add($BlitzRow)
        }

        $RunlogRow = $RunlogDT.NewRow()
        $RunlogRow['Runtime'] = $Now
        $RunlogRow['ServerName'] = $Server.Servername
        $RunlogRow['Metric'] = $JobsName
        $RunlogDT.Rows.Add($RunlogRow)

        if ($BlitzDT.Rows.count -gt 0) {
            "Writing {0} new blitz records." -f $BlitzDT.Rows.count
            Write-SqlTableData -InputData $BlitzDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $BlitzTable
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