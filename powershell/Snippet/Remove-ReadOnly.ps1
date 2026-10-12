# will remove read-only from all files below current folder
Get-ChildItem -Recurse -File | % { Set-ItemProperty $_.FullName -Name IsReadOnly -Value $false }