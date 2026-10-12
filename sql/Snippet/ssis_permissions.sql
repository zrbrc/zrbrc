-- source: https://learn.microsoft.com/en-us/sql/integration-services/system-stored-procedures/catalog-grant-permission-ssisdb-database?view=sql-server-ver16

DECLARE @userid INT

/*
 Logins:		domTEST\ts.dss.pss.batch
 Permissions:	READ(101), EXEC(103)
 Folders:		DSS_PSS_UAT1(24)
				DSS_PSS_UAT2(25)
				DSS_PSS_UAT3(26)
*/
SELECT @userid = USER_ID('domTEST\ts.dss.pss.batch')
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 24, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 24, @principal_id = @userid, @permission_type = 103

EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 25, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 25, @principal_id = @userid, @permission_type = 103

EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 26, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 26, @principal_id = @userid, @permission_type = 103

/*
 Logins:		domTEST\ts.dss.ss.batch
 Permissions:	READ(101), EXEC(103)
 Folders:		DSS_ASSIST_UAT1(21)
				DSS_ASSIST_UAT2(22)
				DSS_ASSIST_UAT3(23)
*/
SELECT @userid = USER_ID('domTEST\ts.dss.ss.batch')
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 21, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 21, @principal_id = @userid, @permission_type = 103

EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 22, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 22, @principal_id = @userid, @permission_type = 103

EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 23, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 23, @principal_id = @userid, @permission_type = 103

/*
FOR EXISTING permissions that we want to correct
*/
DECLARE @userid INT

/* 
Login:     domain.com.workerweb.batch
Permission: READ(101), EXECUTE(103)
Folder:     Workerweb(1)
            Workerweb_TEST(5)
            Workerweb_UAT3(14)
 */
SELECT @userid = USER_ID(domain.com.workerweb.batch')
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 1, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 1, @principal_id = @userid, @permission_type = 103

EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 5, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 5, @principal_id = @userid, @permission_type = 103

EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 14, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 14, @principal_id = @userid, @permission_type = 103

/* 
Login:      domTEST\dmsts.forces.batch
Permission: READ(101), EXECUTE(103)
Folder:     FORCES_2(7)
            FORCES(9)
            FORCES_UAT3(17)
*/
SELECT @userid = USER_ID('domTEST\dmsts.forces.batch')
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 9, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 9, @principal_id = @userid, @permission_type = 103

EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 7, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 7, @principal_id = @userid, @permission_type = 103

EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 17, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 17, @principal_id = @userid, @permission_type = 103

/* 
Login:      domTEST\dssts.poc.batch
Permission: READ(101), EXECUTE(103)
Folder:     Childcare(8)
            Childcare_UAT3(16)
            Childcare_UATCR(2)
*/
SELECT @userid = USER_ID('domTEST\dssts.poc.batch')
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 8, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 8, @principal_id = @userid, @permission_type = 103

EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 16, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 16, @principal_id = @userid, @permission_type = 103

EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 2, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 2, @principal_id = @userid, @permission_type = 103

/*
Login:      domTEST\TS.DSSC.LIHEAP.BATCH
Permission: READ(101), EXECUTE(103)
Folder:     LIHEAP_TEST(13)
            LIHEAP_UAT3(15)
            LIHEAP_UATCR(12)
*/
SELECT @userid = USER_ID('domTEST\TS.DSSC.LIHEAP.BATCH')
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 13, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 13, @principal_id = @userid, @permission_type = 103

EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 15, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 15, @principal_id = @userid, @permission_type = 103

EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 12, @principal_id = @userid, @permission_type = 101
EXEC SSISDB.catalog.grant_permission @object_type = 1, @object_id = 12, @principal_id = @userid, @permission_type = 103