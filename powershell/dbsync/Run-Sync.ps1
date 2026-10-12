Set-Location $PSScriptRoot

& .\Sync-Login.ps1 -Source 'ip,port' -Destination 'ip,port' -WhatIf -RevokePermissions -SyncPassword