############################################################################
# init
#region ####################################################################
$Now = Get-Date
"Start: {0}" -f $Now
$ErrorActionPreference = 'Stop'

# instance config
$Instance = 'hostnameCLS1LS1,15150'
$Database = 'DBA'
$Schema = 'dbo'

# table names
$ServerTable = 'Servers_T'

# get domain to store with server
$Domain = (Get-ADDomain).Name
#endregion


############################################################################
# create data tables to store all our data
#region ####################################################################
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
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'Edition', ([String])))
#endregion

############################################################################
# gather sql server instance list
#region ####################################################################

# servers that have 'checked-in' in the past 60 days
$60DaysOld = (Get-Date).AddDays(-60)

# gets all SQL SPNs
$SqlSPNs = (Get-ADObject -LDAPFilter '(servicePrincipalName=MSSQLsvc*)' -Properties *).servicePrincipalName | Where-Object { $_ -like "MSSQLSvc/*" } | Sort-Object -Unique

"Finding servers, please hold ..."

foreach ($SPN in $SqlSPNs) {
    try {
        $Name = $SPN.Split('/')[1].Split(':')[0].Split('.')[0]
        $Port = $SPN.Split('/')[1].Split(':')[1]
        
        if (-not ($null -ne ($Port -as [int]) -and $null -ne $Port)) {
            continue
        }
        
        "{0}:{1}" -f $Name, $Port
    
        $adobj = Get-ADComputer -Identity $Name -Properties *
    
        if ($adobj.LastLogonDate -lt $60DaysOld) {
            "`told entry"
            continue       
        }
                    
        $TcpClient = New-Object System.Net.Sockets.TcpClient
        if (-not ($TcpClient.ConnectAsync($Name, $Port).Wait(100))) {
            "`tcouldnt connect"
            continue
        }
                
        $details = Get-SqlInstance -ServerInstance "$Name,$Port" -ErrorAction SilentlyContinue
                    
        if ($details.InstanceName -ne '') { $instancename = $details.InstanceName } else { $instancename = 'MSSQLSERVER' }

        switch ($details.VersionMajor) {
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
        $SqlServerRow['Domain'] = $Domain
        $SqlServerRow['ServerName'] = $Name
        $SqlServerRow['IP'] = $adobj.IPv4Address
        $SqlServerRow['OS'] = $adobj.OperatingSystem
        $SqlServerRow['Product'] = $details.Product + $version
        $SqlServerRow['Version'] = $details.Version
        $SqlServerRow['SP'] = $details.ProductLevel
        $SqlServerRow['CU'] = $details.ProductUpdateLevel
        $SqlServerRow['Instance'] = $instancename
        $SqlServerRow['Port'] = $Port
        $SqlServerRow['Edition'] = $details.Edition
        $SqlServersDT.Rows.Add($SqlServerRow)
    }
    catch {
        $ErrorException = $_.Exception
        "Failed to get details for {0}:{1}" -f $Name, $Port
        $ErrorException
        continue
    }
}


# set all records 
"Server Found: {0}" -f $SqlServersDT.Rows.Count
Write-SqlTableData -InputData $SqlServersDT -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $ServerTable

"End: {0}" -f (Get-Date)