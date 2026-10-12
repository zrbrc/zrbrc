# Install Certificate

NOTE: THIS IS THE OLD PROCESS, THE NEW PROCESS INVOLVES A POWERSHELL SCRIPT THAT EXECUTES ON EACH SERVER. IT CREATES CERT, INSTALLS, AND RESTART MSSQL IF DESIRED. THE VALIDATE CERTIFICATE PORTION AT THE END CAN STILL BE USED.

In SQL2019+ you can import the cert right from SQL Configuration Manager and not need to import it via double click (steps 2 and 3 below), but you still can import either way.

If you have hardened SQL and not set the SQL Service service account as a local admin, you need to grant read permissions for the service account to the private key in the local certificate store.

1. Open **certlm.msc** from Start Menu.

1. Go to Personal->Certificates. This is the machine's Certificate Store.

1. Find the certificate you are using for SQL Server, right click, **All Tasks->Manage Private Keys**.

1. Click Add and then add the service account name, not the domain user account.

    NT Service\MSSQL$<instancename>

1. Grant read permissions **only**.

1. Ok out of the screens and restart SQL Server to verify.

## Steps for importing a certificate

This later half of the below steps are for installing a certificate with a **mismatched subject name(SN)**, the first couple steps will be same for installing a valid cert.

A mismatched name cert would be installing a *.domain.com certificate for use in domX domain. SQL looks for a matching subject(server) name to able to select it from the drop down, if they dont match, some manual steps are needed to make SQL use the cert we want to use.

1. Get certificate from telecom, should be a .pfx file, sometimes they will send as a .txt file, just rename to a pfx file. It's password protected, you will need that to import it on the server.

1. Take cert to server, double click cert, and import it to the Local Computer store. Click next a few times and enter password as required.

1. Open **certlm.msc** and go to **Certifcate - Local Computer\Personal\Certificates**, you should see the cert you just imported.

1. If this is not a name mismatched cert, you can go to SQL Configuration Manager\SQL Server Network Configuration and right click on **Protocols for <instancename>**. Then choose the correct certicate from the drop down. SQL Services will need to be restarted. You can stop here if this worked for you.

1. **The rest of this is not needed for SQL2019+, it will let you select a mismatched cert in the GUI now.** If this is a name mismatched cert, open **certlm.msc**, double click on the cert we want to use, go to **Details** tab, scroll to bottom and find **Thumbprint**.

1. Copy the value in that field and paste it to notepad++, remove all spaces and verify there arent any hidden chars at the beginning or end of the string. This can be accomplished by deleting and retyping first and last chars to make sure nothing is before or after. Usually there is a hidden character at the beginning and it will take 2 deletes to actually delete the first character. You should end up with a string like below.

       17aca7c29a32e5d0ac02aff858c5da75adf7c3b7

1. Open **regedit** and browse to key.

       HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL<version.instancename>\MSSQLServer\SuperSocketNetLib\Certificate

1. Paste the thumprint string from above in the **Certificate** key.

## Validate Certificate

1. Once cert is import and select, restart SQL Services and check SQL log to verify it found and used the certificate. You should see a message something like this.

       The certificate [Cert Hash(sha1) "74E64D81B08EC7BFF1F0EDDD4DA8861502881187"] was successfully loaded for encryption.

1. Connect to the SQL instance with encryption enabled and selected in SSMS. Depending on where you are connecting to/from you might need to **Trust Certificate** because its signed by a different CA. This option is right below **Encrypt Connection** and may be slightly different depending on SSMS version.

1. Once connected, check for encrypted connections with below code, you should see one for yourself. You might see some unencrypted connections as well, its takes some time for the connections to expire.

   ````sql
   SELECT *
   FROM sys.dm_exec_connections dec
   left join sys.dm_exec_sessions des on des.session_id = dec.session_id
   CROSS APPLY sys.dm_exec_sql_text(dec.most_recent_sql_handle) AS est
   where dec.encrypt_option = 'TRUE'
   ````

1. DONE
