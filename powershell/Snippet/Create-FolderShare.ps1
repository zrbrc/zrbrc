$share_name = 'test_share'
$share_path = 'M:\test_share'

try {
    if (Get-SmbShare -Name $share_name -ErrorAction SilentlyContinue) {
        "[i] Share already exists."
    }
    else {
        $null | New-SmbShare -Name $share_name -Path $share_path -FullAccess 'Everyone'
        "[+] Share created."
    }
}
catch {
    $_.Exception.Message
    throw "[!] Failed to create share!"
}