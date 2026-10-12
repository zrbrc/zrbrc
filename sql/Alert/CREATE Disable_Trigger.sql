USE [msdb]
GO
 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE TRIGGER [dbo].[jobChecker]
ON sysjobs
FOR UPDATE AS
SET NOCOUNT ON
 
-- # DECLARE VARIABLES # --
 
DECLARE @username VARCHAR(50),
              @hostName VARCHAR(50),
              @jobName VARCHAR(100),
              @newEnabled INT,
              @oldEnabled INT,
              @jobCreated INT,
              @bodyText VARCHAR(200),
              @subjectText VARCHAR(200),
              @servername VARCHAR(50),
              @profileName VARCHAR(50) = 'SQL_Alerts',
              @recipients VARCHAR(500) = 'orlando.ramon@delaware.gov'
 
-- # SET VARIABLES # --
 
SELECT @username = SYSTEM_USER
SELECT @hostName = HOST_NAME()
SELECT @servername = @@servername
SELECT @newEnabled = ENABLED FROM Inserted
SELECT @oldEnabled = ENABLED FROM Deleted
SELECT @jobName = Name FROM Inserted
 
-- # CHECK FOR ENABLED/DISABLED # --
 
IF @newEnabled <> @oldEnabled
BEGIN
 
  IF @newEnabled = 1
  BEGIN
    SET @bodyText = 'The user (' + @username + ') enabled the job from ' + @hostName + ' on ' + CONVERT(VARCHAR(20),GETDATE(),100) + '.'
    SET @subjectText = @servername + ' : [' + @jobName + '] has been ENABLED'
  END
 
  IF @newEnabled = 0
  BEGIN
    SET @bodyText = 'The user (' + @username + ') disabled the job from ' + @hostName + ' on ' + CONVERT(VARCHAR(20),GETDATE(),100) + '.'
    SET @subjectText = @servername+' : [' + @jobName + '] has been DISABLED'
  END
 
  SET @subjectText = 'SQL Job on ' + @subjectText
 
-- # SEND EMAIL # --
 
  EXEC msdb.dbo.sp_send_dbmail
  @profile_name = @profileName,
  @recipients = @recipients,
  @body = @bodyText,
  @subject = @subjectText
 
END