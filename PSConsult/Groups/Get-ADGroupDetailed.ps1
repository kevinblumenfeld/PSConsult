<#
    .SYNOPSIS
    Export key attributes for any ADGroup that has data in the proxyaddresses attribute.
    Does not contain member export/import yet.
    .EXAMPLE
    .\Get-ADGroupDetailed.ps1 | Export-Csv .\ADGroupDetailed.csv -notypeinformation -Encoding UTF8
    
    #>

$properties = @('Description', 'DisplayName', 'DistinguishedName'
    'GroupScope', 'groupType', 'mail', 'ManagedBy'
    'Members', 'Name', 'proxyAddresses', 'SamAccountName')

$Selectproperties = @('Description', 'DisplayName', 'GroupScope', 'groupType', 'mail'
    'ManagedBy', 'Name', 'SamAccountName')


$CalculatedProps = @(@{n = "OU" ; e = {$_.Distinguishedname | ForEach-Object {($_ -split '(OU=)', 2)[1, 2] -join ''}}},
    @{n = "PrimarySMTPAddress" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "SMTP:*"}).Substring(5) -join ";" }},
    @{n = "smtp" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "smtp:*"}).Substring(5) -join ";" }},
    @{n = "x500" ; e = {( $_.proxyAddresses | ? {$_ -match "x500:*"}).Substring(0) -join ";" }},
    @{n = "Members" ; e = {($_.Members | ? {$_ -ne $null}) -join ";" }})

Get-ADGroup -Filter 'proxyaddresses -ne "$null"' -Properties $Properties -searchBase (Get-ADDomain).distinguishedname -SearchScope SubTree |
    select ($Selectproperties + $CalculatedProps)
