USE [msdb]
GO

/****** Object:  Job [Send_Bad_Logon_Email]    Script Date: 12/1/2020 11:14:22 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 12/1/2020 11:14:22 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Send_Bad_Logon_Email', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job is trigged by an alert and thus has no schedule.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'domain\user.test', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Get Bad Logon and Send Email]    Script Date: 12/1/2020 11:14:22 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Get Bad Logon and Send Email', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'PowerShell', 
		@command=N'<#
.SYNOPSIS
    Sends an email with the latest logon error.
.DESCRIPTION
    This will get the latest event id 4625 from the windows security log, parse the details, 
    getting domain, username, and source and send an email to the DBA group.

    This script is installed as a SQL Agent job of Powershell type.

    A Sql alert needs to be created to trigger this for error number 17806.

    Names do not matter, just make sure the alert triggers the SSA job.
#>

$Output = Get-EventLog -LogName Security -InstanceId 4625 -Newest 1

if ($Output) {
    Write-Output "Found logon error, creating email ..."

    $Body = [PSCustomObject]@{
        Timestamp   = (Get-Date -Format ''yyyy/MM/dd HH:mm:ss'')
        Username    = $Output.ReplacementStrings[5]
        Domain      = $Output.ReplacementStrings[6]
        Source      = $Output.ReplacementStrings[13]
        SourceIP    = $Output.ReplacementStrings[14]
    }

    $Email = @{
        To         = ''deptdg_BaseTech_DBA@delaware.gov'' 
        From       = ''dept05sg_SQLAlerts@delaware.gov''
        Subject    = "SQL Server Alert System: ''Unknown user name or bad password.'' occurred on $env:COMPUTERNAME"
        Body       = $Body | ConvertTo-Html -Fragment -As List | Out-String
        Smtp       = ''smtp.state.de.us''
        BodyAsHtml = $true
    }

    Send-MailMessage @Email

    Write-Output "Email sent."
}', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

