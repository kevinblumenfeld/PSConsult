function Add-SecondaryProxyAddressUser {
    <#

    .SYNOPSIS
    Add member(s) to a group(s) from a CSV that look like this

    DisplayName, PrimarySMTPAddress, SecondarySMTPAddress
    Joe, Joe@contoso.com, Joe2@contoso.com
    Sally, Sally@contoso.com, Sally2@contoso.com
    Fred, Fred@contoso.com, Fred3@contoso.com
    Joel, Joel@contoso.com, Joel2@contoso.com

    .EXAMPLE
    . .\Add-SecondaryProxyAddressUser.ps1
    Import-Csv .\Users.csv | Add-SecondaryProxyAddressUser -Path "OU=Users,OU=Mail,OU=Internal,OU=contoso-Users,DC=contoso,DC=com"

    #>
    [CmdletBinding()]
    Param 
    (
        [Parameter(Mandatory = $false, ValueFromPipelinebyPropertyName = $true)]
        $primarySMTPAddress,
        [Parameter(Mandatory = $false, ValueFromPipelinebyPropertyName = $true)]
        $SecondarySMTPAddress,
        [Parameter(Mandatory = $false, ValueFromPipelinebyPropertyName = $true)]
        $DisplayName,
        [Parameter(Mandatory = $true)]
        $Path
    )
    Begin {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    }
    Process {
        $Proxies = $null
        $Proxies = ("smtp:" + $($SecondarySMTPAddress))
        Write-Host "Display   : `t" $DisplayName
        write-Host "Primary   : `t" $primarySMTPAddress
        write-Host "Secondary : `t" $SecondarySMTPAddress
        Try {
            Get-ADObject -LDAPFILTER "(mail=$primarySMTPAddress)" -SearchBase $Path | Set-ADUser -Add @{proxyaddresses = $Proxies} -erroraction Stop
            ($DisplayName + "," + $primarySMTPAddress + "," + $SecondarySMTPAddress + "," + $Proxies) | Out-File -FilePath ".\UserSecondarySUCCESS.csv" -append
        }
        Catch {
            $Error[0]
            ($DisplayName + "," + $primarySMTPAddress + "," + $SecondarySMTPAddress + "," + $Proxies) | Out-File -FilePath ".\UserSecondaryFAIL.csv" -append
        }
    }
    End {

    }
}