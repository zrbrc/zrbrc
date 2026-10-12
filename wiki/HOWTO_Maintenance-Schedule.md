# Maintenance Schedule

## DEV WSUS - Sunday 11am after the 2nd tuesday of Month

### Schedule
- 1st Tuesday: Prod (clustered)
- 2nd Tuesday: Test (non-clustered)
- 3rd Tuesday: Test (clsutered)
- 4th Tuesday: Prod (non-clustered)

### Template

```

# ONGOING

https://certificates.domain.com/

Please email with any additions or updates.

# ONCALL
- Basetech: 
- Telecomm: 

# RFC

# PROD

# TEST

# DEV

```

### EXAMPLES

```
# PROD

- Oracle WSUS & Reboots
- SQL Server backup servers: Assist & DECSS/DEPT
- SQL Database Clusters WSUS & Reboots:
  - DECSS
  - DICER
  - Assist
  - MCI/Biztalk
  - State-Only
  - Dept SQL2014 & SQL2019
- Web, App, DICER, Corticon, TFS, BizTalk, ScaleOut, SSRS, & SSIS WSUS & Reboots
- Dollar Universe UVMS WSUS & Reboot

# RFC
- 684: Add disk space to Assist cluster (xx.xx.xx.xx/103/105)
- 685: Correct IPv6 registry entry and reboot hostmciap01,02,03
- 686: Group Policy Windows 11 changes
- 687: Group Policy PST changes

# TEST
- Automatic WSUS and reboots (non-clustered)

# DEV 
- Oracle WSUS and reboots

## TEST

- VMware tools upgrades and reboots: All of EL2 TEST, please see attachment for server list
- Oracle January 2020 CPU, WSUS, & Reboots
- SQL Database Clusters WSUS & Reboots:
  - DECSS: CAU
  - DICER: CAU
  - Assist: CAU
  - Biztalk 2013
  - Biztalk 2020: CAU
  - Dept: CAU
  - State-Only/Non-infra: CAU
- Web, App, DICER, Corticon, TFS, BizTalk, ScaleOut, SSRS, & SSIS WSUS & Reboots
- Thunderhead maintenance

```