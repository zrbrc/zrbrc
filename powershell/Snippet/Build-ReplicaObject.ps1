$Listener = 'hostnameCLS1LS1,15150'
$AgName = 'AG2016_1'
$data = @()
$file = 'c:\users\ryan.zerbe\desktop\data.xml'


$row = [PSCustomObject]@{
    Listener = $Listener
}
$Server = Get-SqlInstance -ServerInstance $Listener
$ag = $Server.AvailabilityGroups[$AgName]
$reps = $ag.AvailabilityReplicas | Select-Object Name, Role

if ($reps) {
    $row | Add-Member -MemberType NoteProperty -Name 'IsAg' -Value $true
    $row | Add-Member -MemberType NoteProperty -Name 'Ag' -Value $AgName
    $row | Add-Member -MemberType NoteProperty -Name 'Replicas' -Value $reps
    $row | Add-Member -MemberType NoteProperty -Name 'Primary' -Value ( $reps | Where-Object { $_.Role -eq 'Primary' } )
    $row | Add-Member -MemberType NoteProperty -Name 'Secondary' -Value ( $reps | Where-Object { $_.Role -eq 'Secondary' } )
}
else {
    $repobj = [PSCustomObject]@{
        Name = $Listener
        Role = 'Primary'
    }
    $row | Add-Member -MemberType NoteProperty -Name 'IsAg' -Value $false
    $row | Add-Member -MemberType NoteProperty -Name 'Replicas' -Value $repobj
    $row | Add-Member -MemberType NoteProperty -Name 'Primary' -Value $repobj
}

$data += $row

foreach ($r in $data.Replicas | Sort-Object Role) {
    $r.Name
}
