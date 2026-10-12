<#
.Setup:
    1. Create subscription on Collector. Add clients, filter on EventID wanted.

    2. On clients:

        Configure Security Log Access GPO, this gives access to Network Service to read Security Log.
        The last piece is what gives that access, the rest is the defaults.
            
        '\Windows Components\Event Log Service\Security'
            O:BAG:SYD:(A;;0xf0005;;;SY)(A;;0x5;;;BA)(A;;0x1;;;S-1-5-32-573)(A;;0x1;;;NS)
        
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

try {
    $events = Get-WinEvent -FilterHashtable @{
        Logname   = 'ForwardedEvents'
        ID        = '4625'
        StartTime = (Get-Date).AddMinutes(-65)
    } -ErrorAction Ignore
}
catch {
    Write-Output 'Failed to read Forwarded Events.'
}

if ($events) {

    $data = foreach ($event in $events) {
        [PSCustomObject]@{
            Id               = [INT]$event.Id
            LevelDisplayName = $event.LevelDisplayName
            LogName          = $event.LogName
            MachineName      = $event.MachineName
            Username         = $event.Properties[5].Value
            Domain           = $event.Properties[6].Value
            Hostname         = $event.Properties[13].value
            ProviderName     = $event.ProviderName
            RecordID         = [INT]$event.RecordId
            TaskDisplayName  = $event.TaskDisplayName
            TimeCreated      = [DateTime]$event.TimeCreated
        }
    }

    if ($data) {
        try {
            Write-SqlTableData -ServerInstance 'ip,port' -DatabaseName 'DBA' -SchemaName 'dbo' -TableName 'LogonErrors_T' -InputData $data
            Write-Output 'Data inserted.'
        }
        catch {
            Write-Output 'Data failed to insert.'
        }
    }
}
