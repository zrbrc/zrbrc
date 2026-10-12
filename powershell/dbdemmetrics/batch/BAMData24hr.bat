@echo off
@REM Create datetime stamp
FOR /f "tokens=2-4 delims=/ " %%a IN ('date /t') DO (SET temp_date=%%c%%a%%b)
FOR /f "tokens=1-2 delims=/:" %%a IN ('time /t') DO (SET temp_time=%%a%%b)
SET file_append=%temp_date%_%temp_time:~0,4%
ECHO Enter ? for help


                sqlcmd /S PRDBCLS2DB01\PR2014_2 /d BAMPrimaryImport -v Durationhrs = 24 -E -Q "SELECT [ApplicationName],[SDSHServiceName],[SDSHOperationName],CASE WHEN [Notes] IS NULL THEN '' ELSE LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Notes, CHAR(9), ' '), CHAR(10), ' '), CHAR(11), ' '), CHAR(12), ' '), CHAR(13), ' '),',',' '))) END AS Notes,[SDSHStartTime] AS StartTime,[SDSHEndTime] AS EndTime,DATEDIFF(SECOND,[SDSHStartTime] ,[SDSHEndTime]) AS Duration FROM [bam_SDSHTracking_Active] WHERE [SDSHStartTime] BETWEEN DATEADD(HOUR, -$(Durationhrs), getutcdate()) AND getutcdate() ORDER BY [SDSHStartTime] DESC" -o "BizTalkBAMTracking_%file_append%.csv" -s","
               

COPY "BizTalkBAMTracking_%file_append%.csv" "BAMData24hr_PROD.csv"
Move "BizTalkBAMTracking_%file_append%.csv" "D:\Batch\SSIS_IO\DSS\OutputArchive"