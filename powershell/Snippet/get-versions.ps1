Set-Location $PSScriptRoot

$response = Invoke-WebRequest https://docs.microsoft.com/en-us/sql/database-engine/install-windows/latest-updates-for-microsoft-sql-server -UseBasicParsing -UseDefaultCredentials

if ($response.Content -match "<tbody>[^>]*>(?:.|\n)*?<\/tbody>") {

    $data = $Matches[0].Replace("`n", '') -replace '</tr></tbody>', '' -replace '<tbody><tr>' -split '</tr><tr>'

    $table = foreach ($row in $data.TrimStart('<td>').TrimEnd('</td>') ) {
        $row = $row -split '</td><td>'

        if ($row[3] -match '(http|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])?') { $cuurl = $Matches[0] }
        if ($row[1] -match '(http|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])?') { $spurl = $Matches[0] }
        if ($row[2] -match '(http|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])?') { $gdrurl = $Matches[0] }


        [PSCustomObject]@{
            SQLVersion    = $row[0]
            LatestSP      = ($row[1] -split ' <a ')[0]
            LatestSPLink  = $spurl
            LatestCU      = ($row[3] -split ' <a ')[0]
            LatestCULink  = $cuurl
            CUReleaseDate = $row[4]
            LatestGDR     = (($row[2] -split '>')[1] -split '<')[0]
            LatestGDRLink = $gdrurl

        }
    }
    # if (Test-Path -Path .\sqlversions.xlsx) { Remove-item .\sqlversions.xlsx }
    $table | Format-List #| Export-Excel .\sqlversions.xlsx -AutoSize -BoldTopRow -Show
}