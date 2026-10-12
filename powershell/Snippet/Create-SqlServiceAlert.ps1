<#
Sets Recovery options for SQL Server services to run program on failure. It creates the script to send the alert.

example:
    sc.exe failure 'MSSQL$DE2019' reset= 0 command= 'powershell.exe -ExecutionPolicy Bypass C:\Workspace\RyanZ\posh\snippet\Send-ServiceFailed.ps1' actions= run/1000////
    sc.exe failureflag 'MSSQL$DE2019' 1

#>

$Path = 'M:\Management\Scripts'
$Script = 'Send-SqlServiceAlert.ps1'
$ScriptPath = Join-Path -Path $Path -ChildPath $Script

if (-not (Test-Path $Path )) { New-Item $Path -ItemType Directory }

@'
Set-Location $PSScriptRoot

Start-Transcript -Path '.\log.txt'

$email = @{
    To         = 'Ryan.Zerbe@delaware.gov'
    From       = 'dept05sg_SQLAlerts@delaware.gov'
    Subject    = "SQL Server Alert System: SQL Server services failed on $env:COMPUTERNAME"
    Body       =  Get-Service -Name 'MSSQL*' -Exclude 'MSSQLFDLauncher*' | Select-Object Status, Name, DisplayName | ConvertTo-Html -Fragment -As List | Out-String
    Smtp       = 'smtp.state.de.us'
    BodyAsHtml =  $true
}
Send-MailMessage @email

Write-Output 'Email alert sent.'

Stop-Transcript
'@ | Set-Content -Path $ScriptPath

# get sql services--excludes full-text filter daemon
$MSSQLServices = Get-Service -Name 'MSSQL*' -Exclude 'MSSQLFDLauncher*'

# loop thru services in case there are mulitple instances installed
foreach ($Service in $MSSQLServices) {
    # set failure action
    sc.exe failure $Service.Name reset= 0 command= "powershell.exe -ExecutionPolicy Bypass $ScriptPath" actions= run/1000////

    # verify setting
    sc.exe qfailure $Service.Name
    
    # set failure action on error
    sc.exe failureflag $Service.Name 1

    # verify setting
    sc.exe qfailureflag $Service.Name
}