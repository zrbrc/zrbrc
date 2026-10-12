<#
.SYNOPSIS
    Detach and attach DBs
.DESCRIPTION
    This creates a PS object of DBs and files and saves it to an XML file. It then detachs those DBs so the drive can be move to another VM.
    If the pathes on any files on the target server are to be changed, update the paths to match in the XML file. Once all have been updated,
    run the second half of the script to import that xml file and attach all the DBs according to the XML file.
    There are 2 sections of part 2, one creates sql to do the work, the second section does the attach via dbatools, if the later doesnt work, try the former
.OUTPUTS
    Creates XML file of data files in part 1, gets created in same folder as script.
.INPUTS
    Uses XML file from part 1 as input for second part, should be in same folder script.
.NOTES
    None
#>

<#
    Part 1 on Source Server
#>

Set-Location $PSScriptRoot

$sourceinstance = 'localhost,15150'

# capture the source data file info
$query = 'SELECT db.Name AS dbname, type_desc AS FileType, mf.Name, Physical_Name AS filename FROM sys.master_files mf INNER JOIN sys.databases db ON db.database_id = mf.database_id where db.name not in (''master'',''msdb'',''tempdb'',''model'')'
$source = Invoke-DbaQuery -SqlInstance $sourceinstance -Query $query

# save it to xml so we can copy it to the target server
$source | Export-Clixml '.\files.xml'

# WARNING: this will detach all non-system DBs
$dbs = Get-DbaDatabase -SqlInstance $sourceinstance -ExcludeSystem
$exc = 'WWI','Empty2'
$dbs | Where-Object {$_.Name -notin $exc}
# | Dismount-DbaDatabase -force

<#
    Part 2 on Target Server
#>
Set-Location $PSScriptRoot

# init
$targetinstance = 'localhost,15150'

# static
$HeaderSql = @()
$HeaderSql += 'USE [master]'
$HeaderSql += 'GO'

# copy xml to target and now attach them
$target = Import-Clixml '.\files.xml'

# gets list of just dbs so we can loop thru them and its files
$dbs = $target | Sort-Object dbname -Unique | Select-Object -ExpandProperty dbname

# for each DB we have, find its related files and create a filesctructure object to pass to the attach cmd
foreach ($db in $dbs) {
    


    # create t-sql approach
    $Sql = @()
    $Sql += "CREATE DATABASE [$db] ON"
    $FileSql = @()
    foreach ($row in $target | Where-Object { $_.dbname -eq $db }) {
        $FileSql += "(FILENAME = N'$($row.filename)')"
    }
    $Sql += $FileSql -join ",`n"
    $Sql += 'FOR ATTACH'
    $Sql += "GO"
    $HeaderSql + $Sql | Out-File ".\attach_$(Get-Date -Format 'yyyyMMdd').sql" -Append



    # dbatools method
    $fileStructure = New-Object System.Collections.Specialized.StringCollection
    foreach ($row in $target | Where-Object { $_.dbname -eq $db }) {
        $fileStructure.Add($row.filename) | Out-Null
        
    }
    # Mount-DbaDatabase -SqlInstance $targetinstance -Database $db -FileStructure $fileStructure


}