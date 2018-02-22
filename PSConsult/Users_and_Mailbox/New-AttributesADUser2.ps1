function New-AttributesADUser2 {
    <#

    .SYNOPSIS
    Set attribute for AD Users including proxy addresses. 
    
    .EXAMPLE
    . .\New-AttributesADUser.ps1
    Import-Csv ./test.csv | New-AttributesADUser 

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
                Name              = $User.DisplayName
                Title             = $User.Title
                DisplayName       = $User.DisplayName
                GivenName         = $User.GivenName
                Surname           = $User.Surname
                Office            = $User.Office
                Department        = $User.Department
                Division          = $User.Division
                Company           = $User.Company
                Organization      = $User.Organization
                EmployeeID        = $User.EmployeeID
                EmployeeNumber    = $User.EmployeeNumber
                Description       = $User.Description
                StreetAddress     = $User.StreetAddress
                City              = $User.City
                State             = $User.State
                PostalCode        = $User.PostalCode
                Country           = $User.Country
                POBox             = $User.POBox
                MobilePhone       = $User.MobilePhone
                OfficePhone       = $User.OfficePhone
                HomePhone         = $User.HomePhone
                Fax               = $User.Fax
                UserPrincipalName = $User.primarysmtpaddress
                EmailAddress      = $User.primarysmtpaddress
            }
            $params = @{}
            ForEach ($h in $hash.keys) {
                if ($($hash.item($h))) {
                    $params.add($h, $($hash.item($h)))
                }
            }

            # Collect from CSV any SMTP Addresses (for Addition)
            # $Proxies = (($User.smtp -split ";") | % {"smtp:" + $_ })
            $Proxies += ("SMTP:" + $($user.primarysmtpaddress))

            # Collect from CSV any x500 Addresses (for Addition)
            # $Proxies += ($User.x500 -split ";")

            # Collect from CSV any SIP Addresses (for Addition)

            $SamAccountName = (($User.primarysmtpaddress) -split "@")[0]
            # Setting AD User
            New-ADUser @params -SamAccountName $SamAccountName -AccountPassword (ConvertTo-SecureString "PleaseReplace123!" -AsPlainText -Force) -Enabled:$False -Path "OU=SharedMailboxes,OU=Mail,OU=Internal,OU=NRCUS-Users,DC=nrch,DC=us"
            Set-ADUser -identity $SamAccountName -add @{proxyaddresses = $Proxies}
    
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
            
        }
    }

    End {

    }
}