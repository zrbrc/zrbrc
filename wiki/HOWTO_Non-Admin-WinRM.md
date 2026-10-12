# Non-Admin WinRM

#### Check which groups are allowed to remote

    (Get-PSSessionConfiguration -Name Microsoft.PowerShell).Permission

#### Add needed user to local group:

    BUILTIN\Remote Management Users

#### Run this command and grant Execute(Invoke) to 'Remote Management Users'. It should already be listed if it was listed in step 1. Just add the needed permissions.

    Set-PSSessionConfiguration -Name Microsoft.PowerShell -showSecurityDescriptorUI