Set-Location $PSScriptRoot

# uses stored credentials or creates new
if (Test-Path -Path '.\sa.xml') {
    $sa = Import-Clixml '.\sa.xml'
}
else {
    $sa = Get-Credential -Credential 'sa'
    $sa | Export-Clixml '.\sa.xml'
}

function Export-DbObjects {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$ObjectSmo,
        [Parameter(Mandatory = $true)]$DatabaseSmo
    )
    process {
        # creates a scripter object class to script objects to .sql and sets some default options
        $scripter = New-Object Microsoft.SqlServer.Management.Smo.Scripter $DatabaseSmo.Parent
        $scripter.Options.IncludeHeaders = $true
        
        foreach ($obj in $ObjectSmo) { 
            $sql = @()

            # script drops
            $scripter.Options.ScriptDrops = $true 
            foreach ($script in $($scripter.EnumScript($obj))) {
                $sql += $script
                $sql += "GO"
            }
                        
            # scripts creates
            $scripter.Options.ScriptDrops = $false
            foreach ($script in $($scripter.EnumScript($obj))) {
                $sql += $script
                $sql += "GO"
            }
            Write-Output $sql
        }
    }
}

$Objects = (Get-SqlDatabase -ServerInstance 'jupiter.home.lan,1401' -Database random_db -Credential $sa).Synonyms

foreach ($Object in $Objects) {
    Export-DbObjects -DatabaseSmo $Database -ObjectSmo $Object
}


