USE [db_EIAM_PROD];
GO

-- =====================================================================
-- Author        : Sindhoor Hanumansetty
-- Create date   : 08/26/2016
-- UAT Runtime   : 00:00:00:017 
-- Description   : Gets the users count of the disable requests created
-- =====================================================================

select count(*) from [db_EIAM_PROD].[dbo].[UserRequestTracker_T] as a where convert(datetime,a.[FirstInserted_DTTM],101) >= (getdate()) and a.[RequestType_TEXT] = 'User Disable';