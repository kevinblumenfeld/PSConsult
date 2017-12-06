function New-ExchangeGroup {
    <#

    .SYNOPSIS
    Set attribute for AD Users including proxy addresses. 
    
    .EXAMPLE
    . .\New-ExchangeGroup.ps1
    Import-Csv ./Groups.csv | New-ExchangeGroup 

    #>
    
    Param 
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        $Users
    )
    Begin {
        Import-Module ActiveDirectory
    }
    Process {
        ForEach ($User in $Users) {
            $hash = @{
                Name               = $User.Identity
                Alias              = $User.Alias
                PrimarySMTPAddress = $User.PrimarySMTPAddress
            }
            $params = @{}
            ForEach ($h in $hash.keys) {
                if ($($hash.item($h))) {
                    $params.add($h, $($hash.item($h)))
                }
            }
            $hashSet = @{
                Identity = $User.Identity

            }
            $paramsSet = @{}
            ForEach ($h in $hashSet.keys) {
                if ($($hashSet.item($h))) {
                    $paramsSet.add($h, $($hashSet.item($h)))
                }
            }

            # Collect from CSV any SMTP Addresses (for Addition)
            $Proxies = ($user.emailaddresses -split " ") -cmatch "^smtp:"
            $Proxies = ($user.emailaddresses -split " ") -match "^x500:"

            write-host "Proxy Addresses being added:  " $Proxies

            # New DG and set AD User
            New-DistributionGroup @params
            if ($Proxies) {
                write-host "ID: " $($User.Identity)
                $filter = "(samaccountname={0})" -f $user.Identity
                Get-ADGroup -LDAPFilter $filter | Set-ADGroup -add @{proxyaddresses = $Proxies}
            }
            
        }
    }

    End {

    }
}