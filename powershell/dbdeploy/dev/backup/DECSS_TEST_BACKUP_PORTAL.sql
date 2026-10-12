-- run this on 'hostDCSSCPAG,15150' or primary replica.

USE [DCSE_DECSSCPORTAL_TEST]
GO
BACKUP DATABASE [DCSE_DECSSCPORTAL_TEST] TO  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSCPORTAL_TEST.bak' WITH NOFORMAT, INIT,  NAME = N'DCSE_DECSSCPORTAL_TEST-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'DCSE_DECSSCPORTAL_TEST' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'DCSE_DECSSCPORTAL_TEST' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''DCSE_DECSSCPORTAL_TEST'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSCPORTAL_TEST.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO

USE [DCSE_DECSSEPORTAL_TEST]
GO
BACKUP DATABASE [DCSE_DECSSEPORTAL_TEST] TO  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSEPORTAL_TEST.bak' WITH NOFORMAT, INIT,  NAME = N'DCSE_DECSSEPORTAL_TEST-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'DCSE_DECSSEPORTAL_TEST' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'DCSE_DECSSEPORTAL_TEST' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''DCSE_DECSSEPORTAL_TEST'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSEPORTAL_TEST.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO

USE [DCSE_DECSSCPORTAL_TIMEWARP]
GO
BACKUP DATABASE [DCSE_DECSSCPORTAL_TIMEWARP] TO  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSCPORTAL_TIMEWARP.bak' WITH NOFORMAT, INIT,  NAME = N'DCSE_DECSSCPORTAL_TIMEWARP-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'DCSE_DECSSCPORTAL_TIMEWARP' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'DCSE_DECSSCPORTAL_TIMEWARP' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''DCSE_DECSSCPORTAL_TIMEWARP'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSCPORTAL_TIMEWARP.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO

USE [DCSE_DECSSEPORTAL_TIMEWARP]
GO
BACKUP DATABASE [DCSE_DECSSEPORTAL_TIMEWARP] TO  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSEPORTAL_TIMEWARP.bak' WITH NOFORMAT, INIT,  NAME = N'DCSE_DECSSEPORTAL_TIMEWARP-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'DCSE_DECSSEPORTAL_TIMEWARP' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'DCSE_DECSSEPORTAL_TIMEWARP' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''DCSE_DECSSEPORTAL_TIMEWARP'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSEPORTAL_TIMEWARP.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO
