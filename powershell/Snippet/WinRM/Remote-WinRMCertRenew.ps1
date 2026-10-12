<# 
This will remote to a server(s) and recreate the WinRM HTTPS listener with a new cert. 
You will get dropped momentarily, but it will reconnect and validate the cert was applied.
#>

$servers = @(
    'hostnamec2n2domain.com'
)

foreach ($s in $servers) {
    # setup the connect
    try {
        $option = New-PSSessionOption -SkipCNCheck -SkipRevocationCheck
        
        if ($session) { Remove-PSSession $session }

        if (!$cred) { $cred = Get-Credential }

        $session = New-PSSession -ComputerName $s -UseSSL -SessionOption $option -Credential $cred

        Invoke-Command -Session $session -ArgumentList $cred -ScriptBlock {
            try {
                # get server FQDN
                $fqdn = [System.Net.Dns]::GetHostByName($null).HostName
                $fqdn

                # find thumbprint for WinRM HTTPS
                $thumbprint = (((winrm enumerate winrm/config/listener | Select-String 'CertificateThumbprint = ') -split ' = ')[1]) -replace ' ', ''

                $winrm_cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $thumbprint -and $_.Subject -eq ("CN=$fqdn") }
                "Current WinRM: {0}" -f $winrm_cert.Thumbprint

                if ($winrm_cert.NotAfter -lt (Get-Date).AddDays(+300)) {

                    "creating cert"
                    $subjectname = "CN=" + $fqdn
                    $using:cred
                    $subjectname

                    Get-Certificate -Template Machine -CertStoreLocation 'Cert:\LocalMachine\My' -SubjectName $subjectname -Verbose -Credential $Using:cred
                    "created cert"

                    # get thumbprint from cert
                    $thumbprint = $cert.Certificate.Thumbprint
                    "Certificate created with thumbprint: {0}" -f $thumbprint

                    Start-Job -ScriptBlock {
                        "Deleteing HTTPS listener."
                        winrm delete winrm/config/Listener?Address=*+Transport=HTTPS
                        
                        "Creating HTTPS listener."
                        winrm quickconfig -transport:https -quiet
                    }
                }
                "resumed"
            }
            catch {
                "FAILED in INVOKE"
            }
        }
    }
    catch {
        $_
    }

}
