@echo off
@REM Create datetime stamp
FOR /f "tokens=2-4 delims=/ " %%a IN ('date /t') DO (SET temp_date=%%c%%a%%b)
FOR /f "tokens=1-2 delims=/:" %%a IN ('time /t') DO (SET temp_time=%%a%%b)
SET file_append=%temp_date%_%temp_time:~0,4%
ECHO Enter ? for help


del d:\batch\ssis_executables\dss\Metrics_ASSIST_SelfServiceLog.zip

@echo off
"C:\Program Files\7-Zip\7Z" A D:\Batch\SSIS_Executables\DSS\Metrics_ASSIST_SelfServiceLog.zip U:\PR2014_4\Management\Scripts\Metrics\BusinessMetrics\Logs\Metrics_ASSIST_SelfService*log.txt


