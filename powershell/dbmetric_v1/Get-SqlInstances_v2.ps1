<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>
Set-Location $PSScriptRoot

. .\config\Config.ps1
. .\config\Instances.ps1

Import-Module .\modules\SqlServer

# test DBA target instance 
if (-not (Get-SqlInstance -ServerInstance $Instance -TrustServerCertificate -Credential $basetech_old)) {
    throw 'Cant connect to DBA instance.'
    exit
}

# create data tables to store all our data
$SqlServersDT = New-Object System.Data.DataTable
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([Int])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'Timestamp', ([DateTime])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'Domain', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'Servername', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'IP', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'OS', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'Product', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'Version', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'SP', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'CU', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'Instance', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'Port', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'History_CD', ([Int])))

"Start: {0}" -f (Get-Date)

"Finding instances, please hold ..."

foreach ($inst in $Instances) {
    try {
        $Ip = $inst.Split(',')[0]
        $Port = $inst.Split(',')[1]
      
        "{0}:{1} ..." -f $Ip, $Port
    
        $TcpClient = New-Object System.Net.Sockets.TcpClient
        if (-not ($TcpClient.ConnectAsync($Ip, $Port).Wait(100))) {
            "`tPORT NOT OPEN"
            continue
        }
        try {
            $server = Get-SqlInstance -ServerInstance "$Ip,$Port" -TrustServerCertificate -Credential $basetech
        }
        catch {
            $server = Get-SqlInstance -ServerInstance "$Ip,$Port" -TrustServerCertificate -Credential $basetech_old
        }

        if ($server.InstanceName -ne '') { $instancename = $server.InstanceName } else { $instancename = 'MSSQLSERVER' }

        switch ($server.VersionMajor) {
            '16' { $version = ' 2022'  }
            '15' { $version = ' 2019'  }
            '14' { $version = ' 2017'  }
            '13' { $version = ' 2016'  }
            '12' { $version = ' 2014'  }
            '11' { $version = ' 2012'  }
            '10' { $version = ' 2008'  }
            '9' { $version = ' 2005'  }
            Default {$version = "" }
        }

        $SqlServerRow = $SqlServersDT.NewRow()
        $SqlServerRow['Timestamp'] = $Now
        $SqlServerRow['Domain'] = ($server.ServiceAccount).Split('\')[0]
        $SqlServerRow['ServerName'] = $server.NetName
        $SqlServerRow['IP'] = $Ip
        $SqlServerRow['OS'] = $server.HostDistribution
        $SqlServerRow['Product'] = $server.Product + $version
        $SqlServerRow['Version'] = $server.Version
        $SqlServerRow['SP'] = $server.ProductLevel
        $SqlServerRow['CU'] = $server.ProductUpdateLevel
        $SqlServerRow['Instance'] = $server.ServiceName
        $SqlServerRow['Port'] = $Port
        $SqlServerRow['History_CD'] = 0
        $SqlServersDT.Rows.Add($SqlServerRow)
    }
    catch {
        "Failed to get server for {0}:{1}" -f $Ip, $Port
        continue
    }
}


if ($SqlServersDT.Rows.Count -gt 0) {

    # mark all matching hostnames as we collected above as history
    $sql = "UPDATE $ServerTable SET History_CD = 1 WHERE History_CD = 0 AND Servername IN ("
    $sql += "'"
    $sql += $SqlServersDT.Servername -join "', '"
    $sql += "')"
    
    Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $sql -OutputSqlErrors $true -Verbose -TrustServerCertificate -Credential $basetech_old
    
    $SqlServersDT | Write-SqlTableData -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $ServerTable -Force -TrustServerCertificate -Credential $basetech_old
    
    "Data stored to: {0}.{1}.{2}.{3}" -f $Instance, $Database, $Schema, $ServerTable

}

"End:   {0}" -f (Get-Date)
