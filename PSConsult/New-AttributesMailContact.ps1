function New-AttributesMailContact {
    <#

    .SYNOPSIS
    Set attribute for AD Users including proxy addresses. 
    
    .EXAMPLE
    . .\New-AttributesMailContact.ps1
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
                LastName                   = $user.sn
                Title                      = $user.Title
                Department                 = $user.Department
                Division                   = $user.Division
                Company                    = $user.Company
                EmployeeID                 = $user.EmployeeID
                EmployeeNumber             = $user.EmployeeNumber
                Description                = $user.Description
                FirstName                  = $user.GivenName
                StreetAddress              = $user.StreetAddress
                PostalCode                 = $user.PostalCode
                telephoneNumber            = $user.telephoneNumber
                HomePhone                  = $user.HomePhone
                mobilePhone                = $user.mobile
                pager                      = $user.pager
                ipphone                    = $user.ipphone
                city                       = $user.l
                StateOrProvince            = $user.st
                physicalDeliveryOfficeName = $user.physicalDeliveryOfficeName
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
            $Proxies += ("SMTP:" + $user.primarysmtpaddress)

            # Collect from CSV any x500 Addresses (for Addition)
            $Proxies += ($User.x500 -split ";")

            # Setting AD User
            $Contact = New-ADObject -Name $user.Name -Type Contact -PassThru
            # Set Exchange attributes
            if ($user.msExchRecipientDisplayType) {
                Set-ADObject -identity $Contact.distinguishedname -replace @{msExchRecipientDisplayType = $user.msExchRecipientDisplayType}
            }
            if ($user.msExchRecipientTypeDetails) {
                Set-ADObject -identity $Contact.distinguishedname -replace @{msExchRecipientTypeDetails = $user.msExchRecipientTypeDetails}
            }
            if ($user.msExchRemoteRecipientType) {
                Set-ADObject -identity $Contact.distinguishedname -replace @{msExchRemoteRecipientType = $user.msExchRemoteRecipientType}
            }

            Enable-MailContact $Contact.distinguishedname -externalemailaddress ("SMTP:" + $user.primarysmtpaddress)
            Set-Contact $Contact.distinguishedname @params
            Set-MailContact $Contact.distinguishedname -emailaddresses $proxies
        }

    }

    End {

    }
}