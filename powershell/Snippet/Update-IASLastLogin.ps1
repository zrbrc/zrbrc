<#
.SYNOPSIS
    Queries IAS to get the last day of logins and update LastLogonDate via impersonation.
.DESCRIPTION
    Queries IAS to get the last day of logins and then impersonates the user so they don't get disabled by Cerberus. Only interactive logins
    will update this AD property and it's causing issues. Outputs a logs of operations.
.NOTES
    Takes no parameters, need to update any options in the script.
.LINK
    https://gist.github.com/joerodgers/06304f41a8f8309ac12e8ebd450153ff
.EXAMPLE
    .\Update-IASLasLogin.ps1
#>

Set-Location $PSScriptRoot

$log = '.\update_last_login_date.txt'

$instance = 'xx.xx.xx.xx,15150'
$database = 'DMS_IAS_TEST'

$sql = "SELECT ADLogin_TEXT FROM Audit_T1 WHERE Action_CODE = 'XLOGIN' AND Outcome_code = 'SUCCES' AND LastSaved_DTTM > DATEADD(DAY,-1,GETDATE()) ORDER BY ADLogin_TEXT"

"[i] START"
Start-Transcript $log -Append

$users = Invoke-Sqlcmd -ServerInstance $instance -Database $database -Query $sql -TrustServerCertificate

$domain = (Get-ADDomain).Name

if ($users) {
    foreach ($user in $users) {
        $upn = "$($user.ADLogin_TEXT)@$domain"
    
        try {
            $windowsIdentity = New-Object System.Security.Principal.WindowsIdentity($upn)
            $impersonatedContext = $windowsIdentity.Impersonate()
            $impersonatedContext.Undo()
            "[+] SUCCESS: {0}" -f $user.ADLogin_TEXT
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            $ErrorMessage
            "[-] FAILED:  {0}"  -f $user.ADLogin_TEXT
            continue
        } 
    }
}
else {
"[!] NO WORK TO DO"
}

"[i] DONE"

Stop-Transcript