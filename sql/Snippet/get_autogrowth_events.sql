-- simple one
;WITH p as
(
  SELECT [path] = REVERSE(SUBSTRING(p, CHARINDEX(N'\', p), 260)) + N'log.trc'
  FROM (SELECT REVERSE([path]) FROM sys.traces WHERE is_default = 1) s(p)
)
SELECT 
   t.DatabaseName,
   t.[FileName],
   t.SPID,
   t.Duration,
   t.StartTime,
   t.EndTime,
   FileType = CASE t.EventClass 
       WHEN 92 THEN 'Data'
       WHEN 93 THEN 'Log'
   END
FROM p CROSS APPLY sys.fn_trace_gettable(p.[path], DEFAULT) AS t
WHERE t.EventClass IN (92,93)
ORDER BY t.StartTime DESC;

-- fancier one
DECLARE @curr_tracefilename VARCHAR(500);
DECLARE @base_tracefilename VARCHAR(500);
DECLARE @indx INT;

SELECT
    @curr_tracefilename = [path]
FROM
    sys.traces
WHERE
    is_default = 1;

SET @curr_tracefilename = REVERSE(@curr_tracefilename);

SELECT @indx = PATINDEX('%\%', @curr_tracefilename);

SET @curr_tracefilename = REVERSE(@curr_tracefilename);
SET @base_tracefilename = LEFT(@curr_tracefilename, LEN(@curr_tracefilename) - @indx) + '\log.trc';

SELECT
    SERVERPROPERTY('MachineName') AS ComputerName,
    SERVERPROPERTY('InstanceName') AS InstanceName,
    SERVERPROPERTY('ServerName') AS SqlInstance,
    CONVERT(INT, (DENSE_RANK() OVER (ORDER BY [StartTime] DESC)) % 2) AS OrderRank,
    CONVERT(INT, [EventClass]) AS EventClass,
    [DatabaseName],
    [Filename],
    CONVERT(INT, (Duration / 1000)) AS Duration,
    DATEADD(MINUTE, DATEDIFF(MINUTE, GETDATE(), GETUTCDATE()), [StartTime]) AS StartTime,
    DATEADD(MINUTE, DATEDIFF(MINUTE, GETDATE(), GETUTCDATE()), [EndTime]) AS EndTime,
    ([IntegerData] * 8.0 / 1024) AS ChangeInSize,
    ApplicationName,
    HostName,
    SessionLoginName,
    SPID
FROM::fn_trace_gettable(@base_tracefilename, DEFAULT)
WHERE 
    [EventClass] IN (92,93,94,95)
ORDER BY 
    [StartTime] DESC