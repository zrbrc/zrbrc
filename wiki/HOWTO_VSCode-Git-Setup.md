# Using GIT with VS-Code

## Requirements

### VS Code

https://code.visualstudio.com/Download

>Install with default options.

### Git

https://git-scm.com/download/win

>Install with default options. Except for SSL option, choose Windows Channel.

## Setup

1. Before being able to commit any change to TFS, you will need to open a command prompt and run these 2 command to set your git user info.

   ```cmd
   git config --global user.name "Your Name"
   git config --global user.email "youremail@yourdomain.com"
   ```

1. Launch VS Code: Upon first launch, you will probably see the welcome screen and the explorer window on the side, all should be empty. Go to FILE-\>Save Workspace As... and save it to your profile folder or wherever you like with a good name. This will hold your settings and the folders that you add into your workspace to work with. It is not your actual working files from TFS, just settings, etc.

1. Find DBA Git Repo: Go to [Basetech TFS](https://tfs.domain.com/tfs/dept/DMS_BaseTech/) and click on the Code tab on the top bar.  **Note: The guide is for setting up a link to the test repo for testing, but you can use the DBA repo directly as well, just subsititute DBA for test.** The default repo should be the TFS BaseTech repo. On the page, on the second line on the left, click on **$/DMS\_BaseTech**, then **All repositories**, then **test**. You should now see a mostly empty repo. On the top right click the **Clone** button, this will give popup for **Clone repo,** make sure HTTPS is chosen and then click the copy button at the end of that line. This is the URI of the repo we are going to clone into VS Code. Once you have that copied, go back to VS Code.

    ![Clone Repo](.//media/image1.png)

1. Clone a Git Repo: In VS Code, hit F1 key, and a menu will drop down from the top of the screen. Type 'git clone' and the field will start to auto fill, chose the option for 'Git: Clone' and then paste in the URI we copied in the previous step. It should work for a few seconds and then ask you for your username and password, if needed. Enter in your dom domain user and password. It will then ask you where you would like to clone this repo too. Choose a folder to save it. It doesn't matter where, but I recommend not in your Documents folder as that is part of OneDrive and you'll then be syncing all these files there as well, which you don't want. I have a folder **C:\\Workspace** where I clone all my repos too, using something similar, **C:\\TFS**, **C:\\GIT**, etc. The Clone process will create a subfolder using the name of the repo in whatever folder you pick. When that's complete, you will get a pop-up in the bottom right corner if you would like to open the folder in a new workspace or add to your current workspace, chose current. It is now visible in the Explorer pane. I have the side bar on the right side of my screen, but it will show the same on the left in reverse.

    ![File List](.//media/image2.png)

1. You can now edit files in this repo. Try creating a new file in the explorer pane. Right click on the test folder or a subfolder and 'New File'. Name it whatever you want, edit the file however you want in it and then save it 'Ctrl+S' or via File menu. If you use a known file extension, VS Code may ask to install an extension for that type of file. For example if you create a ps1 file, it will ask you if you want to install the Powershell extension, the same for .sql, .xml, .csv, etc. Some extensions offer Intellisense, executing, or just syntax coloring/highlightin. VS Code has a ton of extensions and themes and icons to change its look. Below is what I use. A **lint/linting** extension is similar in function to syntax highlighting/intellisense in VS Code 

    ![VScode Extensions](.//media/image3.png)

     **NOTE: The latest VS Code update have changed the layout of the Git screen slightly.**

1. After making changes and saving a file, if you click on the Git icon on the side panel ![Git Icon](.//media/image5.png), you can see what changes you've made. If this is an existing file, you can click on it and it will show what was changed. Type a message in the message box (pic below), this is the message that will go against your check-in, ideally this would be a TFS\# or some descript change info, limited to 50 chars though. I typically just make a small comment, 'initial commit', 'added some comments', 'tweaked user routine'. The actual changes are tracked, so they can be seen after the fact, all the history is kept. Now if all the changes to all the files are all related, you can click the check button and they will all be staged. If you only want to stage a couple files and not all at once, you can click the '+' next to each file and stage those files you choose. Clicking the check button now will only commit what you staged instead of all changes.

    ![Git](.//media/image6.png)

1. Once you stage your commits, the git master sync button will then change to a sync button with a pull push count. This means there is 1 change-set to be pushed. Click that will then push your changes to the repo. **NOTE**: If you only have 1 repo setup, you will not see this in the same manner. The sync button with changes will show in the bottom left of VS Code on the status bar.

    ![Git](.//media/image7.png)

You have completed a git clone and pushed a file back to the repo. At some point VS Code will ask you if you want to do an occasional fetch to check for changes. This is recommended as it will see if there are any changes on the repo that your local client is not aware of. Nothing will be overwritten locally, this is only getting new/updates files that you haven't made any changes to. If you do have a conflict, VS Code will tell you so and let you determine what to do when you try to push to the repo.

There are other topics outside of this quick getting started doc, branching, merging that could have their own doc.
