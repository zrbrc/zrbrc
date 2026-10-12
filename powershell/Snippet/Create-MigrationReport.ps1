Set-Location $PSScriptRoot

Start-Transcript '.\log.txt'

Import-Module '.\SqlServer'
Import-Module '.\ImportExcel'

$splat = @{
    To         = 'Tomi.Helojoki@delaware.gov','Michael.Singleton@delaware.gov','Ryan.Zerbe@delaware.gov'
    From       = 'donotreply@delaware.gov' 
    Subject    = 'Migration Report ' + (Get-Date).ToString('yyyy-MM-dd')
    Body       = 'Please find the Migration report for the week ' + (Get-Date).AddDays(-7).ToString('yyyy-MM-dd') + ' to ' + (Get-Date).ToString('yyyy-MM-dd') + '.'
    SmtpServer = 'smtp.state.de.us'
}


$sql = @"
SELECT
	mr.MigrationRequest_IDNO as MigrationRequest,
	CASE Environment_CODE
	     WHEN 'TESTEN' THEN 'TEST'
		 WHEN 'PRDCTN' THEN 'PROD'
    END as Environment,
	REPLACE(mr.Division_CODE,'X','') AS Division,
	app.ApplicationName_TEXT as Application,
	mr.FirstInserted_DTTM AS CreateDate,
	(SELECT ADLogin_TEXT FROM UserDetails_T1 WHERE UserDetail_IDNO = mr.FirstInsertedBy_IDNO) as CreatedBy,
	mr.LastSaved_DTTM as LastSavedDate,
	(SELECT ADLogin_TEXT FROM UserDetails_T1 WHERE UserDetail_IDNO = mr.LastSavedBy_IDNO) as LastSavedBy,
	CASE Status_Code 
		 WHEN 'COMPLT' THEN 'Completed'
		 WHEN 'ROLBAK' THEN 'Rolled Back'
	END	as StatusCode
FROM
	MigrationRequests_T1 AS mr
    JOIN Applications_T1 AS app on app.Application_IDNO = mr.Application_IDNO
WHERE 
	mr.LastSaved_DTTM >= DATEADD(day,-7,GETDATE())
	AND mr.Environment_CODE IN ('TESTEN','PRDCTN')
	AND mr.Status_Code IN ('COMPLT','WTHDRW','ROLBAK')
ORDER BY 
	mr.LastSaved_DTTM
"@

try {

    $data = Invoke-Sqlcmd -ServerInstance 'xx.xx.xx.xx,15150' -Database 'db_Migrations_PROD' -Query $sql -TrustServerCertificate

    $file = '.\Reports\MigrationReport_' + (Get-Date).ToString('yyyyMMdd_HHmmss') + '.xlsx'

    Export-Excel -InputObject $data -Path $file -ExcludeProperty RowError, RowState, Table, ItemArray, HasErrors -AutoSize

    Send-MailMessage @splat -Attachments $file

    $null = Get-Item '.\Reports' -Filter '*.xlsx' | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-90) } | Remove-Item

}
catch {
    $ErrorMessage = $_
    Send-MailMessage -To 'ryan.zerbe@delaware.gov' -From 'donotreply@delaware.gov' -Subject '[!] Migration Report Failed' -Body $ErrorMessage -SmtpServer 'smtp.state.de.us'
}

Stop-Transcript