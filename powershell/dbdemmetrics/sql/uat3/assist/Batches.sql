USE [DMS_FORCES_UAT3]
GO

	DECLARE @AsofDate DATE = CAST(GETDATE() -1 AS DATE) ;
	SELECT 'Report Running For AsofDate: ' ,Cast(@AsofDate  AS VARCHAR(30)) ;

----------------------------------------- BATCHES ------------------------------------------------------

	-- Number of Overpayment Notice Triggers 
	SELECT 
			'Number of Overpayment Notice Triggers' as 'Category' ,
			Count(NoticeError_INDC) AS 'Count'
	FROM	
			NoticeGenerator_T
	WHERE	
			NoticeID_Code in ('AR0100','AR0500','AR0510','AR0600','AR0700')
			AND RequestDay_DATE = @AsofDate

	-- Number of Accounting Notice Triggers
	UNION ALL

	SELECT 
			'Number of Collections Notice Triggers' as 'Category' ,
			Count(NoticeError_INDC) AS 'Count'
	FROM	
			NoticeGenerator_T
	WHERE	
			NoticeID_Code in ('AR1000','AR1100','AR2000','AR2100') 
			AND RequestDay_DATE = @AsofDate

	-- Number of Collections Notice Triggers
	UNION ALL

	SELECT 
			'Number of Accouting Notice Triggers' as 'Category' ,
			Count(NoticeError_INDC) AS 'Count'
	FROM	
			NoticeGenerator_T
	WHERE	
			NoticeID_Code in ('AR3000','AR3100','AR4000','AR5000','AR6000','AR8000','EB1000')
			AND RequestDay_DATE = @AsofDate

	-- Number of notices generated 
	UNION ALL

	SELECT 
			'Number of notices generated' as 'Category',
			Count (NoticeError_INDC) As 'Count'
	FROM	
			NoticeGenerator_T
	WHERE	NoticeError_INDC = 'N'
			AND	RequestDay_DATE = @AsofDate

	-- Number of Recoupment transactions posted
	SELECT 
			'Number of Recoupment transactions posted' as 'Category',
			Count (TransactionValue_AMNT) As 'Count'
	FROM	
			Transaction_T
	WHERE	
			TransactionDay_DATE = @AsOfDate
			AND PaymentMethod_CODE = 'RC'
			AND History_Code = '0'



