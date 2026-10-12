DECLARE @batch_size INT = 100000

DECLARE @audit_days INT = -14
DECLARE @except_days INT = -365

DECLARE @audit_delete_date DATETIME2 = DATEADD(day, @audit_days, GETDATE())
DECLARE @except_delete_date DATETIME2 = DATEADD(day, @except_days, GETDATE())

DECLARE @record_count INT

--
PRINT CONCAT('Deleting audit records older than ', @audit_delete_date, '.')

SELECT @record_count = COUNT(*) FROM dbo.Log_T
 WHERE Category IN ('Audit','Logging')
   AND Timestamp < @audit_delete_date;

IF @record_count > 0
BEGIN
  PRINT CONCAT('Deleting ', @record_count, ' audit records.')
  
  WHILE 1=1
  BEGIN
    DELETE TOP (@batch_size)
      FROM dbo.Log_T
     WHERE Category IN ('Audit','Logging')
       AND Timestamp < @audit_delete_date;
    IF @@ROWCOUNT < @batch_size BREAK
  END
END
ELSE
BEGIN
  PRINT 'No records matching date criteria to delete.'
END

--

PRINT CONCAT('Deleting exception records older than ', @except_delete_date, '.')

SELECT @record_count = COUNT(*) FROM dbo.Log_T
 WHERE Category IN ('Exception')
   AND Timestamp < @except_delete_date;

IF @record_count > 0
BEGIN
  PRINT CONCAT('Deleting ', @record_count, ' exception records.')
  
  WHILE 1=1
  BEGIN
    DELETE TOP (@batch_size)
      FROM dbo.Log_T
     WHERE Category IN ('Exception')
       AND Timestamp < @except_delete_date;
    IF @@ROWCOUNT < @batch_size BREAK
  END
END
ELSE
BEGIN
  PRINT 'No records matching date criteria to delete.'
END