<#
.SYNOPSIS
    Scans instance for inconsistent Login and User SIDs, aka orphans.
.DESCRIPTION
    Script gets all the SIDs for instance logins and then scans each DB for users 
    and determines if there is a missing login or if the user and login SID are mismatched. 
.EXAMPLE
    PS C:\> .\Find-SqlOrphans.ps1 -ServerInstance 'sqlinstance'
.INPUTS
    ServerInstance (mandatory): This can be in the format of 'server,port' or 'server\instance'
.OUTPUTS
    Report displayed on the screen.
.NOTES
    This takes no actions, only displays information. This requires SQLServer powershell module.
#>
param (
    [Parameter(Mandatory = $true)]
    [String[]]
    $ServerInstance
)

$report = foreach ($server in $ServerInstance ) {

    $Filter = { $_.LoginType -eq 'SqlLogin' -and $_.IsSystemObject -eq $false -and $_.Name -notlike "NT*" -and $_.Name -notlike "##*" }

    $instance = Get-SqlInstance -ServerInstance  $server

    # gets list of logins-sids
    $lsid = foreach ($login in $instance.Logins | Where-Object $Filter) {

        $sid = '0x'
        $login.sid | ForEach-Object { $sid += ("{0:X}" -f $_).Padleft(2, '0') }
    
        [PSCustomObject]@{
            Instance = $Instance.Name
            Login    = $login.Name
            Sid      = $sid
        }

    }

    # compares list of users-sids and logins-sids for each database
    foreach ($db in $instance.Databases | Where-Object { $_.IsSystemObject -eq $false -and $_.IsAccessible -eq $true }) {
        
        foreach ($user in $db.Users | Where-Object $Filter) {

            $sid = '0x'
            $user.sid | ForEach-Object { $sid += ("{0:X}" -f $_).Padleft(2, '0') }

            if ($user.Name -notin $lsid.Login) {
                $status = 'Login Missing'
            }
            elseif ($sid -notin $lsid.Sid) {
                $status = 'SID Mismatch'
            }
            else {
                # uncomment and comment below lines to show good login/users too
                # $status = 'Good'
                continue
            }

            [PSCustomObject]@{
                Instance = $instance.Name
                Database = $db.Name
                User     = $user.Name
                UserSid  = $sid
                Error    = $status
            }

        }
    }
}
# displays reports
$report | Format-Table
"{0}: {1}" -f 'Total', $report.Count
