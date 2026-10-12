# Find events in Splunk

## Azure

### Wordpress

    source="eventhub://evhns-dept-osec-shared-prod-001.servicebus.windows.net/evh-frontdoor-dept-osec-prod-001;"| spath "properties.ruleName" | search "properties.ruleName"="customBlockBadActor"

### Windows Secuity Log

    source="WinEventLog:Security" user.name

    source="WinEventLog:Security" Source_Network_Address="xx.xx.xx.xx" EventCode=4625