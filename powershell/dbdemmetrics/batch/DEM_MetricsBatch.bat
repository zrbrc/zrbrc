@echo on
net use /delete q:
echo q drive deleted

@REM Create datetime stamp
FOR /f "tokens=2-4 delims=/ " %%a IN ('date /t') DO (SET temp_date=%%c%%a%%b)
FOR /f "tokens=1-2 delims=/:" %%a IN ('time /t') DO (SET temp_time=%%a%%b)
SET file_append=%temp_date%_%temp_time:~0,4%
ECHO Enter ? for help

net use q: \\hostname1N1\M$

del q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\Metrics*.txt

echo q drive mapped

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\MonthlyRenewalLetters.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsMonthlyRenewalLetters_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\noOfTotalRequestsCreated_FullDetails.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsnoOfTotalRequestsCreated_FullDetails_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\TALXTitle_IIInterface.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsTALXTitle_IIInterface_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\VoiceSignatureMetrics.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsVoiceSignatureMetrics_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\FHModuleBusinessQueries.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsFHModuleBusinessQueries_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\ASSIST_WorkerWeb_ClientNotices.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsASSIST_WorkerWeb_ClientNotices_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\ASSIST_WorkerWeb_Eligibility_Confirmations.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsASSIST_WorkerWeb_Eligibility_Confirmations_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\ASSIST_WorkerWeb_ErrorLogs.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsASSIST_WorkerWeb_ErrorLogs_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\ASSIST_WorkerWebApplicationIntake.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsASSIST_WorkerWebApplicationIntake_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\ASSIST_WorkerWeb_BI_ET.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsASSIST_WorkerWeb_BI_ET_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\AssistMain-SDX-LIS-FFM.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsAssistMain-SDX-LIS-FFM_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\Accounting.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsAccounting_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\AutoCreateCase.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsAutoCreateCase_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\Batches.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsBatches_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\CCM_Business_Metrics.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsCCM_Business_Metrics_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\Collections.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsCollections_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\FORCES_YTDAccountReceivablesSelectQuery.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsFORCES_YTDAccountReceivablesSelectQuery_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\Investigations.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsInvestigations_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\Attendance_Daily.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsAttendance_Daily_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\Attendance_Monthly.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsAttendance_Monthly_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\Claims_Daily.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsClaims_Daily_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\Claims_Monthly.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsClaims_Monthly_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\Correspondence_Daily.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsCorrespondence_Daily_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\Correspondence_Monthly.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsCorrespondence_Monthly_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\Funds_Daily.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsFunds_Daily_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\Funds_Monthly.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsFunds_Monthly_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\Sites_Attendance_Daily.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsSites_Attendance_Daily_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\Sites_Attendance_Monthly.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsSites_Attendance_Monthly_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\FORCES_YTDAccountReceivablesSelectQuery.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsFORCES_YTDAccountReceivablesSelectQuery_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\ASSIST_WorkerWeb_Eligibility_Confirmations.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsASSIST_WorkerWeb_Eligibility_Confirmations.sql_%file_append%_log.txt

sqlcmd -S hostmcidbc7l1,15150 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\MCI.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsMCI.sql_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\NationalNewHire.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsNationalNewHire.sql_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\noOfUserEnableRequests_COUNT.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsnoOfUserEnableRequests_COUNT.sql_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\noOfUserEnableRequests_FullDetails.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsnoOfUserEnableRequests_FullDetails.sql_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\noOfUsersCreateRequests_COUNT.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsnoOfUsersCreateRequests_COUNT.sql_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\noOfUsersCreateRequests_FullDetails.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsnoOfUsersCreateRequests_FullDetails.sql_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\noOfUsersDisableRequests_COUNT.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsnoOfUsersDisableRequests_COUNT.sql_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\noOfUsersDisableRequests_FullDetails.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsnoOfUsersDisableRequests_FullDetails.sql_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\noOfUserTerminateRequests_COUNT.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsnoOfUserTerminateRequests_COUNT.sql_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\noOfUserTerminateRequests_FullDetails.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsnoOfUserTerminateRequests_FullDetails.sql_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\noOfUsertrasfersRequests_COUNT.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsnoOfUsertrasfersRequests_COUNT.sql_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\noOfUsertrasfersRequests_FullDetails.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsnoOfUsertrasfersRequests_FullDetails.sql_%file_append%_log.txt

sqlcmd -S hostname1N1\PR2016_1 -i q:\Management\Scripts\DSS\WorkerWeb\Metrics\WorkerPassiveRenewal.sql -o q:\Management\Scripts\DSS\WorkerWeb\Metrics\Logs\MetricsWorkerPassiveRenewal.sql_%file_append%_log.txt

