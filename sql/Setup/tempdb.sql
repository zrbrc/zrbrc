
-- modify or add tempdb files as necessary to match core count, move templog to separate dive for larger instances, max sizes for drive spaces given
USE master
GO
ALTER DATABASE tempdb MODIFY FILE ( NAME = tempdev, FILENAME = 'T:\TempDB\tempdb.mdf' , SIZE = 15GB , FILEGROWTH = 0 )
ALTER DATABASE tempdb ADD FILE ( NAME = temp2, FILENAME = 'T:\TempDB\tempdb_2.ndf' , SIZE = 15GB , FILEGROWTH = 0 )
-- ALTER DATABASE tempdb ADD FILE ( NAME = temp3, FILENAME = 'T:\TempDB\tempdb_3.ndf' , SIZE = 15GB , FILEGROWTH = 0 )
-- ALTER DATABASE tempdb ADD FILE ( NAME = temp4, FILENAME = 'T:\TempDB\tempdb_4.ndf' , SIZE = 15GB , FILEGROWTH = 0 )

ALTER DATABASE tempdb MODIFY FILE ( NAME = templog, FILENAME = 'T:\TempDB\templog.ldf' , SIZE = 15GB , FILEGROWTH = 0 )
GO

--Restart SQL services and verify change:
SELECT name, physical_name AS CurrentLocation, state_desc
FROM sys.master_files
WHERE database_id = DB_ID(N'tempdb'); 

-- Delete old files from the original location, if needed.