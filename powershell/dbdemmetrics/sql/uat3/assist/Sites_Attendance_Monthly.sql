Use DSS_POC_UAT3;
DECLARE @D1 DATE, @D2 DATE;
--@D1: ATTENDANCE MONTH (2015-09-01)
--@D1: ATTENDANCE MONTH (2015-10-01)

SET @D1 = CAST(DATEADD(M,-2,DATEADD(MM, DATEDIFF(M,0,GETDATE()), 0)) AS DATE);
SET @D2 = CAST(DATEADD(M,-1,DATEADD(MM, DATEDIFF(M,0,GETDATE()), 0)) AS DATE);

SELECT 'Report Running For BeginDate: ' ,Cast(@D1  AS VARCHAR(30)) ;
SELECT 'Report Running For EndDate: ' ,Cast(@D2  AS VARCHAR(30)) ;


SELECT AT.AttendanceMonth_DATE AS 'Attendance Month', COUNT(DISTINCT AT.Site_IDNO) AS '# of Sites'
FROM AttendanceTransaction_T AT
WHERE AT.History_CODE = '0'
AND AT.LogicalDelete_INDC = '0'
AND AT.AttendanceMonth_DATE IN (@D1, @D2)
GROUP BY AT.AttendanceMonth_DATE
ORDER BY 'Attendance Month' ASC;
