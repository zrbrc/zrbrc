$ErrorActionPreference = 'Stop'
$backuplog_path = 'E:\mysql_backup_log\'

$backuplog = $backuplog_path + "\backup_log_$(Get-Date -Format 'yyyyMMdd_hhmmss').txt"

Start-Transcript -Path $backuplog

try {
    # set backup config
    $mysqlbackupexe = 'C:\Program Files\MySQL\MySQL Enterprise Backup 8.0\bin\mysqlbackup.exe'
    $backuppath = 'E:\mysql_backup'
	$backupimage = "$backuppath\db_Redcap_TEST_$(Get-Date -Format 'yyyyMMdd_hhmmss').mbi"


    $backupparms = @(
        "--user=Mysql_Backup",
        "--password=<>",
        "--host=xx.xx.xx.xx",
        "--backup-dir=$backuppath\temp",
		"--backup-image=$backupimage",
        "--with-timestamp",
        "backup-to-image"
    )

    "Starting backup ... "
    & $mysqlbackupexe $backupparms
	
	$validateparms = @(
		"--backup-image=$backupimage",
        "validate"
    )
		
	"Verifying backup ... "
	& $mysqlbackupexe $validateparms
	
	if($LASTEXITCODE -ne 0){
		throw
	}

    "Removing old backups ... "
    Get-ChildItem -Path $backuppath -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } | Remove-Item -Force -Recurse
	"done."
	
	"Removing old logs ... "
    Get-ChildItem -Path $backuplog_path -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item -Force -Recurse
	"done."
}
catch {
    Stop-Transcript
    Send-MailMessage -To 'ryan.zerbe@delaware.gov' -From 'dept05sg_SQLAlerts@delaware.gov' -Subject '[!] Redcap Prod Copy Backup Failed' -Body 'Backup failed, check attachment.' -Attachments $backuplog -SmtpServer 'smtp.state.de.us'
}