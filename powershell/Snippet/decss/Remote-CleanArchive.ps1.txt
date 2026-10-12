<#
.DESCRIPTION
    Copies the newest file in the $Source folder to the $Target folder, filterable, and cleans up old file(s) in the target folder.
.EXAMPLE
    PS C:\> ArchiveFile -SourcePath 'D:\Backup' -TargetPath 'D:\Archive' -Filter '*.bak' -Cleanup 72
    This will copy the newest *.bak file from D:\Backup to D:\Archive and then remove any files older than 72 days
.INPUTS
    Source(mandatory): The source path you want to copy files from.
.INPUTS
    Target(mandatory): The target path you want to copy files to.
.INPUTS
    Cleanup(mandatory): The number of days that defines a files as being old. This will clean up any file in the target folder, 
		so dont mix different cleanup time target folders. Dont copy a weekly file into a monthly folder, it will cleanup the existing
		monthly files there too.
.INPUTS
    Filter(optional)
.OUTPUTS
    None, screen only.
#>

function Cleanup-AndArchiveFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $ComputerName,

        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]
        $Source,

        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]
        $Target,
    
        [Parameter(Mandatory = $true)]
        [Int]
        $Cleanup,

        [String]
        $Filter = '*'
    )
    
	$ErrorActionPreference = 'Stop'
	
    try {
        Invoke-Command -ComputerName $ComputerName -ArgumentList $Source, $Target, $Cleanup, $Filter -ScriptBlock {
            param ($Source, $Target, $Cleanup, $Filter)
        
		    $ErrorActionPreference = 'Stop'
		
            if (!(Test-Path $Source)) {throw "Source path does not exist: $Source"}
            if (!(Test-Path $Target)) {throw "Target path does not exist: $Target"}

            # cleanup files older than x days from target
            Get-ChildItem -Path $Target -Filter $Filter | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$Cleanup) } | Foreach-Object { 
                "`tCLEANUP: {0}" -f $_.FullName
                $_ | Remove-Item
            }

            # copies latest file from source to target
            Get-ChildItem -Path $Source -Filter $Filter | Sort-Object LastwriteTime -Descending | Select-Object -First 1 | ForEach-Object {
                if ($_.Name -notin (Get-ChildItem -Path $Target -Filter $Filter).Name) {
                    "`tCOPY: {0} to {1}" -f $_.FullName, $Target
                    $_ | Copy-Item -Destination $Target
                }
                else {
                    "`tEXISTS: {0}\{1}" -f $Target, $_.FullName
                }
            }
        }
    }
    catch {
        throw
    }
}

$ErrorActionPreference = 'Stop'

"[#] Start  : {0}" -f (Get-Date)

try {
    Cleanup-AndArchiveFiles -ComputerName host04 -Source m:\Management\Temp\source -Target m:\Management\Temp\target -Cleanup 10
}
catch {
    "[!] Failure  : {0}`n" -f (Get-Date)
	throw
}

"[#] End  : {0}`n" -f (Get-Date)