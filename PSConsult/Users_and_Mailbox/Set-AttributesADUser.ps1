function Set-AttributesADUser {
    <#

    .SYNOPSIS
    Set attribute for AD Users including proxy addresses.  An example is when a company acquires a firm that is already syncing with ADConnect.
    The acquiring company will create a greenfield domain and will want to stand up AD Connect to sync to the same tenant.
    The acquiring company may have already created (with an AD Migration) all the users in the new domain.
    This will repopulate all the details from the source domain into the target domain.  Thus AD Connect can be reestablished.  
    
    .EXAMPLE
    . .\Set-AttributesADUser.ps1
    Import-Csv ./fromSourceDomain.csv | Set-AttributesADUser 

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
            $Proxies += ($User.x500 -split ";")

            # Collect from CSV any SIP Addresses (for Addition)


            # Removing any existing Primary SMTP: Address(es) from the Target ADUser (to make way for 1 new Primary SMTP Address)
            if ($primary) {
                Set-ADUser -identity $User.SamAccountNameTarget -remove @{proxyaddresses = (($Primary -split ";") | % {"SMTP:" + $_ })}
            }

            # Setting AD User
            Set-ADUser @params -add @{proxyaddresses = $Proxies}
            
            # Set Exchange attributes
            if ($user.msExchRecipientDisplayType) {
                Set-ADUser -identity $User.SamAccountNameTarget -replace @{msExchRecipientDisplayType = $user.msExchRecipientDisplayType}
            }
            if ($user.msExchRecipientTypeDetails) {
                Set-ADUser -identity $User.SamAccountNameTarget -replace @{msExchRecipientTypeDetails = $user.msExchRecipientTypeDetails}
            }
            if ($user.msExchRemoteRecipientType) {
                Set-ADUser -identity $User.SamAccountNameTarget -replace @{msExchRemoteRecipientType = $user.msExchRemoteRecipientType}
            }
            if ($user.targetaddress) {
                Set-ADUser -identity $User.SamAccountNameTarget -replace @{targetaddress = $user.targetaddress}                
            }
            
        }
    }

    End {

    }
}