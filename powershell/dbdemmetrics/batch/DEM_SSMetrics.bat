@echo off
@REM Create datetime stamp
FOR /f "tokens=2-4 delims=/ " %%a IN ('date /t') DO (SET temp_date=%%c%%a%%b)
FOR /f "tokens=1-2 delims=/:" %%a IN ('time /t') DO (SET temp_time=%%a%%b)
SET file_append=%temp_date%_%temp_time:~0,4%


net use u: \\hostname4N1\M$

sqlcmd -S hostname4N1\PR2014_4 -i u:\PR2014_4\Management\Scripts\MCI\BusinessMetrics\ASSIST_SelfService.sql  -o u:\PR2014_4\Management\Scripts\MCI\BusinessMetrics\\Metrics_ASSIST_SelfService_%file_append%_log.csv
