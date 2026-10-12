# mklink

Creates a directory or file symbolic or hard link.

# Documentation Links

- mklink: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/mklink
- cmdkey: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/cmdkey

## Usage

We currently use this on the department SSIS servers to link to the SFTP/FilePrint server, specifically on TEST since they are different domains and we can't just access the share cross domain in $U batch script.

We only use this one place, but since we do and it is so infrequently used/configured, we need a guide. :)

Setting this up requires a few steps.

1. Create an mklink on the SSIS server pointing to the SFTP server. The link folder does not need to exist before creating the link, but the target does.

        $> mklink /d M:\mft \\xx.xx.xx.xx\mft

    To view existing links in your current folder.

        $> dir /al /s

1. Open a cmd.exe with the login that will be using this link. If this is a batch process using a particular login, use that login. You will need the password, its probably in Keepass. We need to do this becuase an mklink does not attach a login with the link like a mapped drive does. The link is system wide and each user using the link can use their own credentials or something defined in credential manager, which is what we need to do since we are connecting cross domain. We will be using the command-line credential manager(cmdkey) to define the dom domain account to use while accessing this link.

   1. Open cmd.exe as another user and enter the credentials.

   1. View existing credentials, if any.

            $> cmdkey /list

   1. Add credential--user and pass are optional and will be requested if you omit them on the command line. Use the correct credentials, below is just an example.

            $> cmdkey /add:xx.xx.xx.xx /user:<domain\username> /pass:<password>

   1. View credentials again and you should now see output like below.

            $> cmdkey /list

            Currently stored credentials:
        
            Target: Domain:target=xx.xx.xx.xx
            Type: Domain Password
            User: dom\DSS.Elig.SFTP

1. With the link and credentials created, you should now be able to browse the link you created. Using the same cmd.exe you opened as the other user, try to view the path in the cmd.exe and folders\file should appear that are present on the target.

1. If you are unable to see the target folders or get an access error, you can try to recreate the cmdkey entry.

        cmdkey /delete:xx.xx.xx.xx

1. Validate it is removed and then re-add the entry as we did above making any corrections.

1. Try to browse the path again. If it is still not working, you may have locked the account, have a bad password, or the account might not have access to the path. Further investigation may be needed. As a last resort, you could login to the server via RDP as the account you need to create the credential for and do all the testing there, the result is the same, but using cmdkey is generally easier for your own RDP session.
