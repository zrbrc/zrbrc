USE DSS_WORKERWEB_UAT3;

DECLARE @BeginDate date = cast(getdate() -1 as date);
DECLARE @EndDate   date = cast(getdate()-1 as date);

SELECT 'Report Running For @BeginDate: ' ,Cast(@BeginDate  AS VARCHAR(30)) ;
SELECT 'Report Running For @EndDate: ' ,Cast(@EndDate  AS VARCHAR(30)) ;

/*
DECLARE @LastSavedBeginDateTime DATETIME =CONVERT(DATETIME, CONVERT(DATE, GETDATE()-3)) + '06:00';
DECLARE @LastSavedEndDateTime DATETIME =CONVERT(DATETIME, CONVERT(DATE, GETDATE()-2)) + '09:00';
*/


Print 'Report between '+ Convert(varchar(10),@BeginDate) +' And' +Convert(varchar(10),@EndDate) ;


SELECT Count(1) as '[NUMBER OF Notices GENERATED]'  FROM [NOTICES].[ClientNoticeTriggersHistory_T] WHERE NoticeLetter_TEXT LIKE 'N%' 
AND Requested_Date between @BeginDate AND @EndDate;

SELECT COUNT(1) AS '[NUMBER OF LETTERS GENERATED]' FROM [NOTICES].[ClientNoticeTriggersHistory_T] WHERE NoticeLetter_TEXT LIKE 'L%' --AND TriggerMode_INDC = 'B' 
AND Requested_Date between @BeginDate AND @EndDate ;
