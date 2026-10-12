@echo off
@REM Create datetime stamp
FOR /f "tokens=2-4 delims=/ " %%a IN ('date /t') DO (SET temp_date=%%c%%a%%b)
FOR /f "tokens=1-2 delims=/:" %%a IN ('time /t') DO (SET temp_time=%%a%%b)
SET file_append=%temp_date%_%temp_time:~0,4%
ECHO Enter ? for help

net use /delete q:
#net use /delete x:
net use q: \\hostname1N1\M$
#net use x: \\hostname2MCI\M$

@echo off
"C:\Program Files\7-Zip\7Z" A D:\Batch\SSIS_Executables\DSS\MetricsLog.zip q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics*.txt








