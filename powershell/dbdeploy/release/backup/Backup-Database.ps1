
Set-Location $PSScriptRoot
$timestamp = Get-Date -Format FileDateTime
Start-Transcript -Path ".\backup_$timestamp.log"

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
    Read-Host "::: ENTER ::"
    exit
}

if (Get-Module -Name dbatools -ListAvailable) {
    Import-Module sqlserver
}
else {
    Write-Output "Module 'dbatools' not found, please install and re-run."
    Read-Host "::: ENTER ::"
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
                
                Write-Output "`n ### B A C K U P  :  $Database"

                $BackupSplat = @{
                    SqlInstance  = $Backup.Instance
                    Database        = $Database
					Path            = $Backup.BackupPath
                    FilePath        = 'dbname.bak'
					Type            = 'Full'
                    Initialize      = $true
                    Checksum        = $true
                    CompressBackup  = $true
                    FileCount       = 4
                    Verify          = $true
                    EnableException = $true
                    CopyOnly        = $true
                }
				
				Backup-DbaDatabase @BackupSplat
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
        Send-MailMessage @emailsplat -Subject 'Backup Job Error' -Body ( $errorbody | Format-List | Out-String ).Trim("`n|`r")
        Write-Output "Abort email sent."
    }
    else {
        Send-MailMessage @emailsplat -Subject 'Backups Completed' -Body '<EOM>'
    }
    
    $jobs | Receive-Job
    $jobs | Format-Table
    
    $EndTime = Get-Date
    $Elapsed = "{0:n2}" -f ( New-TimeSpan -Start $StartTime -End $EndTime ).TotalMinutes
    Write-Output "Backups took $Elapsed minutes."
}
catch {
    $Exception = $_
    Write-Output $Exception
    Send-MailMessage @emailsplat -Subject 'Backup Error' -Body ($Exception | Out-String)
}
Read-Host "::: ENTER ::"
