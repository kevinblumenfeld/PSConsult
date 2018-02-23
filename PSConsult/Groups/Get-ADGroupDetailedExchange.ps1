<#
    .SYNOPSIS
    Export key attributes for any ADGroup that has data in the proxyaddresses attribute.
    Does not contain member export/import yet.
    .EXAMPLE
    .\Get-ADGroupDetailedExchange.ps1 | Export-Csv .\ADGroupDetailedExchange.csv -notypeinformation -Encoding UTF8
    
    #>

$properties = @('Description', 'DisplayName', 'DistinguishedName', 'dLMemSubmitPerms'
    'dLMemSubmitPermsBL', 'GroupScope', 'groupType', 'mail', 'mailNickname', 'ManagedBy'
    'Members', 'msExchBypassAudit', 'msExchGroupDepartRestriction', 'msExchGroupJoinRestriction'
    'msExchMailboxAuditEnable', 'msExchMailboxAuditLogAgeLimit', 'msExchModerationFlags'
    'msExchProvisioningFlags', 'msExchRecipientDisplayType', 'msExchRequireAuthToSendTo'
    'Name', 'proxyAddresses', 'reportToOriginator', 'SamAccountName', 'TargetAddress')

$Selectproperties = @('Description', 'DisplayName', 'GroupScope', 'groupType', 'mail'
    'mailNickname', 'ManagedBy', 'msExchBypassAudit', 'msExchGroupDepartRestriction'
    'msExchGroupJoinRestriction', 'msExchMailboxAuditEnable', 'msExchMailboxAuditLogAgeLimit'
    'msExchModerationFlags', 'msExchProvisioningFlags', 'msExchRecipientDisplayType'
    'msExchRequireAuthToSendTo', 'Name', 'reportToOriginator', 'SamAccountName', 'TargetAddress')


$CalculatedProps = @(@{n = "OU" ; e = {$_.Distinguishedname | ForEach-Object {($_ -split '(OU=)', 2)[1, 2] -join ''}}},
    @{n = "PrimarySMTPAddress" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "SMTP:*"}).Substring(5) -join ";" }},
    @{n = "smtp" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "smtp:*"}).Substring(5) -join ";" }},
    @{n = "x500" ; e = {( $_.proxyAddresses | ? {$_ -match "x500:*"}).Substring(0) -join ";" }},
    @{n = "dLMemSubmitPerms" ; e = {($_.dLMemSubmitPerms | ? {$_ -ne $null}) -join ";" }},
    @{n = "dLMemSubmitPermsBL" ; e = {($_.dLMemSubmitPermsBL | ? {$_ -ne $null}) -join ";" }},
    @{n = "Members" ; e = {($_.Members | ? {$_ -ne $null}) -join ";" }})

Get-ADGroup -Filter 'proxyaddresses -ne "$null"' -Properties $Properties -searchBase (Get-ADDomain).distinguishedname -SearchScope SubTree |
    select ($Selectproperties + $CalculatedProps)
