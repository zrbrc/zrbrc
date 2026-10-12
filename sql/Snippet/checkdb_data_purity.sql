-- source: https://www.mssqltips.com/sqlservertip/1988/ensure-sql-server-data-purity-checks-are-performed/

DBCC TRACEON (3604);;;
GO
CREATE TABLE #DBCC ( 
      ParentObject VARCHAR(255),
      [Object] VARCHAR(255),
      Field VARCHAR(255),
      [Value] VARCHAR(255)
) 
CREATE TABLE #DBCC2 ( 
     DatabaseName VARCHAR(255),
     ParentObject VARCHAR(255),
     [Object] VARCHAR(255),
     Field VARCHAR(255),
     [Value] VARCHAR(255)
)
EXEC master.dbo.sp_MSFOREACHDB 
'USE ? INSERT INTO #DBCC EXECUTE (''DBCC DBINFO WITH TABLERESULTS'');
INSERT INTO #DBCC2 SELECT ''?'', * FROM #DBCC;
DELETE FROM #DBCC'
SELECT * 
FROM #DBCC2
WHERE Field = 'dbi_DBCCFlags'
DROP TABLE #DBCC
DROP TABLE #DBCC2
GO