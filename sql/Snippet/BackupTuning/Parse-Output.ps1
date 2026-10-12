<#
.SYNOPSIS
   Reads a SQL job log containing the output from backup performance tests and displays the results in excel.
.DESCRIPTION
   This script is designed to read the output from a logfile that contains multiple backups which use
   different settings of MAXTRANFERSIZE & BUFFERCOUNT. This logfile will have been created by executing the job
   created using "Backup Test Harness.sql". 
   
   It will read in the log and output the results to excel (you must have this installed). It will also create
   two charts which provide a visual representation of the current, optimal and best possible backup performance
   for the given database. This information will be broken down by file count, maxtransfersize and buffercount. 
   
   The script is based upon one created for parsing SQLIO output, written by Jonathan Kehayis which can be found
   at http://sqlblog.com/blogs/jonathan_kehayias/archive/2010/05/25/parsing-sqlio-output-to-excel-charts-using-regex-in-powershell.aspx
   
   Any questions or problems with this script please contact me - Nic Cain at nic@sirsql.net
.PARAMETER <paramName>
   BackupLogFileName - The path & filename of the backup log
.EXAMPLE
   &'Parse Backup Perf Tests.ps1' -BackupLogFileName "C:\Temp\Log.txt"
   &'Parse Backup Perf Tests.ps1' "C:\Temp\Log.txt"
#>

param( [Parameter(Mandatory = $TRUE)] [ValidateNotNullOrEmpty()] [string] $BackupLogFileName = "M:\Management\Backup.log")


IF (Test-Path $BackupLogFileName) {

	$BackupLogFileName = "M:\Management\Backup.log"
	#Pull in the log file
	
	$BackupLogFileData = [string]::Join([Environment]::NewLine, (Get-Content $BackupLogFileName));
	#Create a split list of the items to query
	$BackupTestResults = $BackupLogFileData.Split([String[]]"NEW BACKUP [SQLSTATE 01000]", [StringSplitOptions]::RemoveEmptyEntries ) |

	#Grab the relevant values from each of the backups performed
	Select-Object @{Name = "BufferCount"; Expression = { [int]([regex]::Match($_, "BufferCount:(\s*\d+)").Groups[1].Value) } },
	@{Name = "MaxTransferSize"; Expression = { [int] ([regex]::Match($_, "MaxTransferSize:(\s*\d+)").Groups[1].Value) } },
	@{Name = "BackupTimeInSeconds"; Expression = { [double] ([regex]::Match($_, "pages in (\s*\d+.\d+)").Groups[1].Value) } },
	@{Name = "BackupSpeedInMBsec"; Expression = { [double] ([regex]::Match($_, "pages in (\s*\d+.\d+) seconds \((\d+.\d+) MB/sec").Groups[2].Value) } },
	@{Name = "BackupFileCount"; Expression = { [int] ([regex]::Match($_, "FILECOUNT=(\d+)").Groups[1].Value) } } 

	$BackupTestResults | Sort-Object buffercount, maxtransfersize, BackupFileCount | ft
}

ELSE {
	Write-Error "The file $BackupLogFileName does not exist."
}