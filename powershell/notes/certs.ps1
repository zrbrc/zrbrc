# found this online, keeping for reference, was used with win-acme
# https://blog.wicktech.net/update-sql-ssl-certs/
exit

Param( $CertThumbprint)
$SQLSvcAcct = (Get-WmiObject win32_service -Filter "Name='MSSQLSERVER'").StartName
$certobj = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $CertThumbprint };
$keyName = (((Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -like $certObj.Thumbprint }).PrivateKey).CspKeyContainerInfo).UniqueKeyContainerName;
$keyPath = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys\";
$fullPath = $keyPath + $keyName;
$acl = Get-Acl -Path $fullPath;
$newPermission = $SQLSvcAcct, "Read", "Allow";
$accessRule = new-object System.Security.AccessControl.FileSystemAccessRule $newPermission;
$acl.AddAccessRule($accessRule);
Try {
    Set-Acl $fullPath $acl;
    write-output "ACL updated";
}
Catch {
    "Error updating ACL";
    Exit;
}
$regkey = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server" -Recurse | Where-Object { $_.Name -like "*SuperSocketNetLib" }
Set-ItemProperty -path $regKey.PSPath -Name Certificate -value $certObj.Thumbprint ;
Restart-Service MSSQLSERVER -Force;