$splat = @{
    Type              = 'SSLServerAuthentication'
    Subject           = "CN=$([System.Net.Dns]::GetHostByName($env:computerName).HostName)"
    FriendlyName      = 'SQL Server SELF-SIGNED'
    DnsName           = "$([System.Net.Dns]::GetHostByName($env:computerName).HostName)", 'localhost.'
    KeyAlgorithm      = 'RSA' 
    KeyLength         = 2048 
    Hash              = 'SHA256'
    TextExtension     = 'xx.xx.xx.xx={text}xx.xx.xx.xx.xx.xx.xx.xx.1'
    NotAfter          = (Get-Date).AddMonths(36)
    KeySpec           = 'KeyExchange'
    Provider          = 'Microsoft RSA SChannel Cryptographic Provider'
    CertStoreLocation = 'Cert:\LocalMachine\My'
}

$splat
New-SelfSignedCertificate @splat