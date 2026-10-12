# playing with SystemInfo - v-4

# save the old Information Pref
$Old_I_Pref = $InformationPreference
# enable Information output
$InformationPreference = 'Continue'

#region >> FunctionList
function Get-PCSystemTypeName
    {
    [CmdletBinding()]
    Param
        (
        [Parameter (
            Mandatory,
            Position = 0
            )]
            [int]
            $PCSystemType
        )
    switch ($PCSystemType)
        {
        0 {'Unspecified'; break}
        1 {'Desktop'; break}
        2 {'Laptop_Or_Mobile'; break}
        3 {'Workstation'; break}
        4 {'Enterprise_Server'; break}
        5 {'SOHO_Server'; break}
        6 {'Appliance_PC'; break}
        7 {'Performance_Server'; break}
        8 {'Maximum'; break}
        default {'Unknown_ID'}
        }
    }
#endregion >> FunctionList

#region >> create & fill in the properties
Write-Information 'Starting SysInfo collection ...'

Write-Information '    getting CIM_BIOSElement info ...'
$CIM_BIOS = Get-CimInstance -ClassName CIM_BIOSElement
Write-Information '    getting CIM_Processor info ...'
$CIM_Processor = Get-CimInstance -ClassName CIM_Processor
Write-Information '    getting CIM_PhysicalMemory info ...'
$CIM_PhysicalMemory = Get-CimInstance -ClassName CIM_PhysicalMemory
Write-Information '    getting CIM_ComputerSystem info ...'
$CIM_ComputerSystem = Get-CimInstance -ClassName CIM_ComputerSystem
Write-Information '    getting CIM_OperatingSystem info ...'
$CIM_OperatingSystem = Get-CimInstance -ClassName CIM_OperatingSystem
Write-Information '    getting Win32_TimeZone info ...'
$CIM_TimeZone = Get-CimInstance -ClassName Win32_TimeZone
Write-Information '    getting CIM_LogicalDisk info ...'
$CIM_LogicalDisk = Get-CimInstance -ClassName CIM_LogicalDisk |
    Where-Object {$_.Name -eq $CIM_OperatingSystem.SystemDrive}
Write-Information '    getting CIM_NetworkAdapter & Win32_NetworkAdapterConfiguration info ...'
# this is a regex OR, so put a '|' between each item you want to exclude
#$ExcludedNetAdapterList = 'Npcap|VirtualBox'
$ExcludedNetAdapterList = 'Npcap'
$CIM_NetAdapter = Get-CimInstance -ClassName CIM_NetworkAdapter
$CIM_NetConfig = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration |
    Where-Object {
        $_.IPEnabled -and 
        $_.Description -notmatch $ExcludedNetAdapterList
        }


$SysInfoProps = [ordered]@{}


# these CPU items likely need to be changed for multi-CPU boxes
$SysInfoProps.Add('CPU_Description', $CIM_Processor.Description)
$SysInfoProps.Add('CPU_Maker', $CIM_Processor.Manufacturer)
$SysInfoProps.Add('CPU_Name', $CIM_Processor.Name)
$SysInfoProps.Add('CPU_LoadPct', $CIM_Processor.LoadPercentage)
$SysInfoProps.Add('CPU_LogicalCoreCount', $CIM_ComputerSystem.NumberOfLogicalProcessors)
$SysInfoProps.Add('CPU_SocketCount', $CIM_ComputerSystem.NumberOfProcessors)
$SysInfoProps.Add('CPU_SocketDesignation', $CIM_Processor.SocketDesignation)
$SysInfoProps.Add('CPU_Speed_Mhz', $CIM_Processor.MaxClockSpeed)


$SysInfoProps.Add('Drive_System', $CIM_OperatingSystem.SystemDrive)
$SysInfoProps.Add('Drive_System_FreeSpace_GB', '{0:N2}' -f ($CIM_LogicalDisk.FreeSpace / 1GB))
$SysInfoProps.Add('Drive_System_FreeSpace_Pct', '{0:N0}' -f (($CIM_LogicalDisk.FreeSpace / $CIM_LogicalDisk.Size) * 100))
$SysInfoProps.Add('Drive_System_Size_GB', '{0:N2}' -f ($CIM_LogicalDisk.Size / 1GB))


