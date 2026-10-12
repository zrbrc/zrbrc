# Notes

Open Internet Options for another user

- Open a cmd prompt as that user.
- run ```inetcpl.cpl ,4```
  
## Settings

Set system-wide proxy, change bypass list as needed. This is what is needed for SSIS test.

    netsh winhttp set proxy proxy-server="dmzproxy.delaware.gov:8080" bypass-list="*.state.de.us;172.31.*.*"

## SSRS

In-palce OS upgrades makes the SSRS console not show the local instance. You make make it re-register it after upgrade with the below, adjust path as necessary.

    mofcomp "C:\Program Files\Microsoft SQL Server\MSRS12.RD2014_1\Reporting Services\ReportServer\bin\reportingservices.mof"