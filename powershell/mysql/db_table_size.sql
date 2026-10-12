SELECT
    ENGINE,
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_ROWS,
    Round( DATA_LENGTH/1024/1024) AS Table_size_MB ,
    round(INDEX_LENGTH/1024/1024) AS Index_size_MB,
    round((DATA_LENGTH+INDEX_LENGTH)/1024/1024) AS Total_size_MB,
    round(DATA_FREE/ 1024/1024) AS Free_space_MB,
    ROW_FORMAT
FROM
    information_schema.tables
WHERE TABLE_SCHEMA NOT IN ('mysql', 'information_schema','performance_schema','dba','sys')
ORDER BY 7 DESC;


SELECT
    table_schema "Database Name",
    ROUND(SUM(data_length + index_length)/1024/1024,0) "DB Size in MB"
FROM
    information_schema.TABLES
WHERE TABLE_SCHEMA NOT IN ('mysql', 'information_schema','performance_schema','dba','sys')
GROUP BY table_schema;