$servers = @(
'hostDBCL1N1',  
'hostDBCL1N3',  
'hostELIGAP02', 
'hostELIGDB01', 
'hostnameCLSN1',  
'hostnameCLSN2',  
'deptTREL2AP01',  
'deptTREL2AP02',  
'deptTRELIGDB01', 
'deptTRELIGDB01', 
'hostname4N1', 
'hostname4N3', 
'hostname5ls3',
'hostname5N2', 
'hostname5N3', 
'hostname7ls1',
'hostname7N1', 
'hostname7N2', 
'hostELIGAP18', 
'hostELIGDB04', 
'hostnamecl6ls1',
'hostnamecl6ls2',
'hostnamecl6ls3',
'hostnameCLS6N1',
'hostnameCLS6N1',
'hostnameCLS6N1',
'hostnameCLS6N2',
'hostnameCLS6N2',
'hostnameCLS6N2',
'PTDBCLS1DB01',   
'TSDBCLS3DB01',   
'TSDBCLS3DB02'   
)

$patchlevel = @()

foreach ($s in ($servers | Sort-Object | Select-Object -Unique)) {
    try {
        $patchlevel += Get-HotFix -ComputerName $s | Sort-Object InstalledOn -Descending | Select-Object PSComputerName, InstalledOn -First 1
    }
    catch {
        "Failed: $s"
    }
}

$patchlevel