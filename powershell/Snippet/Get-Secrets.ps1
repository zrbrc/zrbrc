$credential = Get-Credential

$securePasswordPath = 'C:\Secrets\securestore.xml'
$credential.Password |  Export-Clixml -Path $securePasswordPath