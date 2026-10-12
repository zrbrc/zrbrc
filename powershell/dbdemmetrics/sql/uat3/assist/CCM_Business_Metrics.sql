USE DSS_WorkerWeb_UAT3;

-- =============================================
-- Change Center Module
-- =============================================
BEGIN

	DECLARE @CurrentDATE	DATE = CAST(GETDATE() -1 AS DATE) --'current date';
	DECLARE @BeginDATETIME	DATETIME2 = CAST(GETDATE() -1  AS DATE) --'current Date 00:00:00:000000';
	DECLARE @EndDATETIME	DATETIME2 = DATEADD(ns, - 100, DATEADD(s, 86400, @BeginDATETIME)) --'current date 23:59:59:999999';

SELECT 'Report Running For BEGINDATE: ' ,Cast(@BeginDATETIME  AS VARCHAR(30)) ;
SELECT 'Report Running For ENDDATE: ' ,Cast(@EndDATETIME  AS VARCHAR(30)) ;

	-- ==========Query 1- Number of CR received by Phone ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrReceivedByPhone
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'T'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR received by Phone =============--

	-- ==========Query 2- Number of CR received by Mail ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrReceivedByEmail
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'M'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR received by Mail =============--

	-- ==========Query 3- Number of CR received by Fax ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrReceivedByFax
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'F'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR received by Fax =============--

	-- ==========Query 4- Number of CR received by Email ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrReceivedByEmail
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'E'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR received by Email =============-- 

	-- ==========Query 5- Number of CR received by Walk In ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrReceivedByWalkIn
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'W'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR received by Walk In =============-- 

	-- ==========Query 6- Number of CR received by Self Service ==================--

	SELECT	COUNT(1) CrReceivedBySS
	FROM	R3UXTC.AssistMain_T CrReceivedBySS
	WHERE	ApplicantType_CODE = 'C'
	AND		STATUS_Code IN ('51','52','53')
	AND		Submit_DATE >= @BeginDATETIME
	AND		Submit_DATE <= @EndDATETIME;

	-- ==========End Of Query - Number of CR received by Self Service =============-- 

	-- ==========Query 7- Number of CR Inprogress that were received by Phone ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrInProgressByPhone
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'T'
	AND		CRStatus_TEXT = 'I'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR Inprogress that were received by Phone =============--

	-- ==========Query 8- Number of CR Inprogress that were received by Mail ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrInprogressByMail
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'M'
	AND		CRStatus_TEXT = 'I'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR received by Mail =============--

	-- ==========Query 9- Number of CR Inprogress that were received by Fax ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrInProgressbyFax
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'F'
	AND		CRStatus_TEXT = 'I'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR Inprogress that were received by Fax =============--

	-- ==========Query 10- Number of CR Inprogress that were received by Email ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrInProgressByEmail
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'E'
	AND		CRStatus_TEXT = 'I'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR Inprogress that were received by Email =============-- 

	-- ==========Query 11- Number of CR Inprogress that were received by Walk In ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrInProgressByWalkIn
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'W'
	AND		CRStatus_TEXT = 'I'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR Inprogress that were received by Walk In =============-- 

	-- ==========Query 12- Number of CR Inprogress that were received by Self Service ==================--

	SELECT	COUNT(1) CrInProgressBySS
	FROM	R3UXTC.AssistMain_T CrReceivedBySS
	WHERE	ApplicantType_CODE = 'C'
	AND		STATUS_Code IN ('52')
	AND		Submit_DATE >= @BeginDATETIME
	AND		Submit_DATE <= @EndDATETIME;

	-- ==========End Of Query - Number of CR Inprogress that were received by Self Service =============-- 

	-- ==========Query 13- Number of CR Processed that were received by Phone ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrProcessedByPhone
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'T'
	AND		CRStatus_TEXT = 'P'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR Processed that were received by Phone =============--

	-- ==========Query 14- Number of CR Processed that were received by Mail ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrProcessedByEmail
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'M'
	AND		CRStatus_TEXT = 'P'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR received by Mail =============--

	-- ==========Query 15- Number of CR Processed that were received by Fax ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrProcessedByFax
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'F'
	AND		CRStatus_TEXT = 'P'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR Processed that were received by Fax =============--

	-- ==========Query 16- Number of CR Processed that were received by Email ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrProcessedByEmail
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'E'
	AND		CRStatus_TEXT = 'P'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR Processed that were received by Email =============-- 

	-- ==========Query 17- Number of CR Processed that were received by Walk In ==================--

	SELECT	COUNT(DISTINCT CR_NUMB) CrProcessedByWalkIn
	FROM	ChangeCenterDetail_T
	WHERE	Source_TEXT = 'W'
	AND		CRStatus_TEXT = 'P'
	AND		Created_DATE = @CurrentDATE;

	-- ==========End Of Query - Number of CR Processed that were received by Walk In =============-- 

	-- ==========Query 18- Number of CR Processed that were received by Self Service ==================--

	SELECT	COUNT(1) CrProcessedBySS
	FROM	R3UXTC.AssistMain_T CrReceivedBySS
	WHERE	ApplicantType_CODE = 'C'
	AND		STATUS_Code IN ('53')
	AND		Submit_DATE >= @BeginDATETIME
	AND		Submit_DATE <= @EndDATETIME;

	-- ==========End Of Query - Number of CR Processed that were received by Self Service =============-- 

END
GO
