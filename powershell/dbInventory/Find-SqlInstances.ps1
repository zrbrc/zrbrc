<#
.SYNOPSIS
    Gathers data from Active Directory and queries SQL Instance for info.
.DESCRIPTION
    Creates a table with SQL Server Instance information. This needs to run in each zone as it actively 
    queries SQL to get more info outside of what exists in AD. It will skip and note any servers
    that are unreachable (different zone).
.EXAMPLE
    PS C:\>.\Get-SqlInstances.ps1
    Right-Click->Run Powershell from Explorer.
.INPUTS
    NONE
.OUTPUTS
    Table with data.
#>
#Requires -Modules SqlServer,ActiveDirectory

Set-Location $PSScriptRoot

function Get-LatestSqlVersion {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        $response = Invoke-WebRequest 'https://docs.microsoft.com/en-us/sql/database-engine/install-windows/latest-updates-for-microsoft-sql-server' -UseBasicParsing -UseDefaultCredentials -ErrorAction Stop
    
        if ($response.Content -match "<tbody>[^>]*>(?:.|\n)*?<\/tbody>") {
    
            $data = $Matches[0].Replace("`n", '') -replace '</tr></tbody>', '' -replace '<tbody><tr>' -split '</tr><tr>'
    
            $table = foreach ($row in $data.TrimStart('<td>').TrimEnd('</td>') ) {
                $row = $row -split '</td><td>'
    
                if ($row[3] -match '(http|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])?') { $cuurl = $Matches[0] }
                if ($row[1] -match '(http|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])?') { $spurl = $Matches[0] }
                # if ($row[2] -match '(http|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])?') { $gdrurl = $Matches[0] }
    
    
                [PSCustomObject]@{
                    SQLVersion    = $row[0]
                    LatestSP      = ($row[1] -split ' <a ')[0] -replace 'N/A', 'RTM'
                    LatestCU      = ($row[3] -split ' <a ')[0] -replace 'N/A', '' -replace ' ', '' -replace '<br>', '' -replace '\+GDR', '' # gotta escape the '+'
                    CUReleaseDate = ($row[4] -split '<br>')[0]
                    #LatestGDR     = (($row[2] -split '>')[1] -split '<')[0]
                    LatestSPLink  = $spurl
                    LatestCULink  = $cuurl
                    #LatestGDRLink = $gdrurl
    
                }
            }
            $table
        }
    }
    catch {
        return
    }
}

function Get-SubnetMask {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Int]$Prefix
    )

    $subnet = ''
    for ($i = 0 ; $i -lt 32; $i++) {
        if ($i -lt $prefix) {
            $subnet += '1'
        }
        else {
            $subnet += '0'
        }
    }
    "{0}.{1}.{2}.{3}" -f [Convert]::ToInt32(($subnet.Substring(0, 8)), 2), [Convert]::ToInt32(($subnet.Substring(8, 8)), 2), [Convert]::ToInt32(($subnet.Substring(16, 8)), 2), [Convert]::ToInt32(($subnet.Substring(24, 8)), 2)
}

# data params
$Domain = (Get-ADDomain).Name
$60DaysOld = (Get-Date).AddDays(-60)

$return = @{}

$ipinfo = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.ifIndex -ne 1 -and $_.SkipAsSource -eq $false -and $_.IPAddress -like "172.*.*.*" } | Sort-Object -Property InterfaceIndex | Select-Object -First 1

[System.Net.IPAddress]$LocalIP = $ipinfo.IPAddress
[System.Net.IPAddress]$LocalSubnet = $ipinfo.PrefixLength | Get-SubnetMask

# get SQL versions
if (!($sqllatest = Get-LatestSqlVersion)) {
    "!!! Unable to download SQL Releases. Will be unable to determine UpdateLevel."
}

# finds all sql SPNs
$SqlSPNs = (Get-ADObject -LDAPFilter '(servicePrincipalName=MSSQLsvc*)' -Properties *).servicePrincipalName | Where-Object { $_ -like "MSSQLSvc/*" } | Sort-Object -Unique
# $SqlSPNs = @('MSSQLSvc/hostname:15150', 'MSSQLSvc/hostname:15150')

$instances = @()
$unreachable = @()


