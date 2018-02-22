Get-mailbox -ResultSize Unlimited |
    select UserPrincipalName,DisplayName, samaccountname, Alias, PrimarySmtpAddress,
@{n = "smtp" ; e = {( $_.EmailAddresses | ? {$_ -cmatch "smtp:*"}).Substring(5) -join ";" }},
@{n = "SIP" ; e = {( $_.EmailAddresses | ? {$_ -like "SIP:*"}).Substring(4) -join ";" }},
@{n = "ONmicrosoft" ; e = {( $_.EmailAddresses | ? {$_ -like "*contoso.mail.onmicrosoft.com"}).Substring(5) -join ";" }} |
    Export-Csv .\365UPNmailboxes_FEB_17_2018.csv -NTI -Encoding UTF8
