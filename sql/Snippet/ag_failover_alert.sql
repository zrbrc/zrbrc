USE [msdb]
GO

/****** Object:  Alert [AG Role Change]    Script Date: 4/30/2021 2:40:36 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'AG Failover - Error 1480', 
		@message_id=1480, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=30, 
		@include_event_description_in=1, 
		@notification_message=N'Failover Detected!', 
		@event_description_keyword=N'"PRIMARY" to "RESOLVING"', 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'