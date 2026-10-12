$servers = @(
    'hostMCIDBC7N1',
    'hostMCIDBC7N2',
    'hostMCIDBC7N3',
    'hostname6N1',
    'hostname6N2',
    'hostname8N1',
    'hostname8N2',
    'hostname8N3',
    'hostname3n1',
    'hostname3n2',
    'hostname1N1',
    'hostname1N3',
    'hostname1N5'
    )

$data = Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $servers -Filter 'DriveType = 3 AND Name != "C:" AND Name != "P:" AND Name != "T:" AND Name != "U:"'

$data | Select-Object SystemName, Name, VolumeName, 
@{n="SizeGB";e={[math]::Round($_.Size/1GB,2)}}, 
@{n="FreeGB";e={[math]::Round($_.FreeSpace/1GB,2)}}, 
@{n="Free";e={([math]::Round(($_.FreeSpace/$_.Size),2)).ToString("P")}} |
Sort-Object SystemName, Name | Format-Table