Set-Location $PSScriptRoot

Start-Transcript .\log\Alert-DriveForecastExhaustion_log.txt -Append

Import-Module D:\Scripts\MSSQL\modules\SqlServer

$emailsplat = @{
    To         = 'dept05sg_SQLAlerts@delaware.gov'
    From       = 'dept05sg_SQLAlerts@delaware.gov'
    Subject    = "SQL Server Drive Exhaustion Report : $(Get-Date -Format 'yyyy-MM-dd')"
    BodyAsHtml = $true
    SmtpServer = 'smtp.state.de.us' 
}

$Head = @"
<title>Report</title>
<style>
body { background-color:#FFFFFF; font-family:Tahoma; font-size:10pt; }
td, th { border:1px solid black; border-collapse:collapse; }
th { color:white; background-color:black; }
table, tr, td, th { padding-left: 3px; padding-right: 7px; }
</style>
"@

$sql = @"
SELECT 
	CASE WHEN D.HostName LIKE 'host%' THEN 'PROD'
		 WHEN D.HostName LIKE 'host%' THEN 'TEST'
		 WHEN D.HostName LIKE 'host%' THEN 'PT'
		 ELSE 'OTHR'
	END AS Environment,
	D.HostName AS ServerName,
	D.IPAddress,
	PDLD.Name AS DriveLetter,
	FORMAT(Size/1024/1024, 'N0') AS SizeGB,
	FORMAT((FreeSpace * 1.0)/(Size * 1.0), 'P2') AS FreePercent,
	FORMAT(DATEADD(second, ForecastedExhaustionTimestamp * 5, '2000-01-01 00:00:00'), 'yyyy-MM-dd') AS Forecast
FROM
	PerformanceAnalysisDeviceLogicalDisk AS PDLD
	INNER JOIN Device AS D ON D.ID = PDLD.DeviceID
WHERE
	D.HeartbeatDateTime IS NOT NULL
	AND PDLD.Name NOT IN ('P:','T:','U:')
	AND PDLD.VolumeName NOT IN ('TempDB','TempDBLog')
    AND PDLD.ForecastedExhaustionTimestamp IS NOT NULL
	AND PDLD.ForecastedExhaustionTimestamp <> 50491105920 -- filters drives that dont have an exhaustion calculation
ORDER BY
	ServerName,
	DriveLetter
"@

try {

    $data = Invoke-Sqlcmd -ServerInstance 'hostnidbc1ls1,15150' -Database Sentry_Solarwinds_PROD -Query $sql -TrustServerCertificate

    $data | Format-Table @{Name = 'Date'; Expression={Get-Date -Format 'yyyy-MM-dd'}}, Environment, ServerName, IPAddress, DriveLetter, @{Name = 'SizeGB'; Alignment = 'Right'; Expression = { $_.SizeGb } }, @{Name = 'FreePercent'; Alignment = 'Right'; Expression = { $_.FreePercent } }, Forecast

    $exhausting = $data | Where-Object { [datetime]$_.Forecast -lt (Get-Date).AddDays(30) }

    if ($exhausting.count -gt 0) {

        $body = $exhausting | Select-Object * -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors | ConvertTo-Html -Head $head -PostContent "Executed on $env:COMPUTERNAME"| Out-String

        Send-MailMessage @emailsplat -Body $Body

    }
	else {
		"No email sent, nothing exhausting with-in 30 days."
	}
}
catch {
    $ErrorMessage = $_.Exception.Message
    throw $ErrorMessage
}


