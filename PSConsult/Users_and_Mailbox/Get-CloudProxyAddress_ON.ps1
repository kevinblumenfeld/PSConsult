Get-mailbox -ResultSize Unlimited |
    select UserPrincipalName,DisplayName, samaccountname, Alias, PrimarySmtpAddress,
@{n = "smtp" ; e = {( $_.EmailAddresses | ? {$_ -cmatch "smtp:*"}).Substring(5) -join ";" }},
@{n = "SIP" ; e = {( $_.EmailAddresses | ? {$_ -like "SIP:*"}).Substring(4) -join ";" }},
@{n = "ON" ; e = {( $_.EmailAddresses | ? {$_ -like "*mail.onmicrosoft*"}).Substring(5) -join ";" }},
@{n = "x500" ; e = {( $_.EmailAddresses | ? {$_ -like "X500:*"}).Substring(0) -join ";" }} |
    Export-Csv 365_ON_mailboxes.csv -NTI -Encoding UTF8
