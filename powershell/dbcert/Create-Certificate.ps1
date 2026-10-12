<#
.SYNOPSIS
    This script creates a CSR, submits to CA, gets back cert and then imports into the local machine cert store to marry the public and private keys. 
    It then exports it to a password protected PFX file to bring to another server. You are prompted for password to use when it runs.
    This needs to be run in the dom* domains for the domain you need it for.

    Nothing should need to be edited in this script, execute it and point it at the json file you need to create scripts for.

.EXAMPLE
    PS C:\> .\Create-Certificate.ps1 -ServerFile .\SBX.txt

.INPUTS
    The input file is a json file with server detials to be set on the cert. Entries can be commented out with a '#'.

.COMMENTS
	CA Template (mandatory), should be no reason to change, and it set below instead of the input file: 
    Example: SqlServer

    This is what template to use from the CA. The template name has no spaces, so certman gui shows Sql Server, but here it needs to be
    SqlServer, other templates might require investigation, only this one has been tested and we have authority to use. You can run this command at the prompt to 
    get a list of templates, the unusable templates will say 'ACCESS IS DENIED'.

    In dom use the below command to list the templates.

    $> Certutil -config "deptdc03domain.comdomain.comDC03-CA" -catemplates

    JSON Properties, this describes the properties on the input file.
        SubjectName (mandatory):
            Example: CN=host.domain.com
                This is the Common Name.
        AltDns (optional):
            Example: hostname1,hostname2,hostname3.domain.com
                These are the alternate DNS Names that you want added to the cert, they are comma seperated. You should have the hostname, FQDN and naked; and any listeners, FQDN and naked.
        AltIp (optional):
            Example: xx.xx.xx.xx,xx.xx.xx.xx
                Just like AltDns, but for IPs, this can be used for server IP, listener IP, etc
        FriendlyName (mandatory):
            Example: TEST_SQL_NODE1
                This is the friendly name that shows in certman.

.OUTPUTS
    A bunch of files; csr, rsp, cer, pfx; outputs to certs sub-folder

.NOTES
    Sample setup for the Sandbox Sql cluster and all the AltdNS AltIp that is used with the cert.

    SQL Server Sandbox:
        Node 1:
        	Subject:
        		hostnamec2n1domain.com
        	AltDns:
        		hostnamec2n1
        		hostnamec2n1domain.com
        		hostnamec2l1
        		hostnamec2l1domain.com
        	AltIp:
        		xx.xx.xx.xx
        		xx.xx.xx.xx
                
    The above ends up looking like this in the servers json input file:

        "SubjectName":  "CN=hostnamec2n1domain.com",
        "AltDns":  "hostnamec2n1,hostnamec2n1domain.com,hostnamec2l1,hostnamec2l1domain.com",
        "AltIp":  "xx.xx.xx.xx,xx.xx.xx.xx",
        "FriendlyName":  "SBX_2022_C2N1_AG1"

#>
param (
    [ValidateScript( { Test-Path $_ } )]
    [String]
    $ServerFile
)
Set-Location $PSScriptRoot
$ErrorActionPreference = 'Stop'

# checks if running as admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    "[!] This script is required to be run as admin, please open powershell as admin and run the script again."
    Read-Host '::: ENTER ::'
    exit
}

# checks if serverfile is passed else asks for it
if (-not $PSBoundParameters.ContainsKey('ServerFile')) {
    $f = Read-Host "Server file: "
    $ServerFile = Get-Item $f
}

# reads serverfile
try {
    $servers = Get-Content $ServerFile | Select-String '^[\s]*[#]' -NotMatch | ConvertFrom-Json
}
catch {
    $_.Exception
    Write-Output "`n`n[!] Failed getting $ServerFile"
    Read-Host "::: ENTER ::" 
    exit
}

# checks data in serverfile
if ($servers.count -eq 0) { 
    Write-Output "`n`n[!] Nothing found in $ServerFile" 
    Read-Host "::: ENTER ::" 
    exit 
}

# creates cert folder if not exist
if (-not (Test-Path -Path '.\certs')) { $null = New-Item -Path '.\certs' -ItemType Directory }

# gets the local CA that we'll be creating the cert against
$ca = (((certutil | Select-string "Config" | Select-Object -First 1) -Split ': ')[1]).Trim()

# set cert password
$securepw = Read-Host -Prompt "Set certificate password" -AsSecureString

# keeps a list of our work so we can output at the end
$certlist = @()

# loop thru the server list and does the work
foreach ($server in $servers) {

    Write-Output "`n`n[=] $($server.FriendlyName) starting ..."

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
FriendlyName = "$($server.FriendlyName)"
   
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
        $inf | Out-File -FilePath ".\Certs\$($server.FriendlyName).inf" -Force
    
        # create CSR
        certreq.exe -new -f "certs\$($server.FriendlyName).inf" "certs\$($server.FriendlyName).req"

        # submit CSR and get back the cert
        certreq.exe -submit -f -config $ca "certs\$($server.FriendlyName).req" "certs\$($server.FriendlyName).cer"

        # this puts the public and private keys into the local machine cert store
        $output = certreq.exe -accept "certs\$($server.FriendlyName).cer"

        # find the cert we just accepted into our local machine
        $thumbprint = ($output | Select-String -Pattern 'Thumbprint' | Out-String).Trim().Split(':')[1].Trim()
        $certificate = Get-ChildItem -Path "Cert:\LocalMachine\My\$thumbprint"
        
        # export the cert so we can take to server
        $certpath = ".\certs\$($server.FriendlyName).pfx"
        $null = Export-PfxCertificate -Cert $certificate -FilePath $certpath -Password $securepw -Force
        $certlist += $certificate

        Write-Output "`n`n[=] $($server.FriendlyName) done."

    }

    catch {
        $_.Exception
        continue
    }
}

# displays what work was done, can be copied and pasted into the Cert Spreadsheet
if ($certlist) {
    Write-Output "`nResults:"
    $certlist | ForEach-Object {
        [PSCustomObject]@{
            CertificateName        = $_.Subject.Split('=')[1]
            Issuer                 = $_.Issuer.Split(',')[0].Split('=')[1].Split(' ')[0]
            IssuedDate             = $_.NotBefore.ToString("MM/dd/yyyy")
            ExpiryDate             = $_.NotAfter.ToString("MM/dd/yyyy")
            Wildcard               = if ($_.Subject.Split('=')[1] -eq '*') { "YES" } else { "NO" }
            IntendedPurpose        = $_.FriendlyName
            ImplementationLocation = $_.Subject.Split('=')[1]
            Division               = ''
        }
    } | Format-Table | Out-String -Width 500
}
else {
    "Nothing to output."
}

Read-Host "::: ENTER ::"