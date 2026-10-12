$share = "\\xx.xx.xx.xx\dbbackup"

# find used drives so we can find an open drive letter to use
$used_drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Name | Sort-Object -Descending
$drive = [char[]](90..65) | Where-Object {$_ -notin $used_drives} | Select-Object -First 1

# map network share
$nw_obj = New-Object -ComObject WScript.Network
$nw_obj.MapNetworkDrive($drive + ':', $share, $false)

# get details of drive
$drive_details = Get-PSDrive $drive

# calculate specs
$gb = (1024 * 1024 * 1024)
$free = ($drive_details.free) / $gb
$used = ($drive_details.used) / $gb
$total = ($free + $used)
$free %= ($free / $total * 100)
$free = ([math]::Round($free))
Write-Output "Share $share has free space of $free%"

# remove drive
$nw_obj.RemoveNetworkDrive($drive + ':')