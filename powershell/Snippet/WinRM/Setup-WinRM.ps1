<# 
THIS SHOULD RUN ON LISTENING SERVER

This script will create a domain(CA) signed machine cert and apply it to WinRM HTTPS listener.
#>

#Requires -RunAsAdministrator

$fqdn = [System.Net.Dns]::GetHostByName($null).HostName

$params = @{
    Template          = 'Machine'
    CertStoreLocation = 'Cert:\LocalMachine\My'
    SubjectName       = "CN=$fqdn"
}

try {
    # create cert
    $cert = Get-Certificate @params

    # get thumbprint from cert
    $thumbprint = $cert.Certificate.Thumbprint
    "Certificate created with thumbprint: {0}" -f $thumbprint

    # remove HTTPS listener to recreate with new cert
    if (winrm enumerate winrm/config/listener | Select-String HTTPS) {
        "Deleting HTTPS listener."
        winrm delete winrm/config/Listener?Address=*+Transport=HTTPS
    }

    # create new listener
    "Enabling HTTPS."
    winrm quickconfig -transport:https -quiet
}
catch {
    $_
    "FAILED!"
}

# shows details of cert
Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $thumbprint } | Format-List ThumbPrint, DnsNameList, NotBefore, NotAfter
