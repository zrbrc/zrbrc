$username = '1'
$password = '2'
$schema = '3'
$basePath = 'D:\appdba'
$scriptPath = "$basePath\DBScripts\Scripts"
$LogPath = "$basePath\DBScripts\Logs"
$schemaName = 'UAT1_IAU'
$vEnvironment = 'Test'
# $experror = 0

if (!$username -or !$password -or !$schema) {
    Write-Output "username password schema is missing"
    exit
}

Set-Location $scriptPath

# call env.bat
$env:ORACLE_BASE = 'D:\app'
$env:oracle_home = 'D:\app\DBHOME'
$env:oracle_sid = 'TESTIAM1'

$timestamp = Get-Date -Format 'yyyyMMdd_hhmmss'

$logFile = "db_IAM_DBA_USER_UAT1_IAU_auditDeleteData_wrapper_$timestamp.log"

Start-Transcript -Path "$LogPath\$logFile"

sqlplus $username/$password "$scriptPath\auditDeleteData_wrapper.sql" $schema

Stop-Transcript

$emailsplat = @{
    To          = 'john.kozel@delaware.gov'
    From        = 'oradba@delaware.gov'
    Subject     = "Completed!! $vEnvironment Purge job successful for schema $schemaName."
    Body        = "This is an automated mail. Attached please find purge job details for schema $schemaName in $vEnvironment Environment."
    Attachments = "$LogPath\$logFile"
    SmtpServer  = 'smtp.state.de.us'
}

Send-MailMessage @emailsplat