@echo off
@REM Create datetime stamp
FOR /f "tokens=2-4 delims=/ " %%a IN ('date /t') DO (SET temp_date=%%c%%a%%b)
FOR /f "tokens=1-2 delims=/:" %%a IN ('time /t') DO (SET temp_time=%%a%%b)
SET file_append=%temp_date%_%temp_time:~0,4%
ECHO Enter ? for help

net use u: \\hostELIGDB01\S$
net use v: \\hostELIGDB02\K$

sqlcmd -S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\ASSIST_WorkerWeb_ErrorLogs.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_ASSIST_WorkerWeb_ErrorLogs_log.txt

sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\ASSIST_WorkerWeb_ClientNotices.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_ASSIST_WorkerWeb_ClientNotices_%file_append%_log.txt
               
sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\ASSIST_WorkerWeb_Eligibility_Confirmations.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_ASSIST_WorkerWeb_Eligibility_Confirmations_%file_append%_log.txt
							
sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\ASSIST_WorkerWebApplicationIntake.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_ASSIST_WorkerWebApplicationIntake_%file_append%_log.txt				
				
sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\ASSIST_WorkerWeb_BI_ET.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_ASSIST_WorkerWeb_BI_ET_%file_append%_log.txt				
				
sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\AssistMain-SDX-LIS-FFM.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_AssistMain-SDX-LIS-FFM_%file_append%_log.txt				
				
sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\Accounting.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_Accounting_%file_append%_log.txt				
				
sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\Batches.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_Batches_%file_append%_log.txt				
	
sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\Collections.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_Collections_%file_append%_log.txt

sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\FORCES_YTDAccountReceivablesSelectQuery.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_FORCES_YTDAccountReceivablesSelectQuery_%file_append%_log.txt

sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\Investigations.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_Investigations_%file_append%_log.txt

sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\Attendance_Daily.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_Attendance_Daily_%file_append%_log.txt

sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\Attendance_Monthly.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_Attendance_Monthly_%file_append%_log.txt

sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\Claims_Daily.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_Claims_Daily_%file_append%_log.txt

sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\Claims_Monthly.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_Claims_Monthly_%file_append%_log.txt

sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\Correspondence_Daily.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_Correspondence_Daily_%file_append%_log.txt

sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\Correspondence_Monthly.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_Correspondence_Monthly_%file_append%_log.txt

sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\Funds_Daily.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_Funds_Daily_%file_append%_log.txt

sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\Funds_Monthly.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_Funds_Monthly_%file_append%_log.txt

sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\Sites_Attendance_Daily.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_Sites_Attendance_Daily_%file_append%_log.txt

sqlcmd /S hostELIGDB01\PR2012_1 -i U:\Management\Scripts\DSS\WorkerWeb\Metrics\Sites_Attendance_Monthly.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_Sites_Attendance_Monthly_%file_append%_log.txt

sqlcmd -S hostELIGDB02\PR2012_2 -i V:\Management\Scripts\MCI\BusinessMetrics\MCI.sql -o U:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics_MCI_%file_append%_log.txt



