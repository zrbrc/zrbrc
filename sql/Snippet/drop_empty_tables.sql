DECLARE @sql NVARCHAR(max) = ''

-- drop empty tables
SELECT @sql += 'DROP TABLE ' + SCHEMA_NAME(o.schema_id) + '.' + o.name + '; -- rows: ' + CAST(SUM(ps.row_count) AS CHAR) + CHAR(13) + CHAR(10)
  FROM sys.objects AS o
       INNER JOIN sys.dm_db_partition_stats AS ps
               ON o.object_id = ps.object_id
 WHERE o.type = 'U'
   AND o.is_ms_shipped = 0
   AND SCHEMA_NAME(o.schema_id) = 'dbo'
   AND ps.index_id < 2
 GROUP BY o.schema_id,
          o.name
HAVING SUM(ps.row_count) = 0

print @sql