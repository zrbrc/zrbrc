-- changed this to a CTE for better sorting and formatting
WITH CTE AS (
SELECT t.Name AS tablename,
       s.Name AS schemaname,
       p.Rows AS rowcounts,
       SUM(a.total_pages) * 8 AS totalkb,
       SUM(a.used_pages) * 8 AS usedkb,
       (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS unusedkb
  FROM sys.tables t
       JOIN sys.indexes AS i ON t.object_id = i.object_id
       JOIN sys.partitions AS p ON i.object_id = p.object_id AND i.index_id = p.index_id
       JOIN sys.allocation_units AS a ON p.partition_id = a.container_id
       LEFT OUTER JOIN sys.schemas AS s ON t.schema_id = s.schema_id
 WHERE t.is_ms_shipped = 0
 GROUP BY t.Name, 
          s.Name,
          p.Rows
)
SELECT tablename AS table_name,
       schemaname AS schema_name,
       FORMAT(rowcounts, 'N0') AS rows,
       FORMAT(totalkb, 'N0') AS total_kb,
       FORMAT(usedkb, 'N0') AS used_kb,
       FORMAT(unusedkb, 'N0') AS unused_kb
FROM CTE 
ORDER BY rowcounts DESC