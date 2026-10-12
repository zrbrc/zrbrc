<#

╔═╗┌─┐┬ ┬┌─┐┬─┐╔═╗┬ ┬┌─┐┬  ┬    ╔═╗┌─┐┌┬┐┬┬  ┬┌─┐  ╔╦╗┬┬─┐┌─┐┌─┐┌┬┐┌─┐┬─┐┬ ┬  ╔╦╗┌─┐┌┬┐┌─┐
╠═╝│ ││││├┤ ├┬┘╚═╗├─┤├┤ │  │    ╠═╣│   │ │└┐┌┘├┤    ║║│├┬┘├┤ │   │ │ │├┬┘└┬┘   ║║├┤ ││││ │
╩  └─┘└┴┘└─┘┴└─╚═╝┴ ┴└─┘┴─┘┴─┘  ╩ ╩└─┘ ┴ ┴ └┘ └─┘  ═╩╝┴┴└─└─┘└─┘ ┴ └─┘┴└─ ┴   ═╩╝└─┘┴ ┴└─┘

Domain Controllers

dom:
  deptdc03domain.com          xx.xx.xx.xx
  deptdc04domain.com          xx.xx.xx.xx
domTEST:
  hostdc01domain.com    xx.xx.xx.xx
  hostdc02domain.com    xx.xx.xx.xx
domDEV:
  hostdc01domain.com     xx.xx.xx.xx
  hostdc02domain.com     xx.xx.xx.xx

#>

#  1. Install RSAT Active Directory via Windows Optional Features: Search start menu for Features, choose dom and Features, click Optional Features, 
#     Click Add Feature. Find RSAT Active Directoty and install it.

#  2. Open Powershell terminal and run command below to verify module install and see what commands it offers.

Get-Module -Name ActiveDirectory -ListAvailable

Get-Command -Module ActiveDirectory
    
# 3. Search for yourself against State domain.

Get-Aduser ryan.zerbe

# 4. Searching against another domain requires authentication, create an authentication object for yourself using domtest domain credentials.
#    This can be stored between sessions using Export-Clixml and Import-Clixml.

$cred = Get-Credential

# to save between sessions
$cred | Export-Clixml '.\dom.xml'

# to import to a new session
$cred = Import-Clixml '.\dom.xml'

# 5. Query for yourself on domtest domain using credential object we just created.

Get-Aduser ryan.zerbe -Server xx.xx.xx.xx -Credential $cred

# 6. ActiveDirectory module is quirky, it doesnt return all properties by default, you need to specify to return other properties, 
#    choose which or just '*' for all. Returning all properties for 1 person is not a big deal, but if querying a lot of objects, 
#    only getting what you need can save time.

Get-Aduser ryan.zerbe -Properties * -Server xx.xx.xx.xx -Credential $cred

# 7. Check group membership

Get-Aduser ryan.zerbe -Properties * -Server xx.xx.xx.xx -Credential $cred | Select-Object -ExpandProperty MemberOf | Sort-Object

# 8. Find other objects

Get-ADComputer hostname1n1 -Server xx.xx.xx.xx -Credential $cred -Properties *

# 9. Find more other objects

Get-ADObject -LDAPFilter "(objectClass=site)" -SearchBase 'CN=Configuration,DC=dom,DC=dept' -Properties * -Server xx.xx.xx.xx -Credential $cred | 
    Select-Object Name, CanonicalName

Get-ADComputer hostname1n1 | Move-ADObject -TargetPath "OU=WSUS Manual,OU=Servers,DC=domTest,DC=dept"

Get-ADObject -Identity 'CN=sqladmin.test,CN=Users,DC=domTest,DC=dept' | 
  Set-ADObject -Add @{'msDS-AllowedToDelegateTo'='MSSQLSvc/hostmcidbc1l1domain.com:15150','MSSQLSvc/hostmcidbc1n1domain.com:15150'}

Get-ADGroupMember deptSG_Citrix_Admins -Server xx.xx.xx.xx -Credential $cred