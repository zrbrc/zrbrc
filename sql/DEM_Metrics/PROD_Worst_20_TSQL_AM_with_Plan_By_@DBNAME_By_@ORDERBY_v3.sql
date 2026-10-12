/*************************************
"ACPU" represents Average CPU Usage
"AE"   represents Average Elapsed Time
"AIO"  represents Average IOs
*************************************/
CREATE TABLE #DB_Table(DatabaseName	sysname);

INSERT  INTO #DB_Table (DatabaseName)
VALUES	('DSS_WorkerWeb_PROD'),
		('DSS_POC_PROD'),
		('DMS_FORCES_PROD'),
		('DSS_SummerEBT_PROD'),
		('db_ReferenceTable_PROD'),
		('db_DataServicesHub_PROD'),
		('db_WorkerData_PROD'),
		('DSSC_LIHEAP_PROD');

DECLARE @COUNT		INT = 20
		,@ORDERBY	VARCHAR(4) = 'ACPU'
		,@DAYS		INT = 1
		,@AMPM		CHAR(2) = 'AM';

DECLARE	@NOW		DATETIME = DATEADD(d, -1, GETDATE()),	--'04/17/2015 23:59',
		@LASTWEEK	DATETIME,
		@OB			NCHAR(1);

SET @DAYS = @DAYS * -1
SET @LASTWEEK = DATEADD(d, @DAYS, GETDATE())

IF @AMPM ='AM'
	BEGIN
		SET @LASTWEEK = DATEADD(HH, 7, DATEDIFF(Day, 0, @NOW));
		SET @NOW = DATEADD(HH, 17, DATEDIFF(Day, 0, @NOW));
		SET @OB = 'O';
	END
ELSE
	BEGIN
		SET @LASTWEEK = DATEADD(HH, 17, DATEDIFF(Day, 1, @NOW));
		SET @NOW = DATEADD(HH, 7, DATEDIFF(Day, 0, @NOW));
		SET @OB = 'B';
	END

CREATE	TABLE #DailyTableStats (
		[DailyTableStats_IDNO]	INT IDENTITY (1,1)	NOT NULL,
		[Run_DATE]				DATE				NOT NULL,
		[OnLineBatch_INDC]		NVARCHAR(1)			NOT NULL,
		[DBID]					SMALLINT			NOT NULL,
		[OrderBy]				NVARCHAR(4)			NOT NULL,
		[Sequence]				INT					NOT NULL,
		[Statement]				NVARCHAR(MAX)		NOT NULL,
		[Objtype]				NVARCHAR(40)		NOT NULL,
		[Objectid]				INT					NULL,
		[Execution_Count]		BIGINT				NOT NULL,
		[Average IOs]			BIGINT				NOT NULL,
		[Total IOs]				BIGINT				NOT NULL,
		[Avg Logical Reads]		BIGINT				NOT NULL,
		[Total Logical Reads]	BIGINT				NOT NULL,
		[Avg Logical Writes]	BIGINT				NOT NULL,
		[Total Logical Writes]	BIGINT				NOT NULL,
		[Avg Physical Reads]	BIGINT				NOT NULL,
		[Total Physical Reads]	BIGINT				NOT NULL,
		[Avg CPU]				BIGINT				NOT NULL,
		[Total CPU]				BIGINT				NOT NULL,
		[Avg Elapsed Time]		BIGINT				NOT NULL,
		[Total Elasped Time]	BIGINT				NOT NULL,
		[Last Execution Time]	DATETIME			NOT NULL,
		[Plan_Handle]			VARBINARY(64)		NOT NULL,
		[Query_Plan]			XML					NULL);

