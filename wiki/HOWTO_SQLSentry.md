# SQL Sentry

## Architecture

### Sentry Monitoring Service servers

| Zone       | Domain      | Server             | IP                 | Subnet Monitored    | Service Account          |
| ---------- | ----------- | ------------------ | ------------------ | ------------------- | ------------------------ |
| EL2        | dom        | hostSENTRY02     | xx.xx.xx.xx      | xx.xx.xx.xx/23     | dom\SENTRY.ADMIN        |
| IDMZ3      | dom        | hostSENTRY01     | xx.xx.xx.xx       | xx.xx.xx.xx/24      | dom\SENTRY.ADMIN        |
| EL2        | domTEST    | hostSENTRY01     | xx.xx.xx.xx      | xx.xx.xx.xx/23     | domTEST\SENTRY.ADMIN    |
| IDMZ3      | domTEST    | hostSENTRY02     | xx.xx.xx.xx       | xx.xx.xx.xx/24      | domTEST\SENTRY.ADMIN    |
| ~~DEV~~    | ~~domDEV~~ | ~~hostSENTRY03~~ | ~~xx.xx.xx.xx~~ | ~~xx.xx.xx.xx/24~~ | ~~domDEV\Sentry.Admin~~ | 
| State-Only | STATE       | hostSENTRY04     | xx.xx.xx.xx      | xx.xx.xx.xx/24     | STATE\dept.SENTRY        |

Nothing to monitor in DEV anymore, previously used for TFS, but its decomm'd for DevOps and its in EL2.

### SQL Sentry Data Store

| Zone      | Domain | Cluster      | Server         | IP            | Port  |
| --------- | ------ | ------------ | -------------- | ------------- | ----- |
| Non-Infra | STATE  | hostnidbc2 | hostnidbc2n1 | xx.xx.xx.xx | 15150 |
| Non-Infra | STATE  | hostnidbc2 | hostnidbc2n2 | xx.xx.xx.xx | 15150 |

| SQL Listener    | SQL Listener IP | Port  |
| --------------- | --------------- | ----- |
| hostnidbc1ls1 | xx.xx.xx.xx   | 15150 |


## Desktop Client

### Installation

Installer: ```I:\BaseTech\SentryOne\SolarWinds-SQLSentry-UnifiedInstaller-2025.3.1.exe``` or if you dont have I browse to: ```\\deptfp014\dmsirm$\BaseTech\SentryOne```

Configuration during install:

- Server: ```xx.xx.xx.xx,15150```
- Database: ```Sentry_Solarwinds_PROD```
- Integrated Security: ```Yes```

## Register Instance

1. Determine which subnet and thus which monitoring service is needed for the instance you want to add.
2. RDP to the monitoring server. 
3. Open SQL Sentry
4. Add a new SQL Server under the grouping that corresponds to the Monitoring service.
5. Add hostname & port for the instance. Dont use integrated security, enter ```sentry``` and use the password from Keepass.
6. Click connect and let it scan the instance/server. It should be able to complete all tasks(shown as green).
7. Click Next and complete the process.