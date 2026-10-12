<#
.Setup:
    1. Create subscription on Collector. Add clients, filter on EventID wanted.

    2. On clients:

        Configure Security Log Access GPO, this gives access to Network Service to read Security Log.
        The last piece is what gives that access, the rest is the defaults.
            
        '\Windows Components\Event Log Service\Security'
            O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)

        For a windows user login like sqladmin.decss(below) add this and then add them with READ in REGEDIT in HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\EventLog\Security
            O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;S-1-5-21-1645615794-367192540-85531141-34110)
        
	    Add subscription Manager Endpoint to know where to send events to.

        '\Windows Components\Event Forwarding'
		    Server=http://<FQDN>:5985/wsman/SubscriptionManager/WEC,Refresh=60

    3. Run the corresponding sql script to create the table to house the data.

    4. Setup this script to run on the collector to push the data to SQL. Hourly 
    is best. The script looks back 65 minutes for events, this give a 5 minute buffer
    for this job to execute. Frequency can be changed if you change the event look 
    back time to match. 2 hours frequency, look back 2 hours + 5 mins. More buffer time
    may be needed if the frequency time is long.
#>

# where the data is stored
$DBAInstance = 'xx.xx.xx.xx,15150'

# get list of servers we want to collect from
$Servers = Read-SqlTableData -ServerInstance $DBAInstance -Database 'DBA' -SchemaName 'dbo' -TableName 'Servers_T'

# get domain we are running in 
$Domain = $env:USERDOMAIN

# get local ip to find zone
$IPAddress = (Test-Connection $env:COMPUTERNAME -Count 1 | Select-Object -First 1).IPV4Address.IPAddressToString

# determine our network zone
switch -Wildcard ($IPAddress) {
    "172.31.23*" { $Zone = 'EL2' }
    "172.31.45.*" { $Zone = 'IMDZ3' }
    "172.31.121.*" { $Zone = 'IDEV' }
    default { $Zone = $null }
}

# 6:00:00am yesterday to 5:59:59am today
$Yesterday = (Get-Date -Hour 6 -minute 0 -Second 0).AddDays(-1)
# $Today = (Get-Date -Hour 5 -minute 59 -Second 59)
$Today = (Get-Date)

# create data table
$datatable = New-Object System.Data.DataTable
$datatable.Columns.Add((New-Object System.Data.DataColumn 'ID', ([int]))) # this table ID, not a data field to capture or set
$datatable.Columns.Add((New-Object System.Data.DataColumn 'RecordTime', ([DateTime])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'EventId', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'LogName', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'ServerHostname', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'Username', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'Domain', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'SourceHostname', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'EventRecordID', ([Int])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'EventType', ([String])))
$datatable.Columns.Add((New-Object System.Data.DataColumn 'EventTime', ([DateTime])))

# grabs events
try {
    $events = Get-WinEvent -FilterHashtable @{
        Logname   = 'ForwardedEvents'
        ID        = '4625'
        StartTime = $Yesterday
        EndTime   = $Today
    } -ErrorAction Stop
}
catch {
    $ErrorException = $_
    if ($ErrorException.CategoryInfo.Category -eq 'ObjectNotFound') {
        'No events found.'
    }
    else {
        throw 'Couldnt get winevents.'
    }
}

if ($events.count -ne 0) {
    foreach ($rec in $events) {
        $row = $datatable.NewRow()
        $row['RecordTime'] = [DateTime](Get-Date)
        $row['EventId'] = [INT]$rec.Id
        $row['LogName'] = $rec.LogName
        $row['ServerHostname'] = $rec.MachineName
        $row['Username'] = $rec.Properties[5].Value
        $row['Domain'] = $rec.Properties[6].Value
        $row['SourceHostname'] = $rec.Properties[13].value
        $row['EventRecordID'] = [INT]$rec.RecordId
        $row['EventType'] = $rec.TaskDisplayName
        $row['EventTime'] = [DateTime]$rec.TimeCreated
        $datatable.Rows.Add($row)
    }
    Write-SqlTableData -ServerInstance $DBAInstance -DatabaseName 'DBA' -SchemaName 'dbo' -TableName 'LogonErrors_T' -InputData $datatable -Force
    Write-Output 'Data inserted.'
}
