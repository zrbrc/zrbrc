/****** Object:  Table [dbo].[LogonErrors_T]    Script Date: 6/12/2020 2:25:12 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LogonErrors_T]
(
    [RecordID] [int] NULL,
    [Id] [int] NULL,
    [TimeCreated] [datetime2](7) NULL,
    [LevelDisplayName] [nvarchar](100) NULL,
    [LogName] [nvarchar](100) NULL,
    [ProviderName] [nvarchar](100) NULL,
    [TaskDisplayName] [nvarchar](100) NULL,
    [MachineName] [nvarchar](100) NULL,
    [Username] [nvarchar](100) NULL,
    [Domain] [nvarchar](100) NULL,
    [Hostname] [nvarchar](100) NULL
)
GO

CREATE UNIQUE CLUSTERED INDEX [ClusteredIndex-EventCombo] ON [dbo].[LogonErrors_T]
(
     [RecordID] ASC,
     [MachineName] ASC,
     [LogName] ASC
) WITH (IGNORE_DUP_KEY = ON)
GO