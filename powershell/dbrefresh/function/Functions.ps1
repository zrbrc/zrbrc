<#
.SYNOPSIS
    General functions
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>

function Split-DoubleList {
    [CmdletBinding()]
    param (
        [string]$String
    )

    $list = $string.Split(";")
    $table = $list | ForEach-Object { $_ | ConvertFrom-String -Delimiter "\|" -PropertyNames 'Old', 'New' }
    $table
}

function Disable-QuickEditMode {
    [CmdletBinding()]
    param ()
   
    $QuickEditModeCode = @" 
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;
    using System.Runtime.InteropServices;

    public static class DisableConsoleQuickEdit {
        
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern IntPtr GetStdHandle(int nStdHandle);
        
        [DllImport("kernel32.dll")]
        static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
        
        [DllImport("kernel32.dll")]
        static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
        
        const uint ENABLE_QUICK_EDIT = 0x0040;
        const int STD_INPUT_HANDLE = -10;
        
        public static bool DisableQuickEditMode() {

            IntPtr consoleHandle = GetStdHandle(STD_INPUT_HANDLE);

            // get current setting
            uint consoleMode;
            if (!GetConsoleMode(consoleHandle, out consoleMode)) {
                return false;
            }
            
            consoleMode &= ~ENABLE_QUICK_EDIT;

            // set the new mode
            if (!SetConsoleMode(consoleHandle, consoleMode)) {
                return false;
            }
            return true;
        }
    }
"@

    Add-Type -TypeDefinition $QuickEditModeCode -Language CSharp

    if ([DisableConsoleQuickEdit]::DisableQuickEditMode()) {
        Write-Output "PowerShell Quick Edit Mode disabled."
    }
    else {
        Write-Output "PowerShell Quick Edit Mode failed to disable."
    }
}

function Write-MessageLog {

    param(
        [parameter(Position = 0, Mandatory = $true)]
        [string]
        $Source
        ,        
        [parameter(Position = 1, Mandatory = $true)]
        [string]
        $Message
        ,
        [parameter(Position = 2, Mandatory = $true)]
        [ValidateSet('Crit', 'Error', 'Warn', 'Info', 'Verbose')]
        [string]
        $Type
    )
    # checks if we have a script scope message log and creates one if not
    # it will create this on the first call and then add to it on subsequent calls
    if (-not (Get-Variable -Name MessageLog -Scope Script -ErrorAction Ignore)) { $script:MessageLog = @() }

    # shorten up type for display and table
    $TypeShort = $Type.Substring(0, 4).ToUpper()

    switch ($TypeShort) {
        'CRIT' {
            $ErrorLevel = 1
        }
        'ERRO' {
            $ErrorLevel = 2
        }
        'WARN' {
            $ErrorLevel = 3
        }
        'INFO' {
            $ErrorLevel = 4
        }
        'VERB' {
            $ErrorLevel = 5
        }
    }

    # gets time
    $DateStamp = Get-Date -Format 'yyyy-MM-dd'
    $TimeStamp = Get-Date -Format 'HH:mm:ss.fff'

    # creates log object
    $logobj = [PSCustomObject]@{
        Date       = $DateStamp
        Time       = $TimeStamp
        Type       = $TypeShort
        ErrorLevel = $ErrorLevel
        Source     = $Source
        Message    = $Message.Trim("`r", "`n").Replace("`n", ' ').Replace("`r", ' ').Replace("`t", ' ').Replace('`n', ' ').Replace('`r', ' ').Replace('`t', ' ') 
    }

    # add log object to messagelog table
    $script:MessageLog += $logobj

    if ($Message -ne '') {
        # write log message
        if ($ErrorLevel -eq 5) {
            # only write verbose type errors if verbose is turned on
            if ($VerbosePreference -eq 'Continue') { 
                Write-Output "[$TypeShort][$TimeStamp] $Message"
            }
        }
        else {
            Write-Output "[$TypeShort][$TimeStamp] $Message"
        }
    }
}

function Get-SecuredPassword {

    param(    
        [parameter(Mandatory = $true)]
        [string]
        $Login)

        $SecretsPath = 'C:\Secrets'

        if (-not (Test-Path $SecretsPath -PathType Container)) { $null = New-Item -Path $SecretsPath -ItemType Directory }

        $KeyFile = $SecretsPath + '\' + $Login.replace('\', '_') + '.key'
        $PassFile = $SecretsPath + '\' + $Login.replace('\', '_') + '.pw'
        
        # creates secret folder if doesnt exist
        if (-not (Test-Path $SecretsPath -PathType Container)) { $null = New-Item -Path $SecretsPath -ItemType Directory }
        
        # checks for keyfile and creates
        if (-not (Test-Path -Path $KeyFile)) {
            $Key = New-Object byte[] 32
            [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
            $Key | Out-File -FilePath $KeyFile -Encoding UTF8
        }
        
        # checks for password file
        if (-not (Test-Path -Path $PassFile)) {
            $SecurePw = Read-Host "Enter Password for ($Login)" -AsSecureString 
            ($SecurePw | ConvertFrom-SecureString -Key $Key) | Out-File -FilePath $PassFile -Encoding UTF8
        }
    
        # gets content from password and key files
        $EncryptedPw = Get-Content $PassFile
        $Key = Get-Content $KeyFile
    
        # convert text password to secure string
        $SecurePw = $EncryptedPw | ConvertTo-SecureString -Key $Key
    
        # convert secure string password to string password and cleans up pointer for more security
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePw)
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        $Password
       
}