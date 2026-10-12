<# 

These are the commands MS gives for setting up CAU.

https://learn.microsoft.com/en-us/windows-server/failover-clustering/cluster-aware-updating-requirements

#>

# enable firewall rule, nomt really needed if FW disabled, but add in case FW gets enabled at some point
Set-NetFirewallRule -Group "@firewallapi.dll,-36751" -Profile Domain -Enabled true

# enable WinRM, it should be by default, again, do anyway to make sure
winrm quickconfig -q

# sets some defaults for WinRM to allow PS remoting
Enable-PSRemoting