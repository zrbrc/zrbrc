# stop IO service, this will stop GSI and EEP
Get-Service -DisplayName "Univer*IO*" | Where-Object {$_.Status -eq 'Running'} | Stop-Service -PassThru
"io stopped"

# stop remaing services
Get-Service -DisplayName "Univer*" | Where-Object {$_.Status -eq 'Running'} | Stop-Service -PassThru
"rest of services stopped"

# find any still running java processes
Get-Process -Name "java" | Where-Object {$_.Path -like "C:\Program Files\Java\jre*"} | Stop-Process -PassThru
"stopped all java processes"

# do updates here
Get-Service -DisplayName "Univer*IO*" | Start-Service -PassThru
"io started"

do {
    Start-Sleep 1
    $EEPService = Get-Service -DisplayName "Univer*GSI*" | Where-Object {$_.Status -eq 'Running'}
    $GSIService = Get-Service -DisplayName "Univer*EEP*" | Where-Object {$_.Status -eq 'Running'}
} until ($EEPService.count -ne 0 -and $GSIService.count -ne 0)
"eep and gsi started"

Get-Service -DisplayName "Univer*" | Where-Object {$_.Status -ne 'Running'} | Start-Service -PassThru
"rest of services started"

