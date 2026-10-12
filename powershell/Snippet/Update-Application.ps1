$exe = '.\npp.8.7.5.Installer.x64.exe'
$cli = @('/S', '/noUpdater', '/closeRunningNpp')

Start-Process -FilePath $exe -Wait -ArgumentList $cli