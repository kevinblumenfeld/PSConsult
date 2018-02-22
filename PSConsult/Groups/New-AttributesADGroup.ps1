function New-AttributesADGroup {
    <#

    .SYNOPSIS
    Set attribute for AD Users including proxy addresses. 
    
    .EXAMPLE
    . .\New-AttributesADGroup.ps1
    Import-Csv ./test.csv | New-AttributesADGroup -Path "OU=DistributionGroups,OU=Mail,OU=Internal,OU=Contoso-Users,DC=contoso,DC=com"

    #>
    Param 
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        $Users,
        [Parameter()]
        $Path
    )
    Begin {

    }
    Process {
        $Proxies = $null
        $adds = $null
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
                UserPrincipalName = $User.UserPrincipalName
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
            $adds = @{mail = $user.primarysmtpaddress; proxyaddresses = $Proxies}
            
            # Setting AD Group
            $Display = $User.DisplayName
            $i = $null
            $SamAcct = ((($User.primarysmtpaddress) -split '@')[0])[0..18] -join ''
            $Sam = $SamAcct
            $i = 2
            While (Get-ADObject -LDAPFilter "(SamAccountName=$Sam)") {
                $Sam = ($SamAcct + $i)
                $i++
            }
            if (! $i) {
                $Sam = $SamAcct
            } 
            write-host "Display :  " $Display
            write-host "SAM     :  " $SAM
            New-ADGroup @params -SamAccountName $Sam -GroupScope Universal -GroupCategory Distribution -Path $Path
            # New-ADUser @params -AccountPassword (ConvertTo-SecureString "PleaseReplace123!" -AsPlainText -Force) -Enabled:([System.Convert]::ToBoolean($user.enabled))
            write-host "AFTER   :  " $Display

            Get-ADGroup -LDAPFilter "(displayname=$Display)" -SearchBase $path | Set-ADGroup -add $adds
    
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