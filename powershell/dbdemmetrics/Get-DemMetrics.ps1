Set-Location $PSScriptRoot

$date = Get-Date -Format 'yyyyMMdd'

$environment = ('uat3').ToUpper()

$temppath = ".\temp"
if (-not (Test-Path $temppath -PathType Container)) { $null = New-Item -Path $temppath -ItemType Directory }

$outputpath = ".\output\$environment"
if (-not (Test-Path $outputpath -PathType Container)) { $null = New-Item -Path $outputpath -ItemType Directory }


$config = Get-Content '.\config.json' | ConvertFrom-Json

$sqlfiles = Get-ChildItem ".\sql\$environment" -Filter "*.sql" -Recurse

foreach ($f in $sqlfiles | Select-Object -first 10) {

    $Instance = ($config | Where-Object { $_.Name -eq ($f.DirectoryName).Split('\')[-1] }).Instance

    $output = "$outputpath\Metrics_" + $environment + '_' + $f.BaseName + '_' + $date + '.txt'

    Invoke-Sqlcmd -ServerInstance $Instance -InputFile $f.FullName | Out-File -FilePath $output -Encoding utf8 -Force
}

$zipfile = $temppath + "\DEM_Metrics_" + $environment + '_' + $date + '.zip'

Compress-Archive -Path "$outputpath\*" -DestinationPath $zipfile

Send-MailMessage -To 'ryan.zerbe@delaware.gov' -From 'do_not_reply@delaware.gov' -Subject "DEM Metrics $date $environment" -Attachments $zipfile -Body "<EOM>" -SmtpServer 'smtp.state.de.us'

