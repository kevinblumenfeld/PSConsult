function Clear-ADAttribute {
    <#
.SYNOPSIS
Clear certain AD Attributes (Use with caution)

.DESCRIPTION
Clear certain AD Attributes (Use with caution)

.PARAMETER users
Users to be passed in a CSV

.EXAMPLE
Import-CSV c:\scripts\ADUsers.csv | Clear-ADAttribute

.NOTES
Be careful as this only has a specific need and should not be run in production hybrid Office 365 environments
#>
    Param 
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        $users
    )
    Begin {
        $Params = @(
            'homeMDB', 'homeMTA', 'legacyExchangeDN', 'msExchADCGlobalNames', 'msExchALObjectVersion'
            'msExchHideFromAddressLists', 'msExchHomeServerName', 'msExchMailboxGuid', 'msExchMailboxSecurityDescriptor'
            'msExchMobileMailboxFlags', 'msExchPoliciesExcluded', 'msExchRecipientDisplayType', 'msExchRecipientTypeDetails'
            'msExchUserAccountControl', 'msExchUserCulture', 'msExchVersion', 'mailNickname'
        )
    }
    Process {
        Foreach ($user in $users) {
            $filter = 'DisplayName -eq "{0}"' -f $user.DisplayName 
            Get-ADUser -Filter $filter -Properties $Params |
                ForEach-Object {
                $Guid = $_.ObjectGuid
                Foreach ($Param in $Params) {
                    Set-ADUser -identity $Guid -Clear $Param   
                }
    
            }
        }
    }

    End {

    }
}