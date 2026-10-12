$query = @'
SELECT SUM (user_object_reserved_page_count)*8/1024.0/1024.0 as user_obj_GB,
       SUM (internal_object_reserved_page_count)*8/1024.0/1024.0 as internal_obj_GB,
       SUM (version_store_reserved_page_count)*8/1024.0/1024.0  as version_store_GB,
       SUM (unallocated_extent_page_count)*8/1024.0/1024.0 as freespace_GB,
       SUM (mixed_extent_page_count)*8/1024.0/1024.0 as mixedextent_GB
  FROM sys.dm_db_file_space_usage
'@

if (-not (Get-Item '.\version_store_log.csv')) {
    "datetime,user_obj_GB,internal_obj_GB,version_store_GB,freespace_GB,mixedextent_G" | Out-File '.\version_store_log.csv'
}

while ($true) {

  $o = Invoke-DbaQuery -SqlInstance 'xx.xx.xx.xx,15150' -Database tempdb -Query $query
  "{0},{1},{2},{3},{4},{5}" -f $(Get-Date -Format 'yyyyMMdd_HHmmss'), $o.user_obj_GB, $o.internal_obj_GB, $o.version_store_GB, $o.freespace_GB, $o.mixedextent_GB | Out-File '.\version_store_log.csv' -Append

  Start-Sleep -Seconds 60

}
