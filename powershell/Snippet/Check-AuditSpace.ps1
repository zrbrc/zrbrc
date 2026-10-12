$servers = @(
# EL2
# assist
'hostname1n1',
'hostname1n3',
'hostname1n5',
 # dicer
'hostmcidbc7n1',
'hostmcidbc7n2',
'hostmcidbc7n3',
# sailpoint
'hostname3n1',
'hostname3n2',
# dui
'hostname8n1',
'hostname8n2',
'hostname8n3',
# IDMZ3
# decss
'hostname7n1',
'hostname7n2',
'hostname7n3',
'hostname7n4',
# dept
'hostname5n1',
'hostname5n2',
'hostname5n3',
'hostname5n4',
'hostname5n5',
'hostname5n6'
# IDMZ2
'hostSSISC2N1',
'hostSSISC2N2'
)

foreach ($s in $servers) {
    "\\$s\m`$\Management\Audit: $((Invoke-Command -ComputerName $s -ScriptBlock { Get-ChildItem M:\Management\Audit | Measure-Object -Property Length -sum }).Sum / 1gb)"
}