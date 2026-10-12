USE [DMS_FORCES_UAT3];
GO

	DECLARE @AsofDate DATE = CAST(GETDATE() -1 AS DATE);

	SELECT 'Report Running For AsofDate: ' ,Cast(@AsofDate  AS VARCHAR(30)) ;
	
	--- Food benefit collection by error category 
	
	DECLARE @BeginDate DATE = CASE
			WHEN @AsofDate > '2015-11-30' 
			THEN CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(@AsofDate)-1),@AsofDate),101)
			ELSE '2015-11-12'
			END
	DECLARE @EndDate DATE = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,@AsofDate))),DATEADD(mm,1,@AsofDate)),101);

	SELECT 
		CL.ErrorType_CODE,
		SUM(CASE
			WHEN CP.PaymentReversal_INDC = 'N' 
			THEN CP.Payment_AMNT
			WHEN CP.PaymentReversal_INDC = 'Y'
			THEN CP.Payment_AMNT*-1 
			END) AS 'AMOUNT' 

	FROM 
		Claimpayment_T CP 
		INNER JOIN Claim_T CL
	ON 
		CP.Claim_IDNO = CL.Claim_IDNO
	WHERE
		PaymentDay_Date BETWEEN @BeginDate AND @EndDate
		AND CP.History_CODE = '0'
		AND CL.History_CODE = '0'
		AND CL.Program_CODE = 'FS'
	GROUP BY 
		CL.ErrorType_CODE
	ORDER BY 
		CL.ErrorType_CODE;
