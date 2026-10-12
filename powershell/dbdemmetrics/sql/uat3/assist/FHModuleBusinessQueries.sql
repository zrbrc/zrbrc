USE DSS_WorkerWeb_UAT3
-- =============================================
-- Fair Hearing Module
-- =============================================
BEGIN

	DECLARE @BeginDATETime	DATETIME2 = CAST(DATEADD(d,-1,GETDATE()) AS DATE) --'previous day 00:00:00:000000';
	DECLARE @EndDATETime	DATETIME2 = DATEADD(ns, - 100, DATEADD(s, 86400, @BeginDATETime)) --'previous day 23:59:59:999999';

	--==========Query 1- Number of FH Requests for Given Criteria ==================--
	
	SELECT	COUNT(1) AS FHRequestCOUNT
	FROM	[dbo].FHAndADHRequest_T with (nolock)
	WHERE	FirstInserted_DTTM >= @BeginDATETime
	AND		FirstInserted_DTTM <= @EndDATETime;

	--==========End Of Query - Number of FH Requests for Given Criteria =============--

	--==========Query 2- Number of FH Summary for Given Criteria ==================--
	
	SELECT Count(1) AS FHSummaryCount
	FROM [dbo].FHRequestDetail_T with (nolock)
	WHERE FirstInserted_DTTM >= @BeginDATETime
    AND FirstInserted_DTTM <= @EndDATETime


	--==========End Of Query - Number of FH Summary for Given Criteria =============--

	--==========Query 3- Number of FH Appointment for Given Criteria ==================--
	
	SELECT	COUNT(1) AS FHAppointmentCOUNT
	FROM	[dbo].FHAndADHAppointmentDetail_T with (nolock)
	WHERE	History_Code = '0'
	AND		FirstInserted_DTTM >= @BeginDATETime
	AND		FirstInserted_DTTM <= @EndDATETime;
	
	--==========End Of Query - Number of FH Appointment for Given Criteria =============--

END
GO
