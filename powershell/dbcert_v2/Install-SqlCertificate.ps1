<#
.SYNOPSIS
    This needs to run on each server for it to work.

    1. creates CSR, submits to CA, imports into the local machine cert store. 
    2. grants permissions to and apply the cert to SQL Server.
    3. ask to restart SQL or you can do later manually.

    Nothing should need to be edited in this script, execute it and let it work.

.EXAMPLE
    PS C:\> .\Install-SqlCertificate.ps1 -Instances PR2022_1 -FriendlyName ss_pr_sql2022_n1
.COMMENTS
    This script tries to do everything dynamically, if it is a cluster, it will try to find all IPs/hostnames for each server and listener to apply to 
    the cert's SAN. It will ask what SQL instance to apply the cert to if there are multiple, just enter the instance name. It will also ask for a friendly name
    that is used in certlm.msc. This is just a nice name, it doesnt matter. You can also supply via the command-line.

#>
param (
    [string]
    $FriendlyName,

    [array]
    $Instances
)

Set-Location $PSScriptRoot
$ErrorActionPreference = 'Stop'
$Today = Get-Date -Format 'yyyyMMdd'

# checks if running as admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    "[!] This script is required to be run as admin, please open powershell as admin and run the script from the command-line."
    Read-Host '::: ENTER ::'
    exit
}

# find all the resources we will need to apply on the cert's SAN
try {
    if (!($PSBoundParameters.ContainsKey('FriendlyName'))) { 
        Write-Host "[?] Please enter a friendly name. This will be the filenames and the name in certman, this is only for easier identification of cert."
        $FriendlyName = Read-Host "?"
    }
    # replace any spaces in the name and add date to end
    $FriendlyName = ($FriendlyName.Replace(' ', '_') + '_' + $Today).ToUpper()

    if ((Get-Command -Name Get-Cluster -ErrorAction SilentlyContinue) -and 
        (Get-Service ClusSvc | Where-Object { $_.Status -eq 'Running' })) {

        # find resources belonging to MSSQL
        $ag_owner = (Get-Cluster | Get-ClusterResource | Where-Object { $_.ResourceType -eq "SQL Server Availability Group" } | Select-Object -ExpandProperty OwnerGroup).Name

        $ag_res = Get-ClusterResource | Where-Object { $_.OwnerGroup -in $ag_owner } 

        $ag_res_name = $ag_res | Where-Object { $_.ResourceType -eq "Network Name" }
        $ag_res_ip = $ag_res | Where-Object { $_.ResourceType -eq "IP Address" }

        $ag_dns = ($ag_res_name | ForEach-Object { ($_ | Get-ClusterParameter -Name DnsName, DnsSuffix | Select-Object -ExpandProperty Value) -join '.' }) -join ','
        $ag_ip = ($ag_res_ip | ForEach-Object { $_ | Get-ClusterParameter -Name Address | Select-Object -ExpandProperty Value }) -join ','

        $local_name = [System.Net.Dns]::GetHostByName($env:computerName).Hostname
        $local_ip = (Resolve-DnsName $local_name -DnsOnly).IP4Address

        # custom object for all individual pieces
        $t = [PSCustomObject]@{
            ServerFqdn  = $local_name
            ServerNaked = $local_name.Split('.')[0]
            AgFqdn      = $ag_dns
            AgNaked     = ($ag_dns.Split(',') | ForEach-Object { $_.Split('.')[0] }) -join ','
            IPs         = $local_ip, $ag_ip -join ','
        }

        # puts them together, FQDN is needed in the SAN too
        $AltDns = ($t.ServerFqdn, $t.ServerNaked, $t.AgFqdn, $t.AgNaked) -join ','
        $StateAltDns = ($local_name.Split('.')[0] + '.domain.com') + ',' + (($ag_dns.Split(',') | ForEach-Object { $_.Split('.')[0] + '.domain.com' }) -join ',')

    }
    else {
        $local_name = [System.Net.Dns]::GetHostByName($env:computerName).Hostname
        $local_ip = (Resolve-DnsName $local_name -DnsOnly).IP4Address

        # custom object for all individual pieces
        $t = [PSCustomObject]@{
            ServerFqdn  = $local_name
            ServerNaked = $local_name.Split('.')[0]
            IPs         = $local_ip
        }

        # puts them together, FQDN is needed in the SAN too
        $AltDns = ($t.ServerFqdn, $t.ServerNaked) -join ','
        $StateAltDns = $local_name.Split('.')[0] + '.domain.com'

    }
    # add domain.com as a default, easier automation
    $AltDns = $AltDns + ',' + $StateAltDns

    $server = [PSCustomObject]@{
        SubjectName = 'CN=' + $t.ServerFqdn
        AltDns      = $AltDns
        AltIp       = $t.Ips
    }
}
catch {
    $_.Exception
    Write-Output "`n`n[!] Failed building SAN list."
    Read-Host "::: ENTER ::" 
    exit
}

# gets the local CA that we'll be creating the cert against
$ca = (((certutil | Select-string "Config" | Select-Object -First 1) -Split ': ')[1]).Trim()

Write-Output "`n`n[=] $FriendlyName starting ..."

