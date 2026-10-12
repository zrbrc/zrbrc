<# 
This code was generated via the WinSCP GUI, comments added by us.

This is a basic put script, you need to fill in HostName, Portnumber, UserName, Password, and SshHostKeyFingerprint
and then paths near the bottom for what files to send/receive, variablize them if you want for easier management.

There are a lot more examples for different operations at this below links:

https://winscp.net/eng/docs/library_powershell#example 
and
https://winscp.net/eng/docs/library_examples

#>

# Load WinSCP .NET assembly
Add-Type -Path "WinSCPnet.dll" # might need to specify whole path

# log the powershell commands
Start-Transcript "M:\log\path\log.txt" -Append -UseMinimalHeader

# Set up session options
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Sftp
    HostName = host.domain.com
    SshHostKeyFingerprint = "" # need to know this: https://winscp.net/eng/docs/faq_hostkey
    PortNumber = 22
    UserName = "username"

    # use either or here, key pair or password, comment out which not using
    SshPrivateKeyPath = "M:\Secrets\private_key.ppk"
    PrivateKeyPassphrase = "xxxxxxx"
    # or
    Password = "password"
}
$sessionOptions.AddRawSettings("TryAgent", "0")
$sessionOptions.AddRawSettings("AuthKI", "0")
$sessionOptions.AddRawSettings("AuthKIPassword", "0")
$sessionOptions.AddRawSettings("Compression", "1")

$session = New-Object WinSCP.Session
$session.SessionLogPath = "M:\log\path\sftp.txt" # log the sftp commands

# this may or may not be needed, depends on the sftp server, the first one I tried wouldnt allow the client to set date/time and perms
$transferOptions = New-Object WinSCP.TransferOptions -Property @{
    FilePermissions = $Null
    PreserveTimestamp = $False
}

try
{
    # Connect
    $session.Open($sessionOptions)

    # Transfer files
    $session.PutFiles("M:\path\file.txt", "/remote/path/*", $false ,$transferOptions).Check()
    
}
finally
{
    $session.Dispose()
}
