Set-Location $PSScriptRoot

$credspath = "$env:LOCALAPPDATA\basetech.xml"
if (Test-Path -Path $credspath -PathType Leaf) {
    $basetech = Import-Clixml $credspath
    Write-Output "Credentials imported from $credspath."
}
else {
    $basetech = Get-Credential -Credential 'basetech'
    $basetech | Export-Clixml $credspath
    Write-Output "Account credentials stored to $credspath."
}

$output = & .\Create-DbUserScript.ps1 -Instance 'xx.xx.xx.xx,15150' -Credential $basetech -User 'ANKITA.GOYAL ',domain.com.WorkerWeb.App',domain.comSG_dv_DUReporter_Read','domDEV\dv.dss.ss.app','Basem.Elsheikh','dept.EIAM.App','host04\WWAppPool','DSS_repl','stagingadmin'
$output | Out-File -FilePath '.\output.sql'