# SSMS and SSIS Offline

This info is from this link, but summarized: <https://learn.microsoft.com/en-us/ssms/install/create-offline>

## To download

You need to get the vs_SSMS.exe from MS, you can find it on the SSMS download page.

<https://learn.microsoft.com/en-us/ssms/install/install>

After downloaded, run this command to an empty folder to create the install files, this includes SSIS too.

    .\vs_SSMS.exe --layout C:\SSMS_Layout --add Microsoft.SSMS.Component.IS

You also might need 1 extra cert for the install to work, grab it from the link below and put it in the Certificates folder in the layout folder. 
There should already be 3 certs in that folder.

<https://www.microsoft.com/pkiops/certs/Microsoft%20Windows%20Code%20Signing%20PCA%202024.crt>

## To install

Copy the layout folder to the offline machine.

### Certs

You need these 4 certs installed or the installer will silently fail leaving you clueless.

    certutil.exe -addstore -f "Root" ".\certificates\Microsoft Windows Code Signing PCA 2024.crt"
    certutil.exe -addstore -f "Root" ".\certificates\manifestRootCertificate.cer"
    certutil.exe -addstore -f "Root" ".\certificates\manifestCounterSignRootCertificate.cer"
    certutil.exe -addstore -f "Root" ".\certificates\vs_installer_opc.RootCertificate.cer"

### Setup

Run this command to actually install SSMS, this one included SSIS functionality as well. If you dont install it, you wont be able to see anything SSIS in SSMS.

    .\vs_SSMS.exe --noWeb --add Microsoft.SSMS.Component.IS

Once the setup starts and you get to the 'choosing' screen, just click 'Install'.