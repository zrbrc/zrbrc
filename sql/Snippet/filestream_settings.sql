SELECT db.name AS db_name,  
       mf.type_desc,
       mf.physical_name,
       fso.directory_name,
       fso.non_transacted_access_desc
  FROM sys.master_files AS mf 
       INNER JOIN sys.databases AS db ON db.database_id = mf.database_id 
       INNER JOIN sys.database_filestream_options AS fso ON fso.database_id = mf.database_id
 WHERE type_desc = 'FILESTREAM' 
