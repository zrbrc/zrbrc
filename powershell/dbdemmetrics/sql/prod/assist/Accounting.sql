----------------------------------------- ACCOUNTING ------------------------------------------------------
USE [DMS_FORCES_PROD]
GO

	DECLARE @AsofDate DATE = CAST(GETDATE() -1 AS DATE);

		SELECT 'Report Running For AsofDate: ' ,Cast(@AsofDate  AS VARCHAR(30)) ;
--- Number of claims injected by program

	SELECT 
		Program_CODE as Program,
		COUNT (DISTINCT (Claim_NUMB)) AS 'Number of Claims Established by Program'
	FROM 
		Claim_T
	WHERE 
		ClaimCreation_DATE = @AsofDate
		AND History_Code = '0'
	GROUP BY 
		Program_CODE

	UNION ALL

--- Number of pending claims

	SELECT 
		'Number of Pending Claims' AS 'Category'  , 
		COUNT (DISTINCT (Claim_NUMB)) AS 'Count'
	FROM 
		Claim_T
	WHERE 
		Claimstatus_code = 'PE'
	AND ClaimCreation_DATE <= @AsofDate
	AND History_CODE = '0'

	UNION ALL

--- Number of adjustments made 

	SELECT 
		'Number of adjustments made' AS 'Category',
		Count (NoticeID_CODE) As 'Count'
	FROM 
		NoticeGenerator_T
	WHERE  
		NoticeID_CODE = 'AR6000'
		AND RequestDay_DATE = @AsOfDate

	UNION ALL

--Total number of daily transactions

	SELECT 
		'Number of Daily Transactions' AS 'Category',
		Count (TransactionValue_AMNT) As 'Count'
	FROM 
		Transaction_T
	WHERE 
		TransactionDay_DATE = @AsOfDate
		AND PaymentMethod_CODE <> 'RC'
		AND History_Code = '0'




