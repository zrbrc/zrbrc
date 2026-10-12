param(
    [string] $filepath
)

if ($filepath.Length -eq 0){
    $filepath = "$PSScriptRoot\db_DEM_InfrastructureMonitoring.csv" 
}
$endpoints = Import-CSV $filepath -Header Url -Delimiter ","

#$endpoints | Select Url | Format-Table
$ts = Get-Date -format "dd MMM yyyy h:mm:ss.fff"

### Code to ignore certificates
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

#######




$Result = @()
foreach($ep in $endpoints) { 
    $time = try{ 
        $request = $null 
        $exception = $null

        ## Request the URI, and measure how long the response took. 
        $t = Measure-Command { $request = Invoke-WebRequest -Uri $ep.Url -UseBasicParsing} 
        $t.TotalMilliseconds 
    }  
    catch 
    { 
        <# If the request generated an exception (i.e.: 500 server 
        error or 404 not found), we can pull the status code from the 
        Exception.Response property #> 
        $request = $_.Exception.Response
        $exception = $_.Exception 
        $time = -1 
    }   
    $result += [PSCustomObject] @{ 
        Time = Get-Date; 
        Url = $ep.Url; 
        StatusCode = [int] $request.StatusCode; 
        StatusDescription = $request.StatusDescription; 
        ResponseLength = $request.RawContentLength; 
        TimeTaken =  $time;
        Exception = $exception;
    } 
 
} 
    #Prepare email body in HTML format 
if($result -ne $null) 
{ 
    $Outputreport = "<HTML><TITLE>Performance Test Website Availability Report</TITLE><BODY background-color:peachpuff><font color =""#99000"" face=""Microsoft Tai le""><H2> Perforamnce Test Website Availability Report - Generated on $ts</H2></font><Table border=1 cellpadding=0 cellspacing=0><TR bgcolor=gray align=center><TD><B>Service Name</B></TD><TD><B>Status Code</B></TD><TD><B>StatusDescription</B></TD><TD><B>ResponseLength</B></TD><TD><B>Time Taken</B></TD</TR>" 
    Foreach($Entry in $Result) 
    { 
        switch -Wildcard ($Entry.StatusCode){
            "2*" {$Outputreport += "<TR>"}
            "3*" {$Outputreport += "<TR>"}
            "401" {$Outputreport += "<TR bgcolor='yellow'>"}
            "402" {$Outputreport += "<TR bgcolor='red'>"}
            "403" {$Outputreport += "<TR bgcolor='yellow'>"}
            "404" {$Outputreport += "<TR bgcolor='red'>"}
            "405" {$Outputreport += "<TR bgcolor='yellow'>"}
            "406" {$Outputreport += "<TR bgcolor='yellow'>"}
            "50?" {$Outputreport += "<TR bgcolor='red'>"}
            default {$Outputreport += "<TR bgcolor='gray'>"}
        }

        $Outputreport += "<TD>$($Entry.Url)<P style='font-size:small;'>$($Entry.Exception)</P></TD><TD align=center>$($Entry.StatusCode)</TD><TD align=center>$($Entry.StatusDescription)</TD><TD align=center>$($Entry.ResponseLength)</TD><TD align=center>$($Entry.timetaken)</TD></TR>" 
    } 
    $Outputreport += "</Table></BODY></HTML>" 
    Write-Host "Generatring output..."
    $Outputreport | out-file "$PSScriptRoot\endpointsPT.htm" -Force
 
} 
 
