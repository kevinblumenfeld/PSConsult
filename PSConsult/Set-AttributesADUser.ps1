function Set-AttributesADUser {
    <#

    .SYNOPSIS
    Set attribute for AD Users including proxy addresses. 
    
    .EXAMPLE
    . .\Set-AttributesADUser.ps1
    Import-Csv ./test.csv | Set-AttributesADUser 

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
                identity          = $User.SamAccountNameTarget
                Title             = $User.Title
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
                UserPrincipalName = $User.UserPrincipalName
            }
            $params = @{}
            ForEach ($h in $hash.keys) {
                if ($($hash.item($h))) {
                    $params.add($h, $($hash.item($h)))
                }
            }

            # Collect Existing Primary SMTP Addresses (for Removal)
            $Primary = (Get-ADUser -Filter "samaccountname -eq '$($user.samaccountnameTarget)'" -searchBase (Get-ADDomain).distinguishedname -SearchScope SubTree -properties proxyaddresses | Select @{n = "PrimarySMTP" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "SMTP:"}).Substring(5) -join ";" }}).PrimarySMTP

            # Collect from CSV any SMTP Addresses (for Addition)
            $Proxies = (($User.smtp -split ";") | % {"smtp:" + $_ })
            $Proxies += ("SMTP:" + $($user.primarysmtpaddress))

            # Collect from CSV any x500 Addresses (for Addition)
            # Remove ForEach after testing
            $Proxies = (($User.x500 -split ";") | % {$_})

            # Collect from CSV any SIP Addresses (for Addition)


            # Removing any existing Primary SMTP: Addresses for the Target ADUser (to make way for 1 new Primary SMTP Address)
            if ($primary) {
                Set-ADUser -identity $User.SamAccountNameTarget -remove @{proxyaddresses = (($Primary -split ";") | % {"SMTP:" + $_ })}
            }

            # Setting AD User
            Set-ADUser @params -add @{proxyaddresses = $Proxies} 
        }
    }

    End {

    }
}