$Dacpacs = @()
$DacpacPath = '\\xx.xx.xx.xx\e$\DACPAC\*\SITCR'

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

# gets file name from .config files
$Filename = $Dacpacs | Where-Object { $_.Database -eq 'DSS_WorkerWeb_SITCR' } | Select-Object -ExpandProperty Filename | Sort-Object -Unique

# gets full path for correct dacpac
$DacpacFile = $DacList | Where-Object { $_.Name -eq $Filename } | Sort-Object LastWriteTime | Select-Object -ExpandProperty Fullname -First 1
$DacpacFile