try {
    & .\Archive-Files.ps1 -ComputerName hostnameclsn2 -Source M:\Temp\source -Target M:\Temp\target -Cleanup 10
    & .\Archive-Files.ps1 -ComputerName hostnameclsn2 -Source M:\Temp\source -Target M:\Temp\target2 -Cleanup 10
}
catch {
    $_
    "`nFAILURE!"
}
