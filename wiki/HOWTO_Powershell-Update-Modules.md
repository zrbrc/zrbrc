# Updating Powershell Modules

## PackageManagement and PowerShellGet

If you are having issues installing Powershell modules, there could be a couple things going on. To fix this, we will try a couple steps to get updates so we can install the newer module that helps install other modules. During the process, whenever you are prompt for permission to install something, just say A or Y.

1. Open elevated Powershell prompt and set Tls version and execution policy.

       [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
       Set-ExecutionPolicy RemoteSigned

1. Check if PowerShell see's the proxy setting. The first command should not be blank and you should see our delaware.gov proxy. You can run the second command to verify Powershell can get to the internet.

       netsh winhttp show proxy
       Invoke-WebRequest https://www.bing.com

1. Check installed versions of PacakageManagement and PowerShellGet. The default versions are xx.xx.xx.xx and if you dont have a newer version, we need to update.

       Get-Module PackageManagement,PowerShellGet -ListAvailable

   ![versions](.//media/poshupdate/version1.png)

1. Install Nuget PackageProvider.

       Install-PackageProvider Nuget –Force –Verbose

1. Exit elevated prompt and re-open elevated prompt. Adding the Nuget requires a restart of the session.

1. Install new PowerShellGet. Once you get the new PowershellGet installed, you shouldnt need to set it for Tls12 anymore.

       [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
       Install-Module –Name PowerShellGet –Force -AllowClobber

1. Check installed versions again, you should now see other versions besides xx.xx.xx.xx.

       Get-Module PackageManagement,PowerShellGet -ListAvailable

   ![versions](.//media/poshupdate/version1.png)

1. Exit elevated prompt and re-open a normal prompt.

1. You should now be able to install a regular module.

       Install-Module ImportExcel -Scope CurrentUser