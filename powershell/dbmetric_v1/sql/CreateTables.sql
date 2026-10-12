USE [DBA]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Audits_T](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RecordTime] [datetime2](7) NOT NULL,
	[AuditLog] [nvarchar](100) NOT NULL,
	[event_time] [datetime2](7) NOT NULL,
	[sequence_number] [int] NOT NULL,
	[action_id] [nvarchar](100) NOT NULL,
	[succeeded] [int] NULL,
	[is_column_permission] [int] NULL,
	[session_id] [int] NULL,
	[server_principal_id] [int] NULL,
	[database_principal_id] [int] NULL,
	[target_server_principal_id] [int] NULL,
	[target_database_principal_id] [int] NULL,
	[object_id] [int] NULL,
	[class_type] [nvarchar](max) NULL,
	[session_server_principal_name] [nvarchar](max) NULL,
	[server_principal_name] [nvarchar](max) NULL,
	[server_principal_sid] [nvarchar](max) NULL,
	[database_principal_name] [nvarchar](max) NULL,
	[target_server_principal_name] [nvarchar](max) NULL,
	[target_server_principal_sid] [nvarchar](max) NULL,
	[target_database_principal_name] [nvarchar](max) NULL,
	[server_instance_name] [nvarchar](100) NULL,
	[database_name] [nvarchar](100) NULL,
	[schema_name] [nvarchar](100) NULL,
	[object_name] [nvarchar](100) NULL,
	[statement] [nvarchar](max) NULL,
	[file_name] [nvarchar](255) NULL,
	[audit_file_offset] [bigint] NULL,
	[user_defined_event_id] [int] NULL,
	[user_defined_information] [nvarchar](100) NULL,
	[audit_schema_version] [int] NULL,
	[sequence_group_id] [nvarchar](100) NOT NULL,
	[transaction_id] [bigint] NOT NULL
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [NCIX_ServerInstanceName_SequneceGrouId_TransactionId] ON [dbo].[Audits_T]
(
	[server_instance_name] ASC,
	[sequence_group_id] ASC,
	[transaction_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = ON, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE TABLE [dbo].[BackupHistory_T](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RunTimeStamp] [datetime2](7) NULL,
	[SqlInstance] [char](50) NULL,
	[Database] [char](50) NULL,
	[Start] [datetime2](7) NULL,
	[End] [datetime2](7) NULL,
	[Duration] [char](50) NULL,
	[FilePath] [char](255) NULL,
	[BackupSizeGB] [decimal](7, 2) NULL,
	[CompressedBackupSizeGB] [decimal](7, 2) NULL,
	[CompressionRatio] [decimal](7, 2) NULL,
	[Type] [char](50) NULL,
	[BackupSetId] [int] NULL,
	[IsCopyOnly] [char](50) NULL
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_BackupHistory_T] ON [dbo].[BackupHistory_T]
(
	[BackupSetId] ASC,
	[SqlInstance] ASC,
	[Database] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = ON, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Blitz_T](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Runtime] [smalldatetime] NOT NULL,
	[ServerName] [nvarchar](100) NOT NULL,
	[Priority] [tinyint] NULL,
	[FindingsGroup] [nvarchar](max) NULL,
	[Finding] [nvarchar](max) NULL,
	[DatabaseName] [nvarchar](max) NULL,
	[Details] [nvarchar](max) NULL,
	[QueryPlan] [nvarchar](max) NULL,
	[QueryPlanFiltered] [nvarchar](max) NULL,
	[CheckID] [int] NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[DriveStats_T](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RunTimeStamp] [datetime2](7) NOT NULL,
	-- [ServerID] [int] NOT NULL,
	[ServerName] [nvarchar](50) NOT NULL,
	[ServerIp] [nvarchar](50) NOT NULL,
	[DriveLetter] [nvarchar](50) NOT NULL,
	[DriveLabel] [nvarchar](50) NULL,
	[SizeGB] [decimal](7, 2) NOT NULL,
	[FreeGB] [decimal](7, 2) NOT NULL,
	[FreePercent] [decimal](5, 2) NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Jobs_T](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SqlInstance] [char](100) NOT NULL,
	[JobName] [char](100) NOT NULL,
	[JobId] [char](100) NOT NULL,
	[InstanceId] [int] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[RunDuration] [int] NOT NULL,
	[Status] [char](100) NOT NULL,
	[Message] [nvarchar](max) NOT NULL
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [SqlInstance_JobID_InstanceID] ON [dbo].[Jobs_T]
(
	[SqlInstance] ASC,
	[JobId] ASC,
	[InstanceId] ASC
) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = ON, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE TABLE [dbo].[LogonErrors_T](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RecordTime] [datetime2](7) NOT NULL,
	[EventId] [int] NOT NULL,
	[LogName] [nvarchar](100) NOT NULL,
	[ServerHostname] [nvarchar](100) NOT NULL,
	[Username] [nvarchar](100) NOT NULL,
	[Domain] [nvarchar](100) NOT NULL,
	[SourceHostname] [nvarchar](100) NOT NULL,
	[EventRecordID] [int] NOT NULL,
	[EventType] [nvarchar](max) NOT NULL,
	[EventTime] [datetime2](7) NOT NULL
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_LogName_ServerHostname_EventRecordID_EventTime] ON [dbo].[LogonErrors_T]
(
	[LogName] ASC,
	[ServerHostname] ASC,
	[EventRecordID] ASC,
	[EventTime] ASC
) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = ON, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Servers_T](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Hostname] [nvarchar](100) NOT NULL,
	[IPv4Address] [nvarchar](100) NOT NULL,
	[Domain] [nvarchar](100) NOT NULL,
	[DMZ] [nvarchar](100) NOT NULL,
	[SqlServerPort] [int] NULL,
	[Type] [smallint] NULL,
	[Comment] [nvarchar](100) NULL,
 CONSTRAINT [PK_Servers_T] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


