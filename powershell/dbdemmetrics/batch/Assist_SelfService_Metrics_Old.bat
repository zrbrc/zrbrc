@echo off
@REM Create datetime stamp
FOR /f "tokens=2-4 delims=/ " %%a IN ('date /t') DO (SET temp_date=%%c%%a%%b)
FOR /f "tokens=1-2 delims=/:" %%a IN ('time /t') DO (SET temp_time=%%a%%b)
SET file_append=%temp_date%_%temp_time:~0,4%


  sqlcmd /S xx.xx.xx.xx /d DSS_ASSIST_PROD -E -Q "SELECT [ApplicationRegistration_NUMB],[Screening_NUMB],[Type_CODE],[Source_CODE],[Language_CODE],[Origin_CODE],[CreatorType_CODE]
      ,[Release_NUMB]
      ,[Status_CODE]
      ,[County_CODE]
      ,[Zip_CODE]
      ,[IsApplicationEsigned_FLAG]
      ,[RecommendedPool_IDN]
      ,[ActualPool_IDN]
      ,[ActualServiceCenter_CODE]
      ,[ActualArea_CODE]
      ,[Failure_CNT]
      ,[ApplicantUser_NAME]
      ,[Created_DTTM]
      ,[LastUpdated_DTTM]
      ,[Submitted_DTTM]
      ,[CaseLoad_NUMB]
      ,[IsContinueApplication_FLAG]
      ,[Worker_IDN]
      ,[IsEligiibilityDetermined]
  FROM [DSS_ASSIST_PROD].[dbo].[Application_T]
where Created_DTTM > DATEADD(hour,-2,getdate())" -o "d:\batch\ssis_executables\dss\Metrics_ASSIST_SelfService_%file_append%_log.csv"



pause