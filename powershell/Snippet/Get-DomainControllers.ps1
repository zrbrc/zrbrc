<# 

** Are open from .9/.99 management subnet.

dom:
**deptdc03domain.com xx.xx.xx.xx
**deptdc04domain.com xx.xx.xx.xx

  deptdc01domain.com xx.xx.xx.xx
  deptdc02domain.com xx.xx.xx.xx
  deptdc05domain.com xx.xx.xx.xx
  deptdc06domain.com xx.xx.xx.xx
  deptdc07domain.com xx.xx.xx.xx
  deptdc08domain.com xx.xx.xx.xx
  deptdc09domain.com xx.xx.xx.xx

domTEST:
  **hostdc01domain.com xx.xx.xx.xx
  **hostdc02domain.com xx.xx.xx.xx
  
  hostdc03domain.com xx.xx.xx.xx
  hostdc04domain.com xx.xx.xx.xx
  hostdc06domain.com xx.xx.xx.xx
  hostdc07domain.com xx.xx.xx.xx

domDEV:
  **hostdc01domain.com xx.xx.xx.xx
  **hostdc02domain.com xx.xx.xx.xx

#>

# run in each domain to get the DC list
(get-addomain).ReplicaDirectoryServers | ForEach-Object { Resolve-DnsName $_ | Select-Object Name, IPAddress }