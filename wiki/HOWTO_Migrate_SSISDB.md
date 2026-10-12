# Migrate SSISDB to New Server

Source: https://www.mssqltips.com/sqlservertip/6831/how-to-migrate-ssisdb-to-another-server/

This approach is to restore the SSIS database and encryption key from the backup of the source server to the new server. This approach retains the execution history, project versions, permissions, environment variables, SSIS catalog properties, etc. If your business needs execution history for reporting usage statistics or trend analysis, you may want to choose this approach.

## Install SQL Server

Install the SSIS catalog on the new server as described in approach 1.  This will avoid some hassles that could make restoring the encryption key harder.

## Backup Keys and Database

On the source server, backup the SSISDB database. 

For the master key, if you don’t have the original password that was used to create SSISDB, do a backup of the master key.

```sql
backup master key to file = 'c:\mybackup\SrcSSISEncrptKey'
encryption by password = 'Keepsafe2!'
```

Or if needed add a new password and then backup the key.

```sql
alter master key
add encryption by password = 'Keepsafe2!'
```

## Restore Keys and Database

On the new server, create the SSIS catalog, then restore with replace on the SSISDB database using the backup.

Restore the master key by using one of the following methods

If you have performed a backup of the database master key and you have the password used to encrypt the master key, use the following and ignore the warning.

```sql
restore master key from file = 'c:\mybackup\SrcSSISEncrptKey'
decryption by password = 'Keepsafe2!' -- Master Key Password
encryption by password = 'Keepsafe3!' -- New Password
force
```

Use this method if you have the original password that was used to create SSISDB or use the new password you added.

```sql
USE SSISDB
open master key decryption by password = 'Keepsafe2!' -- SSISDB Password
alter Master Key Add encryption by Service Master Key
```

Use sp_change_users_login to synchronize the SID of SSIS catalog user.

```sql
EXEC sp_change_users_login 'update_one', '##MS_SSISServerCleanupJobUser##','##MS_SSISServerCleanupJobLogin##'
```

## Upgrade Database

The database is migrated, but the format of SSISDB is still at the original version. Run the SSISDB Upgrade Wizard to upgrade the SSIS Catalog.

Right-click on SSISDB and then select Database Upgrade to launch the SSISDB Upgrade Wizard. Or launch the SSISDB Upgrade Wizard by running C:\Program Files\Microsoft SQL Server\150\DTS\Binn\ISDBUpgradeWizard.exe with elevated permissions on the local server.

Note: there used to be an error when running the wizard, but SQL 2019 CU9- KB5000642 fixed it.

END
