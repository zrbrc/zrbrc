Use DSS_POC_PROD;
DECLARE @D1 DATE;
--@D1: YESTERDAY

SET @D1 = CAST(DATEADD(D,-1,DATEDIFF(D,0,GETDATE())) AS DATE);

SELECT 'Report Running For BeginDate: ' ,Cast(@D1  AS VARCHAR(30)) ;

SELECT CPF.AttendanceMonth_DATE AS 'Attendance Month', F.FiscalYear_NUMB AS 'Year', F.FundDescription_TEXT, F.Fund_NUMB AS 'Fund Description', SUM(CPF.Line_AMNT) AS 'Sum Amount'
FROM ContractorPaymentFund_T CPF
INNER JOIN Fund_T F
ON CPF.Fund_IDNO = F.Fund_IDNO
INNER JOIN ContractorPayment_T CP
ON CPF.ContractorPayment_IDNO = CP.ContractorPayment_IDNO
WHERE CAST(CP.PaymentVoucher_DTTM AS DATE) = @D1
AND CP.Status_CODE = 'PD'
AND CP.History_CODE = '0'
AND CP.PaymentType_CODE = 'CC'
AND CP.StarsPayment_IDNO IS NULL
GROUP BY CPF.AttendanceMonth_DATE, F.FiscalYear_NUMB, F.FundDescription_TEXT, F.Fund_NUMB
ORDER BY 'Attendance Month' ASC;
