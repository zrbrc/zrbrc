# Delete an orphaned database user under SSISDB

Souce: *https://blog.dbi-services.com/delete-an-orphan-user-database-under-ssisdb/*

To check if a user is orphaned.

```sql
SELECT * 
  FROM sys.database_principals a
       LEFT OUTER JOIN sys.server_principals b ON a.sid = b.sid
 WHERE b.sid IS NULL
   AND a.type In ('U','G')
   AND a.principal_id > 4
```

The result is one database user.

```text
Name: dbi\orphan_user
Type_desc: WINDOWS_USER
Default_schema_name: dbo
```

And now, attempt to delete the orphaned user with the classical DROP command:

```sql
USE [SSISDB]
DROP USER [dbi\orphan_user]
GO
```

You will get an error below.

```sql
Msg 27226, Level 16, State 1, Procedure ddl_cleanup_object_permissions, Line 16
The database principal has granted or denied permissions to catalog objects in the database and cannot be dropped
Msg 3609, Level 16, State 2, Line 1  The transaction ended in the trigger. The batch has been aborted.
```

## STEP 1

The first step to analyze this error is to see the trigger “ddl_cleanup_object_permissions” from the Error message. 

You can see in the trigger there are 5 views/tables. `[internal].[object_permissions]` is a view created with 4 tables linked by ‘UNION ALL’ commands.

- `[internal].[object_permissions]`  –> view
- `[internal].[folder_permissions]` –> table
- `[internal].[project_permissions]` –> table
- `[internal].[environment_permissions]` –> table
- `[internal].[operation_permissions]` –> table

I will search what permissions have this user.
I create this script to have a view between the Object Type (folder, project, environment or operation), permission associated and the user name:

```sql
SELECT CASE (ObjPerm.object_type) 
         WHEN 1 THEN 'folder'
         WHEN 2 THEN 'project'
         WHEN 3 THEN 'environment'
         WHEN 4 THEN 'operation'
       END AS object_type,
       CASE (ObjPerm.permission_type)
         WHEN 1 THEN 'READ'
         WHEN 2 THEN 'MODIFY'
         WHEN 3 THEN 'EXECUTE'
         WHEN 4 THEN 'MANAGE_PERMISSIONS'
         WHEN 100 THEN 'CREATE_OBJECTS'
         WHEN 101 THEN 'READ_OBJECTS'
         WHEN 102 THEN 'MODIFY_OBJECTS'
         WHEN 103 THEN 'EXECUTE_OBJECTS'
         WHEN 104 THEN 'MANAGE_OBJECT_PERMISSIONS'
       END AS permission_description,
       Princ.Name AS database_user_name
  FROM internal.object_permissions ObjPerm 
       JOIN sys.server_principals Princ ON ObjPerm.sid = Princ.sid
 WHERE Princ.Name='dbi\orphan_user'
 ORDER BY object_type DESC,
          database_user_name,
          permission_description
```

In this case, I have no result…

MSDN Reference for the object type matrix and the permission matrix in the “catalog.grant_permission” webpage

## STEP 2

The second step is to verify the specific object permission tables with this script:

```sql
/*Folder Permissions*/
SELECT fo.*,
       p.name
  FROM internal.folder_permissions fo
       INNER JOIN sys.database_principals p on fo.[sid] = p.[sid]
 WHERE p.name = 'dbi\orphan_user'
/*Project Permissions*/
SELECT pr.*,
       p.name
  FROM internal.project_permissions pr
       INNER JOIN sys.database_principals p on pr.[sid] = p.[sid]
 WHERE p.name = 'dbi\orphan_user'
/*Environment Permissions*/
SELECT en.*,
       p.name
  FROM internal.environment_permissions en
       INNER JOIN sys.database_principals p on en.[sid] = p.[sid]
 WHERE p.name = 'dbi\orphan_user'
/*Operation Permissions*/
SELECT op.*,
       p.name
  FROM internal.operation_permissions op
       INNER JOIN sys.database_principals p on op.[sid] = p.[sid]
 WHERE p.name = 'dbi\orphan_user'
```

Only one return a result. In this case, it is the query with internal.operation_permissions.
I can deduct that I have some “ghost rows” in this table.

## STEP 3

The third step is to delete these “ghost rows” but before don’t forget every time to back up the database SSISDB.
The ugly step is now to delete all rows in the internal.operation_permissions with the orphan user ‘dbi\orphan_user’ I use the sid from the user to delete it
1

```sql
DELETE internal.operation_permissions WHERE sid = 0x0105000000000005...
```

Logically, if you have others rows in the other object types, you can also delete rows.
The last step is really to drop the database user and now, it works!

If you are still unable to drop the user, the next step would be to disable the trigger, drop user, then re-enable. 
