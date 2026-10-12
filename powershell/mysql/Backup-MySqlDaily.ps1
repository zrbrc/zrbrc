$ErrorActionPreference = 'Stop'

$now = Get-Date -Format 'yyyyMMdd_hhmmss'

# set config paths
$mysqlbackupexe = 'C:\Program Files\MySQL\MySQL Enterprise Backup 8.0\bin\mysqlbackup.exe'

$basepath = '\\xx.xx.xx.xx\prod\Redcap'

$backuptemp = "$basepath\temp"
$backuppath = "$basepath\backups"

$backuplog_path = "$basepath\logs"
$backuplog = "$backuplog_path\backup_log_$now.txt"

$backupimage = "$backuppath\DPH_Redcap_PROD_$now.mbi"

Start-Transcript -Path $backuplog

try {
    # set backup config
    $backupparms = @(
        "--user=mysqlbackup",
        "--password=<password>",
        "--host=xx.xx.xx.xx",
        "--backup-dir=$backuptemp",
        "--backup-image=$backupimage",
        "--compress",
        "--with-timestamp",
        "backup-to-image"
    )

    "Starting backup ... "
    & $mysqlbackupexe $backupparms
	
    if ($LASTEXITCODE -ne 0) {
        throw "[!] Backup failed."
    }
	
    $validateparms = @(
        "--backup-image=$backupimage",
        "validate"
    )
		
    "Verifying backup ... "
    & $mysqlbackupexe $validateparms
	
    if ($LASTEXITCODE -ne 0) {
        throw "[!] Verification failed."
    }

    "`n[i] Removing old backups and temp files... "
    Get-ChildItem -Path $backuppath -Filter *.mbi | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-5) } | Remove-Item -Force -Recurse -Verbose
    Get-ChildItem -Path $backuptemp -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } | Remove-Item -Force -Recurse -Verbose
    "done."
	
    "`n[i] Removing old logs ... "
    Get-ChildItem -Path $backuplog_path -Directory | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Force -Recurse -Verbose
    "done."
}
catch {
    Send-MailMessage -To 'dept05sg_SQLAlerts@delaware.gov' -From 'dept05sg_SQLAlerts@delaware.gov' -Subject '[!] MySQL Redcap Prod Backup Failed' -Body 'Backup failed, check attachment.' -Attachments $backuplog -SmtpServer 'smtp.state.de.us'
}
finally {
	Stop-Transcript
}