try {
    # the is the template file for submitting the CSR to the CA, made it in the code for easier management
    $inf = @"
[Version]
Signature = "`$Windows NT`$"

[NewRequest]
Subject = "$($server.SubjectName)"
KeyLength =  2048
KeySpec = 1
Exportable = True
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12 
MachineKeySet = True
SMIME = False
KeyUsage = 0xA0
FriendlyName = "$FriendlyName"
   
[Strings]
szOID_SUBJECT_ALT_NAME2 = "xx.xx.xx.xx"
szOID_ENHANCED_KEY_USAGE = "xx.xx.xx.xx"
szOID_PKIX_KP_SERVER_AUTH = "xx.xx.xx.xx.xx.xx.xx.xx.1"
szOID_PKIX_KP_CLIENT_AUTH = "xx.xx.xx.xx.xx.xx.xx.xx.2"


[RequestAttributes]
CertificateTemplate = "SQLServer"

[Extensions]
%szOID_ENHANCED_KEY_USAGE% = "{text}%szOID_PKIX_KP_SERVER_AUTH%,%szOID_PKIX_KP_CLIENT_AUTH%"
"@

    # parse the alt dns and alt ip in the syntax that is needed
    if ($server.AltDns -or $server.AltIp) {
        $altname = "`n%szOID_SUBJECT_ALT_NAME2% = `"{text}"
        if ($server.AltDns) {
            $altname += 'DNS=' + ($server.AltDns.Split(',') -join '&DNS=')
            if ($server.AltIp) {
                $altname += '&IPAddress=' + ($server.AltIp.Split(',') -join '&IPAddress=')
            }
        }
        else {
            if ($server.AltIp) {
                $altname += 'IPAddress=' + ($server.AltIp.Split(',') -join '&IPAddress=')
            }
        }
        $altname += '"'
        $inf += $altname
    }

    # save template to create the csr, certreq requires it be on disk
    $inf | Out-File -FilePath ".\$FriendlyName.inf" -Force
    
    # create CSR
    certreq.exe -new -f "$FriendlyName.inf" "$FriendlyName.req"

    # submit CSR and get back the cert
    certreq.exe -submit -f -config $ca "$FriendlyName.req" "$FriendlyName.cer"

    # this puts the public and private keys into the local machine cert store
    $output = certreq.exe -accept "$FriendlyName.cer"

    # find the cert we just accepted into our local machine
    $thumbprint = ($output | Select-String -Pattern 'Thumbprint' | Out-String).Trim().Split(':')[1].Trim()
    $certificate = Get-ChildItem -Path "Cert:\LocalMachine\My\$thumbprint"
        
    Write-Output "`n`n[=] $FriendlyName done."

}
catch {
    $_.Exception
    exit
}

# displays what work was done, can be copied and pasted into the Cert Spreadsheet
if ($certificate) {
    Write-Output "`nCertificate Results, copy into notepad temporarily and then copy ALL into Certificates spreadsheet:"
    [PSCustomObject]@{
        CertificateName        = $certificate.Subject.Split('=')[1]
        Issuer                 = $certificate.Issuer.Split(',')[0].Split('=')[1].Split(' ')[0]
        IssuedDate             = $certificate.NotBefore.ToString("MM/dd/yyyy")
        ExpiryDate             = $certificate.NotAfter.ToString("MM/dd/yyyy")
        Wildcard               = 'NO'
        FriendlyName           = $certificate.FriendlyName
        ImplementationLocation = $local_ip
        Division               = ''
    } | Format-Table | Out-String -Width 500
}
else {
    "Nothing to output, no cert created"
    exit
}

if ($PSBoundParameters.ContainsKey('Instances')) {
    try {
        foreach ($in in $Instances) {
            $sql_service_name = (Get-Service -Name ('MSSQL$' + $in)).Name.ToUpper()
    
            "[+] $sql_service_name"

            $sql_service_name = 'NT Service\' + $sql_service_name

            $cert_path = 'C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys\' + $certificate.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
            if (Test-Path $cert_path) {
                $acl = Get-Acl -Path $cert_path
                $new_perm = $sql_service_name, "Read", "Allow"

                $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $new_perm;
    
                $acl.AddAccessRule($accessRule);

                Set-Acl $cert_path $acl;
                Write-Output "[++] ACL updated";
            }
            
            $reg_key = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*$in\MSSQLServer\SuperSocketNetLib"
            
            # check to see if certficate key exists and then set it
            if (Get-ItemProperty -Path $reg_key.PSPath -Name Certificate) {
                Set-ItemProperty -Path $reg_key.PSPath -Name Certificate -Value $certificate.Thumbprint.ToString().ToLowerInvariant()
                Write-Output "[++] SQL cert set";
            }
            

            # $response = Read-Host "Do you want to restart SQL Server now? (y/N)"
            # if ($response.ToUpper() -eq 'Y') { Get-Service -Name "MSSQL*" | Restart-Service -Force } else { "Not restarting" }
        }
    }
    catch {
        $_.Exception
        "[!] Failed to grant permissions and set cert for to $instance_name."
    }
}
else {
    "No instances passed to apply cert to."
}
