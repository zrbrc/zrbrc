<#
.SYNOPSIS
    General helper functions for the refresh process.
.NOTES
    Dot-sourced by Refresh-Database.ps1, so $script: here is the main script's scope.
#>

####################################################################################################
# Logging and display
####################################################################################################

function Write-Log {
    <#
    .SYNOPSIS
        Writes a timestamped line to the console/transcript and keeps it in $script:MessageLog for the summary and email report.
    .EXAMPLE
        Write-Log -Source 'Init' -Message ('Loaded {0}.' -f $Path)
        Write-Log -Source $Refresh.TargetDb -Message 'Restore failed.' -Level Error
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Message,

        [ValidateSet('Crit', 'Error', 'Warn', 'Info')]
        [string]$Level = 'Info'
    )

    if ($null -eq $script:MessageLog) {
        $script:MessageLog = New-Object -TypeName 'System.Collections.Generic.List[object]'
    }

    $LevelMap = @{
        Crit  = @{ ErrorLevel = 1; Color = 'Red' }
        Error = @{ ErrorLevel = 2; Color = 'Red' }
        Warn  = @{ ErrorLevel = 3; Color = 'Yellow' }
        Info  = @{ ErrorLevel = 4; Color = 'Gray' }
    }

    # flatten to a single line for the log table
    $CleanMessage = ($Message -replace '[\r\n\t]+', ' ').Trim()
    $Now = Get-Date

    $Entry = [PSCustomObject]@{
        Date       = $Now.ToString('yyyy-MM-dd')
        Time       = $Now.ToString('HH:mm:ss.fff')
        Type       = $Level.ToUpper()
        ErrorLevel = $LevelMap[$Level].ErrorLevel
        Source     = $Source
        Message    = $CleanMessage
    }
    $script:MessageLog.Add($Entry)

    if ($CleanMessage -ne '') {
        $Line = '[{0,-5}][{1}][{2}] {3}' -f $Entry.Type, $Entry.Time, $Source, $CleanMessage
        Write-Host -Object $Line -ForegroundColor $LevelMap[$Level].Color
    }
}


function Write-Table {
    <#
    .SYNOPSIS
        Writes objects as a table or list to the host so it lands in the transcript without polluting the pipeline.
    .EXAMPLE
        Write-Table -InputObject $Requests -Title 'R E Q U E S T E D  D A T A B A S E S'
        Write-Table -InputObject $BakFiles -List -DetailOnly
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $InputObject,

        [string]$Title,

        [string[]]$Property,

        # format as a list instead of a table
        [switch]$List,

        # only write when -Detailed was passed to the main script
        [switch]$DetailOnly
    )

    if ($DetailOnly -and -not $script:ShowDetail) { return }

    if ($Title) {
        Write-Host -Object ('{0}= = =  {1}  = = =' -f [Environment]::NewLine, $Title)
    }

    if ($null -eq $InputObject) { return }

    $FormatSplat = @{}
    if ($Property) { $FormatSplat.Property = $Property }

    if ($List) {
        $Text = $InputObject | Format-List @FormatSplat | Out-String -Width 500
    }
    else {
        $Text = $InputObject | Format-Table @FormatSplat -AutoSize | Out-String -Width 500
    }

    Write-Host -Object $Text.TrimEnd()
}


function Read-Choice {
    <#
    .SYNOPSIS
        Prompts until one of the allowed single-letter answers is given, returns it upper-case.
    .EXAMPLE
        $Answer = Read-Choice -Prompt '[?] Continue? (y)es/(n)o/(a)ll ' -Choice 'Y', 'N', 'A'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [Parameter(Mandatory = $true)]
        [string[]]$Choice
    )

    do {
        $Answer = (Read-Host -Prompt $Prompt).Trim().ToUpper()
    } until ($Answer -in $Choice)

    $Answer
}


function Disable-QuickEditMode {
    <#
    .SYNOPSIS
        Turns off console Quick Edit so a stray click does not pause the refresh. Returns a status message.
    #>
    [CmdletBinding()]
    param ()

    # type can only be added once per session
    if (-not ('DisableConsoleQuickEdit' -as [type])) {
        $QuickEditModeCode = @'
using System;
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

        uint consoleMode;
        if (!GetConsoleMode(consoleHandle, out consoleMode)) {
            return false;
        }

        consoleMode &= ~ENABLE_QUICK_EDIT;

        return SetConsoleMode(consoleHandle, consoleMode);
    }
}
'@
        Add-Type -TypeDefinition $QuickEditModeCode -Language CSharp
    }

    if ([DisableConsoleQuickEdit]::DisableQuickEditMode()) {
        'PowerShell Quick Edit Mode disabled.'
    }
    else {
        'PowerShell Quick Edit Mode failed to disable.'
    }
}


####################################################################################################
# Input files
####################################################################################################

function Import-RefreshFile {
    <#
    .SYNOPSIS
        Reads a delimited file, skipping blank lines and lines commented with '#'.
    .EXAMPLE
        $Requests = Import-RefreshFile -Path '.\request\SBX.txt' -Delimiter ';'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$Delimiter = ','
    )

    $Lines = Get-Content -Path $Path | Where-Object { $_.Trim() -ne '' -and -not $_.TrimStart().StartsWith('#') }

    if ($Lines) {
        $Lines | ConvertFrom-Csv -Delimiter $Delimiter
    }
}


