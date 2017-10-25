<#
    .SYNOPSIS
    Export key attributes for any ADUSer that has data in the proxyaddresses attribute.

    .EXAMPLE
    .\Get-ADUserDetailed.ps1 | Export-Csv .\ADUsersDetailed.csv -notypeinformation -Encoding UTF8
    
    #>

$properties = @('DisplayName', 'Title', 'Office', 'Department', 'Division'
    'Company', 'Organization', 'EmployeeID', 'EmployeeNumber', 'Description', 'GivenName'
    'Surname', 'StreetAddress', 'City', 'State', 'PostalCode', 'Country', 'countryCode'
    'POBox', 'MobilePhone', 'OfficePhone', 'HomePhone', 'Fax', 'cn'
    'mailnickname', 'samaccountname', 'UserPrincipalName', 'proxyAddresses'
    'Distinguishedname', 'legacyExchangeDN', 'EmailAddress', 'msExchRecipientDisplayType'
    'msExchRecipientTypeDetails', 'msExchRemoteRecipientType', 'targetaddress')

$Selectproperties = @('DisplayName', 'Title', 'Office', 'Department', 'Division'
    'Company', 'Organization', 'EmployeeID', 'EmployeeNumber', 'Description', 'GivenName'
    'Surname', 'StreetAddress', 'City', 'State', 'PostalCode', 'Country', 'countryCode'
    'POBox', 'MobilePhone', 'OfficePhone', 'HomePhone', 'Fax', 'cn'
    'mailnickname', 'samaccountname', 'UserPrincipalName', 'Distinguishedname'
    'legacyExchangeDN', 'EmailAddress', 'msExchRecipientDisplayType'
    'msExchRecipientTypeDetails', 'msExchRemoteRecipientType', 'targetaddress')

$CalculatedProps = @(@{n = "OU" ; e = {$_.Distinguishedname | ForEach-Object {($_ -split '(OU=)', 2)[1, 2] -join ''}}},
    @{n = "PrimarySMTPAddress" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "SMTP:*"}).Substring(5) -join ";" }},
    @{n = "smtp" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "smtp:*"}).Substring(5) -join ";" }},
    @{n = "x500" ; e = {( $_.proxyAddresses | ? {$_ -match "x500:*"}).Substring(0) -join ";" }},
    @{n = "SIP" ; e = {( $_.proxyAddresses | ? {$_ -match "SIP:*"}).Substring(4) -join ";" }})   

Get-ADUser -Filter 'proxyaddresses -ne "$null"' -ResultSetSize $null -Properties $Properties -searchBase (Get-ADDomain).distinguishedname -SearchScope SubTree |
    select ($Selectproperties + $CalculatedProps)

