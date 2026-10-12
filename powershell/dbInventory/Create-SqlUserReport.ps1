Set-Location $PSScriptRoot

Import-Module ImportExcel
# Import-Module SharePointPnPPowerShell2013

# uses stored credentials or creates new
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

$instances = @(
    'xx.xx.xx.xx,15150',
    'xx.xx.xx.xx,15150'
)

# $instances = Get-Content '.\servers.txt'

# static
$ExcelFile = ".\Sql_Users_Roles_$(Get-Date -Format "yyyyMMdd_hhmm").xlsx"

# sp paths
# $site = Connect-PnPOnline -Url 'http://wss.domain.com/dms/irm/basetech' -CurrentCredentials
# $folder = '/Shared Documents/Database/Audits'

# init
$table = @()

$icount = 1
$itotal = $instances.Count

$start = Get-Date

try {
    foreach ($instance in $instances) {
        Write-Output "`n($icount/$itotal): $($instance)"

        $i = Get-SqlInstance -ServerInstance $instance -Credential $basetech
    
        # get all the dbs on the instance
        $dbs = $i.Databases | Where-Object { $_.IsSystemObject -eq $false -and $_.IsAccessible -eq $true }
        $dbtotal = $dbs.Count
        $dbcount = 1
    
        foreach ($db in $dbs) {
            Write-Output "`n  - ($dbcount/$dbtotal): $($db.Name)"
        
            $users = $db.Users | Where-Object { $_.IsSystemObject -eq $false -and $_.Name -notlike "##*" -and $_.Name -notlike "NT*" }
            $usertotal = $users.Count
            $usercount = 1
        
            foreach ($user in $users) {
                Write-Output "    - ($usercount/$usertotal): $($user.Name)"
            
                # see if we have a matching login and get its details, else mark as orphan 
                if ($user.Login -eq '') {
                    $orphan = $true
                }
                else {
                    $orphan = $false
                }

                $roles = ($user.EnumRoles() | Sort-Object) -join ','
            
                if ($roles) {
                    $row = [PSCustomObject]@{
                        Instance   = $i.Name
                        Database   = $db.Name
                        User       = $user.Name
                        Roles      = $roles
                        Login      = $user.Login
                        LoginType  = $user.LoginType
                        CreateDate = $user.CreateDate
                        IsOrphan   = $orphan
                        # these are slower and the values on the user seem to be valid
                        # Login      = $logins | Where-Object { $_.Name -eq $user.Name } | Select-Object -ExpandProperty Name
                        # LoginType  = $logins | Where-Object { $_.Name -eq $user.Name } | Select-Object -ExpandProperty LoginType
                        # CreateDate = $logins | Where-Object { $_.Name -eq $user.Name } | Select-Object -ExpandProperty CreateDate
                        # Disabled   = $logins | Where-Object { $_.Name -eq $user.Name } | Select-Object -ExpandProperty IsDisabled
                        # this is not reliable, its using sys.dm_exec_sessions
                        # LastLogin  = $lastlogins | Where-Object { $_.LoginName -eq $User.Name } | Select-Object -ExpandProperty LastLogin
                    }
                
                    $table += $row
                }
                $usercount++
            }
            $dbcount++
        }
        $icount++
    }
}
catch {
    Write-Output "$instance failed."
    $_.Exception.Message
    break
}

$end = Get-Date
Write-Output "sql export completed in: $(New-TimeSpan -Start $start -End $end)"

if ($table) {
    $table | Export-Excel -Path $ExcelFile 

    # $file = Add-PnPFile -Connection $site -Folder $folder -Path $ExcelFile
    # Set-PnPFileCheckedIn -Connection $site -Url $file.ServerRelativeUrl

    # Write-Output "exported to excel and uploaded to sharepoint"
}