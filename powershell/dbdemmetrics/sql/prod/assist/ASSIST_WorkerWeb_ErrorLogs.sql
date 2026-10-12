Use DSS_WorkerWeb_Log;

SET QUOTED_IDENTIFIER ON

DECLARE @INPUTSTARTDATE DATETIME = cast(getdate() -1 as date);
DECLARE @INPUTENDDATE DATETIME;

SET @INPUTSTARTDATE = DATEADD(HOUR, 11, @INPUTSTARTDATE);
SET @INPUTENDDATE = DATEADD(Hour, 14, @INPUTSTARTDATE);


--SELECT 'Report Running For @INPUTSTARTDATE: ' ,Cast(@INPUTSTARTDATE  AS VARCHAR(30));
--SELECT 'Report Running For @INPUTENDDATE: ' ,Cast(@INPUTENDDATE  AS VARCHAR(30));
SELECT --top 10  
              [TransactionId]
              ,[ApplicationId]
              ,[UserName]
              ,[MachineName]
              ,[Category]
              ,CAST([Message] as XML).value('(/MessageException/@ResourceUri)[1]','nvarchar(max)') AS 'URL'
              ,LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(CAST([Message] as XML).value('(/MessageException/Exception/Message)[1]','nvarchar(max)'))), CHAR(9), ' '), CHAR(10), ' '), CHAR(11), ' '), CHAR(12), ' '), CHAR(13), ' '))) AS 'ErrorMessage'
              ,LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(CAST([Message] as XML).value('(/MessageException/Exception/InnerException/Exception/Message)[1]','nvarchar(max)'))), CHAR(9), ' '), CHAR(10), ' '), CHAR(11), ' '), CHAR(12), ' '), CHAR(13), ' '))) AS 'InnerErrorMessage1'
              ,LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(CAST([Message] as XML).value('(/MessageException/Exception/InnerException/Exception/InnerException/Exception/Message)[1]','nvarchar(max)'))), CHAR(9), ' '), CHAR(10), ' '), CHAR(11), ' '), CHAR(12), ' '), CHAR(13), ' '))) AS 'InnerErrorMessage2'
              ,LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(CAST([Message] as XML).value('(/MessageException/Exception/InnerException/Exception/InnerException/Exception/InnerException/Exception/Message)[1]','nvarchar(max)'))), CHAR(9), ' '), CHAR(10), ' '), CHAR(11), ' '), CHAR(12), ' '), CHAR(13), ' '))) AS 'InnerErrorMessage3'
              ,[Timestamp]
FROM   [dbo].[Log_T] WITH(NOLOCK)
WHERE  [Category] IN ('Exception', 'Error')
 AND           [Timestamp] BETWEEN @INPUTSTARTDATE AND @INPUTENDDATE  -- based on time 
--AND         [Message] LIKE '%Timeout%'  ---check only timeout 
--AND         [ApplicationId] = 146641    ---check specific application id 
AND           CAST([Message] as XML).exist('(/MessageException/@ResourceUri)[1]') = 1;
