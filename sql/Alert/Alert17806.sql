USE [msdb]
GO

/****** Object:  Alert [Bad Logon Alert]    Script Date: 12/1/2020 11:13:05 AM ******/
EXEC msdb.dbo.sp_add_alert @name=N'Bad Logon Alert', 
		@message_id=17806, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=0, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'edaafcea-860d-41a9-84bf-3587b77fef5c'
GO

