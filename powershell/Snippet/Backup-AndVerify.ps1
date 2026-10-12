$Database = 'empty'
$BackupFile = "$($database)_$(Get-Date -Format 'yyyyMMdd_HHmmss').bak"

# backup and verify
Backup-SqlDatabase -ServerInstance 'xx.xx.xx.xx,15150' -Database $Database -BackupFile "M:\Temp\$BackupFile" -Initialize -CompressionOption On -Checksum
Invoke-Sqlcmd -ServerInstance 'xx.xx.xx.xx,15150' -Verbose -Query "RESTORE VERIFYONLY FROM DISK=N'M:\Temp\$BackupFile' WITH CHECKSUM"