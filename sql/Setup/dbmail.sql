USE master
GO
sp_CONFIGURE 'show advanced', 1
GO
RECONFIGURE
GO
sp_CONFIGURE 'Database Mail XPs', 1
GO
RECONFIGURE
GO 
EXEC msdb.dbo.sysmail_configure_sp 
     @parameter_name=N'AccountRetryAttempts', 
     @parameter_value=N'1', 
     @description=N'Number of retry attempts for a mail server'

EXEC msdb.dbo.sysmail_configure_sp 
     @parameter_name=N'AccountRetryDelay', 
     @parameter_value=N'60', 
     @description=N'Delay between each retry attempt to mail server'

EXEC msdb.dbo.sysmail_configure_sp 
     @parameter_name=N'DatabaseMailExeMinimumLifeTime', 
     @parameter_value=N'600', 
     @description=N'Minimum process lifetime in seconds'

EXEC msdb.dbo.sysmail_configure_sp 
     @parameter_name=N'DefaultAttachmentEncoding', 
     @parameter_value=N'MIME', 
     @description=N'Default attachment encoding'

EXEC msdb.dbo.sysmail_configure_sp 
     @parameter_name=N'LoggingLevel', 
     @parameter_value=N'2', 
     @description=N'Database Mail logging level: normal - 1, extended - 2 (default), verbose - 3'

EXEC msdb.dbo.sysmail_configure_sp 
     @parameter_name=N'MaxFileSize', 
     @parameter_value=N'1000000', 
     @description=N'Default maximum file size'

EXEC msdb.dbo.sysmail_configure_sp 
     @parameter_name=N'ProhibitedExtensions', 
     @parameter_value=N'exe,dll,vbs,js', @description=N'Extensions not allowed in outgoing mails'

EXEC msdb.dbo.sysmail_add_account_sp 
     @account_name=N'SQL_Alerts', 
     @description=N'', 
     @email_address=N'dept05SG_SQLAlerts@state.de.us', 
     @display_name=N'SQL_Alerts', 
     @replyto_address=N'dept05SG_SQLAlerts@state.de.us', 
     @mailserver_name=N'smtp.state.de.us', 
     @mailserver_type=N'SMTP', 
     @port=25, @username=N'', 
     @password=N'', 
     @use_default_credentials=0, 
     @enable_ssl=0

EXEC msdb.dbo.sysmail_add_profile_sp 
     @profile_name=N'SQL_Alerts'

EXEC msdb.dbo.sysmail_add_profileaccount_sp 
     @profile_name=N'SQL_Alerts', @account_name=N'SQL_Alerts', 
     @sequence_number=1

EXEC msdb.dbo.sysmail_add_principalprofile_sp 
     @principal_name=N'guest', @profile_name=N'SQL_Alerts', 
     @is_default=1

EXEC msdb.dbo.sp_add_operator @name=N'SQL_Alerts',
     @enabled=1,
     @weekday_pager_start_time=90000,
     @weekday_pager_end_time=180000,
     @saturday_pager_start_time=90000,
     @saturday_pager_end_time=180000,
     @sunday_pager_start_time=90000,
     @sunday_pager_end_time=180000,
     @pager_days=0,
     @email_address=N'dept05sg_SQLAlerts@state.de.us',
     @category_name=N'[Uncategorized]'