param(
	[string]$env = 'PROD',
    [string] $filepath
)

$smtpServer = "smtp.state.de.us"
$fromAddress = "db_DoNotReply@delaware.gov"
$toAddressPassed = "USDEdeptOperationsNotification@deloitte.com,beth.foraker@delaware.gov"
$toAddressFailed = "USDEdeptOperationsNotification@deloitte.com, dept05dg_db_Enterprise_Operations@delaware.gov, USDelawareIEInfrastructureNotifications@deloitte.com, beth.foraker@delaware.gov, michael.singleton@delaware.gov"
$subject = "PASSED - $env Web Services Health Check"

if ($filepath.Length -eq 0){
    $filepath = "$PSScriptRoot\db_DEM_Prod_InfrastructureMonitor.csv" 
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
    if ($ep.url.trim().length -eq 0 -or $ep.url.trim()[0] -eq '#')
    {
        continue;
    }
    
    #Write-Host $ep.Url

    $time = try{ 
        $request = $null 
        $exception = $null

        ## Request the URI, and measure how long the response took. 
        $t = Measure-Command { $request = Invoke-WebRequest -Uri $ep.Url -UseBasicParsing } 
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
    $Outputreport = "<HTML><TITLE>$env Web Services Availability Report</TITLE><BODY background-color:peachpuff><font color =""#99000"" face=""Microsoft Tai le""><H2> Website Availability Report - Generated on $ts</H2></font><Table border=1 cellpadding=0 cellspacing=0><TR bgcolor=gray align=center><TD><B>#</B></TD><TD><B>Service Name</B></TD><TD><B>Status Code</B></TD><TD><B>StatusDescription</B></TD><TD><B>ResponseLength</B></TD><TD><B>Time Taken</B></TD></TR>" 
    $isFailed = $false
    $inc = 1
    Foreach($Entry in ($Result | Sort-Object -Property StatusCode -Descending)) 
    { 
        switch -Wildcard ($Entry.StatusCode){
            "2*" {$Outputreport += "<TR>"; break;}
            "3*" {$Outputreport += "<TR>"; break}
            "401" {$Outputreport += "<TR bgcolor='yellow'>"; break}
            "402" {
                $Outputreport += "<TR bgcolor='red'>"
                $isFailed = $true
                break
            }
            "403" {
                $Outputreport += "<TR bgcolor='yellow'>"
                $isFailed = $true
            }
            "404" {
                $Outputreport += "<TR bgcolor='red'>"
                $isFailed = $true
                break
             }
            "405" {
                $Outputreport += "<TR bgcolor='yellow'>"
                $isFailed = $true
                break
            }
            "406" {
                $Outputreport += "<TR bgcolor='yellow'>"
                $isFailed = $true
                break
            }
            "50?" {
                $Outputreport += "<TR bgcolor='red'>"
                $isFailed = $true
                break
            }
            default {
                $Outputreport += "<TR bgcolor='gray'>"
                $isFailed = $true
                break
            }
        }

        $Outputreport += "<TD>$inc</TD><TD>$($Entry.Url)<P style='font-size:small;'>$($Entry.Exception)</P></TD><TD align=center>$($Entry.StatusCode)</TD><TD align=center>$($Entry.StatusDescription)</TD><TD align=center>$($Entry.ResponseLength)</TD><TD align=center>$($Entry.timetaken)</TD></TR>" 
        $inc =  $inc + 1
    } 
    $Outputreport += "</Table></BODY></HTML>" 
    Write-Output "Generatring output..."


            $smtp = new-object Net.Mail.SmtpClient($smtpServer)
	        $msg = new-object Net.Mail.MailMessage
             $msg.From = $fromAddress
		    $msg.Subject = $subject
	        $msg.Body =  $Outputreport
	        $msg.IsBodyHTML = $true

	
    if ($isFailed -eq $true){

        $subject = "FAILED - $env Web Services Health Check"
	    $msg.To.Add($toAddressFailed)

    }
    else{

        $subject = "PASSED - $env Web Services Health Check"
        $msg.To.Add($toAddressPassed)
    }

	        $smtp.Send($msg)

	
    #$Outputreport | out-file "$PSScriptRoot\endpoints.htm" -Force
    #Invoke-Expression "$PSScriptRoot\endpoints.htm"    
} 
 
