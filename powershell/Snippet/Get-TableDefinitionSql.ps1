#Requires -Modules sqlserver,importexcel

# instance required
$instance = 'host04\DV2016_1'

# database(s) optional, put a list or set to $null if you want all, will automatically exclude system database
$databases = 'DSS_WorkerWeb_SIT3', 'db_DataServicesHubLog_SIT3'
# $databases = $null

# creates new blank excel or creates existing with matching name
$date = Get-Date -Format 'yyyy-MM-dd'
$excel = '.\PDM_' + $instance.Replace(',','_').Replace('\','_') + '_' + $date + '.xlsx'
Export-Excel $excel -ClearSheet

# sql to run the query
$sql = @"
SELECT db_name() as DATABASE_NAME, c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME, sep.value AS DESCRIPTION, c.DATA_TYPE, c.CHARACTER_MAXIMUM_LENGTH, c.IS_NULLABLE 
FROM INFORMATION_SCHEMA.COLUMNS AS c
INNER JOIN sys.columns AS sc ON sc.object_id = object_id(c.TABLE_SCHEMA + '.' + c.TABLE_NAME) AND sc.name = c.COLUMN_NAME
LEFT JOIN sys.extended_properties AS sep ON sc.object_id = sep.major_id and sc.column_id = sep.minor_id and sep.name = 'MS_Description'
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION
"@

# gets database list and executes on each and appends to excel file
$db = Get-SqlDatabase -ServerInstance $instance | Where-Object { ($_.Name -in $Databases -or !$Databases) -and ($_.Name -notin 'master,model,msdb,tempdb') }
foreach ($d in $db) {
     $d.Name
     $data = Invoke-Sqlcmd -ServerInstance $instance -Database $d.Name -Query $sql -OutputAs DataTables
     Export-Excel $excel -InputObject $data -Append
}

"Done" 