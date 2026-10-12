@echo off
@REM Create datetime stamp
FOR /f "tokens=2-4 delims=/ " %%a IN ('date /t') DO (SET temp_date=%%c%%a%%b)
FOR /f "tokens=1-2 delims=/:" %%a IN ('time /t') DO (SET temp_time=%%a%%b)
SET file_append=%temp_date%_%temp_time:~0,4%
ECHO Enter ? for help

net use u: \\hostELIGDB01\G$
net use v: \\hostELIGDB02\K$



sqlcmd -S host001\PRDB1_2008 -i H:\PR2014_IS1\Management\Scripts\ASSIST_SelfService.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_ASSIST_SelfService_%file_append%_log.txt
pause
net use /delete u:
net use /delete v:
