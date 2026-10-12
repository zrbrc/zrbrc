USE DSS_WORKERWEB_UAT3;

DECLARE @BeginDate date = cast(getdate() -1 as date);
DECLARE @RUNDATE  date= cast(getdate() -1 as date);

--select DATEADD(DD, 0, CAST (@BeginDate AS DATE))

SELECT 'Report Running For @BeginDate: ' ,Cast(@BeginDate  AS VARCHAR(30)) ;
SELECT 'Report Running For @RUNDATE: ' ,Cast(@RUNDATE  AS VARCHAR(30)) ;

select  convert(Varchar,@BeginDate);

SELECT Count(1) as 'Number of BI daily triggers for Food- Disbursed'   FROM BenefitIssuanceFoodBenefitsDisbursement_T 
where  CAST (FirstInserted_DTTM AS DATE) =@BeginDate;

SELECT Count(1) as 'Number of BI daily triggers for Cash- Disbursed'   FROM [dbo].[BenefitIssuanceCashDisbursement_T] 
where  CAST (FirstInserted_DTTM AS DATE) =@BeginDate;

--SELECT COUNT(1) AS '[NUMBER OF CHILD CARE AUTHORIZATIONS]' FROM ChildCareAuthorization_T 
--WHERE CAST (Posted_Date AS DATE) = cast(getdate() -1 as date)
--Modified query to get only valid authorizations
SELECT COUNT(1) AS '[NUMBER OF CHILD CARE AUTHORIZATIONS]' FROM ChildCareAuthorization_T 
WHERE CAST (Posted_Date AS DATE) = @BeginDate and AuthorizationEffective_DATE <= AuthorizationExpiration_DATE;


-- E&T
-- NUMBER OF E&T REFERRALS GENERATED A DAY BEFORE TODAY DATE
SELECT COUNT(1) AS '[NUMBER OF E&T REFERRALS GENERATED A DAY BEFORE TODAY DATE]' FROM Participant_T 
WHERE CAST (FirstInserted_DTTM AS DATE) = @RUNDATE;

-- E&T REFERRALS BY VENDOR A DAY BEFORE TODAY DATE
SELECT VENDOR_CODE, COUNT(1) AS '[E&T REFERRALS BY VENDOR A DAY BEFORE TODAY DATE]' FROM Participant_T
 WHERE CAST (FirstInserted_DTTM AS DATE) = @RUNDATE GROUP BY VENDOR_CODE;


