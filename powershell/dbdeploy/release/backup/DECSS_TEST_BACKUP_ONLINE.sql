-- run this on 'hostDCSSAG,15150' or primary replica.

USE [DCSE_DECSS_TEST]
GO
BACKUP DATABASE [DCSE_DECSS_TEST] TO  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSS_TEST.bak' WITH NOFORMAT, INIT,  NAME = N'DCSE_DECSS_TEST-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'DCSE_DECSS_TEST' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'DCSE_DECSS_TEST' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''DCSE_DECSS_TEST'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSS_TEST.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO

USE [DCSE_DECSSRPT_TEST]
GO
BACKUP DATABASE [DCSE_DECSSRPT_TEST] TO  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSRPT_TEST.bak' WITH NOFORMAT, INIT,  NAME = N'DCSE_DECSSRPT_TEST-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'DCSE_DECSSRPT_TEST' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'DCSE_DECSSRPT_TEST' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''DCSE_DECSSRPT_TEST'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSRPT_TEST.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO

USE [DCSE_DECSS_FEDCERT]
GO
BACKUP DATABASE [DCSE_DECSS_FEDCERT] TO  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSS_FEDCERT.bak' WITH NOFORMAT, INIT,  NAME = N'DCSE_DECSS_FEDCERT-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'DCSE_DECSS_FEDCERT' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'DCSE_DECSS_FEDCERT' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''DCSE_DECSS_FEDCERT'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSS_FEDCERT.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO

USE [DCSE_DECSSRPT_FEDCERT]
GO
BACKUP DATABASE [DCSE_DECSSRPT_FEDCERT] TO  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSRPT_FEDCERT.bak' WITH NOFORMAT, INIT,  NAME = N'DCSE_DECSSRPT_FEDCERT-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'DCSE_DECSSRPT_FEDCERT' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'DCSE_DECSSRPT_FEDCERT' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''DCSE_DECSSRPT_FEDCERT'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSRPT_FEDCERT.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO

USE [DCSE_DECSSTIMEWARP_TEST]
GO
BACKUP DATABASE [DCSE_DECSSTIMEWARP_TEST] TO  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSTIMEWARP_TEST.bak' WITH NOFORMAT, INIT,  NAME = N'DCSE_DECSSTIMEWARP_TEST-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'DCSE_DECSSTIMEWARP_TEST' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'DCSE_DECSSTIMEWARP_TEST' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''DCSE_DECSSTIMEWARP_TEST'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSTIMEWARP_TEST.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO

USE [DCSE_DECSSRPTTIMEWARP_TEST]
GO
BACKUP DATABASE [DCSE_DECSSRPTTIMEWARP_TEST] TO  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSRPTTIMEWARP_TEST.bak' WITH NOFORMAT, INIT,  NAME = N'DCSE_DECSSRPTTIMEWARP_TEST-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO
declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'DCSE_DECSSRPTTIMEWARP_TEST' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'DCSE_DECSSRPTTIMEWARP_TEST' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''DCSE_DECSSRPTTIMEWARP_TEST'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'\\deptBKDBTS01\tsdcssc2\DBA.BuildKit\Backups\DCSE_DECSSRPTTIMEWARP_TEST.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND
GO
