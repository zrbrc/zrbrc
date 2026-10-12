<# 
This is a sample of how to ADD SPNs to be useable for delegation and fix the double-hop issue when using linked servers.
#>

Get-ADObject -Identity 'CN=sqladmin.test,CN=Users,DC=domTest,DC=dept' | Set-ADObject -Add @{'msDS-AllowedToDelegateTo'='MSSQLSvc/hostmcidbc1l1domain.com:15150',
'MSSQLSvc/hostmcidbc1n1domain.com:15150',
'MSSQLSvc/hostmcidbc1n1domain.com:PT2019_1',
'MSSQLSvc/hostmcidbc1n2domain.com:15150',
'MSSQLSvc/hostmcidbc1n2domain.com:PT2019_2',
'MSSQLSvc/hostmcidbc1n3domain.com:15150',
'MSSQLSvc/hostmcidbc1n3domain.com:PT2019_3',
'MSSQLSvc/host1btcls1domain.com:15150',
'MSSQLSvc/hostnamecl6ls1domain.com:15150',
'MSSQLSvc/hostnamecl6ls2domain.com:15150',
'MSSQLSvc/hostnamecl6ls3domain.com:15150',
'MSSQLSvc/hostnamecls6n1domain.com:15151',
'MSSQLSvc/hostnamecls6n1domain.com:15152',
'MSSQLSvc/hostnamecls6n1domain.com:15153',
'MSSQLSvc/hostnamecls6n1domain.com:TS2019_4',
'MSSQLSvc/hostnamecls6n1domain.com:TS2019_5',
'MSSQLSvc/hostnamecls6n1domain.com:TS2019_6',
'MSSQLSvc/hostnamecls6n2domain.com:15151',
'MSSQLSvc/hostnamecls6n2domain.com:15152',
'MSSQLSvc/hostnamecls6n2domain.com:15153',
'MSSQLSvc/hostnamecls6n2domain.com:TS2019_7',
'MSSQLSvc/hostnamecls6n2domain.com:TS2019_8',
'MSSQLSvc/hostnamecls6n2domain.com:TS2019_9'}