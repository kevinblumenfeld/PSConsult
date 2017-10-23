function Set-AttributesADUser {
    <#

    .SYNOPSIS
    Set attribute for AD Users including proxy addresses. 
    
    .EXAMPLE 
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
            $params = @{
                Title              =	$User.Title
                Office             =	$User.Office
                Department         =	$User.Department
                Division           =	$User.Division
                Company            =	$User.Company
                Organization       =	$User.Organization
                EmployeeID         =	$User.EmployeeID
                EmployeeNumber     =	$User.EmployeeNumber
                Description        =	$User.Description
                StreetAddress      =	$User.StreetAddress
                City               =	$User.City
                State              =	$User.State
                PostalCode         =	$User.PostalCode
                Country            =	$User.Country
                POBox              =	$User.POBox
                MobilePhone        =	$User.MobilePhone
                OfficePhone        =	$User.OfficePhone
                HomePhone          =	$User.HomePhone
                Fax                =	$User.Fax
                UserPrincipalName  =	$User.UserPrincipalName
                
            }
            $Primary = (Get-ADUser -Filter "samaccountname -eq '$($user.samaccountnameTarget)'" -searchBase (Get-ADDomain).distinguishedname -SearchScope SubTree -properties proxyaddresses | Select @{n = "PrimarySMTP" ; e = {( $_.proxyAddresses | ? {$_ -cmatch "SMTP:"}).Substring(5) -join ";" }}).PrimarySMTP
            $Proxies = (($User.smtp -split ";") | % {"smtp:" + $_ })
            $Proxies += ("SMTP:" + $($user.primarysmtpaddress))
            if ($primary) {
                Set-ADUser -identity $User.SamAccountNameTarget -remove @{proxyaddresses = (($Primary -split ";") | % {"SMTP:" + $_ })}
            }
            Set-ADUser -identity $User.SamAccountNameTarget -add @{proxyaddresses = $Proxies} @params
        }
    }

    End {

    }
}