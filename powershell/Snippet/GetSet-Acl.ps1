$acl = Get-Acl -Path 'c:\temp'
$rule = New-Object System.Security.Accesscontrol.FileSystemAccessRule("state\fake.user", "FullControl", "ContainerInherit,ObjectInherit", "none", "Allow")
$acl.AddAccessRule($rule)
Set-Acl -Path 'c:\temp' -AclObject $acl

# to remove
$remove = $acl.Access | Where-Object {$_.IdentityReference -eq 'state\fake.user'}
$acl.RemoveAccessRule($remove)

set-acl -path c:\temp -acl $acl