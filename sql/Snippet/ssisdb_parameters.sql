SELECT
    f.name AS folder_name,
    p.name AS project_name,
    op.object_name,
    op.parameter_name,
    op.default_value AS configured_value
FROM
    SSISDB.catalog.object_parameters op
    INNER JOIN SSISDB.catalog.projects p ON p.project_id = op.project_id
    INNER JOIN SSISDB.catalog.folders f ON f.folder_id = p.folder_id
WHERE
    -- if you want to search on a value, need to convert it, its a sql_variant
	CONVERT(VARCHAR(255),op.default_value) LIKE '%xls%'
ORDER BY
    project_name,
    op.object_type, 
	op.object_name