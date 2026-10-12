# Cluster Setup

## Cluster AD Setup basics

This setup is going with the assumption that we are creating this for a SQL Server Availability Group cluster.

### Pre-requirements

- Two or more servers to create the cluster with names and IPs
- Cluster name (CNO) and IP
- SQL Listener names (VCO) and IPs

### Cluster requirements links

- Overview of creating a cluster, accounts and permissions: <https://docs.microsoft.com/en-us/windows-server/failover-clustering/configure-ad-accounts>
- Specific related to pre-staging/creating the cluster object in AD the cluster needs to function: <https://docs.microsoft.com/en-us/windows-server/failover-clustering/prestage-cluster-adds>

### Cluster Objects

There are 2 options, either have a domain admin create the cluster or pre-stage the object. The first option should create the objects with the proper permissions needed and is prefered since Basetech does not have the permissions to create a cluster.

#### Option 1 (domain admin)

#### Note: If you are having an issue moving the CNO to another OU, try unchecking 'Protect object from accidental deletion', move, and then re-check.

1. From an elevated prompt, create a cluster, this will create the needed AD objects and update DNS. Run a 'get' to verify the cluster created.

       New-Cluster -Name <clustername> -Node <nodename>,<nodename> -NoStorage -StaticAddress <172.31.x.x> -AdministrativeAccessPoint ActiveDirectoryAndDns
       Get-ClusterNode

1. Move CNO to correct OU. Since we probably want to run CAU on the cluster (if in TEST), we should move it to the 'WSUS Manual OU'. This may be different in each domain, but this is the correct OU for TEST. Telecomm would know the correct info here. After, run a 'get' to verify the DistinguishedName is showing the correct OU.

       Get-ADComputer <clustername> | Move-ADObject -TargetPath "OU=WSUS Manual,OU=Servers,DC=domTest,DC=dept"
       Get-ADComputer <clustername>

#### Option 2 (domain admin)

1. Create (pre-stage) the CNO. CNO pre-stage guide states to disable the computer object after creation, so we are setting Enabled to false here. After, run a 'get' to verify creation.

       New-ADComputer -Name <clustername> -SamAccountName <clustername> -Path "OU=WSUS Manual,OU=Servers,DC=domTest,DC=dept" -Enabled $false
       Get-ADComputer -Name <clustername>

1. Grant create computer to the CNO we just created in the same OU. THis will allow the cluster to create the VCO/SQL Listeners as needed in AD.

       dsacls.exe "OU=WSUS Manual,OU=Servers,DC=domTest,DC=dept" /G clustername$:CC;computer

### Post cluster configuration and validation

#### Cluster Only Network

Make sure Telecomm has added a second cluster only network to each node. This can be viewed in Failover Cluster Manager

#### Fileshare Witness

| Domain   | Zone  | Witness Path               |
| -------- | ----- | -------------------------- |
| dom     | EL2   | \\\hostfp01\\witness     |
| dom     | IDMZ3 | \\\_\_                     |
| domtest | EL2   | \\\hostfp02\\witness     |
| domtest | IDMZ3 | \\\\hostfp04\\hostWitness |

1. Connect to one of the nodes in the cluster.
1. Open an elevated admin prompt and run ``Get-Cluster``. Copy and paste this name to save for the next step.
1. Browse to the correct path above, right-click, **Properties**, **Security**, **Advanced**,  and add permissions for the cluster name to the folder with **Full control**, apply permissions.
1. Once the permission is set, go back to the elevated powershell window and run the command with the correct path for the domain\zone. This is the same path from the previous step.

       Set-ClusterQuorum -FileShareWitness **<path\from\table\above>**

   Example

       Set-ClusterQuorum -FileShareWitness \\hostfp02\witness
  
1. Validate changein Failover Cluster Manager or powershell.

       Get-ClusterResource 'File Share Witness' | Get-ClusterParameter

END
