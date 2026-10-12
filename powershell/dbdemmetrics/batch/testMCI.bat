@echo on
net use /delete q:
net use /delete x:
echo q drive deleted

@REM Create datetime stamp
FOR /f "tokens=2-4 delims=/ " %%a IN ('date /t') DO (SET temp_date=%%c%%a%%b)
FOR /f "tokens=1-2 delims=/:" %%a IN ('time /t') DO (SET temp_time=%%a%%b)
SET file_append=%temp_date%_%temp_time:~0,4%
ECHO Enter ? for help

net use q: \\hostname1N1\M$
net use x: \\hostname2MCI\F$
sqlcmd -S hostmcidbc7l1,15150 -i x:\PR2014_2\Management\Scripts\DSS\WorkerWeb\Metrics\MCI.sql -o D:\Batch\SSIS_Executables\DSS\MetricsMCI.sql_%file_append%_log.txt