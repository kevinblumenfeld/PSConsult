<#
    .SYNOPSIS
    Export key attributes for any ADUSer that has data in the proxyaddresses attribute.

    .EXAMPLE
    .\Get-ProxyAddressUser.ps1 | Export-Csv .\ADUsers.csv -notypeinformation
    
    #>

    $properties = @('DisplayName', 'samaccountname'
    'UserPrincipalName', 'proxyAddresses'
    'Distinguishedname', 'legacyExchangeDN')
Get-ADUser -Filter 'proxyaddresses -ne "$null"' -ResultSetSize $null -Properties $Properties -searchBase (Get-ADDomain).distinguishedname -SearchScope SubTree |
    select DisplayName, samaccountname, UserPrincipalName, legacyExchangeDN,
@{n = "OU" ; e = {$_.Distinguishedname | ForEach-Object {($_ -split '(OU=)',2)[1,2] -join ''}}},
@{n = "PrimarySMTPAddress" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "SMTP:*"}).Substring(5) -join ";" }},
@{n = "smtp" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "smtp:*"}).Substring(5) -join ";" }},
@{n = "x500" ; e = {( $_.proxyAddresses | ? {$_ -match "x500:*"}).Substring(0) -join ";" }},
@{n = "SIP" ; e = {( $_.proxyAddresses | ? {$_ -match "SIP:*"}).Substring(4) -join ";" }}