BEGIN
	
	INSERT	INTO #DailyTableStats 
	SELECT	--TOP (@COUNT) 
			CONVERT(DATE, @LASTWEEK)
			,@OB
			,st.DBID
			,@ORDERBY AS ORDERBY
			,CASE 
				WHEN @ORDERBY = 'ACPU' THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_worker_time / execution_count ) DESC)
				WHEN @ORDERBY = 'TCPU' THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_worker_time) DESC)
				WHEN @ORDERBY = 'AE'   THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_elapsed_time / execution_count) DESC)
				WHEN @ORDERBY = 'TE'   THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_elapsed_time  ) DESC)
				WHEN @ORDERBY = 'EC'   THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (execution_count) DESC)
				WHEN @ORDERBY = 'AIO'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY ((total_logical_reads + total_logical_writes + total_physical_reads) / execution_count  ) DESC)
				WHEN @ORDERBY = 'TIO'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_reads + total_logical_writes + total_physical_reads) DESC)
				WHEN @ORDERBY = 'ALR'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_reads  / execution_count) DESC)
				WHEN @ORDERBY = 'TLR'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_reads ) DESC)
				WHEN @ORDERBY = 'ALW'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_writes / execution_count) DESC)
				WHEN @ORDERBY = 'TLW'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_writes  ) DESC)
				WHEN @ORDERBY = 'APR'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_physical_reads / execution_count ) DESC)
				WHEN @ORDERBY = 'TPR'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_physical_reads) DESC)
			END  AS [Sequence]
			,SUBSTRING(TEXT, CASE WHEN statement_start_offset = 0 OR statement_start_offset IS NULL THEN 1  
								  ELSE statement_start_offset/2 + 1 END, 
							 CASE WHEN statement_end_offset = 0 OR statement_end_offset = -1 OR statement_end_offset IS NULL THEN LEN(TEXT)  
								  ELSE statement_end_offset/2 END - CASE WHEN statement_start_offset = 0 OR statement_start_offset IS NULL THEN 1  
																		 ELSE statement_start_offset/2 
																	END + 1) AS [Statement]  
			,cp.objtype 
			,st.objectid
			,execution_count [Execution Count]  
			,(total_logical_reads + total_logical_writes + total_physical_reads )/execution_count [Average IOs] 
			,total_logical_reads + total_logical_writes + total_physical_reads [Total IOs]  
			,total_logical_reads/execution_count [Avg Logical Reads] 
			,total_logical_reads [Total Logical Reads]  
			,total_logical_writes/execution_count [Avg Logical Writes]  
			,total_logical_writes [Total Logical Writes]  
			,total_physical_reads/execution_count [Avg Physical Reads] 
			,total_physical_reads [Total Physical Reads]   
			,total_worker_time / execution_count [Avg CPU] 
			,total_worker_time [Total CPU] 
			,total_elapsed_time / execution_count [Avg Elapsed Time] 
			,total_elapsed_time  [Total Elasped Time] 
			,last_execution_time [Last Execution Time]  
			,qs.plan_handle
			,null
	FROM		sys.dm_exec_query_stats						qs  
	JOIN		sys.dm_exec_cached_plans					cp	ON	qs.plan_handle = cp.plan_handle 
	CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle)		st 
	INNER JOIN	#DB_Table									dt	ON	DB_NAME(st.dbid) = dt.DatabaseName
	OUTER APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa 
	WHERE	attribute = 'DBID'
	--AND		DB_NAME(st.dbid) IN (SELECT DatabaseName FROM #DB_Table)
	AND		last_execution_time BETWEEN @LASTWEEK AND @NOW
	--AND		OBJECT_NAME([Objectid],[DBID]) <> 'CaseCopy_Source_toFile'
	AND		ISNULL(OBJECT_NAME([Objectid],[DBID]),'X') <> 'CaseCopy_Source_toFile'
	ORDER BY CASE 
				WHEN @ORDERBY = 'ACPU' THEN total_worker_time / execution_count 
				WHEN @ORDERBY = 'TCPU' THEN total_worker_time
				WHEN @ORDERBY = 'AE'   THEN total_elapsed_time / execution_count
				WHEN @ORDERBY = 'TE'   THEN total_elapsed_time  
				WHEN @ORDERBY = 'EC'   THEN execution_count
				WHEN @ORDERBY = 'AIO'  THEN (total_logical_reads + total_logical_writes + total_physical_reads) / execution_count  
				WHEN @ORDERBY = 'TIO'  THEN total_logical_reads + total_logical_writes + total_physical_reads
				WHEN @ORDERBY = 'ALR'  THEN total_logical_reads  / execution_count
				WHEN @ORDERBY = 'TLR'  THEN total_logical_reads 
				WHEN @ORDERBY = 'ALW'  THEN total_logical_writes / execution_count
				WHEN @ORDERBY = 'TLW'  THEN total_logical_writes  
				WHEN @ORDERBY = 'APR'  THEN total_physical_reads / execution_count 
				WHEN @ORDERBY = 'TPR'  THEN total_physical_reads
			END DESC;

	SET @ORDERBY = 'AE'
	INSERT	INTO #DailyTableStats
	SELECT	--TOP (@COUNT) 
			CONVERT(DATE, @LASTWEEK)
			,@OB
			,st.DBID
			,@ORDERBY AS ORDERBY
			,CASE 
				WHEN @ORDERBY = 'ACPU' THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_worker_time / execution_count ) DESC)
				WHEN @ORDERBY = 'TCPU' THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_worker_time) DESC)
				WHEN @ORDERBY = 'AE'   THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_elapsed_time / execution_count) DESC)
				WHEN @ORDERBY = 'TE'   THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_elapsed_time  ) DESC)
				WHEN @ORDERBY = 'EC'   THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (execution_count) DESC)
				WHEN @ORDERBY = 'AIO'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY ((total_logical_reads + total_logical_writes + total_physical_reads) / execution_count  ) DESC)
				WHEN @ORDERBY = 'TIO'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_reads + total_logical_writes + total_physical_reads) DESC)
				WHEN @ORDERBY = 'ALR'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_reads  / execution_count) DESC)
				WHEN @ORDERBY = 'TLR'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_reads ) DESC)
				WHEN @ORDERBY = 'ALW'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_writes / execution_count) DESC)
				WHEN @ORDERBY = 'TLW'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_writes  ) DESC)
				WHEN @ORDERBY = 'APR'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_physical_reads / execution_count ) DESC)
				WHEN @ORDERBY = 'TPR'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_physical_reads) DESC)
			END  AS [Sequence]
			,SUBSTRING(TEXT, CASE WHEN statement_start_offset = 0 OR statement_start_offset IS NULL THEN 1  
								  ELSE statement_start_offset/2 + 1 END, 
							 CASE WHEN statement_end_offset = 0 OR statement_end_offset = -1 OR statement_end_offset IS NULL THEN LEN(TEXT)  
								  ELSE statement_end_offset/2 END - CASE WHEN statement_start_offset = 0 OR statement_start_offset IS NULL THEN 1  
																		 ELSE statement_start_offset/2 
																	END + 1) AS [Statement]  
			,cp.objtype 
			,st.objectid
			,execution_count [Execution Count]  
			,(total_logical_reads + total_logical_writes + total_physical_reads )/execution_count [Average IOs] 
			,total_logical_reads + total_logical_writes + total_physical_reads [Total IOs]  
			,total_logical_reads/execution_count [Avg Logical Reads] 
			,total_logical_reads [Total Logical Reads]  
			,total_logical_writes/execution_count [Avg Logical Writes]  
			,total_logical_writes [Total Logical Writes]  
			,total_physical_reads/execution_count [Avg Physical Reads] 
			,total_physical_reads [Total Physical Reads]   
			,total_worker_time / execution_count [Avg CPU] 
			,total_worker_time [Total CPU] 
			,total_elapsed_time / execution_count [Avg Elapsed Time] 
			,total_elapsed_time  [Total Elasped Time] 
			,last_execution_time [Last Execution Time]  
			,qs.plan_handle
			,null
	FROM		sys.dm_exec_query_stats						qs  
	JOIN		sys.dm_exec_cached_plans					cp	ON	qs.plan_handle = cp.plan_handle 
	CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle)		st 
	OUTER APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa 
	JOIN		#DB_Table									dt	ON	DB_NAME(st.dbid) = dt.DatabaseName
	WHERE	attribute = 'DBID'
	AND		last_execution_time BETWEEN @LASTWEEK AND @NOW
	--AND		OBJECT_NAME([Objectid],[DBID]) <> 'CaseCopy_Source_toFile'
	AND		ISNULL(OBJECT_NAME([Objectid],[DBID]),'X') <> 'CaseCopy_Source_toFile'
	ORDER BY CASE 
				WHEN @ORDERBY = 'ACPU' THEN total_worker_time / execution_count 
				WHEN @ORDERBY = 'TCPU' THEN total_worker_time
				WHEN @ORDERBY = 'AE'   THEN total_elapsed_time / execution_count
				WHEN @ORDERBY = 'TE'   THEN total_elapsed_time  
				WHEN @ORDERBY = 'EC'   THEN execution_count
				WHEN @ORDERBY = 'AIO'  THEN (total_logical_reads + total_logical_writes + total_physical_reads) / execution_count  
				WHEN @ORDERBY = 'TIO'  THEN total_logical_reads + total_logical_writes + total_physical_reads
				WHEN @ORDERBY = 'ALR'  THEN total_logical_reads  / execution_count
				WHEN @ORDERBY = 'TLR'  THEN total_logical_reads 
				WHEN @ORDERBY = 'ALW'  THEN total_logical_writes / execution_count
				WHEN @ORDERBY = 'TLW'  THEN total_logical_writes  
				WHEN @ORDERBY = 'APR'  THEN total_physical_reads / execution_count 
				WHEN @ORDERBY = 'TPR'  THEN total_physical_reads
			END DESC;

	SET @ORDERBY = 'AIO'
	INSERT	INTO #DailyTableStats
	SELECT	--TOP (@COUNT) 
			CONVERT(DATE, @LASTWEEK)
			,@OB
			,st.DBID
			,@ORDERBY AS ORDERBY
			,CASE 
				WHEN @ORDERBY = 'ACPU' THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_worker_time / execution_count ) DESC)
				WHEN @ORDERBY = 'TCPU' THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_worker_time) DESC)
				WHEN @ORDERBY = 'AE'   THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_elapsed_time / execution_count) DESC)
				WHEN @ORDERBY = 'TE'   THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_elapsed_time  ) DESC)
				WHEN @ORDERBY = 'EC'   THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (execution_count) DESC)
				WHEN @ORDERBY = 'AIO'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY ((total_logical_reads + total_logical_writes + total_physical_reads) / execution_count  ) DESC)
				WHEN @ORDERBY = 'TIO'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_reads + total_logical_writes + total_physical_reads) DESC)
				WHEN @ORDERBY = 'ALR'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_reads  / execution_count) DESC)
				WHEN @ORDERBY = 'TLR'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_reads ) DESC)
				WHEN @ORDERBY = 'ALW'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_writes / execution_count) DESC)
				WHEN @ORDERBY = 'TLW'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_logical_writes  ) DESC)
				WHEN @ORDERBY = 'APR'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_physical_reads / execution_count ) DESC)
				WHEN @ORDERBY = 'TPR'  THEN RANK() OVER (PARTITION BY st.DBID ORDER BY (total_physical_reads) DESC)
			END  AS [Sequence]
			,SUBSTRING(TEXT, CASE WHEN statement_start_offset = 0 OR statement_start_offset IS NULL THEN 1  
								  ELSE statement_start_offset/2 + 1 END, 
							 CASE WHEN statement_end_offset = 0 OR statement_end_offset = -1 OR statement_end_offset IS NULL THEN LEN(TEXT)  
								  ELSE statement_end_offset/2 END - CASE WHEN statement_start_offset = 0 OR statement_start_offset IS NULL THEN 1  
																		 ELSE statement_start_offset/2 
																	END + 1) AS [Statement]  
			,cp.objtype 
			,st.objectid
			,execution_count [Execution Count]  
			,(total_logical_reads + total_logical_writes + total_physical_reads )/execution_count [Average IOs] 
			,total_logical_reads + total_logical_writes + total_physical_reads [Total IOs]  
			,total_logical_reads/execution_count [Avg Logical Reads] 
			,total_logical_reads [Total Logical Reads]  
			,total_logical_writes/execution_count [Avg Logical Writes]  
			,total_logical_writes [Total Logical Writes]  
			,total_physical_reads/execution_count [Avg Physical Reads] 
			,total_physical_reads [Total Physical Reads]   
			,total_worker_time / execution_count [Avg CPU] 
			,total_worker_time [Total CPU] 
			,total_elapsed_time / execution_count [Avg Elapsed Time] 
			,total_elapsed_time  [Total Elasped Time] 
			,last_execution_time [Last Execution Time]  
			,qs.plan_handle
			,null
	FROM		sys.dm_exec_query_stats						qs  
	JOIN		sys.dm_exec_cached_plans					cp	ON	qs.plan_handle = cp.plan_handle 
	CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle)		st 
	OUTER APPLY sys.dm_exec_plan_attributes(qs.plan_handle) pa 
	JOIN		#DB_Table									dt	ON	DB_NAME(st.dbid) = dt.DatabaseName
	WHERE	attribute = 'DBID'
	AND		last_execution_time BETWEEN @LASTWEEK AND @NOW
	--AND		OBJECT_NAME([Objectid],[DBID]) <> 'CaseCopy_Source_toFile'
	AND		ISNULL(OBJECT_NAME([Objectid],[DBID]),'X') <> 'CaseCopy_Source_toFile'
	ORDER BY CASE 
				WHEN @ORDERBY = 'ACPU' THEN total_worker_time / execution_count 
				WHEN @ORDERBY = 'TCPU' THEN total_worker_time
				WHEN @ORDERBY = 'AE'   THEN total_elapsed_time / execution_count
				WHEN @ORDERBY = 'TE'   THEN total_elapsed_time  
				WHEN @ORDERBY = 'EC'   THEN execution_count
				WHEN @ORDERBY = 'AIO'  THEN (total_logical_reads + total_logical_writes + total_physical_reads) / execution_count  
				WHEN @ORDERBY = 'TIO'  THEN total_logical_reads + total_logical_writes + total_physical_reads
				WHEN @ORDERBY = 'ALR'  THEN total_logical_reads  / execution_count
				WHEN @ORDERBY = 'TLR'  THEN total_logical_reads 
				WHEN @ORDERBY = 'ALW'  THEN total_logical_writes / execution_count
				WHEN @ORDERBY = 'TLW'  THEN total_logical_writes  
				WHEN @ORDERBY = 'APR'  THEN total_physical_reads / execution_count 
				WHEN @ORDERBY = 'TPR'  THEN total_physical_reads
			END DESC;

	SELECT	[DailyTableStats_IDNO]	
			,[Run_DATE]				
			,CASE WHEN [OnLineBatch_INDC] = 'O' THEN 'Online'
				  ELSE 'Batch'
			 END AS 'Online_or_Batch'
			,DB_NAME([DBID]) AS Database_Name
			,[OrderBy]				
			,[Sequence]				
			--,[Statement]
			,CASE	WHEN OBJECT_NAME([Objectid],[DBID]) = 'CaseCopy_Source_toFile' THEN 'CaseCopy_Source_toFile'
					ELSE LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(CAST([Statement] as VARCHAR(MAX)))), CHAR(9), ' '), CHAR(10), ' '), CHAR(11), ' '), CHAR(12), ' '), CHAR(13), ' '))) 
			 END AS 'Statement'
			,[Objtype]					
			,OBJECT_SCHEMA_NAME([Objectid],[DBID]) [Schema Name] 
			,OBJECT_NAME([Objectid],[DBID]) [Object Name]			
			,[Execution_Count]		
			,[Average IOs]			
			,[Total IOs]				
			,[Avg Logical Reads]		
			,[Total Logical Reads]	
			,[Avg Logical Writes]	
			,[Total Logical Writes]	
			,[Avg Physical Reads]	
			,[Total Physical Reads]	
			,[Avg CPU]				
			,[Total CPU]				
			,[Avg Elapsed Time]		
			,[Total Elasped Time]	
			,[Last Execution Time]	
			,CONVERT(TIME(3), DATEADD (MILLISECOND, ([Total Elasped Time] / execution_count)/1000, 0)) AS [Avg Elapsed Time hh:mm:ss.mmm]
			,CONVERT(TIME(3), DATEADD (MILLISECOND, [Total Elasped Time]/1000, 0)) AS [Total Elasped Time hh:mm:ss.mmm]	
			,[Plan_Handle]
			--,[Query_Plan]
	FROM	#DailyTableStats
	WHERE	[Sequence] <= @COUNT
	ORDER BY	[Run_DATE]
				,[OrderBy]
				,DB_NAME([DBID])
				,[Sequence];

DROP TABLE #DailyTableStats;
DROP TABLE #DB_Table;

/*
SELECT	*
FROM	sys.dm_exec_query_plan(0x06002400BC556008C09689319602000001000000000000000000000000000000000000000000000000000000
)

*/

END
