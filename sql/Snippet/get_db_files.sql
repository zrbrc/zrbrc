SELECT db_name(database_id) as db_name,
       name,
       physical_Name,
       type_desc,
       size * 8 / 1024 AS size_mb
  FROM sys.master_files
 WHERE type_desc = 'LOG'
 order by db_name, name, physical_name

