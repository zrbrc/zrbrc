# Create a cert for local server
$fqdn = [System.Net.Dns]::GetHostByName($null).HostName

$params = @{
    Template          = 'Machine'
    CertStoreLocation = 'Cert:\LocalMachine\My'
    SubjectName       = "CN=$fqdn"
}

# create cert
$cert = Get-Certificate @params  

# get thumbprint from cert
$thumbprint = $cert.Certificate.Thumbprint

# show listener config
# winrm enumerate winrm/config/listener

# you need to recreate listener with new cert thumbprint
# drop existing
winrm delete winrm/config/Listener?Address=*+Transport=HTTPS

# create new listener
$WinrmCreate = "winrm create --% winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=`"$fqdn`";CertificateThumbprint=`"$thumbprint`"}"
Invoke-Expression $WinrmCreate


# find the servers valid cert
Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $thumbprint } | Format-List *