foreach ($SPN in $SqlSPNs) {
    $Name = $SPN.Split('/')[1].Split(':')[0].Split('.')[0]
    $Port = $SPN.Split('/')[1].Split(':')[1]

    try {
        if ($null -ne ($Port -as [int]) -and $null -ne $Port) {

            # get AD objects to see how old it is
            $adobj = Get-ADComputer -Identity $Name -Properties OperatingSystem, DNSHostName, LastLogonDate, Description -ErrorAction Stop
            
            if ($adobj.LastLogonDate -lt $60DaysOld) {
                throw 'OLD'
            } 
            
            [System.Net.IPAddress]$ServerIP = (Resolve-DnsName -Name $adobj.DNSHostName -DnsOnly).IPAddress

            # see if local ip and server ip are in the same subnet, dont try to query it if they arent
            if ( ($LocalIP.Address -band $LocalSubnet.Address) -ne ($ServerIP.Address -band $LocalSubnet.Address) ) {
                throw 'SUBNET'
            }
            
            "# querying: {0} ({1})" -f $Name, $ServerIP.IPAddressToString
            
            # get instance details
            $details = Get-SqlInstance -ServerInstance "$Name,$Port" -ErrorAction Stop
            
            # if ad name doesnt match the NetName on the instance, its probably a listener and no point in gathering more info on it
            if ($adobj.Name -ne $details.NetName) {
                throw 'LISTENER'
            }
            
            # used name instance name else default name, SMO oddity
            if ($details.InstanceName -ne '') { 
                $instancename = $details.InstanceName 
            } 
            else { 
                $instancename = 'MSSQLSERVER' 
            }
            
            # get server specs
            # $NumberOfCores = Get-CimInstance -ClassName Win32_Processor -ComputerName $Name -ErrorAction Stop | Select-Object -ExpandProperty NumberOfCores | Measure-Object -Sum | Select-Object -ExpandProperty Sum
            # $Capacity = Get-CimInstance -ClassName Win32_PhysicalMemory -ComputerName $Name -ErrorAction Stop | Select-Object -ExpandProperty Capacity | Measure-Object -Sum | Select-Object -ExpandProperty Sum

            # set version year
            switch ($details.VersionMajor) {
                '15' { $version = ' 2019' }
                '14' { $version = ' 2017' }
                '13' { $version = ' 2016' }
                '12' { $version = ' 2014' }
                '11' { $version = ' 2012' }
                '10' { $version = ' 2008' }
                '9' { $version = ' 2005' }
                Default { $version = "" }
            }
            
            # trim version infoS
            $product = $details.Product.Replace('Microsoft ', '') + $version

            # check if we are running latest version
            if (!$sqllatest) {
                $Latest = 'UNKNOWN'
            }
            else {
                $Latest = $sqllatest | Where-Object { $product -eq $_.SQLVersion -and $_.LatestSP -notlike "*Azure*" } | Select-Object -First 1

                $CurrentUpdateLevel = ($details.ProductLevel, $details.ProductUpdateLevel -join ' ').Trim()

                $LatestUpdateLevel = ($Latest.LatestSP, $Latest.LatestCU -join ' ').Trim()
                
                if ($CurrentUpdateLevel -eq $LatestUpdateLevel) {
                    $UpdateLevel = "CURRENT"
                }
                else {
                    $UpdateLevel = "NEEDS UPDATE"
                }
            }
                    
            $LastWindowsUpdate = ( Get-HotFix -ComputerName $adobj.Name | Sort-Object InstalledOn | Select-Object -Last 1).InstalledOn.ToString('yyyy/MM/dd')
        
            $instances += [PSCustomObject]@{
                Domain            = $Domain
                ServerName        = $adobj.Name
                OS                = $adobj.OperatingSystem
                LastWindowsUpdate = $LastWindowsUpdate
                IP                = $ServerIP.IPAddressToString
                # CpuCores          = $NumberOfCores
                # RamGB             = $Capacity / 1024 / 1024 / 1024
                Port              = $Port
                Instance          = $instancename
                Product           = $product
                Version           = $details.Version
                CurrentSPCU       = $CurrentUpdateLevel
                LatestSPCU        = $LatestUpdateLevel
                UpdateLevel       = $UpdateLevel
                # Description       = $adobj.Description
            }
        }
    }
    catch {
        $em = $_.Exception.Message
        $unreachable += [PSCustomObject]@{
            Instance = $Name
            Port     = $Port 
            Status   = $em
        }
    }
}

$return.unreachable = $unreachable
$return.sqllatest = $sqllatest
$return.instances = $instances

$return.sqllatest | Format-Table *
$return.instances | Format-Table *

# outputs to text file for Sql Permissions Report
# $return.instances | ForEach-Object { $_.ServerName + ',' + $_.Port } | Out-File ".\$($env:USERDOMAIN)_Servers.txt"

# $return.instances | Export-Excel ".\$($env:USERDOMAIN)_Instances_$(Get-Date -Format 'yyyyMMdd').xlsx" -WorksheetName 'Instances'
# $return.sqllatest | Export-Excel ".\$($env:USERDOMAIN)_Instances_$(Get-Date -Format 'yyyyMMdd').xlsx" -WorksheetName 'Releases'
# $return.unreachable | Export-Excel ".\$($env:USERDOMAIN)_Instances_$(Get-Date -Format 'yyyyMMdd').xlsx" -WorksheetName 'Unreachable'