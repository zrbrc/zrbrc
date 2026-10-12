DECLARE	@date_captured	DATETIME = GETDATE();
DECLARE @database_id int = DB_ID()

SELECT @date_captured AS date_captured,
       @@SERVERNAME,
       DB_NAME(@database_id) AS database_name,
       @database_id AS database_id,
       objects.object_id,
       schemas.name,
       objects.name as object_name,
       objects.type_desc AS object_type,
       indexes.index_id,
       indexes.name AS index_name,
       indexes.type_desc AS index_type,
       indexes.fill_factor,
       index_stats.page_count,
       index_stats.index_depth,
       CAST(index_stats.avg_fragmentation_in_percent AS decimal(10,2)) AS avg_frag_percent,
       CAST(index_stats.avg_fragment_size_in_pages AS decimal(10,2)) AS avg_frag_page_size
  FROM sys.dm_db_index_physical_stats (@database_id, NULL, NULL, NULL, 'LIMITED') AS index_stats
       INNER JOIN sys.indexes indexes ON index_stats.object_id = indexes.object_id AND index_stats.index_id = indexes.index_id
       INNER JOIN sys.objects objects ON indexes.object_id = objects.object_id
       INNER JOIN sys.schemas schemas ON objects.schema_id = schemas.schema_id
 WHERE objects.type IN('U','V')
   AND objects.is_ms_shipped = 0
   AND indexes.type IN (1,2,3,4)
   AND indexes.is_disabled = 0
   AND indexes.is_hypothetical = 0
   AND index_stats.alloc_unit_type_desc = 'IN_ROW_DATA'
   AND index_stats.index_level = 0
   --AND index_stats.page_count >= 1000
 ORDER BY index_stats.avg_fragmentation_in_percent DESC