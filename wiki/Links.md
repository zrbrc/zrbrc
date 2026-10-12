# Links

## Work Links
### KACE
- https://depthelpdesk.domain.com/

### Okta Portal
Internal dom for leave, training, VPN, etc.
- https://id.delaware.gov/

### Request For Change app
Any production configuration changes must have an RFC submitted and approved during the weekly Change Advisory Board (CAB) meeting. You will be invited once submitted.
- https://rfc.domain.com/

### Migration app
This is used by Basetech and the Application teams (Maintenance and Support/M&S/MNS). They create migration requests and we work them. Production migrations are Thursday evenings unless its an emergency. Other environments are when requested and available to do the work.
- https://migrations.domain.com/

### Basetech Database on-call list
- https://wss.domain.com/dms/irm/Enterprise%20Operations/Forms/AllItems.aspx?RootFolder=%2Fdms%2Firm%2FEnterprise%20Operations%2FOn%5FCall%5FList%2FBasetech%5FOn%2DCall%5FList

### Basetech DBA git repo
- https://tfs.domain.com/tfs/dept/DMS_BaseTech/_git/DBA

### Basetech Sharepoint site
- https://wss.domain.com/dms/irm/basetech/default.aspx

## Software

### VS Code

#### How to Set Up Visual Studio Code to Work with GitHub/TFS

https://adamtheautomator.com/visual-studio-code-github/

### SQL Server

#### MSDTC Best Practices with an Availability Group

https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/msdtc-best-practices-with-an-availability-group/ba-p/909429

#### Statistics

##### Brent Ozar - An Introduction to Microsoft SQL Server's Statistics

https://www.youtube.com/watch?v=uqkf1VVZulg

##### Brent Ozar - Identifying and Fixing Parameter Sniffing Issues

https://www.youtube.com/watch?v=pd7xqLT_-2k

### SQL Agent

#### Tokens to use in Sql Agent job output path

https://docs.microsoft.com/en-us/sql/ssms/agent/use-tokens-in-job-steps?view=sql-server-ver15

``` t-sql
M:\Management\Reports\$(ESCAPE_SQUOTE(JOBNAME))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt
```

### Query Store

#### Overview

https://www.youtube.com/watch?v=HZIkOGDpq3E

#### Settings

https://www.sqlskills.com/blogs/erin/query-store-settings/

#### Enabling QS will Flush Plan Cache

https://www.sqlskills.com/blogs/erin/query-store-and-the-plan-cache-flushing/


#### Contraints

https://sqlserverfast.com/blog/hugo/2007/03/can-you-trust-your-constraints/