function Split-ReplacePair {
    <#
    .SYNOPSIS
        Splits 'old1|new1;old2|new2' into objects with Old and New.
    .EXAMPLE
        Split-ReplacePair -String '_PROD|_SBX;PRODSRV|TESTSRV'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$String
    )

    foreach ($Pair in $String.Split(';')) {
        if ([string]::IsNullOrWhiteSpace($Pair)) { continue }

        $Parts = $Pair.Split('|')
        if ($Parts.Count -ne 2) {
            throw ('Invalid replace pair "{0}", expected old|new.' -f $Pair)
        }

        [PSCustomObject]@{
            Old = $Parts[0].Trim()
            New = $Parts[1].Trim()
        }
    }
}


function ConvertTo-FileMapping {
    <#
    .SYNOPSIS
        Converts 'logical=path,logical2=path2' into the hashtable Restore-DbaDatabase -FileMapping expects.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$String
    )

    $Map = @{}
    foreach ($Entry in $String.Split(',')) {
        if ([string]::IsNullOrWhiteSpace($Entry)) { continue }

        $Parts = $Entry -split '=', 2
        if ($Parts.Count -ne 2) {
            throw ('Invalid file mapping "{0}", expected logicalname=path.' -f $Entry)
        }

        $Map[$Parts[0].Trim()] = $Parts[1].Trim()
    }

    $Map
}


function Test-NameMatch {
    <#
    .SYNOPSIS
        True if Name matches any of the patterns (exact names or wildcards).
    #>
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string[]]$Name,

        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$Pattern
    )

    foreach ($Item in $Name) {
        foreach ($Wildcard in $Pattern) {
            if ($Item -like $Wildcard) { return $true }
        }
    }

    return $false
}


####################################################################################################
# Credential
####################################################################################################

function Get-RefreshCredential {
    <#
    .SYNOPSIS
        Returns the PSCredential for the share account, stored with DPAPI (only the same user on the same machine can read it).
    .DESCRIPTION
        First run prompts for the password. If the old AES .key/.pw pair from the previous version exists,
        it is converted automatically so non-interactive runs (SQL Agent) keep working.
        Delete the old .key/.pw files once every account that runs the refresh has converted.
    .EXAMPLE
        $Credential = Get-RefreshCredential -Login 'domain\user.refresh' -SecretsPath 'C:\Secrets'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Login,

        [Parameter(Mandatory = $true)]
        [string]$SecretsPath
    )

    if (-not (Test-Path -Path $SecretsPath -PathType Container)) {
        $null = New-Item -Path $SecretsPath -ItemType Directory
    }

    $BaseName = $Login.Replace('\', '_')
    $CredFile = Join-Path -Path $SecretsPath -ChildPath ('{0}_{1}_{2}.cred.xml' -f $BaseName, $env:COMPUTERNAME, $env:USERNAME)
    $LegacyKeyFile = Join-Path -Path $SecretsPath -ChildPath ('{0}.key' -f $BaseName)
    $LegacyPassFile = Join-Path -Path $SecretsPath -ChildPath ('{0}.pw' -f $BaseName)

    if (-not (Test-Path -Path $CredFile)) {

        # convert the old AES key/password pair if present
        if ((Test-Path -Path $LegacyKeyFile) -and (Test-Path -Path $LegacyPassFile)) {
            $Key = [byte[]](Get-Content -Path $LegacyKeyFile)
            $SecurePassword = Get-Content -Path $LegacyPassFile | ConvertTo-SecureString -Key $Key
            $Credential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $Login, $SecurePassword
            $Credential | Export-Clixml -Path $CredFile
            Write-Log -Source 'Credential' -Message ('Converted legacy key/password files to {0}.' -f $CredFile) -Level Warn
        }
        elseif ([Environment]::UserInteractive) {
            $CredentialSplat = @{
                UserName = $Login
                Message  = ('Password for {0}. Saved encrypted for {1} on {2}.' -f $Login, $env:USERNAME, $env:COMPUTERNAME)
            }
            $Credential = Get-Credential @CredentialSplat
            if ($null -eq $Credential) {
                throw 'No credential entered.'
            }
            $Credential | Export-Clixml -Path $CredFile
        }
        else {
            throw ('Credential file {0} not found and the session is not interactive. Run once interactively as {1} to create it.' -f $CredFile, $env:USERNAME)
        }
    }

    Import-Clixml -Path $CredFile
}


####################################################################################################
# Email
####################################################################################################

function Send-RefreshMail {
    <#
    .SYNOPSIS
        Sends a notification. A mail failure is logged as a warning and never stops the refresh.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$To,

        [Parameter(Mandatory = $true)]
        [string]$Subject,

        [Parameter(Mandatory = $true)]
        [string]$Body,

        [Parameter(Mandatory = $true)]
        [hashtable]$EmailSettings,

        [switch]$BodyAsHtml
    )

    $MailSplat = @{
        From       = $EmailSettings.From
        SmtpServer = $EmailSettings.SmtpServer
        To         = $To
        Subject    = $Subject
        Body       = $Body
        BodyAsHtml = $BodyAsHtml.IsPresent
    }

    try {
        Send-MailMessage @MailSplat -WarningAction SilentlyContinue
        Write-Log -Source 'Mail' -Message ('Sent "{0}" to {1}.' -f $Subject, ($To -join ', '))
    }
    catch {
        Write-Log -Source 'Mail' -Message ('Failed to send "{0}": {1}' -f $Subject, $_.Exception.Message) -Level Warn
    }
}
