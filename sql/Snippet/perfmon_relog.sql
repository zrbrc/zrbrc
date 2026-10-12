SELECT CounterDetails.MachineName,
       CounterDetails.ObjectName,
       CounterDetails.CounterName,
       CounterDetails.CounterType,
       CounterDetails.InstanceName,
       DATEDIFF(minute, st.starttime, CAST(LEFT(CounterData.CounterDateTime, LEN(CounterData.CounterDateTime) - 5) AS DATETIME)) AS interval,
       Avg(CounterData.CounterValue) AS counterValues
  FROM CounterData
       INNER JOIN CounterDetails ON CounterData.CounterID = CounterDetails.CounterID,
                                    (SELECT CounterDetails.MachineName,
                                            MIN(CAST(LEFT(CounterData.CounterDateTime, Len(CounterData.CounterDateTime) - 5) AS DATETIME)) AS startTime
                                       FROM CounterData
                                            INNER JOIN CounterDetails ON CounterData.CounterID = CounterDetails.CounterID
                                      GROUP BY MachineName) AS st
 WHERE CounterDetails.ObjectName = 'PhysicalDisk'
   AND st.MachineName = CounterDetails.MachineName   
   AND CounterDetails.CounterName = 'Avg. Disk sec/Transfer'
   AND CounterDetails.InstanceName = '2 E:'
 GROUP BY CounterDetails.MachineName,
          CounterDetails.ObjectName,
          CounterDetails.CounterName,
          CounterDetails.CounterType,
          CounterDetails.InstanceName,
          DATEDIFF(minute, st.startTime, Cast(LEFT(CounterData.CounterDateTime, Len(CounterData.CounterDateTime) - 5) AS DATETIME)),
          CounterData.CounterValue