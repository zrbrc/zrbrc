#requires -Module SqlServer

# edit the below lines for target and source scripts
$server = 'xx.xx.xx.xx,15150'
$database = 'DMS_HRPFS_PROD'
$inputfolder = 'C:\Deploy\HRPFS_PROD_Migration20230214_30930\Scripts'


# dont edit anything below here
$errors = $false

$null = Start-Transcript ("{0}\{1}_deploy_log_{2}.txt" -f $inputfolder, $database, (Get-Date -Format 'yyyyMMdd_hhmmss'))

$scripts = Get-ChildItem $inputfolder -Filter "*.sql"

try {

    if ($scripts.Count -eq 0) {
        throw "[!] No .sql scripts found in path: $inputfolder"
    }

    "`n[i] Testing database connectivity ..."
    $null = Get-SqlDatabase -ServerInstance $server -Database $database -ErrorAction Stop
    "`n[i] Connected."

    foreach ($s in $scripts) {
        "`n[+] Starting: {0} ..." -f $s.Fullname
        Invoke-Sqlcmd -ServerInstance $server -Database $database -InputFile $s.Fullname -Verbose -ErrorAction Stop
        "`n[+] Finished: {0}" -f $s.Fullname
    }

}
catch {
    $errors = $true
    $ErrorMessage = $_.Exception.Message
    Write-Output "`n$ErrorMessage`n"
}
finally {
    if ($errors) {
        "[!] ERROR"
    }
    else {
        "[+] COMPLETED"
    }
    $null = Stop-Transcript
}