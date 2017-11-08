<#
    .SYNOPSIS

    .EXAMPLE
   
    
    #>

$properties = @('Description', 'DisplayName', 'dLMemSubmitPerms', 'dLMemSubmitPermsBL'
    'groupType', 'mail', 'mailNickname', 'ManagedBy', 'Members', 'msExchBypassAudit'
    'msExchGroupDepartRestriction', 'msExchGroupJoinRestriction', 'msExchMailboxAuditEnable'
    'msExchMailboxAuditLogAgeLimit', 'msExchModerationFlags', 'msExchPoliciesExcluded'
    'msExchPoliciesIncluded', 'msExchProvisioningFlags', 'msExchRecipientDisplayType'
    'msExchRequireAuthToSendTo', 'proxyAddresses', 'reportToOriginator', 'showInAddressBook'
    'TargetAddress')

$Selectproperties = @('Description', 'DisplayName', 'dLMemSubmitPerms', 'dLMemSubmitPermsBL', 'GroupCategory',
    'GroupScope', 'ManagedBy', 'Members', 'msExchBypassAudit'
    'msExchGroupDepartRestriction', 'msExchGroupJoinRestriction', 'msExchMailboxAuditEnable', 'msExchMailboxAuditLogAgeLimit'
    'msExchModerationFlags', 'msExchPoliciesExcluded', 'msExchPoliciesIncluded', 'msExchProvisioningFlags'
    'msExchRecipientDisplayType', 'msExchRequireAuthToSendTo', 'Name', 'reportToOriginator', 'proxyAddresses'
    'SamAccountName', 'showInAddressBook', 'TargetAddress')

    # 'groupType'
    # 'mail'
    # mailNickname
    ForEach ($Object in $Objects) {
        $hash = @{
            Name              = $Object.Name
            Title             = $Object.Title
            DisplayName       = $Object.DisplayName
            GivenName         = $Object.GivenName
            Surname           = $Object.Surname
            Office            = $Object.Office
            Department        = $Object.Department
            Division          = $Object.Division
            Company           = $Object.Company
            Organization      = $Object.Organization
            EmployeeID        = $Object.EmployeeID
            EmployeeNumber    = $Object.EmployeeNumber
            Description       = $Object.Description
            StreetAddress     = $Object.StreetAddress
            City              = $Object.City
            State             = $Object.State
            PostalCode        = $Object.PostalCode
            Country           = $Object.Country
            POBox             = $Object.POBox
            MobilePhone       = $Object.MobilePhone
            OfficePhone       = $Object.OfficePhone
            HomePhone         = $Object.HomePhone
            Fax               = $Object.Fax
            UserPrincipalName = $Object.UserPrincipalName
        }
        $params = @{}
        ForEach ($h in $hash.keys) {
            if ($($hash.item($h))) {
                $params.add($h, $($hash.item($h)))
            }
        }
    }
    ForEach ($object in $objects) {
        New-ADGroup -Name $_.Name -SamAccountName $_.SamAccountName -GroupScope $_.GroupScope -GroupCategory $_.GroupCategory -Description -DisplayName
        Set-ADGroup 
    }


    select $Selectproperties
