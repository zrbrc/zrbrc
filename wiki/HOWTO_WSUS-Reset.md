# Reset WSUS

```bat
:: Reset Windows Update components manually

:: Open a Windows command prompt. To open a command prompt, select Start > Run. Copy and paste (or type) cmd and then press Enter.

:: Stop the BITS service, the Windows Update service and the Cryptographic service. Type the following commands at a command prompt. Press Enter after you type each command.

net stop bits
net stop wuauserv
net stop cryptsvc   

:: Delete the qmgr*.dat files.

Del "%ALLUSERSPROFILE%\Application Data\Microsoft\Network\Downloader\qmgr*.dat"

:: If it is your first attempt at resolving your Windows Update issues by using the steps in this article, go to step 5 without carrying out the steps in step 4. The steps in step 4 should only be performed at this point in the troubleshooting if you can't resolve your Windows Update issues after following all steps but step 4. The steps in step 4 are also performed by the "Aggressive" mode of the Fix it Solution above.

:: Rename the following folders to *.BAK:
:: %Systemroot%\SoftwareDistribution\DataStore
:: %Systemroot%\SoftwareDistribution\Download
:: %Systemroot%\System32\catroot2

:: To do this, type the following commands at a command prompt. Press Enter after you type each command.

:: Ren %Systemroot%\SoftwareDistribution\DataStore DataStore.bak
:: Ren %Systemroot%\SoftwareDistribution\Download Download.bak
:: Ren %Systemroot%\System32\catroot2 catroot2.bak

:: Important
:: The reset step below using sc.exe will overwrite your existing security ACLs on the BITS and Windows Update service and set them to default. Skip this step unless the other steps to reset Windows Update components have not resolved the issue.
:: Reset the BITS service and the Windows Update service to the default security descriptor. To do this, type the following commands at a command prompt. Press Enter after you type each command.

:: sc.exe sdset bits D:(A;CI;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)
:: sc.exe sdset wuauserv D:(A;;CCLCSWRPLORC;;;AU)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;SY)

::Type the following command at a command prompt, and then press Enter:

cd /d %windir%\system32

:: Reregister the BITS files and the Windows Update files. To do this, type the following commands at a command prompt. Press Enter after you type each command.

regsvr32.exe atl.dll
regsvr32.exe urlmon.dll
regsvr32.exe mshtml.dll
regsvr32.exe shdocvw.dll
regsvr32.exe browseui.dll
regsvr32.exe jscript.dll
regsvr32.exe vbscript.dll
regsvr32.exe scrrun.dll
regsvr32.exe msxml.dll
regsvr32.exe msxml3.dll
regsvr32.exe msxml6.dll
regsvr32.exe actxprxy.dll
regsvr32.exe softpub.dll
regsvr32.exe wintrust.dll
regsvr32.exe dssenh.dll
regsvr32.exe rsaenh.dll
regsvr32.exe gpkcsp.dll
regsvr32.exe sccbase.dll
regsvr32.exe slbcsp.dll
regsvr32.exe cryptdlg.dll
regsvr32.exe oleaut32.dll
regsvr32.exe ole32.dll
regsvr32.exe shell32.dll
regsvr32.exe initpki.dll
regsvr32.exe wuapi.dll
regsvr32.exe wuaueng.dll
regsvr32.exe wuaueng1.dll
regsvr32.exe wucltui.dll
regsvr32.exe wups.dll
regsvr32.exe wups2.dll
regsvr32.exe wuweb.dll
regsvr32.exe qmgr.dll
regsvr32.exe qmgrprxy.dll
regsvr32.exe wucltux.dll
regsvr32.exe muweb.dll
regsvr32.exe wuwebv.dll

:: Reset Winsock. Type the following command at a command prompt, and then press Enter:

netsh winsock reset

:: If you're running Windows XP or Windows Server 2003, you have to set the proxy settings. Type the following command at a command prompt, and then press Enter:

proxycfg.exe -d

:: Restart the BITS service, the Windows Update service and the Cryptographic service. Type the following commands at a command prompt. Press Enter after you type each command.

net start bits
net start wuauserv   
net start cryptsvc
```