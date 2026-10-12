<#
 # This is a custom routine for Deloitte's dacpac setup. Set the path and it will find all the matching configs and files. 
 # Since we aren't filtering on a particular database, you can only supply 1 environment at a time.
 #>

$Dacpacs = @()
# $DacpacPath = '\\xx.xx.xx.xx\e$\DACPAC\WW\SITCR'
$DacpacPath = '\\xx.xx.xx.xx\e$\DACPAC\WW\SIT31'

$XmlList = Get-ChildItem -Path $DacpacPath -Filter '*.config' -Recurse | Select-Object Name, Directory, FullName
$DacList = Get-ChildItem -Path $DacpacPath -Filter '*.dacpac' -Recurse | Select-Object Name, Directory, FullName

foreach ($Xml in $XmlList) {
    # get content
    [XML]$XmlFile = Get-Content $Xml.FullName

    # dacpac options
    $do = $null # clear options in case it carries over
    foreach ($o in $XmlFile.deployments.options) {
        $do = [PSCustomObject]@{
            Key   = $o.option.Key
            Value = $o.option.Value
        }
    }

    # dacpac setings and variables
    foreach ($d in $XmlFile.deployments.dacpac) {
        $dp = [PSCustomObject]@{
            App       = ($Xml.FullName).Split('\')[-2]
            Filename  = $d.name
            Database  = $d.db
            Instance  = $d.instance
            Variables = $d.variables.variable
            Options   = $do
        }
        $Dacpacs += $dp
    }
}

$table = foreach ($dacpac in $Dacpacs) {
    $dac = $DacList | Where-Object {$_.Name -eq $dacpac.Filename}
    [PSCustomObject]@{
        App = $dacpac.App
        Filename = $dacpac.Filename
        Database = $dacpac.Database
        # Instance = $dacpac.Instance
        # Variables = $dacpac.Variables
        FullPath = $dac.FullName
    }
}

$table | Sort-Object App, Database | Format-Table