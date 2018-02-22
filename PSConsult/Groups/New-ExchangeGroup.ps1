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
        $Groups
    )
    Begin {
        Import-Module ActiveDirectory
    }
    Process {
        ForEach ($Group in $Groups) {
            $hashNew = @{
                Name               = $Group.Name
                DisplayName        = $Group.DisplayName                
                SamAccountName     = $Group.SamAccountName                                
                Alias              = $Group.mailnickname
                PrimarySMTPAddress = $Group.PrimarySMTPAddress
            }
            $params = @{}
            ForEach ($h in $hashNew.keys) {
                if ($($hashNew.item($h))) {
                    $params.add($h, $($hashNew.item($h)))
                }
            }
            $hashSet = @{
                Description = $Group.Description
            }
            $paramsSet = @{}
            ForEach ($h in $hashSet.keys) {
                if ($($hashSet.item($h))) {
                    $paramsSet.add($h, $($hashSet.item($h)))
                }
            }
            # Collect from CSV any SMTP Addresses (for Addition)
            $Proxies = (($Group.smtp -split ";") | % {"smtp:" + $_ })
            $Proxies += ($Group.x500 -split ";") -match "^x500:"

            write-host "Proxy Addresses being added:  " $Proxies

            # New DG and set AD User
            New-DistributionGroup @params
            if ($Proxies) {
                write-host "ID: " $($Group.samaccountname)
                $filter = "(samaccountname={0})" -f $Group.samaccountname
                Get-ADGroup -LDAPFilter $filter | Set-ADGroup @paramsSet -add @{proxyaddresses = $Proxies}
            }
            
        }
    }

    End {

    }
}