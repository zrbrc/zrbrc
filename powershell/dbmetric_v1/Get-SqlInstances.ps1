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

#Requires -Modules SqlServer

if (Get-Module SqlServer -ListAvailable) { 
    Import-Module SqlServer
}


# test DBA target instance 
if (-not (Get-SqlInstance -ServerInstance $Instance)) {
    throw 'Cant connect to DBA instance.'
    exit
}

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
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'History_CD', ([Int])))
$SqlServersDT.Columns.Add((New-Object System.Data.DataColumn 'LastWindowsUpdate', ([String])))
#endregion

############################################################################
# gather sql server instance list
#region ####################################################################

"Start: {0}" -f (Get-Date)

# servers that have 'checked-in' in the past 60 days
$60DaysOld = (Get-Date).AddDays(-60)

# gets all SQL SPNs
$SqlSPNs = (Get-ADObject -LDAPFilter '(&(servicePrincipalName=MSSQL*)(sAMAccountName=*sqladmin*))' -Properties *).servicePrincipalName | Where-Object { $_ -like "MSSQLSvc/*" } | Sort-Object -Unique

"Finding servers, please hold ..."

foreach ($SPN in $SqlSPNs) {
    try {
        $Name = $SPN.Split('/')[1].Split(':')[0].Split('.')[0]
        $Port = $SPN.Split('/')[1].Split(':')[1]
        
        if (-not ($null -ne ($Port -as [int]) -and $null -ne $Port)) {
            continue
        }
        
        "{0}:{1} ..." -f $Name, $Port
    
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
        
        $LastWindowsUpdate = (Get-Hotfix -ComputerName $Name | Select-Object -Last 1).InstalledOn.ToString('yyyy/MM/dd hh:mm:ss')

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
        $SqlServerRow['History_CD'] = 0
        $SqlServerRow['LastWindowsUpdate'] = $LastWindowsUpdate
        $SqlServersDT.Rows.Add($SqlServerRow)
    }
    catch {
        $ErrorException = $_.Exception
        "Failed to get details for {0}:{1}" -f $Name, $Port
        $ErrorException
        continue
    }
}

# mark all matching hostnames as we collected above as history
$sql = "UPDATE $ServerTable SET History_CD = 1 WHERE History_CD = 0 AND Servername IN ("
$sql += "'"
$sql += $SqlServersDT.Servername -join "', '"
$sql += "')"

Invoke-Sqlcmd -ServerInstance $Instance -Database $Database -Query $sql -OutputSqlErrors $true -Verbose

$SqlServersDT | Write-SqlTableData -ServerInstance $Instance -Database $Database -SchemaName $Schema -TableName $ServerTable -Force

"Data stored to: {0}.{1}.{2}.{3}" -f $Instance, $Database, $Schema, $ServerTable

"End:   {0}" -f (Get-Date)