$SysInfoProps.Add('Net_Domain', $CIM_ComputerSystem.Domain)
$SysInfoProps.Add('Net_DomainJoined', $CIM_ComputerSystem.PartOfDomain)
foreach ($CNC_Item in $CIM_NetConfig)
    {
    $Index = '{0:D2}' -f $CNC_Item.Index
    $SysInfoProps.Add("Net_${Index}_AdapterIndex", $CNC_Item.Index)
    $SysInfoProps.Add("Net_${Index}_AdapterName", $CNC_Item.Description)
    $SysInfoProps.Add("Net_${Index}_AdapterManufacturer", $CIM_NetAdapter[$Index].Manufacturer)
    # using 1e9 instead of 1GB since the NIST uses base 10
    $SysInfoProps.Add("Net_${Index}_AdapterSpeed_Gbit", $CIM_NetAdapter[$Index].Speed / 1e9)

    $DefaultGateway = if ($CNC_Item.DefaultIPGateway -is [array])
        {
        $CNC_Item.DefaultIPGateway[0]
        }
        else
        {
        $Null
        }
    $SysInfoProps.Add("Net_${Index}_DefaultGateway", $DefaultGateway)

    $SysInfoProps.Add("Net_${Index}_DHCP_Enabled", $CNC_Item.DHCPEnabled)
    $SysInfoProps.Add("Net_${Index}_DHCP_Server", $CNC_Item.DHCPServer)

    $SysInfoProps.Add("Net_${Index}_DNS_HostName", $CNC_Item.DNSHostName)

    # on my system the addresses are stored [0]=IPv4, [1]=IPv6
    #    the [ipaddress] conversion fails with ipv6 subnet info
    #    "64" becomes "0.0.0.64" [ipv4] instead of "64" or "::64" [ipv6]
    $SysInfoProps.Add("Net_${Index}_IPv4_Address",
        ([ipaddress[]]$CNC_Item.IPAddress).
        Where({$_.AddressFamily -eq 'Internetwork'})  -join '; ')
    $SysInfoProps.Add("Net_${Index}_IPv4_AddressSubnet", $CNC_Item.IPSubnet[0])
    $SysInfoProps.Add("Net_${Index}_IPv4_DNS_Servers",
        ([ipaddress[]]$CNC_Item.DNSServerSearchOrder).
        Where({$_.AddressFamily -eq 'Internetwork'}) -join '; ')

    $SysInfoProps.Add("Net_${Index}_IPv6_Address",
        ([ipaddress[]]$CNC_Item.IPAddress).
        Where({$_.AddressFamily -eq 'InternetworkV6'})  -join '; ')
    $SysInfoProps.Add("Net_${Index}_IPv6_AddressSubnet", $CNC_Item.IPSubnet[1])
    # IPV6 DNS servers are shown in "ipconfig /all", but not with CIM
    #    so this will be blank on my system
    $SysInfoProps.Add("Net_${Index}_IPv6_DNS_Servers", 
        ([ipaddress[]]$CNC_Item.DNSServerSearchOrder).
        Where({$_.AddressFamily -eq 'InternetworkV6'}) -join '; ')

    $SysInfoProps.Add("Net_${Index}_MAC_Address", $CNC_Item.MACAddress)
    }


$SysInfoProps.Add('OS_Architecture', $CIM_OperatingSystem.OSArchitecture)
$CultureInfo = [System.Globalization.CultureInfo]::GetCultureInfo([int]$CIM_OperatingSystem.OSLanguage)
$SysInfoProps.Add('OS_Language_DisplayName', $CultureInfo.DisplayName)
$SysInfoProps.Add('OS_Language_LCID', $CultureInfo.LCID)
$SysInfoProps.Add('OS_Language_Name', $CultureInfo.Name)
$SysInfoProps.Add('OS_LastBootUpTime', $CIM_OperatingSystem.LastBootUpTime)
$SysInfoProps.Add('OS_TimeZone', $CIM_TimeZone.Caption)
$SysInfoProps.Add('OS_TimeZone_DST_Active', $CIM_ComputerSystem.DaylightInEffect)
$SysInfoProps.Add('OS_TimeZone_Offset', $CIM_TimeZone.Bias)
$SysInfoProps.Add('OS_TimeZone_Offset_Current', $CIM_OperatingSystem.CurrentTimeZone)
$SysInfoProps.Add('OS_Version', $CIM_OperatingSystem.Version)
$SysInfoProps.Add('OS_Version_BuildNumber', $CIM_OperatingSystem.BuildNumber)
$SysInfoProps.Add('OS_Version_Caption', $CIM_OperatingSystem.Caption)
$SysInfoProps.Add('OS_Version_ServicePack', $CIM_OperatingSystem.CSDVersion)


# the original number returned is in KBytes, not Bytes
$SysInfoProps.Add('RAM_Free_GB', [math]::Round($CIM_OperatingSystem.FreePhysicalMemory / 1MB, 2))
# this presumes each RAM bank will run at the same speed - almost certainly true [*grin*] 
$SysInfoProps.Add('RAM_Speed_Mhz', $CIM_PhysicalMemory[0].Speed)
# the original number returned is in Bytes
$SysInfoProps.Add('RAM_Total_GB', [math]::Round($CIM_ComputerSystem.TotalPhysicalMemory / 1GB, 2))


$SysInfoProps.Add('System_Manufacturer', $CIM_ComputerSystem.Manufacturer)
$SysInfoProps.Add('System_Model', $CIM_ComputerSystem.Model)
$SysInfoProps.Add('System_Name', $CIM_ComputerSystem.Name)
$SysInfoProps.Add('System_PCSystemType', $CIM_ComputerSystem.PCSystemType)
$PCSystemTypeName = Get-PCSystemTypeName -PCSystemType $CIM_ComputerSystem.PCSystemType
$SysInfoProps.Add('System_PCSystemType_Name', $PCSystemTypeName)
$SysInfoProps.Add('System_SerialNumber', $CIM_BIOS.SerialNumber)
$SysInfoProps.Add('System_SystemType', $CIM_ComputerSystem.SystemType)

#endregion >> create & fill in the properties

$SysInfo = [PSCustomObject]$SysInfoProps

$SysInfo

# restore the Information Pref
$InformationPreference = $Old_I_Pref