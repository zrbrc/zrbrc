# Define username and password
$smtpUserName = 'AKIASJ4WVO66KUWUNGCW'
$smtpPassword = ConvertTo-SecureString 'BBiuZOODJufcDVfzZ6UEmoFxES0w0DGBDhj0wanYcYqK' -AsPlainText -Force

[pscredential]$credential = New-Object System.Management.Automation.PSCredential ($smtpUserName, $smtpPassword)

$splat = @{
    useSSL     = $true
    smtpServer = 'email-smtp.us-east-1.amazonaws.com'
    port       = 587
    from       = 'mailbot@zerbe.io'
    to         = 'ryan@zerbe.io'
    subject    = 'Email via Amazon SES SMTP Endpoint'
    body       = 'Email via Amazon SES SMTP Endpoint'
}
Send-MailMessage -Credential $credential @splat
