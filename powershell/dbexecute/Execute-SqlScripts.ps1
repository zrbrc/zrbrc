<# 

This will execute scripts in a folder sorted by name, make sure filenames have 
leading zeros (if needed) or it will probably execute in the wrong order.
This will not look in subfolders. If you to need to execute in a bunch of folders,
just do a folder at a time via this script.

#>
#requires -Module SqlServer
Set-Location $PSScriptRoot

# edit the below lines for target and source scripts
$instance = 'xx.xx.xx.xx,15150'
$database = 'DATABASE_NAME_TEST'
$inputfolder = 'M:\Management\Scripts\...'

# dont edit anything below here
Start-Transcript ("{0}\{1}_deploy_log_{2}.txt" -f $inputfolder, $database, (Get-Date -Format 'yyyyMMdd_hhmmss'))

$scripts = Get-ChildItem $inputfolder -Filter "*.sql" -File

try {

    if ($scripts.Count -eq 0) {
        throw "[!] No .sql scripts found in path: $inputfolder"
    }

    "`n[i] Testing database connectivity ..."
    $null = Get-SqlDatabase -ServerInstance $instance -Database $database -ErrorAction Stop
    "`n[i] Connected."

    foreach ($s in $scripts | Sort-Object Name ) {
        "`n[+] Starting: {0} ..." -f $s.Fullname
        Invoke-Sqlcmd -ServerInstance $instance -Database $database -InputFile $s.Fullname -Verbose -ErrorAction Stop
        "`n[+] Finished: {0}" -f $s.Fullname
    }

}
catch {
    $ErrorMessage = $_.Exception.Message
    $ErrorMessage
    throw
}
Stop-Transcript