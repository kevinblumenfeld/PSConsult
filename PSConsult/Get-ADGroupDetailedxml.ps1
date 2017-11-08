<#
    .SYNOPSIS
    Export key attributes for any ADGroup that has data in the proxyaddresses attribute.
    Does not contain member export/import yet.
    .EXAMPLE
    .\Get-ADGroupDetailed.ps1 | Export-Csv .\ADGroupDetailed.csv -notypeinformation -Encoding UTF8
    
    #>

$properties = @('Description', 'DisplayName', 'dLMemSubmitPerms', 'dLMemSubmitPermsBL'
    'groupType', 'mail', 'mailNickname', 'ManagedBy', 'Members', 'msExchBypassAudit'
    'msExchGroupDepartRestriction', 'msExchGroupJoinRestriction', 'msExchMailboxAuditEnable'
    'msExchMailboxAuditLogAgeLimit', 'msExchModerationFlags', 'msExchPoliciesExcluded'
    'msExchPoliciesIncluded', 'msExchProvisioningFlags', 'msExchRecipientDisplayType'
    'msExchRequireAuthToSendTo', 'proxyAddresses', 'reportToOriginator', 'showInAddressBook'
    'TargetAddress')

$Selectproperties = @('Description', 'DisplayName', 'dLMemSubmitPerms', 'dLMemSubmitPermsBL', 'GroupCategory',
    'GroupScope', 'groupType', 'mail', 'mailNickname', 'ManagedBy', 'Members', 'msExchBypassAudit'
    'msExchGroupDepartRestriction', 'msExchGroupJoinRestriction', 'msExchMailboxAuditEnable', 'msExchMailboxAuditLogAgeLimit'
    'msExchModerationFlags', 'msExchPoliciesExcluded', 'msExchPoliciesIncluded', 'msExchProvisioningFlags'
    'msExchRecipientDisplayType', 'msExchRequireAuthToSendTo', 'Name', 'reportToOriginator', 'proxyAddresses'
    'SamAccountName', 'showInAddressBook', 'TargetAddress')


Get-ADGroup -Filter 'proxyaddresses -ne "$null" -and GroupCategory -eq "Distribution"' -Properties $Properties -searchBase (Get-ADDomain).distinguishedname -SearchScope SubTree |
    select $Selectproperties
