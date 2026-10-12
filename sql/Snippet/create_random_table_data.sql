USE [master]
GO

IF db_id(N'dates_db') IS NULL
BEGIN
	CREATE DATABASE [dates_db]
	PRINT ('Created dates_db')
END
GO

USE [dates_db]
GO

SET ANSI_PADDING ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dates]') AND type in (N'U'))
CREATE TABLE dbo.dates
(
	id INT IDENTITY(1,1),
	date1 DATETIME NOT NULL,
	date2 DATETIME NOT NULL,
	date3 DATETIME NOT NULL,
	date4 DATETIME NOT NULL,
	date5 DATETIME NOT NULL

)
GO

CREATE UNIQUE CLUSTERED INDEX [ClusteredIndex-20200702-210813] ON [dbo].[dates]
(
	[id] ASC
)
GO

USE [dates_db]
GO

DECLARE @RowCount INT
DECLARE @RowString VARCHAR(10)
DECLARE @Random INT
DECLARE @Upper INT
DECLARE @Lower INT
DECLARE @InsertDate DATETIME

SET @Lower = -730
SET @Upper = -1
SET @RowCount = 0

WHILE @RowCount < 10000000 -- 1mil
BEGIN
	SELECT @Random = ROUND(((@Upper - @Lower -1) * RAND() + @Lower), 0)
	SET @InsertDate = DATEADD(dd, @Random, GETDATE())
	
	INSERT INTO dates
		(date1
		,date2
		,date3
		,date4
		,date5)
	VALUES
	    (DATEADD(dd, 1, @InsertDate)
		,DATEADD(dd, 2, @InsertDate)
		,DATEADD(dd, 3, @InsertDate)
		,DATEADD(dd, 4, @InsertDate)
		,DATEADD(dd, 5, @InsertDate))

	SET @RowCount = @RowCount + 1
END