$ProgressPreference = 'SilentlyContinue'

$table = @()
$BackupFile = "E:\Backup\random_db-$(Get-Date -Format 'yyyyMMdd-hhmmssfff').bak"
try {

    $Server = Get-SqlInstance -ServerInstance 'LUNA\DE2019'
    $Server | Backup-SqlDatabase -Database 'random_db' -BackupFile $BackupFile

    $Files = Get-ChildItem -Path 'E:\Backup' -Filter "*.bak"

    foreach ($File in $Files) {
        $Restore = New-Object Microsoft.SqlServer.Management.Smo.Restore

        $Backup = New-Object Microsoft.SqlServer.Management.Smo.BackupDeviceItem ($File.FullName, [Microsoft.SqlServer.Management.Smo.DeviceType]::File)

        $Restore.Devices.Add($Backup)

        $Verify = $Restore.SqlVerify($Server)

        if ($Verify -eq $true) {

            $Header = $Restore.ReadBackupHeader($Server)

            if ($Header) {

                $row = $Header | Select-Object *

                $row | Add-Member -MemberType NoteProperty -Name "FileName" -Value $File.FullName
                $row | Add-Member -MemberType NoteProperty -Name "BackupGood" -Value $Verify

                $row.PSObject.TypeNames.Insert(0, 'BackupHeader')

                $table += $row
            }
        }
        else {
            "[!] $($File.FullName) failed verification."
        }
    }
}
catch {
    $Try = $_
    $Try.Exception.Message
}
# set default output
$TypeData = @{
    TypeName                  = 'BackupHeader'
    DefaultDisplayPropertySet = 'ServerName', 'DatabaseName', 'BackupTypeDescription', 'BackupStartDate', 'BackupFinishDate', 'CompressedBackupSize', 'BackupGood', 'FileName'
}
Update-TypeData  @TypeData -Force

$table | Format-Table

