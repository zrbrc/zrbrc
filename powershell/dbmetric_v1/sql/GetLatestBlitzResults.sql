USE DBA
GO

WITH RunTime AS
(
	SELECT MAX(Runtime) AS MAXRUNTIME,
	       ServerName
	  FROM Blitz_T
	 GROUP BY ServerName
)
SELECT *
  FROM Blitz_T AS B
       JOIN RunTime AS R 
	        ON R.MAXRUNTIME = B.Runtime 
	        AND R.ServerName = B.ServerName
 WHERE Priority <= 50
 ORDER BY B.ServerName,
          B.Priority,
		  B.ID