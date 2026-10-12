SELECT 
S.Servername, 
S.IP, 
S.Port, 
S.Instance, 
MAX(R.RunTime) AS LastRunTime 
FROM Servers AS S 
LEFT JOIN Runlog AS R ON R.ServerName = S.Servername 
WHERE History_CD = 0 AND S.Timestamp > DATEADD(DAY,-30,GETDATE()) -- if we havent seen it in 30 days, skip it
GROUP BY S.Servername, S.IP, S.Port, S.Instance 
HAVING (MAX(R.RunTime) < DATEADD(HOUR,-1,GETDATE()) OR MAX(R.RunTime) IS NULL) -- if its been updated in the last hour, skip it
ORDER BY S.Servername, S.Port
