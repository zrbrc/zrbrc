<#
.SYNOPSIS
    Updates Java on remote server 
.DESCRIPTION
    This will update java on a rewmotge server, but it still needs to be in the same subnet. Update line 19 with $msi_path
    to the local path for the MSI that the remote server will copy and then update with. It will use c:\temp on the remote server.
    Edit $servers for what servers will be updated. These need to be with-in all subnet due to network resttrictions. FQDN is required
    for the remote shell to work.
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
$msi = 'microsoft-jdk-11.0.30-windows-x64.msi'
$latest_version = '11.0.30'
$msi_path = 'D:\Setup\java\' + $msi

$servers = @(
    'hosteligwb04domain.com',
    'hosteligwb03domain.com',
    'hostsftp01domain.com',
    'hosteligap25domain.com',
    'hosteligap26domain.com',
    'hostel2ss01domain.com',
    'hostname4n1domain.com',
    'hostname4n3domain.com'
)

$servers = $servers | Sort-Object -Unique

foreach ($server in $servers) {
    "`n== {0} ==" -f $server

    $destination = '\\' + $server + '\c$\temp'

    "{0} to {1}" -f $msi_path, $destination

    Copy-Item -Path $msi_path -Destination $destination

    Invoke-Command -ComputerName $server -ArgumentList $msi, $latest_version -ScriptBlock {
        param ($msi_remote, $latest_version)
        try {
            $ErrorActionPreference = 'Stop'
        
            $now = Get-Date -Format 'yyyyMMdd_hhmmss'
            $localcomputer = $env:computername

            $msiexec = 'msiexec.exe'

            # change these 2 lines for what version is installing
            $latestjava = $latest_version
        
            $installpath = 'C:\temp\' + $msi_remote

            $installlog = 'C:\temp\java_install_log_' + $localcomputer + '_' + $now + '.txt'
            $uninstalllog = 'C:\temp\java_uninstall_log_' + $localcomputer + '_' + $now + '.txt'

            $MsiInstallArguments = @('/i', $installpath, 'ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome', '/norestart', '/quiet', '/L*V', $installlog)

            function Get-InstalledJava {
                $JavaFilter = { $_.DisplayName -like "*JDK*" -and $_.Publisher -like "Microsoft*" }
    
                Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object -FilterScript $JavaFilter
            }

            # get java
            $java = Get-InstalledJava

            $java.DisplayName

            # check if we need to update
            if ($java.DisplayVersion -like $latestjava) {
                "Latest version already installed."
            }
            else {
                "INSTALL: {0} {1}" -f $msiexec, ($MsiInstallArguments -join ' ')
                
                # install new java, then we stop all the old version of java processes, remove old java(s), then start $U again using newly installed java
                Start-Process -FilePath $msiexec -Wait -ArgumentList $MsiInstallArguments 
                
                $java = Get-InstalledJava
                "After Install"
                $java.DisplayVersion

                # stop IO service, this will stop GSI and EEP
                "stopping io"
                Get-Service -DisplayName "Univer*IO*" | Where-Object { $_.Status -eq 'Running' } | Stop-Service -PassThru
                "  io stopped"

                # stop remaing services
                "stopping other services"
                Get-Service -DisplayName "Univer*" | Where-Object { $_.Status -eq 'Running' } | Stop-Service -PassThru
                "  rest of services stopped"

                # stop any still running $U processes
                "stopping any other hung DU processes"
                Get-Process | Where-Object { $_.Path -like "*AUTOMIC\DUAS\*\bin\*" } | Stop-Process -PassThru
                "  $U processes stopped"

                # stop any still running java processes
                "stopping other java processes"
                Get-Process -Name "java" -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "C:\Program Files\Java\jre1.8*" } | Stop-Process -PassThru
                "  java processes stopped"


                # uninstall older versions
                foreach ($j in $java | Where-Object { $_.DisplayVersion -notlike $latestjava } ) {
                    "Removing {0} {1}" -f $j.DisplayName, $j.DisplayVersion

                    # capture the guid from the uninstall string
                    $package = $j.UninstallString | Select-String -Pattern '{[-0-9A-F]+?}' -AllMatches | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value
                    $MsiUnInstallArguments = @('/x', $package, '/quiet', '/norestart', '/le', $uninstalllog)
                        
                    "REMOVE: {0} {1}" -f $msiexec, ($MsiUnInstallArguments -join ' ')
                    # #     Start-Process -FilePath $msiexec -Wait -ArgumentList $MsiUnInstallArguments
                }

                "After Removal of old"
                $java.DisplayVersion

                # get all installed $U values.xml
                $ValuesXMLs = Get-ChildItem HKLM:\SYSTEM\CurrentControlSet\Services\DHS*IO*\Parameters | Get-ItemPropertyValue -Name Values

                # replace the java path to just 'java', it should be in the path and acceptable
                foreach ($xml in $ValuesXMLs) {
                    "updating values.xml: {0}" -f $xml
                    (Get-Content -Path $xml -Raw) -replace '<var id="UXJEE_JAVA_EXE">.+</var>', '<var id="UXJEE_JAVA_EXE">java</var>' | Set-Content -Path $xml
                    "  values.xml updated"
                }

                "starting io"
                Get-Service -DisplayName "Univer*IO*" | Start-Service -PassThru
                "  io started"

                "waiting for eep and gsi to start"
                do {
                    Start-Sleep 1
                    $EEPService = Get-Service -DisplayName "Univer*GSI*" | Where-Object { $_.Status -eq 'Running' }
                    $GSIService = Get-Service -DisplayName "Univer*EEP*" | Where-Object { $_.Status -eq 'Running' }
                } until ($EEPService.count -ne 0 -and $GSIService.count -ne 0)
                "  eep and gsi started"

                "starting rest of services"
                Get-Service -DisplayName "Univer*" | Where-Object { $_.Status -ne 'Running' } | Start-Service -PassThru
                "  rest of services started"

                # display outcome
                $java = Get-InstalledJava
                $java | Select-Object DisplayName, DisplayVersion
            }
        }
        catch {
            "FAILED: {}" -f $server
        }
    }
}
