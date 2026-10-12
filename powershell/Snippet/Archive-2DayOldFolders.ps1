$folders = Get-ChildItem . -Directory | Where-Object {$_.CreationTime -lt (Get-Date).AddDays(-2) -and $_.BaseName -ne 'archive'}

foreach ($folder in $Folders) {
    Compress-Archive -Path $folder.FullName -DestinationPath ".\archive\$($folder.BaseName).zip"
}