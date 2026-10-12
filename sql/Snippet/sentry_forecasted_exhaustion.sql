USE Sentry_Solarwinds_PROD

SELECT 
	CASE WHEN D.HostName LIKE 'host%'
	          THEN 'PROD'
		 WHEN D.HostName LIKE 'host%'
		      THEN 'TEST'
		 WHEN D.HostName LIKE 'host%'
		      THEN 'PT'
		 ELSE 'OTHR'
	END AS Environment,
	D.HostName AS ServerName,
	D.IPAddress,
	PDLD.Name AS DriveLetter,
	FORMAT(Size/1024/1024, 'N2') AS Size,
	FORMAT((FreeSpace * 1.0)/(Size * 1.0), 'P') AS FreePercent,
	FORMAT(DATEADD(second, ForecastedExhaustionTimestamp * 5, '2000-01-01 00:00:00'), 'yyyy-MM-dd') AS ForecastedExhaustion
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
	Environment,
	ServerName,
	DriveLetter