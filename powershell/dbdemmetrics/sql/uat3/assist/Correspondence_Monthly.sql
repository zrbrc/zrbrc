Use DSS_POC_UAT3;
DECLARE @D1 DATE, @D2 DATE;

--@D1: 1ST DAY OF CURRENT MONTH
--@D2: YESTERDAY

SET @D1 = CAST(DATEADD(M,0,DATEADD(MM, DATEDIFF(M,0,GETDATE()), 0)) AS DATE);
SET @D2 = CAST(DATEADD(D,-1,DATEDIFF(D,0,GETDATE())) AS DATE);



SELECT 'Report Running For BeginDate: ' ,Cast(@D1  AS VARCHAR(30)) ;
SELECT 'Report Running For EndDate: ' ,Cast(@D2  AS VARCHAR(30)) ;

SELECT 
CASE 
WHEN CorrespondenceType_CODE = 'CCLTPR410' THEN 'Withholding Letter' 
WHEN CorrespondenceType_CODE = 'CCLTPR409' THEN 'Site Connected to a Contractor'
WHEN CorrespondenceType_CODE = 'CCLTPR407' THEN 'Private Rate Information'
WHEN CorrespondenceType_CODE = 'CCLTPR408' THEN 'Direct Deposit Account Information'
WHEN CorrespondenceType_CODE = 'CCNCCL215' THEN 'Contractor and Site Statement'
WHEN CorrespondenceType_CODE = 'CCNCCL218' THEN 'Direct Deposit Contractors'
WHEN CorrespondenceType_CODE = 'CCNCCL213' THEN 'Child Care Expense Report'
WHEN CorrespondenceType_CODE = 'CCNCAT104' THEN 'Daily Attendance'
WHEN CorrespondenceType_CODE = 'CCNCAT103' THEN 'Summary Attendance'
WHEN CorrespondenceType_CODE = 'CCNCST503' THEN 'Stars Tiered Reimbursement Statement'
END AS CorrespondenceType, 
COUNT(DISTINCT Request_NUMB) NumberGenerated
FROM CorrespondenceTrigger_T
WHERE Status_INDC <> 'S'
AND CAST(Generated_DTTM AS DATE) BETWEEN @D1 AND @D2
GROUP BY CorrespondenceType_CODE;
