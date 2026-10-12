$java = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "Java *" -and $_.Publisher -like "Oracle*" }

if ($java.DisplayVersion -like "8.0.301*") {
    "Latest version already installed."
}
else {
    "Installing latest version ..."
    cmd.exe /c "start /wait msiexec /i C:\Users\ryanz\Downloads\jre1.8.0_30164.msi /q"
    $java = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "Java *" -and $_.Publisher -like "Oracle*" }
}

# uninstall not latest version
foreach ($j in $java | Where-Object { $_.DisplayVersion -notlike "8.0.301*" } ) {
    "Removing {0} {1}" -f $j.DisplayName, $j.DisplayVersion
    $uninstallparms = "start /wait $($j.UninstallString) /qn"
    cmd.exe /c $uninstallparms
}

$java = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "Java *" -and $_.Publisher -like "Oracle*" }

$java | Format-List DisplayName, DisplayVersion