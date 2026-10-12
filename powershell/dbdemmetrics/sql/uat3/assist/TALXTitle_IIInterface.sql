USE db_DataServicesHub_UAT3
-- =============================================
-- TALX/Title II Interface Module
-- =============================================
BEGIN

	DECLARE @BeginDATETIME	DATETIME2 = CAST(DATEADD(d,-1,GETDATE()) AS DATE) --'previous day 00:00:00:000000';
	DECLARE @EndDATETIME	DATETIME2 = DATEADD(ns, - 100, DATEADD(s, 86400, @BeginDATETIME)) --'previous day 23:59:59:999999';
	
	select @BeginDATETIME
	-- ========== Query 2- Number of requests ==================--

	SELECT SUM(Requests) As 'TALX-TITLEII-ReqCount' 
	FROM 
		(SELECT	COUNT(1) AS Requests
		 FROM	(select DISTINCT IncomeVerificationResponse_IDNO from [dbo].[IncomeVerificationResponse_T]  with (nolock)
					WHERE OriginalRequestedDate_DTTM >= @BeginDATETIME and OriginalRequestedDate_DTTM <= @EndDATETIME
				) AS TALXNoOfRequests
		UNION
		SELECT	COUNT(1) AS Requests
		FROM	(SELECT DISTINCT SSAResponse_IDNO FROM [dbo].[SSAResponse_T] with (nolock)
				WHERE RequestTitleIIMonthlyIncomeVerification_INDC=1 
				AND OriginalRequestedDate >= @BeginDATETIME and OriginalRequestedDate <= @EndDATETIME
		  		) AS TITLEIINoOfRequests
		) R;

	-- ========== End Of Query - Number of requests =============--

END
USE DSS_WorkerWeb_UAT3
GO
BEGIN

	DECLARE @currentDATE DATE = CAST(DATEADD(d,-1,GETDATE()) AS DATE) --'previous day';

	-- ========== Query 1- Number of responses ==================--

	SELECT SUM(Response) As Numberofresponses 
	FROM 
		(SELECT	COUNT(1) AS Response
		 FROM	(SELECT DISTINCT AsOfDate_DATE,
						EmployeeSSN_NUMB
				 FROM	[INTERFACE].[DataExchangeTALXIncomeInformation_T] with (nolock)
				 WHERE	AsOfDate_DATE = @currentDATE
				) AS TALXNoOfRequestsResponses
		UNION
		SELECT	COUNT(1) AS Response
		FROM	(SELECT DISTINCT AsOfDate_DATE,
					ApplicantSSN_NUMB
				 FROM	[INTERFACE].[DataExchangeTitleIIResponse_T] with (nolock)
				 WHERE	AsOfDate_DATE = @currentDATE
		  		) AS TITLEIINoOfRequestsResponses
		) R;

	-- ========== End Of Query - Number of responses =============--

END






