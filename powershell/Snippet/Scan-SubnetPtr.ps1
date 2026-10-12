<#
.SYNOPSIS
    Checks for A record and PTR record mismatches.
.DESCRIPTION
    Grabs all A records in the Domain zone, resolves the hostname to the IP, then compares the PTR records IPs.
.EXAMPLE
    PS C:\> .\Scab0SubnetPtr.ps1
.INPUTS
    none
.OUTPUTS
    screen output only
.NOTES
    This scans against the USER DNS Domain for the user running it, so it needs to be run in each network zone.

    Sample code:

    $Domain = Get-ADDomain

$ForwardLookupRecords = Get-DnsServerZone -ComputerName $env:LOGONSERVER.TrimStart('\\') |
                     Where-Object { $_.ZoneName -eq $Domain.DNSRoot -and $_.IsAutoCreated -eq $False } |
                     Get-DnsServerResourceRecord -ComputerName $env:LOGONSERVER.TrimStart('\\') -RRType A | Where-Object { $_.HostName -notin "@","gc._msdcs" }

$ReverseLookupRecords= Get-DnsServerZone -ComputerName $env:LOGONSERVER.TrimStart('\\') |
                     Where-Object { $_.IsReverseLookupZone -eq $True -and $_.IsAutoCreated -eq $False } |
                     Get-DnsServerResourceRecord -ComputerName $env:LOGONSERVER.TrimStart('\\') | Where-Object { $_.HostName -ne "@" }
#>

# output tables
$ForwardLookupMismatches = @()
$ReverseLookupMismatches = @()

# get the lookup zone
$ForwardLookupZone = Get-DnsServerZone -ComputerName $env:LOGONSERVER.TrimStart('\\') | Where-Object { $_.ZoneName -eq $env:USERDNSDOMAIN }

# get A records in forward lookup zone
$ARecords = Get-DnsServerResourceRecord -ComputerName $env:LOGONSERVER.TrimStart('\\') -ZoneName $ForwardLookupZone.ZoneName |
Where-Object { $_.RecordType -eq 'A' -and $_.HostName -notin '@', 'DomainDnsZones', 'ForestDnsZones' -and $_.Timestamp -gt (Get-Date).AddDays(-30) }

# loop thru each A record to verify A record resolves correctly and see if the PTR matches
foreach ($record in $ARecords) {
    "Checking: {0}" -f $record.HostName
    
    # resolve hostname
    $ResolvedByName = (Resolve-DnsName $record.HostName -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -ne '::1' })
    
    # check if the A record revoles correctly, it should
    if ($record.RecordData.IPv4Address.IPAddressToString -notin $ResolvedByName.IPAddress) {
        $ForwardLookupMismatches += [PSCustomObject]@{
            HostName  = $record.HostName
            IPAddress = $record.RecordData.IPv4Address.IPAddressToString
            A         = $ResolvedByName.IPAddress
        }
    }
            
    # loops in case a server has multiple IPs
    foreach ($i in $ResolvedByName.IPAddress) {
        # if the A record doesnt match the resolved IP, get the PTR
        $ResolvedByIp = (Resolve-DnsName $i -DnsOnly -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -ne '::1' })

        if ($ResolvedByIp) {
            if ($record.HostName -ne $ResolvedByIp.NameHost.Split('.')[0]) {
                $ReverseLookupMismatches += [PSCustomObject]@{
                    Hostname  = $record.HostName 
                    IPAddress = $record.RecordData.IPv4Address.IPAddressToString
                    PTR       = $ResolvedByIp.NameHost.Split('.')[0]
                }
            }
        }
        else {
            $ReverseLookupMismatches += [PSCustomObject]@{
                Hostname  = $record.HostName 
                IPAddress = $record.RecordData.IPv4Address.IPAddressToString
                PTR       = 'MISSING'
            }
        }
    }
}

$ForwardLookupMismatches | Format-Table
$ReverseLookupMismatches | Format-Table