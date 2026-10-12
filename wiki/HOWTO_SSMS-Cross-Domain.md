# HOWTO

Replace \<domain\> and \<username\> with the correct value and then run the whole line from the command prompt, batch file or short-cut(lnk):

    runas /user:<domain>\<username> /netonly "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe"

For example:

    runas /user:domtest\ryan.zerbe /netonly "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe"


## Connect to SQL Server via SSMS in another domain using Windows Authentication
SQL Server Management Studio
Connect to SQL Server via SSMS in another domain using Windows Authentication
written by Aaron Bertrand February 26, 2025 11 comments
Problem
You may find that you need to connect remotely to a SQL Server that is in another domain via SSMS. Since I work from home, I face this challenge all the time. Almost every SQL Server I connect to is in another domain. It is usually behind a VPN, a stingy firewall, and a stingier network team. This is a problem when SQL authentication is not an option because my Windows machine is in its own domain. SQL Server Management Studio cannot directly override the local Windows credentials and pass the credentials for a remote domain user.

The easy answer is to simply establish a remote desktop session to the machine in question. Then use Management Studio and other tools locally, but there are several challenges with that. Many corporations have policies in place that prevent tools like SSMS from being installed on the server. Some companies even resort to Server Core at least in part as a means to enforce this policy. They may not have a dedicated “jump” box to support remote desktop connections to the SQL Server machine. Or they may have such a box, but without all of the tools you require.

Solution
Aside from pushing for SQL Authentication, adding your machine to the remote domain, or making your local domain trusted, there are two approaches commonly used to get around this problem. Both work equally well for Management Studio, Visual Studio, SSDT, Excel, and many other applications that support passing Windows credentials. To keep things simple, I’m going to stick to the most common use case, Management Studio.

    runas /netonly
The method I use is the Windows built-in runas command. This allows you to run an application with Windows credentials you provide on the command line. The syntax is relatively simple:

    runas /netonly /noprofile /user:domain\username "c:\path\ssms.exe"
At this point, you are prompted for the password for the remote user. Once provided, you are told that it is attempting to run the program as that user:

command prompt
With this instance of the application, when you attempt to connect to the remote server using Windows Authentication. The New Query window will *look* like it is using your local Windows credentials in the connection dialog:

connection dialog
But in reality – behind the scenes – you are impersonating the login you passed on the command line. You can confirm this by querying SUSER_SNAME(). In modern versions of Management Studio, confirm this with the username next to the server you’ve connected to in Object Explorer:

evidence of impersonation
If you are connecting to the same remote domain many times, you may want to set up a shortcut. This will allow you to bypass entering all this information on the command line every time. Right-click the desktop and choose New > Shortcut. Then enter the same information as above in the command line:

create shortcut
And give the shortcut a label that will make it easy to identify:

name shortcut
Now, double-click the shortcut. After providing the remote password, it will launch an instance of Management Studio. The remote credentials will be used every time you use Windows Authentication:

launching shortcut
(You can achieve similar results using Microsoft’s SysInternals tool, ShellRunas.)

Credential Manager
Another method to connect to remote domains using Windows Authentication is to use the Credential Manager built into Windows. This can be a little tricky to setup, especially if you are connecting over a VPN. An added complication in my environment is that I am using a Mac host. This is connected by VPN to a remote domain in a data center. From there, I am connecting from Management Studio inside a Windows virtual machine.

The part that is tricky is ensuring that name resolution matches exactly. The Windows machine needs to identify the remote server by IP or fully-qualified domain name (FQDN), and may need to explicitly specify the port. I was finally able to make this work once I added the remote server names to my hosts file, and then ran ipconfig /dnsflush. I am not sure if the complication here is due to the VPN on its own, or the fact that I have an extra network translation layer due to the interaction with an additional operating system. Or maybe both.

Once you are sure you have the right FQDN (make sure you can ping it by name, or better yet, telnet to the server name on the SQL Server port (usually 1433)), go to Control Panel > Credential Manager, choose Windows Credentials, and Add a Windows Credential:

credential manager
Then specify the specific server name (potentially you may need server:port notation), the domain user (including the domain name), the password, and click OK:

add a windows credential
Connect via SSMS 
Now, when you connect from Management Studio, make sure you use the exact same server name as the one you entered in the credential, including the port number (only now, use a comma instead of colon if specifying the port number: server,port). Like with the runas /netonly solution, it will *look* like you are connecting using your local Windows credentials, but – as long as the credential store doesn’t have any issues in matching the server name – those really are the remote credentials that are being passed under the covers.

You will know quite quickly if the credentials are not matched – if you do not establish connectivity immediately, you will receive one of these errors:

Login failed. The login is from an untrusted domain and cannot be used with Windows authentication.
Login failed for user ”. The user is not associated with a trusted SQL Server connection.

These could be because the local credentials were passed, or because the username didn’t include the domain name (or user the wrong one). Double-check all of the properties of the stored credential and recreate it if you need to – you can modify the username and password, but if the server name is wrong, you’ll need to re-create it.

Once it is working, the difference in behavior here is that the credential is looked up every time you try to connect, based on the IP or server name entered, rather than when you launch the application. You will need to create a separate Windows Credential for every server you need to connect to; it does not work across all servers in a domain.

Conclusion
Those are two ways you can connect to SQL Servers in a remote domain and continue using Windows Authentication. In my opinion, the runas option is better if you only use SSMS to connect to a couple of remote domains (or a lot of different servers within one remote domain), since it is much quicker to set up and manage, and because the same Windows credentials will be passed for all of the servers you connect to from that instance of SSMS. The Credential Manager solution – while a little more cumbersome to set up, and a little trickier to troubleshoot – is better if you use the same instance of Management Studio to connect to many different servers, especially if they are in different environments, since it will automatically pick the right domain credentials based on server name, not based on the application’s startup arguments.

Of course, some of the reasons that prevent you from being able to connect to SQL Server inside the domain may also prevent you from using it outside, regardless of what application or credential passing mechanism you are using; for example, the port you need to connect to may not be open, or you may need to experiment with both IP address and FQDN to establish connectivity. In some cases, obtaining access to the SQL Server may still need further action by the network operations team in charge of the domain you’re trying to access. Note that this is not really any different from connectivity issues when using SQL Authentication or connecting from inside the domain or on the same network.