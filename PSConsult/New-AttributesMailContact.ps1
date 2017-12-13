function New-AttributesMailContact {
    <#

    .SYNOPSIS
    Set attribute for AD Users including proxy addresses. 
    
    .EXAMPLE
    . .\New-AttributesADUser.ps1
    Import-Csv ./test.csv | New-AttributesMailContact 

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
            $hash = @{
                DisplayName                = $user.DisplayName
                initials                   = $user.initials
                sn                         = $user.sn
                Title                      = $user.Title
                Department                 = $user.Department
                Division                   = $user.Division
                Company                    = $user.Company
                EmployeeID                 = $user.EmployeeID
                EmployeeNumber             = $user.EmployeeNumber
                Description                = $user.Description
                GivenName                  = $user.GivenName
                StreetAddress              = $user.StreetAddress
                PostalCode                 = $user.PostalCode
                telephoneNumber            = $user.telephoneNumber
                HomePhone                  = $user.HomePhone
                mobile                     = $user.mobile
                pager                      = $user.pager
                ipphone                    = $user.ipphone
                l                          = $user.l
                st                         = $user.st
                cn                         = $user.cn
                physicalDeliveryOfficeName = $user.physicalDeliveryOfficeName
                mailnickname               = $user.mailnickname
                legacyExchangeDN           = $user.legacyExchangeDN
                mail                       = $user.mail
                msExchRecipientDisplayType = $user.msExchRecipientDisplayType
                msExchRecipientTypeDetails = $user.msExchRecipientTypeDetails
                msExchRemoteRecipientType  = $user.msExchRemoteRecipientType
                targetaddress              = $user.targetaddress
                info                       = $user.info
                
            }
            $params = @{}
            ForEach ($h in $hash.keys) {
                if ($($hash.item($h))) {
                    $params.add($h, $($hash.item($h)))
                }
            }


            # Collect from CSV any SMTP Addresses (for Addition)
            $Proxies = (($User.smtp -split ";") | % {"smtp:" + $_ })
            $Proxies += ("SMTP:" + $($user.primarysmtpaddress))

            # Collect from CSV any x500 Addresses (for Addition)
            $Proxies += ($User.x500 -split ";")

            # Setting AD User
            New-ADObject -Name $user.Name -Type Contact -PassThru | Set-Contact $_.distinguishedname @params -add @{proxyaddresses = $Proxies}
        }
        <#
        # Set Exchange attributes
        if ($user.msExchRecipientDisplayType) {
            Set-ADUser -identity $User.SamAccountName -replace @{msExchRecipientDisplayType = $user.msExchRecipientDisplayType}
        }
        if ($user.msExchRecipientTypeDetails) {
            Set-ADUser -identity $User.SamAccountName -replace @{msExchRecipientTypeDetails = $user.msExchRecipientTypeDetails}
        }
        if ($user.msExchRemoteRecipientType) {
            Set-ADUser -identity $User.SamAccountName -replace @{msExchRemoteRecipientType = $user.msExchRemoteRecipientType}
        }
        if ($user.targetaddress) {
            Set-ADUser -identity $User.SamAccountName -replace @{targetaddress = $user.targetaddress}                
        }
            #>
    }

    End {

    }
}