$Desktop = $env:USERPROFILE + "\OneDrive - STATE OF DELAWARE\Desktop"
$ProgramFiles = 'C:\Program Files (x86)'

$ShellRunasExe = "$env:APPDATA\ShellRunas.exe"

Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/ShellRunas.zip' -OutFile "$Desktop\ShellRunas.zip"
Expand-Archive "$Desktop\ShellRunas.zip" -DestinationPath $env:APPDATA -Force
Remove-Item "$Desktop\ShellRunas.zip"

Write-Output "Finding ssms.exe give me a minute ..."
$SsmsExe = (Get-ChildItem -Path $ProgramFiles -Filter 'ssms.exe' -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1).FullName
Write-Output "Found SSMS: $SsmsExe"

$shell = New-Object -ComObject ("WScript.shell")

$lnk = $Shell.CreateShortcut($env:USERPROFILE + "\OneDrive - STATE OF DELAWARE\Desktop\ShellRunas-SSMS.lnk")

$lnk.TargetPath = $ShellRunasExe
$lnk.Arguments = "/netonly ""$SsmsExe"""
$lnk.WorkingDirectory = (Split-Path -Path $SsmsExe -Parent)
$lnk.WindowStyle = 1
$lnk.IconLocation = "$SsmsExe, 0"
$lnk.Description = "Runs SSMS for dom"

$lnk.Save()
