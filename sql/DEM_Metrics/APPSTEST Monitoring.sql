--Drive Space per Server
;WITH core AS ( 
SELECT	DISTINCT	--@@SERVERNAME AS ServerName,
		Drive,
		TotalGBs,
		CAST((TotalGBs - AvailableGBs) as decimal(12,2)) UsedGBs,
		AvailableGBs,
		CAST((((TotalGBs - AvailableGBs) / TotalGBs) * 100) as decimal(12,2)) Pct_Used
FROM (SELECT DISTINCT 
				s.volume_mount_point [Drive],
				CAST(s.available_bytes / 1048576.0 /1024.0 as decimal(12,2)) [AvailableGBs],
				CAST(s.total_bytes / 1048576.0 /1024.0 as decimal(12,2)) [TotalGBs]
		FROM sys.master_files f
		CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) s) AS T
)

SELECT	* 
FROM	core
ORDER BY	Drive;
--ORDER BY ServerName, Drive;

--Page life expectancy
DECLARE @Date VARCHAR(10) = FORMAT(GETDATE(),'MM/dd/yyyy'),
		@SQL  NVARCHAR(MAX);

SET @SQL = '
SELECT	--@@SERVERNAME AS ServerName,
		FORMAT([cntr_value], ''#,#'') AS ['+ @Date +']
FROM	sys.dm_os_performance_counters
WHERE	[object_name] LIKE ''%Manager%''
AND		[counter_name] = ''Page life expectancy'';'
--ORDER BY ServerName;'
EXEC (@SQL);

--Buffer cache hit ratio
SET @SQL = '
SELECT	--@@SERVERNAME AS ServerName,
		FORMAT([cntr_value], ''#,#'') AS ['+ @Date +']
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE ''%Buffer Manager%''
AND [counter_name] = ''Buffer cache hit ratio'';'
--ORDER BY ServerName;'
EXEC (@SQL);

--Average CPU Usage Per Database
;WITH CPU_Per_Db AS
(SELECT	 dmpa.DatabaseID
		 ,DB_Name(dmpa.DatabaseID) AS [Database]
		 ,SUM(dmqs.total_worker_time) AS CPUTimeAsMS
 FROM			sys.dm_exec_query_stats dmqs
 CROSS APPLY (SELECT CONVERT(INT, value) AS [DatabaseID] 
			  FROM	 sys.dm_exec_plan_attributes(dmqs.plan_handle)
			  WHERE  attribute = N'dbid') dmpa
 GROUP BY dmpa.DatabaseID)
 
SELECT	--@@SERVERNAME AS ServerName,
		DB_Name(d.database_id) AS Database_Name,
		ISNULL([CPUTimeAsMS],0) AS [CPUTimeAsMS],
		ISNULL(CAST([CPUTimeAsMS] * 1.0 / SUM([CPUTimeAsMS]) OVER() * 100.0 AS DECIMAL(5, 2)),0) AS [CPUTimeAs%]
FROM		sys.databases	d
LEFT JOIN	CPU_Per_Db		c	ON	d.database_id = c.DatabaseID
WHERE DB_Name(d.database_id) NOT IN ('master', 'msdb', 'model', 'tempdb', 'db_DBBaseline', 'EmptyDB1')
ORDER BY DB_Name(d.database_id);
--ORDER BY ServerName, DB_Name(d.database_id);

/*****	Script: SQL Server CPU Utilization report from last N minutes *****/
/*****	Support: SQL Server 2008 and Above *****/
/*****	Tested On: SQL Server 2008 R2 and 2014 *****/
/*****	Output: 
	SQLServer_CPU_Utilization: % CPU utilized from SQL Server Process
	System_Idle_Process: % CPU Idle - Not serving to any process 
	Other_Process_CPU_Utilization: % CPU utilized by processes otherthan SQL Server
	Event_Time: Time when these values captured
*****/

DECLARE @ts BIGINT;
DECLARE @lastNmin BIGINT = 1440; --(60 minutes x 24 hours = 1440 minutes)
SELECT @ts =(SELECT cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info); 
SELECT	TOP(@lastNmin)
		--@@SERVERNAME AS ServerName,
		SQLProcessUtilization AS [SQLServer_CPU_Utilization], 
		SystemIdle AS [System_Idle_Process], 
		100 - SystemIdle - SQLProcessUtilization AS [Other_Process_CPU_Utilization], 
		DATEADD(ms,-1 *(@ts - [timestamp]),GETDATE())AS [Event_Time] 
FROM	(SELECT record.value('(./Record/@id)[1]','int')AS record_id, 
				record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]','int')AS [SystemIdle], 
				record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]','int')AS [SQLProcessUtilization], 
				[timestamp]      
		 FROM	(SELECT	[timestamp], 
						convert(xml, record) AS [record]             
				 FROM	sys.dm_os_ring_buffers             
				 WHERE	ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
				 AND	record LIKE'%%'
				) AS x 
		) AS y 
ORDER BY record_id DESC; 
--ORDER BY ServerName, record_id DESC; 