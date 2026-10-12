USE [db_EIAM_UAT3];
GO

-- =====================================================================
-- Author        : Sindhoor Hanumansetty
-- Create date   : 08/26/2016
-- UAT Runtime   : 00:00:00:017 
-- Description   : Gets the users details of the enable requests created
-- =====================================================================

      select * from [db_EIAM_UAT3].[dbo].[UserRequestTracker_T] as a where convert(datetime,a.[FirstInserted_DTTM],101) >= (getdate()) and a.[RequestType_TEXT] = 'User Enable';
