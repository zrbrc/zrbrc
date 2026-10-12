USE db_DBStatTracking

select 
    f.type_desc as [Type]
    ,f.name as [FileName]
    ,fg.name as [FileGroup]
    ,f.physical_name as [Path]
    ,f.size / 128.0 as [CurrentSizeMB]
    ,f.size / 128.0 - convert(int,fileproperty(f.name,'SpaceUsed')) / 
        128.0 as [FreeSpaceMb]
from 
    sys.database_files f with (nolock) left outer join 
        sys.filegroups fg with (nolock) on
            f.data_space_id = fg.data_space_id
option (recompile);

SELECT 	s.name AS SchemaName,
		t.name AS TableName,
		SUM(p.rows) AS Count
FROM 		sys.partitions 	AS p
INNER JOIN 	sys.tables 		AS t	ON 	p.[object_id] = t.[object_id]
INNER JOIN 	sys.schemas 	AS s	ON 	t.[schema_id] = s.[schema_id]
GROUP BY s.name, t.name, p.index_id
HAVING 	p.index_id IN (0,1) -- heap or clustered index
AND		t.name IN ('IndexFragLvl','StatisticsUsage')
