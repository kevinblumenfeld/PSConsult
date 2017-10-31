<#
    .SYNOPSIS
    Export key attributes for any ADUSer that has data in the proxyaddresses attribute.
    .EXAMPLE
    .\Get-ADGroupDetailed.ps1 | Export-Csv .\ADGroupDetailed.csv -notypeinformation -Encoding UTF8
    
    #>

$properties = @('DisplayName', 'name', 'Title', 'Department', 'Division'
    'Company', 'EmployeeID', 'EmployeeNumber', 'Description', 'GivenName'
    'StreetAddress', 'cn', 'mailnickname', 'samaccountname', 'UserPrincipalName', 'proxyAddresses'
    'Distinguishedname', 'legacyExchangeDN', 'msExchRecipientDisplayType'
    'msExchRecipientTypeDetails', 'msExchRemoteRecipientType', 'targetaddress')

$Selectproperties = @('DisplayName', 'name', 'Title', 'Department', 'Division'
    'Company', 'EmployeeID', 'EmployeeNumber', 'Description', 'GivenName'
    'cn', 'mailnickname', 'samaccountname', 'UserPrincipalName', 'Distinguishedname'
    'legacyExchangeDN', 'msExchRecipientDisplayType', 'msExchRecipientTypeDetails'
    'msExchRemoteRecipientType', 'enabled', 'targetaddress')

$CalculatedProps = @(@{n = "OU" ; e = {$_.Distinguishedname | ForEach-Object {($_ -split '(OU=)', 2)[1, 2] -join ''}}},
    @{n = "PrimarySMTPAddress" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "SMTP:*"}).Substring(5) -join ";" }},
    @{n = "smtp" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "smtp:*"}).Substring(5) -join ";" }},
    @{n = "x500" ; e = {( $_.proxyAddresses | ? {$_ -match "x500:*"}).Substring(0) -join ";" }},
    @{n = "SIP" ; e = {( $_.proxyAddresses | ? {$_ -match "SIP:*"}).Substring(4) -join ";" }})   

Get-ADGroup -Filter * -ResultSetSize $null -Properties $Properties -searchBase (Get-ADDomain).distinguishedname -SearchScope SubTree |
    select ($Selectproperties + $CalculatedProps)
