# DBDeploy for DECSS

## Current Installs

dbdeploy is current installed on the following servers:

- Prod:
  - hostname7n1 - xx.xx.xx.xx at M:\\Management\\Scripts\\dbdeploy

- Test:
  - hostname8n1 - xx.xx.xx.xx at M:\\Management\\Scripts\\dbdeploy

## Getting Started

To setup the TFS workspace, you need to do the 2 commands below before the TFS steps will work in the build script:

```
cd "C:\Program Files\Microsoft Visual Studio\2022\TeamExplorer\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer"

TF.exe workspaces /collection:https://tfs.domain.com/tfs/DESyst
```

### Requirements

- Visual Studio Team Explorer or Visual Studio Community Edition, latest version should be fine. The page has changed since this guide was written, but download either of those.

  https://visualstudio.microsoft.com/downloads/

At the link, scroll to the bottom of this page to the 'downloads'
section, expand Visual Studio 2019 and then download Visual Studio 2019
Team Explorer.

  ![Download](.//media/image1.png)

- Powershell 5: This is included with Windows 10 and Windows Server 2016, no action needed. If you happen to be on Server 2012, Powershell 5 needs to be installed, 'Google' WMF5.

- ImportExcel powershell module: This is installed during the first run of the Build script, no action needed. This is expected to take place on your desktop with access to the internet and the Powershell gallery.

- dbdeploy scripts: Can be found on the DBA TFS repo at this [location](https://tfs.domain.com/tfs/dept/DMS_BaseTech/_git/DBA?path=%2FPowershell%2Fdbdeploy). This step can be accomplished via VS code or you can download the files manually. Open a browser to the above URL. On the left pane find dbdeploy folder and then the 3 dots for the folder. Click the 3 dots and download the folder as a zip. Once downloaded, unzip and store some place on your local disk so we can run the build later.

- Sqlserver powershell module: This is a requirement to do the deploy on the **server**, it is most likely already on there. If its not, this can be downloaded and saved to your local PC and then copied to the server. Do so via Save-Module sqlserver -Path 'C:\\<localpath>'. This will create a module folder at that path. You then need to get this folder to the server. It will be quicker and easier to zip it and then copy. You will then need to unzip this in the global powershell modules folder. The path will be like 'C:\\Program Files\\WindowsPowerShell\\Modules\\sqlserver\\ 21.1.18221' with all the files and folders existing under the version number folder. If you are doing this on Server 2012. The modules folder does not support the version number subfolder. Move all the sqlserver modules files and folders up one folder and delete the version number folder which should be empty after the move.

## Setup

### Installing and Setup of TFS for DECSS

After installing Team Explorer via the above link, connect Team Explorer
to our TFS. 

  [Connect to projects in Team Explorer](https://docs.microsoft.com/en-us/visualstudio/ide/connect-team-project)

If you don't see hosted repos and your account(as below), you may need to manually add our TFS on this screen.

1. Click Add account, choose your Delaware.gov account.

2. Click 'Add' server for repo and use: https://tfs.domain.com/tfs

3. After that adds, you should see the collections on TFS, like below. You need access to DESyst for DECSS source code which is contained in **DECSS Source \<env\>** projects in that collection.

4. Choose DESyst and then click connect.

   ![tfs connection](.//media/image2.png){

We now need to map a folder to TFS so we can download/sync our local desktop with the code on TFS.

Once you complete the previous step and connect to TFS, the right pane should look something like below. Click on Source Control Explorer, you will now have a new pane that fills up the rest of the window.**

   ![Source Control Explorer](.//media/image3.png)

In Source Control Explorer you should see something like below. Choose the root folder and look where it says Local Path: (already filled in the screen below), it should say something like not-mapped\\un-mapped. Click on that and choose a local folder to map it to. I recommend something simple like I have chosen. Remember the location as this will be needed for input when we run the build script the first time. You don't need to copy the path as you will be able to select via an explorer window, but just remember where you put it.

When you go thru the mapping wizard, DO NOT download all the code when it asks. We don't need all the code, just a subset related to DB changes.

   ![Mapping](.//media/image4.png)

Once the root mapping is complete, in the same window 'Source Control Explorer', find folders 'DECSS Source <ENV>', go to the 'DecssDB' subfolders for each environment and right-click 'Get Latest', again, just on the DecssDB folders. This will download all the code in the subfolder to your local PC. This will be the source used for the build script. Make sure to do this on at least Prod and UAT environments of DecssDB, we most likely don't need the lower environments.

At this point you can close out Team Explorer, we are done with it. All further TFS GET updates will be handled via the Build and Deploy Powershell script.

If you have more questions or want more screenshots of the process, here is a link with some more info:

https://blogs.objectsharp.com/post/2012/11/20/Mapping-to-a-TFS-Source-Control-Folder.aspx

## Running the Build

### UPDATES

There have been some new features added to the dbdeploy scripts.

1. Build-DecssSqlPackage.ps1 will now self-update. It will check its current version against TFS and if you are running an old version, it will update the whole folder to grab any changes and restart itself.

   ![self updating](.//media/image5.png)

2. You can now build for each environment separately. For example,
    DECSS UAT has Test, Timewarp, and Fedcert. You can now build for 1
    or all of them. This done by using a numbered comma separated list.
    This change was made to accommodate DECSS' change to no longer
    include FEDCERT in their UAT builds. Rather than hardcode what
    should or should not be included, I decided to let the builder
    choose environments. A normal UAT build is now **TEST and
    TIMEWARP**, so you would enter **1,2** when prompted, without the
    quotes.

   ![env select](.//media/image6.png)

3. Some other minor formatting on Build and Deploy.

### Starting the Build

You should have the dbdeploy scripts saved to your PC somewhere, the
instructions for doing so are above in the requirements section.

Browse to that folder and find dbdeploy\\release\\Build-DecssSqlPackage.ps1. This
is the singular build script. The only other folder\\file that is needed
is config\\dbconfig.json. This file has all the info about the servers,
instances, and DBs. Any other files\\folders will be created during the
build. There are other files\\folder present, but this is all that is
needed for the BUILD.

When you run the build script for the first time it will do a couple
things:

1. Install the ImportExcel powershell module.

2. Scan your PC for tf.exe.

3. Ask you to point it at the DECSS TFS Root folder. This is folder
    that I asked you to make note of above.

On subsequent runs, it will also check the version on TFS to see if you
need a new version. This should all happen transparently without any
interaction. If this fails to do the check/update for any reason, it
should continue on with the build process.

Right-Click on Build-DecssSqlPackage.ps1 and click Run with Powershell
to start the build process.

It will perform steps 1 and 2 automatically and then prompt you for the
DECSS ROOT. Choose the correct folder that you mapped in TFS earlier. On
subsequent runs, it will not perform these steps again if they are
already set in the config file.

   ![folder select](.//media/image7.png)

- **Choose environment**: Type the correct code of what we are
    building for. This is to know which environment in TFS to sync. This
    can now a multiple selection.

- **Choose excel build file**: When the file choose dialog opens, pick
    the Excel file for the build you are performing. Choose your file
    and then click 'Open'. The location of the file does not matter, it
    will bring the file into the package when its built. Make sure you
    don't have the Excel build file open or you'll get an error in
    Powershell and you'll have to do it again. If you forget, just
    cancel out of script, close excel and run Build-DecssSqlPackage.ps1
    again.

   ![choose excel](.//media/image8.png)

After you validate the environment and file, it will update the TFS
files on your local PC and then the build will start. It will give you a
count of the files from the Excel file, a message if any can't be found,
and then it will zip all the sql files, Excel file, and a deploy file
with all the info needed to perform the deploy. It will then open the
output folder in explorer so you can view/validate it.

The zip will be put into the build folder with a naming scheme of
APPL\_ENV\_TIMESTAMP\_randomcode.zip. The random code is strictly for
identification. If someone happens to create a package at the same time
and as you, this randomcode will differentiate those 2 packages. This is
used during the deploy, along with date and time, to determine if a
package has already been deployed.

The contents will be like:

   ![zip file](.//media/image9.png)

The deploy.json looks like:

   ![json file](.//media/image10.png)

The deploy.json file will be the input of the deploy script when we
execute the deploy.

## Deploy the Build

dbdeploy script locations:

- Prod: xx.xx.xx.xx (node 1): **M:\\Management\\Powershell\\dbdeploy**

- Test: xx.xx.xx.xx (node 1): **M:\\Management\\dbdeploy**

Copy the zip file (in the build folder on YOUR PC) we just created to
the server where we will be deploying the changes from. Location of the
copied zip on the server does not matter as the deploy script will ask
for the location when you run it. Just remember where it is.

Browse to the location of the Deploy-SqlPackage.ps1, full paths above.
If dbdeploy scripts has not yet been deployed to the server, you will
need to do this step.

### Backups

Before deploying changes, we need to backup the databases and there are
3 options here. In the dbdeploy folder there is a backupscripts folder.

1. You can either use SSMS and execute the 2 .sql files against the correct AG replica or AG listener. The first line in the script is a commented lined about where to execute the script. Once completed, continue to the deploy.

2. Run Backup-Database.ps1. This will run backup jobs in parallel on each AG for the same databases as the above scripts. The powershell option will send an email to the executor when completed. Right-click and **Run with Powershell**. This will show the same output as if you had run the scripts via SSMS. It should trap all errors and alert if there is an error, but I like to scan the log and make sure it has successfully verified the backup files. You can do so on the screen or via backup.log file in the same directory.

3. Use the OLA scripts in Sql Server Agent. This is not yet in place and will hopefully be the standard option once DECSS moves to OLA.

### Deploy

After the backups are completed, right-click on Deploy-SqlPackage.ps1
and **Run with Powershell**, it will start and ask you to select the
.zip file we copied to the server earlier.

![choose zip](.//media/image11.png)

After verification the script will unzip the zip file, read in the
deploy.json, and execute the scripts in order of priority as defined in
the deploy.json.

You will see each script execute with output and then a summary of the
status of each script at the end. This screen is slightly different now,
it also show the Instance and Database the execution occurs on.

![output](.//media/image12.png)

If all is completed successfully, the zip file will be moved to the
archive folder with an included log file.

If there is an error, it will be noted, and the extracted files can be
found in the temp\\\<APPL\_ENV\_DATE\> folder. This will allow any .sql
file updates to be updated and then the build re-run. It will use these
updated files instead of what's in the ZIP, but it still asks for the
ZIP as it uses that info to determine what we are trying to build. This
is a fringe use case and we would most likely not be editing any sql
files.

All actions are also logged in the log folder with a dated file.