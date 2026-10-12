param (
    [Parameter(Mandatory = $false)]
    [string]$Instance = 'xx.xx.xx.xx,15150',

    [Parameter(Mandatory = $false)]
    [string]$Database = 'DSAMH_CDS_PROD',

    [Parameter(Mandatory = $false)]
    [string]$Table
)

Set-Location $PSScriptRoot

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

$out = @()

$db = Get-SqlDatabase -ServerInstance $instance -Database $database -Credential $basetech

$out = foreach ($t in $db.Tables) {
    foreach ($c in $t.Columns) {
        [PSCustomObject]@{
            TableName     = $t.Name
            ColumnName    = $c.Name
            ColumnComment = $c.ExtendedProperties.Properties.Value
            Identity      = $c.Identity
            DataType      = $c.Properties.Item('DataType').Value
            Length        = $c.Properties.Item('Length').Value
            Nullable      = $c.Nullable
            InPrimaryKey  = $c.Properties.Item('InPrimaryKey').Value
            IsForeignKey  = $c.Properties.Item('IsForeignKey').Value
        }
    }
}

$file = '.\' + $Database + '_' + (Get-Date -Format 'yyyyMMdd') + '.xlsx'
$out | Export-Excel $file