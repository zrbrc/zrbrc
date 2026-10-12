$dt = [datetime]"01/01/2020"

$olds = Get-ADComputer -Filter ('(OperatingSystem -Like "*SERVER*") -AND (PasswordLastSet -lt $dt)') -prop *

$olds | Select-Object Name,IPv4Address,OperatingSystem,PasswordLastSet,LastLogonDate,Deleted, DistinguishedName | ft

$olds | Export-Csv .\Desktop\olds.csv