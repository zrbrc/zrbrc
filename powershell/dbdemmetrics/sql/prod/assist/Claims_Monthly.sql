Use DSS_POC_PROD;
DECLARE @D1 DATE, @D2 DATE;
--@D1: ATTENDANCE MONTH (2015-09-01)
--@D1: ATTENDANCE MONTH (2015-10-01)

SET @D1 = CAST(DATEADD(M,-2,DATEADD(MM, DATEDIFF(M,0,GETDATE()), 0)) AS DATE);
SET @D2 = CAST(DATEADD(M,-1,DATEADD(MM, DATEDIFF(M,0,GETDATE()), 0)) AS DATE);


SELECT 'Report Running For @BeginDate: ' ,Cast(@D1  AS VARCHAR(30)) ;
SELECT 'Report Running For @EndDate: ' ,Cast(@D2  AS VARCHAR(30)) ;

SELECT CPF.AttendanceMonth_DATE AS 'Attendance Month', SUM(CPF.Line_AMNT) AS 'Amount Paid'
FROM ContractorPaymentFund_T CPF
INNER JOIN ContractorPayment_T CP
ON CPF.ContractorPayment_IDNO = CP.ContractorPayment_IDNO
WHERE CP.History_CODE = '0'
AND CP.[Status_CODE] = 'PD'
AND CP.[PaymentType_CODE] = 'CC'
AND CP.StarsPayment_IDNO IS NULL
AND CPF.[AttendanceMonth_DATE] IN (@D1, @D2)
GROUP BY CPF.AttendanceMonth_DATE
ORDER BY 'Attendance Month' ASC;
