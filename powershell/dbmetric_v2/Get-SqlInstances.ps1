Set-Location $PSScriptRoot

Start-Transcript .\log\Get-SqlInstances_log.txt

. .\includes\Config.ps1

# create data tables to store all our data
$SqlServersDT = New-Object System.Data.DataTable
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'ID', ([Int])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'Timestamp', ([DateTime])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'Domain', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'ServerName', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'IP', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'OS', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'Product', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'Version', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'SP', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'CU', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'Instance', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'Port', ([String])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'History_CD', ([Int])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'CoreCount', ([int])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'MemoryMB', ([int])))

"Finding instances to scan, please hold ..."

$query = 'SELECT ServerName, Ip, Port FROM Servers WHERE Active = 1'
$instances  =  Invoke-Dbaquery -SqlInstance $datastore_instance -Database $datastore_database -Query $query -SqlCredential $sqlmetrics

foreach ($inst in $Instances) {
    try {
     
        "Querying: {0}:{1} ..." -f $Inst.IP, $inst.Port
    
        $TcpClient = New-Object System.Net.Sockets.TcpClient
        if (-not ($TcpClient.ConnectAsync($Inst.IP, $inst.Port).Wait(100))) {
            $query = "UPDATE Servers SET Active = 0, Status = 'NOT OPEN ', Scanned = GETDATE() WHERE ServerName = '$($inst.ServerName)' AND Ip = '$($inst.IP)' AND Port = $($inst.Port)"
            Invoke-Dbaquery -SqlInstance $datastore_instance -Database $datastore_database -Query $query -SqlCredential $sqlmetrics
            continue
        }
        else {
            $query = "UPDATE Servers SET Active = 1, Status = 'OPEN', Scanned = GETDATE() WHERE ServerName = '$($inst.ServerName)' AND Ip = '$($inst.IP)' AND Port = $($inst.Port)"
            Invoke-Dbaquery -SqlInstance $datastore_instance -Database $datastore_database -Query $query -SqlCredential $sqlmetrics
        }

        $i = "{0},{1}" -f $Inst.IP, $inst.Port
        $server = Connect-DbaInstance -SqlInstance $i -TrustServerCertificate -SqlCredential $sqlmetrics

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

        $query = 'SELECT cpu_count AS CoreCount, physical_memory_kb/1024 AS MemoryMB FROM sys.dm_os_sys_info'
        $specs = Invoke-DbaQuery -SqlInstance $i -SqlCredential $sqlmetrics -Query $query

        $SqlServerRow = $SqlServersDT.NewRow()
        $SqlServerRow['Timestamp'] = $Now
        $SqlServerRow['Domain'] = (($server.ServiceAccount).Split('\')[0]).ToUpper()
        $SqlServerRow['ServerName'] = $server.NetName
        $SqlServerRow['IP'] = $Inst.IP
        $SqlServerRow['OS'] = $server.HostDistribution
        $SqlServerRow['Product'] = $server.Product + $version
        $SqlServerRow['Version'] = $server.Version
        $SqlServerRow['SP'] = $server.ProductLevel
        $SqlServerRow['CU'] = $server.ProductUpdateLevel
        $SqlServerRow['Instance'] = $server.ServiceName
        $SqlServerRow['Port'] = $Inst.Port
        $SqlServerRow['History_CD'] = 0
        $SqlServerRow['CoreCount'] = $specs.CoreCount
        $SqlServerRow['MemoryMB'] = $specs.MemoryMB
        $SqlServersDT.Rows.Add($SqlServerRow)
    }
    catch {
        "Failed to get server for {0}:{1}" -f $inst.ip, $inst.port
        continue
    }
}

if ($SqlServersDT.Rows.Count -gt 0) {

    # mark all matching hostnames as we collected above as history
    $sql = "UPDATE $InstanceTable SET HistoryCode = 1 WHERE HistoryCode = 0 AND Servername IN ("
    $sql += "'"
    $sql += $SqlServersDT.Servername -join "', '"
    $sql += "')"
    
    Invoke-DbaQuery -SqlInstance $datastore_instance -Database $datastore_database -Query $sql -SqlCredential $sqlmetrics -EnableException
    
    $SqlServersDT | Write-DbaDbTableData -SqlInstance $datastore_instance -Database $datastore_database -Table $InstanceTable -SqlCredential $sqlmetrics -EnableException
    
    "Data stored to: [{0}].[{1}].[dbo].[{2}]" -f $datastore_instance, $datastore_database, $InstanceTable

}

"End:   {0}" -f (Get-Date)

Stop-Transcript
