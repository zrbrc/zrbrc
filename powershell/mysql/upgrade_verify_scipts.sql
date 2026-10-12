-- schema
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'dph_redcap_prod'

-- count
SELECT  table_schema, table_name, table_rows
FROM INFORMATION_SCHEMA.TABLES
where table_schema = 'dph_redcap_prod'

-- other
show global variables like '%authentication%';

select host, user, plugin, authentication_string from mysql.user;

show global variables;

show binary logs
