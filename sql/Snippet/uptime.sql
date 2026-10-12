-- shows service uptime to see when a server might have last reboot, hopefully bc of WSUS running
-- not pefect bc service coule have been restarted for any reason, but server not
SELECT @@SERVERNAME AS server_name, sqlserver_start_time AS uptime FROM sys.dm_os_sys_info