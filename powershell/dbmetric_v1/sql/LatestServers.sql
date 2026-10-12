USE DBA

;WITH CTE_Servers
AS (
  SELECT MAX(ID) AS ID,
         Servername, 
         IP,
         Instance
    FROM Servers_T 
   GROUP BY Servername, 
            IP,
            Instance
)
SELECT A.* 
  FROM Servers_T AS A
       JOIN CTE_Servers AS B ON A.ID = B.ID
 ORDER BY Servername
