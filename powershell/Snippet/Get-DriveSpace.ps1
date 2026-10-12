$computers = @(
    # assist test
    'hostname4n1',
    'hostname4n3',
    'depttreligdb01',
    'hostdbcl1n1',
    'hostdbcl1n3',
    'tsdbcls3db02'
    # decss test
    # 'hostdcssc2n1',
    # 'hostdcssc2n2',
    # 'hostdcssc2n3',
    # 'hostdcssc2n4'
    # assist prod
    # 'hostname1n1',
    # 'hostname1n3',
    # 'hostname1n5'
    # decss prod
    # 'hostdcssc1n1',
    # 'hostdcssc1n2',
    # 'hostdcssc1n3',
    # 'hostdcssc1n4'
)

$table = foreach ($computer in $computers ) {
    $out = Get-CimInstance -Class CIM_LogicalDisk -ComputerName $computer | Where-Object { $_.DriveType -eq '3' }

    $out | ForEach-Object {
        [PSCustomObject]@{
            Server      = $computer
            Drive       = $_.DeviceId
            Label       = $_.VolumeName
            SizeGB      = "{0:f2}" -f ($_.Size / 1024 / 1024 / 1024)
            FreeGB      = "{0:f2}" -f ($_.FreeSpace / 1024 / 1024 / 1024)
            FreePercent = "{0:f2}" -f (($_.FreeSpace / $_.Size) * 100)
        }
    }
}
$table | Sort-Object Server,Drive | Format-Table


# or
Get-CimInstance -Class CIM_LogicalDisk | Where-Object {$_.DriveType -eq '3'} | 
Select-Object SystemName, Name, VolumeName,
@{n="Size(GB)";e={[math]::Round($_.Size/1GB,2)}},
@{n="Free(GB)";e={[math]::Round($_.FreeSpace / 1GB, 2)}},
@{n="Used(%)";e={[math]::Round((($_.Size-$_.FreeSpace)/$_.Size)*100,2)}} | Format-Table