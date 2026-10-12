-- need to find principal ID and then change it below to script it out.
-- copy and paste it into SSMS and run, it only outputs code, it doesnt make any changes

SELECT
    '/* FOLDER: ' + name + ' */' as FOLDER_NAME,
	'EXEC [SSISDB].[catalog].[grant_permission] @object_type=1, @object_id=' + CAST(folder_id as varchar(10)) + ', @principal_id=37, @permission_type=1;' AS 'READ',
	'EXEC [SSISDB].[catalog].[grant_permission] @object_type=1, @object_id=' + CAST(folder_id as varchar(10))  + ', @principal_id=37, @permission_type=101' AS 'READ_OBJECTS'
FROM
    ssisdb.catalog.folders
ORDER BY
    name

-- can run this to what forlder IDs are.
select * from ssisdb.catalog.folders

