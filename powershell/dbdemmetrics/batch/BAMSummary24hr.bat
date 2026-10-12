@echo off
@REM Create datetime stamp
FOR /f "tokens=2-4 delims=/ " %%a IN ('date /t') DO (SET temp_date=%%c%%a%%b)
FOR /f "tokens=1-2 delims=/:" %%a IN ('time /t') DO (SET temp_time=%%a%%b)
SET file_append=%temp_date%_%temp_time:~0,4%



sqlcmd /S PRDBCLS2DB01\PR2014_2 /d BAMPrimaryImport -v Durationhrs = 24 -E -Q "SELECT [ApplicationName],[SDSHServiceName],[SDSHOperationName],AVG(DATEDIFF( MILLISECOND, [SDSHStartTime] ,[SDSHEndTime])) AS Average,MIN(DATEDIFF( MILLISECOND, [SDSHStartTime] ,[SDSHEndTime])) AS Minimum,MAX(DATEDIFF( MILLISECOND, [SDSHStartTime] ,[SDSHEndTime])) AS Maximum,COUNT(*)  AS Requests,COUNT([Notes])  AS Errors,COUNT([Notes])*100/COUNT(*)AS ErrorPercentage FROM [BAMPrimaryImport].[dbo].[bam_SDSHTracking_Active]WHERE [SDSHStartTime] BETWEEN DATEADD(HOUR, -$(Durationhrs), getutcdate()) AND getutcdate() GROUP BY [ApplicationName],[SDSHServiceName],[SDSHOperationName];SELECT COUNT(*) AS MedicaidRequests, [VerificationCode]AS VerificationCode, [OrganizationCode] AS OrganizationCode FROM [BAMPrimaryImport].dbo.bam_NonEsiMecMedicaid_Active WHERE [SDSHStartTime] BETWEEN DATEADD(HOUR, -$(Durationhrs), getutcdate()) AND getutcdate()  GROUP BY [ApplicationName],[VerificationCode],[OrganizationCode]" -o "BAMSummary_%file_append%.csv" -s","


COPY "BAMSummary_%file_append%.csv" "BAMSummary24hr_PROD.csv"
Move "BAMSummary_%file_append%.csv" "D:\Batch\SSIS_IO\DSS\OutputArchive"