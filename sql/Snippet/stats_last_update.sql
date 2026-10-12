-- taken from dba tools with some modifcations for all-in-one.
-- https://github.com/dataplat/dbatools/blob/master/functions/Get-DbaDbccStatistic.ps1

-- filters auto-stats and finds not updated in 180 days

WITH CTE1 AS (
     SELECT DB_NAME() AS database_name,
            Schema_Name(o.SCHEMA_ID) + '.' + o.name as table_name, 
            st.name as stat_name,
            STATS_DATE(st.object_id, st.stats_id) AS stats_last_update
       FROM sys.stats st
            INNER JOIN sys.objects o ON o.object_id = st.object_id
      WHERE o.type in ('U', 'V')
        AND st.name NOT LIKE '_WA_%'
)
SELECT * 
  FROM CTE1
 WHERE stats_last_update <= DATEADD(day,-180,GETDATE())
 ORDER BY table_name,
          stat_name