Set-Location $PSScriptRoot

# input file
# $instances = Get-Content -Path .\All_db_Servers.txt  | Select-String '^[^#]'

# uses stored credentials or creates new
$credspath = "$env:LOCALAPPDATA\basetech.xml"
if (Test-Path -Path $credspath -PathType Leaf) {
    $credential = Import-Clixml $credspath
}
else {
    $credential = Get-Credential -Credential 'basetech'
    $credential | Export-Clixml $credspath
}

$instances = @(
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150'
)

$table = @()
$fails = @()

"Querying instances ..."

foreach ($instance in $instances ) {
    try {
        " - $instance"

        $i = Get-SqlInstance -ServerInstance $instance -Credential $credential
    
        $udbs = $i.Databases | Where-Object { $_.IsSystemObject -ne $true }

        foreach ($udb in $udbs) {
            switch ($udb.CompatibilityLevel) {
                "Version160" { $compat = "SQL Server 2022" }
                "Version150" { $compat = "SQL Server 2019" }
                "Version140" { $compat = "SQL Server 2017" }
                "Version130" { $compat = "SQL Server 2016" }
                "Version120" { $compat = "SQL Server 2014" }
                "Version110" { $compat = "SQL Server 2012" }
                "Version100" { $compat = "SQL Server 2008" }
                "Version90" { $compat = "SQL Server 2005" }
                "Version80" { $compat = "SQL Server 2000" }
                default { $compat = "unknown" }
            }

            $db = [PSCustomObject]@{
                Domain             = ($i.ServiceAccount.Split('\')[0]).ToUpper()
                Computer           = $i.ComputerNamePhysicalNetBIOS
                Instance           = $i.InstanceName
                Database           = $udb.Name
                Size               = [Math]::Round($udb.Size/1000,2)
                CompatibilityLevel = $compat
                IsAccessible       = $udb.IsAccessible 
                AG                 = $udb.AvailabilityGroupName
            }
            $table += $db
        }
    }
    catch {
        $fails += $instance
    }
}

$file = '.\All_db_Databases_' + (Get-Date -Format 'yyyyMMdd') + '.xlsx'
$table | Export-Excel -Path $file
