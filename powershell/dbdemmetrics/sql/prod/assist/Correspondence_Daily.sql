Use DSS_POC_PROD;
DECLARE @D1 DATE;
--@D1: YESTERDAY

SET @D1 = CAST(DATEADD(D,-1,DATEDIFF(D,0,GETDATE())) AS DATE);

SELECT 'Report Running For AsofDate: ' ,Cast(@D1  AS VARCHAR(30)) ;

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
AND CAST(Generated_DTTM AS DATE) = @D1
GROUP BY CorrespondenceType_CODE;
