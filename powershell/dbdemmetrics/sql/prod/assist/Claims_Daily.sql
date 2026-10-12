Use DSS_POC_PROD;
DECLARE @D1 DATE;
--@D1: YESTERDAY

SET @D1 = CAST(DATEADD(D,-1,DATEDIFF(D,0,GETDATE())) AS DATE);
SELECT 'Report Running For AsofDate: ' ,Cast(@D1  AS VARCHAR(30)) ;

SELECT CPF.AttendanceMonth_DATE AS 'Attendance Month', SUM(CPF.Line_AMNT) AS 'Amount Paid'
FROM ContractorPaymentFund_T CPF
INNER JOIN ContractorPayment_T CP
ON CPF.ContractorPayment_IDNO = CP.ContractorPayment_IDNO
WHERE CP.History_CODE = '0'
AND CP.[Status_CODE] = 'PD'
AND CP.[PaymentType_CODE] = 'CC'
AND CP.StarsPayment_IDNO IS NULL
AND CAST(CP.PaymentVoucher_DTTM AS DATE) = @D1
GROUP BY CPF.AttendanceMonth_DATE
ORDER BY 'Attendance Month' ASC;
