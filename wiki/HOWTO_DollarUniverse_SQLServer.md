# Connect Dollar Universe to SQL server

## Connection Parameters

### Options

- **Configuration name**: Can be anything, but cannot rename the default connection. Additional connects can be added as needed.
- **Server**
  - **SQL Server host**: IP/Hostname and Port, example: ```xx.xx.xx.xx:15150``` Note this is not using the standard port notation SQL uses else where, this is using a colon, not a comma.
  - **SQL Server instance**: can be blank if entered port above, else enter instance name.
- **Authentication**
  - **Login**: Enter SQL login name, Windows logins not supported. We typically use a SQL login named ```dept.scheduler```
  - **Password**: Password can be found in **Keypass**.
- **Connections advanced Parameters**
  - **Advanced parameters**: It attempts to use a secure connection by default, we need to either trust the certificate as we do not have our cert chain added in the java keystore or force a non-TLS connection. If connecting to an SQL/AG listener, set option for that as well. ```trustServerCertificate=true;multiSubnetFailover=true```