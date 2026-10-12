-- show files that have percent growth, not best practice
SELECT mf.type_desc,
       DB_name(mf.database_id) AS "database_name",
       mf.name AS "logical_name",
       mf.physical_name AS "filename",
       mf.size * 8 AS "size_kb",
       mf.growth
  FROM sys.master_files AS mf
 WHERE database_id > 4
   AND is_percent_growth = 1

-- shows files that have a set growth size and what percent that growth is vs the current file size, small files might have high percent
;WITH CTE1 AS
(
SELECT mf.type_desc,
       DB_name(mf.database_id) AS "database_name",
       mf.name AS "logical_name",
       mf.physical_name AS "filename",
       mf.size * 8 AS "size_kb",
       mf.growth,
       mf.is_percent_growth
  FROM sys.master_files AS mf
 WHERE database_id > 4
   AND is_percent_growth != 1
)
SELECT type_desc,
       database_name,
       logical_name,
       filename,
       size_kb,
       growth,
       FORMAT(CONVERT(float,growth)/CONVERT(float,size_kb), 'p') AS "size_v_growth"
  FROM CTE1
 ORDER BY database_name,
          type_desc