SELECT server_principal_name, action_id, count(*) FROM Audits_T GROUP BY server_principal_name, action_id

SELECT CAST(RecordTime AS DATE) as DateCol, action_id, count(*) FROM Audits_T GROUP BY CAST(RecordTime AS DATE), action_id ORDER BY DateCol