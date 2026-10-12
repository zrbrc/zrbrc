USE db_DollarUniverse_SBX

SELECT *
FROM Objects obj
LEFT JOIN NODES nd ON nd.NODE = obj.Node
Order by obj.node, taskname