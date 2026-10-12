$DateStamp = Get-Date -Format 'yyyyMMdd'
$TimeStamp = Get-Date -Format 'yyyyMMdd_HHmmss'

$ReqName = (Get-Item -Path $RequestFile).BaseName

$RefreshRootDated = $WorkingPath + '\refresh\' + $DateStamp

$LogPath = $RefreshRootDated + '\log\'
$LogFile = $LogPath + $ReqName + '_' + $TimeStamp + '.txt'

if (-not (Test-Path $LogPath -PathType Container)) { $null = New-Item -Path $LogPath -ItemType Directory }