# SQL Server Upgrade Checklist

## Note

This is not intended to be a checklist about how to perform the upgrade, but settings or configurations to check during the upgrade process to verify they are set at their best practice setting.

Some of this can be found/checked using sp_Blitz.

    EXEC sp_Blitz @CheckUserDatabaseObjects = 0, @CheckServerInfo = 1

Other items to check can be found from these links:

- https://www.brentozar.com/archive/2008/03/sql-server-2005-setup-checklist-part-2-after-the-install/
- https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/performance-guidelines-best-practices-checklist?view=azuresql
- 

### Best Practice Checklist

1. Database autogrowth should be set to 256MB and 128MB for mdf and ldf files respectively, at a minimum.
1. Database PAGE_VERIFY set to CHECKSUM.
