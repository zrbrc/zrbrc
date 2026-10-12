<#
.SYNOPSIS
    Scan for SQL Vulnerabilities
.DESCRIPTION
    Scan for SQL Vulnerabilities on the $target instance.
.EXAMPLE
.INPUTS
.OUTPUTS
.NOTES
#>

try {
    Import-Module SqlServer
    
    $targets = @( 
        # 'xx.xx.xx.xx,15150',
        'xx.xx.xx.xx,15150'
        # 'xx.xx.xx.xx,15150',
        # 'xx.xx.xx.xx,15150',
        # 'xx.xx.xx.xx,15150',
        # 'xx.xx.xx.xx,15151',
        # 'xx.xx.xx.xx,15150'
    )
    
   
    $output = 'M:\Management\VulnerabilityScan'
    if (-not (Test-Path -Path $output -PathType Container)) { New-Item -Path $output -ItemType  Directory }
    
    foreach ($target in $targets) {
        $UserDbs = Get-Sqldatabase -ServerInstance $target | Where-Object { $_.IsAccessible -eq $true -and $_.IsSystemObject -eq $false }
        
        foreach ($db in $UserDbs) {
            $results = Invoke-SqlVulnerabilityAssessmentScan -ServerInstance $db.Parent -Database $db.Name
            $results | Export-SqlVulnerabilityAssessmentScan -FolderPath "$output\$($db.Parent.NetName)_$($db.Parent.InstanceName)_$($db.Name)_ScanResult.xlsx"
        }
    }
    Get-ChildItem -Path $output -Filter *.xlsx | ForEach-Object {
        Import-Excel -Path $_.FullName -WorksheetName Results -StartRow 8
    } | Export-Excel -Path "M:\Management\Temp\all.xlsx"
}
catch {
    $Exception = $_
    Write-Output "Something broke."
    $Exception
}


# the below code is how you can create baselines
# $failedResults = @{}
# $results.Results.GetEnumerator() | Where-Object { $_.Value.Status -eq "Failed" } | ForEach-Object { $failedResults[$_.Key] = $_.Value }
# $results1281 = $failedResults['VA1281']

# $baseline1281 = New-SqlVulnerabilityAssessmentBaseline -SecurityCheckId $results1281.SecurityCheckId -ExpectedResult $results1281.QueryResults -Severity Low
# $baselineset = New-SqlVulnerabilityAssessmentBaselineSet -Baselines $baseline1281
# $r2 = Invoke-SqlVulnerabilityAssessmentScan -ServerInstance $target -Database DSS_WorkerWebReports_SBX -Baseline $baselineset

# $r2.Results.GetEnumerator() | Where-Object { $_.Value.Status -eq "Failed" }

# $baselineset | Export-SqlVulnerabilityAssessmentBaselineSet -FolderPath '.\baselineset.json'