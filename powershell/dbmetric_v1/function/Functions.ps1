############################################################################
# functions
#region ####################################################################
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
#endregion