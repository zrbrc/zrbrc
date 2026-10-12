<# 
Put cluster names in the clusters list, it will loop thru and change each. Shows before and after setting.
#>

$clusters = @(
    'hostmcidbc1',
    'hostmcdbc1',
    'hostname10',
    'hostspdbc9',
    'hostnamec2'
)

"BEFORE:"
$clusters | ForEach-Object { Get-Cluster $_ } | Format-Table Name, SameSubnetDelay, CrossSubnetThreshold

foreach ($c in $clusters) {
    (Get-Cluster $c).SameSubnetThreshold = 40
    (Get-Cluster $c).CrossSubnetThreshold = 40
}

"AFTER:"
$clusters | ForEach-Object { Get-Cluster $_ } | Format-Table Name, SameSubnetDelay, CrossSubnetThreshold