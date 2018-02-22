function Set-ADAttributes {
    <#

    .SYNOPSIS
    Set attribute for AD Users including proxy addresses. 
    
    .EXAMPLE
    . .\Set-ADAttributes.ps1
    Import-Csv ./test.csv | Set-ADAttributes

    #>
    Param 
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        $Users
    )
    Begin {

    }
    Process {
        ForEach ($User in $Users) {
            # Set AD attributes
            Set-ADGroup -identity $User -replace @{
                msExchBypassAudit             = $False
                msExchGroupDepartRestriction  = "1"
                msExchGroupJoinRestriction    = "1"
                msExchMailboxAuditEnable      = $False
                msExchMailboxAuditLogAgeLimit = "7776000"
                msExchModerationFlags         = "6"
                msExchProvisioningFlags       = "0"
                msExchRecipientDisplayType    = "1"
		
            }
        }
    }
    End {

    }
}