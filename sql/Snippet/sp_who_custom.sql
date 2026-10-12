SELECT spid,
	   ecid,
	   status,
	   loginame = rtrim(loginame),
	   hostname,
	   blk = convert(char(5),blocked),
	   dbname = CASE
	       WHEN dbid = 0 THEN null
		   WHEN dbid <> 0 THEN db_name(dbid)
	   END,
	   cmd,
	   request_id
  FROM sys.sysprocesses
 WHERE loginame != 'sa'
 ORDER BY loginame