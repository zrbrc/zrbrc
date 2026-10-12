<#
.SYNOPSIS
    Grabs latest sql version from M$ webpage and parses into an excel.

.EXAMPLE
    PS C:\> .\Get-LatestSqlVersion.ps1
.INPUTS
    M$ website
.OUTPUTS
    Excel File
.NOTES
    No interaction needed, just run from cli or explorer, it will grab the info needed and parse it.
    Needs ImportExcel module and internet access to get to M$'s site.
#>

Set-Location $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$response = Invoke-WebRequest 'https://docs.microsoft.com/en-us/sql/database-engine/install-windows/latest-updates-for-microsoft-sql-server' -UseBasicParsing -UseDefaultCredentials -Proxy 'http://dmzproxy.state.de.us:8080' -ProxyUseDefaultCredentials

if ($response.Content -match "<tbody>[^>]*>(?:.|\n)*?<\/tbody>") {

    $data = $Matches[0].Replace("`n", '') -replace '</tr></tbody>', '' -replace '<tbody><tr>' -split '</tr><tr>'

    $table = foreach ($row in $data.TrimStart('<td>').TrimEnd('</td>') ) {
        $row = $row -split '</td><td>'

        if ($row[3] -match '(http|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])?') { $cuurl = $Matches[0] }
        if ($row[1] -match '(http|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])?') { $spurl = $Matches[0] }
        if ($row[2] -match '(http|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])?') { $gdrurl = $Matches[0] }


        [PSCustomObject]@{
            SQLVersion    = $row[0]
            LatestSP      = ($row[1] -split ' <a ')[0] -replace 'N/A', 'RTM'
            LatestCU      = ($row[3] -split ' <a ')[0] -replace 'N/A', '' -replace ' ', ''
            CUReleaseDate = ($row[4] -split '<br>')[0] -replace 'N/A',''
            LatestSPLink  = $spurl
            LatestCULink  = $cuurl
            #LatestGDR     = (($row[2] -split '>')[1] -split '<')[0]
            #LatestGDRLink = $gdrurl
        }
    }
    $table | Format-Table
}