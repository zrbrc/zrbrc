$installed = Get-InstalledModule

foreach ($mod in $installed) {
    Update-Module $mod -Force

    $latest = Get-InstalledModule -Name $mod.Name

    $all = Get-InstalledModule -Name $mod.Name -AllVersions

    $all | Where-Object { $_.Version -ne $latest.Version } | Uninstall-Module -Verbose #-WhatIf
}