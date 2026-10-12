USE DSS_WorkerWeb_PROD
-- =============================================
-- Voice Signature Module
-- =============================================
BEGIN

	DECLARE @BeginDATETime	DATETIME2 = CAST(DATEADD(d,-1,GETDATE()) AS DATE) --'previous day 00:00:00:000000';
	DECLARE @EndDATETime	DATETIME2 = DATEADD(ns, - 100, DATEADD(s, 86400, @BeginDATETime)) --'previous day 23:59:59:999999';

	-- ==========Query 1- Number of Voice Signature ==================--

	SELECT	COUNT(1) NoOfVoiceSignatures 
	FROM	VoiceSignature_T with (nolock)
	WHERE	VoiceSignatureResponse_CODE = 'A' 
	AND		FirstInserted_DTTM  >= @BeginDATETime 
	AND		FirstInserted_DTTM  <= @EndDATETime;

	-- ==========End Of Query - Number of Voice Signature =============--

END
GO