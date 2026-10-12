# set secrets folder
$SecretsFolder = "$env:APPDATA\Secrets"

# check is folder exists, it not, create it
if (!(Test-Path -Path $SecretsFolder -PathType Container)) { $null = New-Item -Path $SecretsFolder -ItemType Directory }

# find existing secrets
$Secrets = Get-ChildItem -Path $SecretsFolder -Filter *.xml | Import-Clixml

$answer = $null
$continue = $false

do {
    Write-Output "`nSecrets:"
    for ($i = 0; $i -lt $Secrets.Length; $i++) { "  {0}`t{1}" -f $i, $Secrets[$i].UserName }
    "  {0}`t{1}" -f "A", "Add Account"
    "  {0}`t{1}" -f "E", "Edit Account"
    "  {0}`t{1}" -f "R", "Remove Account"
    "  {0}`t{1}" -f "C", "Cancel"
    $answer = Read-Host "Which option?"
    switch ($true) {
        # add a new secret
        ($answer -eq 'a') {
            "a"
            
            $cred = Get-Credential
            $cred | Export-Clixml -Path "$SecretsFolder\$(($cred.UserName).Replace('\','_')).xml"
            
            $Secrets = Get-ChildItem -Path $SecretsFolder -Filter *.xml | Import-Clixml
        }
        # edit a secret
        ($answer -eq 'e') {
            "e"
            for ($i = 0; $i -lt $Secrets.Length; $i++) { "  {0}`t{1}" -f $i, $Secrets[$i].UserName }
            
            [int]$edit = Read-Host "Edit which secret?"
            if ($null -ne ($edit -as [int]) -and $answer -ne '') {
                if ([int]$edit -lt $Secrets.length) {
                    $cred = Get-Credential -Credential $Secrets[$edit].UserName 
                    $cred | Export-Clixml -Path "$SecretsFolder\$(($cred.UserName).Replace('\','_')).xml"
                }
            }
            
            $Secrets = Get-ChildItem -Path $SecretsFolder -Filter *.xml | Import-Clixml
        }
        ($answer -eq 'r') {
            "r"
            for ($i = 0; $i -lt $Secrets.Length; $i++) { "  {0}`t{1}" -f $i, $Secrets[$i].UserName }
            
            [int]$remove = Read-Host "Remove which secret?"
            if ($null -ne ($remove -as [int]) -and $answer -ne '') {
                if ([int]$remove -lt $Secrets.length) {
                    Remove-Item -Path "$SecretsFolder\$(($Secrets[$remove].UserName).Replace('\','_')).xml" -Force
                }
            }
            
            $Secrets = Get-ChildItem -Path $SecretsFolder -Filter *.xml | Import-Clixml
        }        
        # choose existing secert
        ($null -ne ($answer -as [int]) -and $answer -ne '') {
            if ([int]$answer -lt $Secrets.length) {
                "num"
                $continue = $true
            }
        }
        ($answer -eq 'c') {
            "c"
            exit
        }
        # you chose wrong
        default {
            "Please enter a valid secret"
            $answer = $null
        }
    }

}
until ($continue -eq $true)

$LaunchCred = $Secrets[$answer]
$LaunchCred

