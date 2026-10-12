Set-Location $PSScriptRoot

$ErrorActionPreference = 'Stop'

$log = ".\log\copy_log_$(Get-Date -Format 'yyyyMMdd_hhmmss').txt"

$emailsplat = @{
    From       = 'dept05sg_SQLAlerts@delaware.gov'
    To         = 'dept05sg_SQLAlerts@delaware.gov'
    SmtpServer = 'smtp.state.de.us' 
}
Start-Transcript -Path $log

$failed = $false

"`n`n = = =  B A C K U P  C O P Y  A N D  C L E A N U P  = = =`n`n"

"Some of these source paths dont exist, but are added as sources to handle cluster primary/secondary replicas"

# For SS/PSS, Assist(WW, Forces, Liheap, POC), MCI/DICER
$backup_paths = @'
local,network
\\hostname10N1\dbbackup$\hostname10$AG2022_1,\\xx.xx.xx.xx\dbbackup\pr\hostname10\hostname10$AG2022_1
\\hostname10N2\dbbackup$\hostname10$AG2022_1,\\xx.xx.xx.xx\dbbackup\pr\hostname10\hostname10$AG2022_1
\\hostname1N1\dbbackup$\hostname1N1$PR2016_1,\\xx.xx.xx.xx\dbbackup\pr\hostname1\hostname1N1$PR2016_1
\\hostname1N1\dbbackup$\hostname1$AG2016_1,\\xx.xx.xx.xx\dbbackup\pr\hostname1\hostname1$AG2016_1
\\hostname1N1\dbbackup$\hostname1$AG2016_2,\\xx.xx.xx.xx\dbbackup\pr\hostname1\hostname1$AG2016_2
\\hostname1N3\dbbackup$\hostname1N3$PR2016_3,\\xx.xx.xx.xx\dbbackup\pr\hostname1\hostname1N3$PR2016_3
\\hostname1N3\dbbackup$\hostname1$AG2016_1,\\xx.xx.xx.xx\dbbackup\pr\hostname1\hostname1$AG2016_1
\\hostname1N3\dbbackup$\hostname1$AG2016_2,\\xx.xx.xx.xx\dbbackup\pr\hostname1\hostname1$AG2016_2
\\hostmcidbc7n1\dbbackup$\hostmcidbc7$AG2019_1,\\xx.xx.xx.xx\dbbackup\pr\hostmcidbc7\hostmcidbc7$AG2019_1
\\hostmcidbc7n2\dbbackup$\hostmcidbc7$AG2019_1,\\xx.xx.xx.xx\dbbackup\pr\hostmcidbc7\hostmcidbc7$AG2019_1
'@

$start_time = Get-Date 

$copied = @()

$backup_paths = $backup_paths | ConvertFrom-Csv

try {
    foreach ($bp in $backup_paths) {

        "`nChecking: {0}" -f $bp.local

        if (Test-Path $bp.local) {

            $local_files = Get-ChildItem -Path $bp.local -Filter *.bak -Recurse
        
            # copy files from local to network
            if ($local_files) {
                foreach ($lf in $local_files) {
                    
                    $destination = $lf.FullName.Replace($bp.local, $bp.network)
                    
                    # if the destination file exists and file size matches, not going to recopy, we are letting Ola do cleanup, so they will exist until Ola removes them
                    if (Test-Path $destination) {
                        $df = Get-Item $destination
                        if ($lf.Length -eq $df.Length) {
                            "`n`tDestination exists and matches, skipping: {0}" -f $df.FullName
                            continue
                        }
                    }
                    
                    "Copy: {0}`n  to: {1}" -f $lf, $destination

                    $file = $null
                    $file = Copy-Item -Path $lf.FullName -Destination $destination -PassThru
                        
                    if ($file) {
                        $copied += $file.Name
                    }
                    else {
                        "[!] Failed!"
                    }
                }
            }
        }
        else {
            "`nSource path does not exist, skipping {0}.`n" -f $bp.local
            continue
        }
    }

    if ($copied.Count -gt 0) {
        "`nSummary: These files were copied to network:"
        $copied
    }
    else {
        "No files where copied."
    }
    
    "`nChecking FULL and DIFF network backup folders, if they are older than 7 days, they will be deleted."
    foreach ($nbp in $backup_paths | Sort-Object Network -Unique) {

        $folders = Get-ChildItem -Path $nbp.Network -Directory -Filter FULL -Recurse | Select-Object FullName
        $folders += Get-ChildItem -Path $nbp.Network -Directory -Filter DIFF -Recurse | Select-Object FullName

        foreach ($f in $folders) {
            "Searching: {0}" -f $f.FullName

            $bak_files = Get-ChildItem $f.FullName -Filter *.bak -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }

            $bak_files.Name
            $bak_files | Remove-Item
        }
    }
}
catch {
    $_
    $failed = $true
}
finally {

    $stop_time = Get-Date

    "Duration: {0}" -f ($stop_time - $start_time).ToString("hh\:mm\:ss")

    Stop-Transcript

    if ($failed) { $subject = "[!] Alert: EL2 Backup Copy Failed" } else { $subject = "[i] EL2 Backup Copy Completed" }

    # Send-MailMessage @emailsplat -Subject $subject -Body "Please find log attached." -Attachments $log
}