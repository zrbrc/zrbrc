# https://learn.microsoft.com/en-us/windows/win32/winrm/installation-and-configuration-for-windows-remote-management

# on server connecting to
# enable winrm if needec
winrm quickconfig

# show config
winrm get winrm/config

# add https listener
winrm quickconfig -transport:https

# on server connecting from
# add all the servers you want to hosts file with full DNS so its 'trusted' and CN matches
xx.xx.xx.xx hostnameC2N1domain.com

#create cred ibject
$cred = Get-Credential

# connect via SSL with domains cert
$option = New-PSSessionOption -SkipCACheck -SkipRevocationCheck
$s = New-PSSession -ComputerName hostnameC2N1domain.com -UseSSL -SessionOption $option -Credential $cred

Invoke-Command -Session $s -ScriptBlock {
    Get-CimInstance -ClassName Win32_Volume | 
        Where-Object Capacity -ge 0 |
        Select-Object DriveLetter, Label, BlockSize, 
        @{n = "Size(GB)"; e = { [math]::Round($_.Capacity / 1GB, 2) } }, 
        @{n = "Free(GB)"; e = { [math]::Round($_.FreeSpace / 1GB, 2) } } | 
        Sort-Object DriveLetter | Format-Table
}