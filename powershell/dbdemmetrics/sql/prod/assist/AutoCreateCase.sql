USE DSS_WorkerWeb_PROD;
-- =============================================
-- Auto Create Case Module
-- =============================================
BEGIN
       --Variables
       DECLARE @RUNBEGINDATE                    DATETIME2 = CAST(DATEADD(d,-1,GETDATE()) AS DATE) --'previous day 00:00:00:000000';
       DECLARE @RUNENDDATE                      DATETIME2 = DATEADD(ns, - 100, DATEADD(s, 86400, @RUNBEGINDATE)) --'previous day 23:59:59:999999';
       DECLARE @NEWAPPLICATION                  VARCHAR(1) = 'W';
       DECLARE @FFMAPPLICATION                  VARCHAR(1) = 'M';
       DECLARE @MAREQUESTED                     VARCHAR(1) = 'Y';
       DECLARE @ISAUTOCASE                      BIT = 1;
       DECLARE @AUTOCASECREATEDSTATUS           VARCHAR(2) = '90';
       DECLARE @FFMPROCESSEDSTATUS              VARCHAR(2) = '63';
       DECLARE @AUTOCASEOPEN                    VARCHAR(2) = '16';
       DECLARE @MAGICOMBOCASE                   VARCHAR(2) = '72';
       DECLARE @FFMAUTOCASEOPEN                 VARCHAR(2) = '64';



       -- ========== Query 1- Number of SS MA dom received ==================--

       SELECT COUNT(DISTINCT b.Assist_NUMB) AS NoOfAutoCaseMAdomReceived
       FROM          R3UXTC.AssistProgramDetails_T     a with (nolock)
       INNER JOIN    R3UXTC.AssistMain_T               b with (nolock) ON  a.Assist_NUMB = b.Assist_NUMB
       WHERE		 b.ApplicantType_CODE = @NEWAPPLICATION
       AND           a.MedicalAssistanceNewRequest_INDC = @MAREQUESTED
       AND           (b.Submit_DATE >= @RUNBEGINDATE AND b.Submit_DATE <= @RUNENDDATE);

       -- ========== End Of Query - Number of SS MA dom received =============--

       -- ========== Query 2- Number of SS MA dom automated ==================--

       SELECT COUNT(DISTINCT b.Assist_NUMB) AS NoOfAutoCaseMAdomAutomated
       FROM          R3UXTC.AssistProgramDetails_T     a with (nolock)
       INNER JOIN    R3UXTC.AssistMain_T               b with (nolock)  ON  a.Assist_NUMB = b.Assist_NUMB
       WHERE		 b.ApplicantType_CODE = @NEWAPPLICATION
       AND           b.Status_CODE IN (@AUTOCASECREATEDSTATUS ,@AUTOCASEOPEN ,@MAGICOMBOCASE)
       AND           b.CaseAutoCreated_INDC = @ISAUTOCASE
       AND           a.MedicalAssistanceNewRequest_INDC = @MAREQUESTED
       AND           (b.Submit_DATE >= @RUNBEGINDATE   AND b.Submit_DATE <= @RUNENDDATE);

       -- ========== End Of Query - Number of SS MA dom automated =============--

       -- ========== Query 3- Number of FFM MA dom received ==================--
       SELECT COUNT(DISTINCT b.Assist_NUMB) AS NoOfAutoCaseFFMMAdomReceived
       FROM          R3UXTC.AssistProgramDetails_T     a with (nolock)
       INNER JOIN    R3UXTC.AssistMain_T               b with (nolock)    ON  a.Assist_NUMB = b.Assist_NUMB
       WHERE		 b.ApplicantType_CODE = @FFMAPPLICATION
       AND           a.MedicalAssistanceNewRequest_INDC = @MAREQUESTED
       AND           (b.Submit_DATE >= @RUNBEGINDATE   AND b.Submit_DATE <= @RUNENDDATE);

       -- ========== End Of Query - Number of FFM MA dom received =============--

       -- ========== Query 4- Number of FFM MA dom automated ==================--
       SELECT COUNT(DISTINCT b.Assist_NUMB) AS NoOfAutoCaseFFMMAdomAutomated
       FROM          R3UXTC.AssistProgramDetails_T     a with (nolock)
       INNER JOIN    R3UXTC.AssistMain_T               b with (nolock)     ON  a.Assist_NUMB = b.Assist_NUMB
       WHERE		 b.ApplicantType_CODE = @FFMAPPLICATION
       AND           b.Status_CODE IN (@FFMPROCESSEDSTATUS,@FFMAUTOCASEOPEN)
       AND           b.CaseAutoCreated_INDC = @ISAUTOCASE
       AND           a.MedicalAssistanceNewRequest_INDC = @MAREQUESTED
       AND           (b.Submit_DATE >= @RUNBEGINDATE   AND b.Submit_DATE <= @RUNENDDATE);
       -- ========== End Of Query - Number of FFM MA dom automated =============--

END
GO

