# SQL Server Build Checklist

This is intented to be a checklist to verify a SQL build before deploying it live.

## Checklist

### Server

- Correct time source. Verify via ```w32tm /query /source```. It should show the domain controller not CMOS/Bios or Free-running. If this is wrong, it can be fixed by re-registering the Time service or you can ask Telecomm to do the same.

   ````bat
   Net Stop W32time
   W32tm.exe /unregister
   W32tm.exe /register
   Net Start W32time
   w32tm /query /source
   ````

   If the above doesnt work and it doesnt show/sync via the domain, force it. (source: https://learn.microsoft.com/en-us/windows-server/networking/windows-time-service/windows-time-service-tools-and-settings)

   ````bat
   w32tm /config /syncfromflags:DOMHIER /update
   w32tm /resync /nowait
   net stop w32time
   net start w32time
   w32tm /query /source
   ````



### SQL

- Verify User Database Backups--FULL, DIFF, and LOG are active (if necessary) and their retention and LogToTable options are set correctly. LogToTable is not necessary for log backups due to their high frequency. Log backups also have a shorter CleanupTime than FULL and DIFF. This can depend on the app and SLA policies, so please check wwith business team on requirements.
- Verify System Database Backups--FULL is active. Should be set for Daily 7pm, CleanupTime = 24, and LogToTable 'Y'.

### Network \ AD

- Verify server(s) (and cluster) are in the correct OU and the cluster CNO has create computer permissions to the OU. Command to do this is in HOWTO_WindowsCluster-AD-Permissions.md.
- WSUS is able to find/check for updates. It may not show any available if not setup on the WSUS side correctly, you can ask Telecomm to verify. This is somewhat related to verifiing that the server is in the correct OU as that sets WSUS policies, but if its not added in WSUS to begin with, the OU wont matter.
- FOR TEST ONLY - Setup Cluster Aware updating, the previous step needs to be completed first. Ask telecomm to request a Crowdstrike exception with DTI for the cluster. There was some work being done with remote reboots being part of a default Crowdstrike exception, so this may no be needed. You can attempt to configure CAU and run ```Test-CauSetup``` to see if the remote reboot works or not. If not, request an exception.
- Verify DNS and reverse DNS exist for the all the hostnames and IPs for SQL instances and listener if applicable. Can be checked with ```Resolve-DnsName <hostname and IP>```

## Check script
