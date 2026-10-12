"C:\Temp" | Get-ChildItem -Recurse -Directory |
  Get-Acl | Where-Object { $_.AreAccessRulesProtected -eq $true } |
  foreach-Object { $_.SetAccessRuleProtection($false, $false); $_ | Set-Acl -Verbose; }

# or 

$allFolders = Get-ChildItem -Path 'D:\Backup Shares\Prod' -Directory -Recurse

foreach ($Folder in $allFolders) {
  $Permission = get-acl -Path $Folder.FullName
  $Permission.SetAccessRuleProtection($False, $true)
  Set-Acl -Path $Folder.FullName -AclObject $Permission
}