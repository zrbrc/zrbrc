Use DSS_POC_PROD;
DECLARE @D1 DATE;
--@D1: YESTERDAY

SET @D1 = CAST(DATEADD(D,-1,DATEDIFF(D,0,GETDATE())) AS DATE);

	
SELECT 'Report Running For BeginDate: ' ,Cast(@D1  AS VARCHAR(30)) ;

SELECT AT.AttendanceMonth_DATE AS 'Attendance Month', COUNT(DISTINCT AT.Site_IDNO) AS '# of Sites'
FROM AttendanceTransaction_T AT
INNER JOIN AttendanceSubmission_T ATS
ON AT.AttendanceSubmission_IDNO = ATS.AttendanceSubmission_IDNO
WHERE ATS.History_CODE = '0'
AND ATS.LogicalDelete_INDC = '0'
AND AT.History_CODE = '0'
AND AT.LogicalDelete_INDC = '0'
AND CAST(ATS.AttendanceSubmission_DTTM AS DATE) = @D1
GROUP BY AT.AttendanceMonth_DATE
ORDER BY 'Attendance Month' ASC;
