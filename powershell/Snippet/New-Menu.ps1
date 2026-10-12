param (
    [string]$App,
    [string]$Env
)

Set-Location $PSScriptRoot

$Build = @(
    [PSCustomObject]@{
        App    = 'Inventory'
        Env    = 'Prod'
        Server = 'Server1'
    },    
    [PSCustomObject]@{
        App    = 'Inventory'
        Env    = 'Test'
        Server = 'Server2'
    },    
    [PSCustomObject]@{
        App    = 'Inventory'
        Env    = 'Dev'
        Server = 'Server3'
    },    
    [PSCustomObject]@{
        App    = 'Audit'
        Env    = 'Prod'
        Server = 'Server4'
    },    
    [PSCustomObject]@{
        App    = 'Audit'
        Env    = 'Test'
        Server = 'Server5'
    },    
    [PSCustomObject]@{
        App    = 'Audit'
        Env    = 'Dev'
        Server = 'Server6'
    }
)
    
    
if (-not $PSBoundParameters.ContainsKey('App')) {
    while ($true) {

        # Display applications and prmopt for.
        $i = 0
        $Apps = $Build | Select-Object -ExpandProperty App -Unique | ForEach-Object { [PSCustomObject]@{ '#' = $i++; Application = $_ } }
        ($Apps | Format-Table | Out-String).TrimEnd("`r|`n")
        $WhichApp = Read-Host "Which App?"

        # Check if you chose a valid application.
        if ($null -ne ($WhichApp -as [int]) -and $WhichApp -ne '' -and [int]$WhichApp -lt $Apps.count) {
            $App = $Apps[$WhichApp].Application
        }
        else { 
            continue
        }
        break

    }
}

if (-not $PSBoundParameters.ContainsKey('Env')) {
    :top while ($true) {

        # Display environments and prompt for.
        $i = 0
        $Envs = $Build | Where-Object { $_.App -eq $App } | Select-Object -ExpandProperty Env -Unique | ForEach-Object { [PSCustomObject]@{ '#' = $i++; Environment = $_ } }
        ($Envs | Format-Table | Out-String).TrimEnd("`r|`n")
        $WhichEnv = (Read-Host "Which Env?").Split(',')
        
        # Check if you chose a valid environment.
        $Env = @()
        foreach ($item in $WhichEnv) {
            if ($null -ne ($item -as [int]) -and $item -ne '' -and [int]$item -lt $Envs.count) {
                $Env += $Envs[$item].Environment
            }
            else {
                continue top
            }
        }
        break

    } 
}

$Build | Where-Object { $_.Env -eq $Env -and $_.App -eq $App } | Format-Table

