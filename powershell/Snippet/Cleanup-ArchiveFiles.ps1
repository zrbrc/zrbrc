try {

    & $env:S_DIR_UPROC\Archive-Files.ps1 -ComputerName hostnameclsn2 -Source M:\Temp\source -Target M:\Temp\target -Cleanup 10
}
catch {
    $_
    "`nFAILURE!"
}
