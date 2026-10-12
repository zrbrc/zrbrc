-- Check full version history of installed SSIS packages
-- only works for project deployment model
USE SSISDB
SELECT folders.name AS folder_name,
       projects.name AS project_name,
       packages.name AS package_name,
       version_major,
       version_minor,
       version_build,
       object_versions.created_time
  FROM internal.packages
       JOIN internal.projects ON projects.project_id = packages.project_id
       JOIN internal.object_versions ON object_versions.object_id = projects.project_id
            AND object_versions.object_version_lsn = packages.project_version_lsn
       JOIN internal.folders ON folders.folder_id = projects.folder_id
-- comment out WHERE to show everything
 WHERE folders.name = 'MyAccount'
   AND projects.name = 'PHRST_Step_2'
 ORDER BY projects.name,
          packages.name,
          version_build DESC