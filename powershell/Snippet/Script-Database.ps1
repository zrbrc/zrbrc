# set which instance you want to run for
$instance = 'xx.xx.xx.xx,15150'

# give a list or set as null for all, (un)comment whichever you need
$db_list = 'DSS_ASSISTREF_UATPT'
# $db_list = $null

# dont need to edit below this line unless you know what you are doing

$basetech = $null # reset each time for sanity

# this is will use sql auth, comment out if-else block if you want to use windows auth, if basetech password hasnt been set, will ask for and save for next time
$credspath = "$env:LOCALAPPDATA\basetech.xml"
if (Test-Path -Path $credspath -PathType Leaf) {
    $basetech = Import-Clixml $credspath
    Write-Output "Credentials imported from $credspath."
}
else {
    $basetech = Get-Credential -Credential 'basetech'
    $basetech | Export-Clixml $credspath
    Write-Output "Account credentials stored to $credspath."
}

function Export-DbObjects {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Instance,
        [Parameter(Mandatory = $true)]$Object,
        $Type
    )
    process {
        $sql = @()
        
        # script just the schemas
        $scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter $Instance
        foreach ($obj in $Object | Where-Object { $_.IsSystemObject -eq $false }) { 
            foreach ($script in $($scripter.EnumScript($obj))) {
                $sql += $script
                $sql += "GO"
            }
        }
        
        # if its a table, script all its extra objects--indexes, keys, contraints, etc.
        if ($Type -eq 'Tables') {
            $scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter $Instance
            $scripter.Options.Default = $false
            $scripter.Options.ClusteredIndexes = $true
            $scripter.Options.DriAll = $true
            $scripter.Options.FullTextIndexes = $true
            $scripter.Options.Indexes = $true
            $scripter.Options.NonClusteredIndexes = $true
            $scripter.Options.Statistics = $true
            $scripter.Options.Triggers = $true
            
            foreach ($obj in $Object | Where-Object { $_.IsSystemObject -eq $false }) { 
                foreach ($script in $($scripter.EnumScript($obj))) {
                    $sql += $script
                    $sql += "GO"
                }
            }
        }
        $sql
    }
}
if ($null -eq $basetech) {
    $i = Get-SqlInstance -ServerInstance $instance
}
else {
    $i = Get-SqlInstance -ServerInstance $instance -Credential $basetech
}

foreach ($d in $i.Databases | Where-Object { ($_.Name -in $db_list -or !$db_list) -and ($_.IsSystemObject -eq $false) -and ($_.IsAccessible -eq $true) }) {

    "[i] {0}" -f $d.Name

    $sql = @()
    $file = 'C:\Temp\' + $d.Name + '_' + $(Get-Date -Format 'yyyyMMdd') + '.sql'

    $sql += Export-DbObjects -Instance $i -Object $d
    $sql += "USE [$($d.Name)]"
    $sql += "GO"

    $types = 'Tables'#, 'Views', 'Synonyms', 'StoredProcedures', 'Functions'

    foreach ($type in $types) {
        
        $o = $d.($type) | Where-Object { $_.IsSystemObject -eq $false }

        if ($o.count -ne 0) { 
            " |--> {0}: {1}" -f $type, $o.count
            $sql += Export-DbObjects -Instance $i -Object $o -Type $type
        }

    # }
    if ($null -ne $sql) { $sql | Out-File $file }
    # $sql
}