-- a sample to delete 50k records at a time, change tables and where as needed
DECLARE @BatchSize INT = 50000

WHILE 1=1
BEGIN

  DELETE TOP (@BatchSize)
    FROM dbo.Log_T
   WHERE Category IN ('Exception')
     
  IF @@ROWCOUNT < @BatchSize BREAK
END
