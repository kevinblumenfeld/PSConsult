<#
    .SYNOPSIS
    Export key attributes for any ADContact that has data in the proxyaddresses attribute.

    .EXAMPLE
    .\Get-ADContactDetailed.ps1 | Export-Csv .\ADContactsDetailed.csv -notypeinformation -Encoding UTF8
    
    #>

$properties = @('CanonicalName', 'Description', 'DisplayName', 'DistinguishedName'
    'givenName', 'legacyExchangeDN', 'mail', 'Name', 'initials', 'sn', 'targetAddress'
    'Title', 'Department', 'Division', 'Company', 'EmployeeID', 'EmployeeNumber'
    'StreetAddress', 'PostalCode', 'telephoneNumber', 'HomePhone', 'mobile', 'pager', 'ipphone'
    'facsimileTelephoneNumber', 'l', 'st', 'cn', 'physicalDeliveryOfficeName', 'co'
    'mailnickname', 'proxyAddresses', 'msExchRecipientDisplayType'
    'msExchRecipientTypeDetails', 'msExchRemoteRecipientType', 'info')

$Selectproperties = @('CanonicalName', 'DisplayName', 'name', 'initials', 'sn', 'Title', 'Department', 'Division'
    'Company', 'EmployeeID', 'EmployeeNumber', 'Description', 'GivenName', 'StreetAddress'
    'PostalCode', 'telephoneNumber', 'HomePhone', 'mobile', 'pager', 'ipphone', 'l', 'st', 'cn'
    'physicalDeliveryOfficeName', 'mailnickname', 'Distinguishedname'
    'legacyExchangeDN', 'mail', 'msExchRecipientDisplayType', 'msExchRecipientTypeDetails'
    'msExchRemoteRecipientType', 'targetaddress', 'info')

$CalculatedProps = @(@{n = "OU" ; e = {$_.Distinguishedname | ForEach-Object {($_ -split '(OU=)', 2)[1, 2] -join ''}}},
    @{n = "PrimarySMTPAddress" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "SMTP:*"}).Substring(5) -join ";" }},
    @{n = "smtp" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "smtp:*"}).Substring(5) -join ";" }},
    @{n = "x500" ; e = {( $_.proxyAddresses | ? {$_ -match "x500:*"}).Substring(0) -join ";" }},
    @{n = "SIP" ; e = {( $_.proxyAddresses | ? {$_ -match "SIP:*"}).Substring(4) -join ";" }})   

Get-ADObject -LDAPFilter "objectClass=Contact" -ResultSetSize $null -Properties $Properties -searchBase (Get-ADDomain).distinguishedname -SearchScope SubTree |
    select ($Selectproperties + $CalculatedProps)

