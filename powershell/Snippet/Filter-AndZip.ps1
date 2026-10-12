# source folder
$SourceFolder = 'C:\Workspace\DBA\RFC'

# output folder
$DestinationFolder = 'C:\Temp'

# what files
$Filter = '*.sql'

# build zip location
$Zip = $DestinationFolder + '\' + $SourceFolder.Split('\')[-1] + '_' + (Get-Date -Format 'yyyyMMdd_hhmmss') + '.zip'

# check if we already have a file
if (Test-Path $Zip) { Remove-Item $Zip }

# set location so we can get relative path later
Set-Location $SourceFolder

# find the files
$Files = Get-ChildItem -Recurse -Filter $Filter

# instantiate the zip
$Archive = [IO.Compression.ZipFile]::Open($Zip, 'Update')

# add each file
foreach ($f in $Files) {
    $relative = (Resolve-Path -Path $f.FullName -Relative).Replace('.\', '')
    $null = [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Archive, $f.FullName, $relative)
    $relative
}

# close the zip
$Archive.Dispose()