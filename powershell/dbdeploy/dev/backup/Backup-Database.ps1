
Set-Location $PSScriptRoot
Start-Transcript -Path '.\backup.log'

$emailsplat = @{
    To         = "$env:USERNAME" + '@delaware.gov'
    From       = 'dept05sg_SQLAlerts@delaware.gov'
    SmtpServer = 'smtp.state.de.us' 
}

try {
    $Backups = Get-Content -Path '.\backup.json' | ConvertFrom-Json
}
catch {
    Write-Output "File 'backup.json' cannot be found, please rename the correct environment file to 'backup.json'."
    Read-Host "= = = ENTER = = ="
    exit
}

if (Get-Module -Name sqlserver -ListAvailable) {
    Import-Module sqlserver
}
else {
    Write-Output "Module 'sqlserver' not found--please install and re-run."
    Read-Host "= = = ENTER = = ="
    exit
}

Write-Output "Backing up database(s):"
$Backups.Database

$StartTime = Get-Date
try {
    $jobs = @()
    foreach ($Backup in $Backups) {
        $jobs += Start-Job -Name $Backup.Name -ArgumentList $Backup -ScriptBlock {
            param($Backup)
            $ProgressPreference = 'SilentlyContinue'
            foreach ($Database in $Backup.Database) {
                $BackupFile = "$($Backup.BackupPath)\$Database.bak"
                $BackupSplat = @{
                    ServerInstance    = $Backup.Instance
                    Database          = $Database
                    BackupFile        = $BackupFile
                    # Incremental       = $true
                    Initialize        = $true
                    Checksum          = $true
                    CompressionOption = 'On'
                    ErrorAction       = 'Stop'
                    Verbose           = $true
                }
                Write-Output "`nBackup: $Database ..."
                $BackupSplat | Format-Table -HideTableHeaders
                Backup-SqlDatabase @BackupSplat

                $VerifySplat = @{
                    ServerInstance = $Backup.Instance
                    Query          = "RESTORE VERIFYONLY FROM DISK=N'$BackupFile' WITH CHECKSUM"
                    Verbose        = $true
                }
                Write-Output "`nValidate backup: $Database ..."
                $VerifySplat | Format-Table -HideTableHeaders
                Invoke-Sqlcmd @VerifySplat
            }
        }
    }

    Write-Output "`nJobs submitted, waiting for completion ..."

    # wait for jobs to finish
    $jobs | Wait-Job | Out-Null

    # checks for failed jobs and send email about them if so
    $errorbody = foreach ($job in $jobs | Where-Object { $_.State -eq 'Failed' }) {
        $job | Receive-Job -ErrorVariable JobError

        [PSCustomObject]@{
            Name   = $job.Name
            State  = $job.State
            Output = ($JobError.Exception | Out-String)
        }
    }

    if ($errorbody) {
        Send-MailMessage @emailsplat -Subject 'Backup Job Error' -Body ($body | Format-List | Out-String).Trim("`n|`r")
        Write-Output "Abort email sent."
    }
    else {
        Send-MailMessage @emailsplat -Subject 'Backups Completed' -Body '<EOM>'
    }
    
    $jobs | Receive-Job
    $jobs | Format-Table
    
    $EndTime = Get-Date
    $Elapsed = "{0:n2}" -f (New-TimeSpan -Start $StartTime -End $EndTime).TotalMinutes
    Write-Output "Backups too $Elapsed minutes."
}
catch {
    $Exception = $_
    Write-Output $Exception
    Send-MailMessage @emailsplat -Subject 'Backup Error' -Body ($Exception | Out-String)
}
Read-Host "= = = ENTER = = ="
