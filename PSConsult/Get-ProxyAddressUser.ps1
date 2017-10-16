Get-ADUser -Filter 'proxyaddresses -ne "$null"' -ResultSetSize $null -Properties DisplayName, samaccountname, UserPrincipalName, proxyAddresses, Distinguishedname -searchBase "DC=CONTOSO,DC=local" |
    select DisplayName, samaccountname, UserPrincipalName,
@{n = "OU" ; e = {$_.Distinguishedname | ForEach-Object {($_ -split '(OU=)',2)[1,2] -join ''}}},
@{n = "PrimarySMTPAddress" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "SMTP:*"}).Substring(5) -join ";" }},
@{n = "smtp" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "smtp:*"}).Substring(5) -join ";" }},
@{n = "x500" ; e = {( $_.proxyAddresses | ? {$_ -match "x500:*"}).Substring(0) -join ";" }},
@{n = "SIP" ; e = {( $_.proxyAddresses | ? {$_ -match "SIP:*"}).Substring(4) -join ";" }} |
    Export-Csv ADUsers.csv -NTI  
