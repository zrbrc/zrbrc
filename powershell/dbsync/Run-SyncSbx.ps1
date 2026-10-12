Set-Location $PSScriptRoot

& .\Sync-Login.ps1 -Source 'hostnameCLSN1,15150' -Destination 'hostnameCLSN2,15150' -WhatIf -RevokePermissions -SyncPassword