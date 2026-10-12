$sql = @"
    select
        @@servername AS server_name
"@

$prod_instances = @(
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150'
)

# asks for creds if you haven't set it
if (!$basetech) { $basetech = Get-Credential -Credential 'basetech' }

$output = foreach ($pi in $prod_instances) {
    try {
        Invoke-Sqlcmd -ServerInstance $pi -Query $sql -Credential $basetech -TrustServerCertificate
    }
    catch {
        "FAILED: $pi"
    }
}

$output