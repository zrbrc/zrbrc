Import-Module SqlServer

$ServerInstance = Get-SqlInstance -ServerInstance 'LUNA\DE2019'

$DacFxPath = Resolve-Path -Path "$PSScriptRoot\packages\Microsoft.SqlServer.DacFx\Microsoft.SqlServer.Dac.dll"
Add-Type -Path $DacFxPath

$DbName = 'random_db'
$Version = New-Object System.Version -ArgumentList '1.0.0.0'
$DacpacPath = 'E:\Temp\me-random_db.dacpac'

$ExtractOptions = New-Object -TypeName Microsoft.SqlServer.Dac.DacExtractOptions
$ExtractOptions.IgnoreUserLoginMappings =  $true
$ExtractOptions.ExtractApplicationScopedObjectsOnly = $true
$ExtractOptions.ExtractReferencedServerScopedElements = $false
$ExtractOptions.IgnorePermissions = $true
$ExtractOptions | Get-Member

$DeployOptions = New-Object -TypeName Microsoft.SqlServer.Dac.DacDeployOptions
$DeployOptions

$ConnectionString = "$($ServerInstance.ConnectionContext.ConnectionString);Database=$DbName"
$ExtractionUnit = New-Object -TypeName Microsoft.SqlServer.Dac.DacServices -ArgumentList $ConnectionString -ErrorAction Stop
$ExtractionUnit.Extract($DacpacPath, $DbName, $DbName, $Version, $null, $null, $ExtractOptions, $null) 
