<# 
    Create empty database shell and then run this to create the structure

CREATE DATABASE db_DICER_UAT4
CREATE DATABASE db_DICERLog_UAT4
CREATE DATABASE db_MCILog_UAT4
CREATE DATABASE db_MCIReports_UAT4
CREATE DATABASE db_MCIBatchLog_UAT4

# this one needs some tables copied after the dacpacs apply
# MCIAttributes_T
# MCIErrorInfo_T
# MCILookupTable_T
# MCISystem_T
# MCISystemAttributes_T
CREATE DATABASE db_MCI_UAT4

# I think this needs to be a restore from UATCR bc its all data that needs copying
# CREATE DATABASE db_MCIReferenceTable_UAT4

#>


Set-Location $PSScriptRoot
$ErrorActionPreference = 'Stop'

$sqlpackage = "C:\Program Files\Microsoft SQL Server\160\DAC\bin\SqlPackage.exe"

# dblist is 'source instance, source database, target instance, target database'
$dblist = @(
    ('hostmcdbc1n2\TS2019_15', 'db_DICER_UAT3', 'hostOMCIDB01\TS2019_23', 'db_DICER_UAT4'),
    ('hostmcdbc1n2\TS2019_15', 'db_DICERLog_UAT3', 'hostOMCIDB01\TS2019_23', 'db_DICERLog_UAT4'),
    ('hostmcdbc1n2\TS2019_15', 'db_MCI_UATCR', 'hostOMCIDB01\TS2019_23', 'db_MCI_UAT4'),
    ('hostmcdbc1n2\TS2019_15', 'db_MCILog_UATCR', 'hostOMCIDB01\TS2019_23', 'db_MCILog_UAT4'),
    ('hostmcdbc1n2\TS2019_15', 'db_MCIBatchLog_UATCR', 'hostOMCIDB01\TS2019_23', 'db_MCIBatchLog_UAT4'),
    # ('hostmcdbc1n2\TS2019_15', 'db_MCIReferenceTable_UATCR', 'hostOMCIDB01\TS2019_23', 'db_MCIReferenceTable_UAT4'),
    ('hostmcdbc1n2\TS2019_15', 'db_MCIReports_UATCR', 'hostOMCIDB01\TS2019_23', 'db_MCIReports_UAT4')
)

Start-Transcript ".\export_publish_log_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"

"`n`nStarting ... "
foreach ($item in $dblist | Select-Object) {
    Get-Date
    try {
        $extract = @(
            "/Action:extract",
            "/TargetFile:.\$($item[1]).dacpac",
            "/SourceServerName:$($item[0])",
            "/SourceDatabaseName:$($item[1])",
            "/SourceEncryptConnection:false"
        )
        "Running sqlpackage.exe extract: '{0}'" -f ($extract -join ' ')
        & $sqlpackage @extract

        $publish = @(
            "/Action:publish",
            "/SourceFile:.\$($item[1]).dacpac",
            "/TargetServerName:$($item[2])",
            "/TargetDatabaseName:$($item[3])",
            "/TargetEncryptConnection:false",
            "/Properties:ExcludeObjectTypes=Users;Logins;RoleMembership;Permissions"
        )
    
        "Running sqlpackage.exe publish: '{0}'" -f ($publish -join ' ')
        & $sqlpackage @publish
    }
    catch {
        throw "Failed on $item[1]"
    }
    finally {
        Get-Date
    }
}

"`nDONE`n"

Stop-Transcript