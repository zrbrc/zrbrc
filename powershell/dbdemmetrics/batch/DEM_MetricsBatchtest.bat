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

echo q drive mapped

#sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\MonthlyRenewalLetters.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsMonthlyRenewalLetters_%file_append%_log.txt

sqlcmd -S hostmcidbc7l1,15150 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\MCI.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsMCI.sql_%file_append%_log.txt

pause

net use /delete q:
net use /delete x: