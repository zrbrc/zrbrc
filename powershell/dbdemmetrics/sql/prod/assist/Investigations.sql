USE [DMS_FORCES_PROD];
GO
----------------------------------------- INVESTIGATIONS------------------------------------------------------

	DECLARE @AsofDate DATE = CAST(GETDATE() -1 AS DATE)
	DECLARE @BeginDate DATE = CASE
			WHEN @AsofDate > '2015-11-30' 
			THEN CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(@AsofDate)-1),@AsofDate),101)
			ELSE '2015-11-12'
			END
	DECLARE @EndDate DATE = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,@AsofDate))),DATEADD(mm,1,@AsofDate)),101)

	
SELECT 'Report Running For BeginDate: ' ,Cast(@AsofDate  AS VARCHAR(30)) ;

-- Number of cases created by error  category (Cases created by Source and Type)

	SELECT 
		CaseSource_CODE as 'Source',
		Count (Distinct (CA.ARMSCase_NUMB)) As 'Count of Cases Created'
	FROM 
		Case_T CA
	WHERE 
		CONVERT (DATE,CA.FirstInserted_DTTM,101) BETWEEN @BeginDate AND @EndDate
	GROUP BY 
		CaseSource_CODE

	SELECT 
		CaseType_CODE as 'Type',
		Count (Distinct (CA.ARMSCase_NUMB)) As 'Count of Cases Created'
	FROM 
		Case_T CA
	WHERE 
		CONVERT (DATE,CA.FirstInserted_DTTM,101) BETWEEN @BeginDate AND @EndDate
	GROUP BY 
		CaseType_CODE

--Number of cases completed by error category  (Cases Completed by overpayment Recommendation)

	SELECT 
		RIGHT (Outcome_CODE,3) as 'Error Category',
		Count (Distinct (CA.ARMSCase_NUMB)) As 'Count of Cases Closed'
	FROM 
		Case_T CA 
		INNER JOIN Recommendation_T RT
	ON 
		CA.Case_IDNO = RT.Case_IDNO
	WHERE 
		RT.Outcome_CODE LIKE 'OO%'
		AND CONVERT (DATE,CA.CaseClosed_DTTM,101) BETWEEN @BeginDate AND @EndDate
	GROUP BY 
		Outcome_CODE

--Number of case Injections by program (with reason for injection)  -- Cases inject by DOL

	SELECT 
		'Count of Cases Injected' as Description,
		Count (Distinct (CA.ARMSCase_NUMB)) as Record_Count
	FROM 
		Case_T CA 
	WHERE 
		CONVERT (DATE,CA.FirstInserted_DTTM,101) BETWEEN @BeginDate AND @EndDate
		AND CA.CaseType_Code = 'TYDOL'
