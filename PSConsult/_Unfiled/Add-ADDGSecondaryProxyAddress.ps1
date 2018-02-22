function Add-ADDGSecondaryProxyAddress {
    <#

    .SYNOPSIS
    Add member(s) to a group(s) from a CSV that look like this
    DisplayName, PrimarySMTPAddress
    Group01, Joe@contoso.com
    Group01, Sally@contoso.com
    Group02, Fred@contoso.com
    Group03, Joe@contoso.com

    .EXAMPLE
    . .\Add-ADDGSecondaryProxyAddress
    Import-Csv .\Users.csv | Add-ADDGSecondaryProxyAddress -Path "OU=Users,OU=Mail,OU=Internal,OU=contoso-Users,DC=contoso,DC=com"

    #>
    [CmdletBinding()]
    Param 
    (
        [Parameter(Mandatory = $false,
            ValueFromPipelinebyPropertyName = $true)]
        $primarySMTPAddress,
        [Parameter(Mandatory = $false,
            ValueFromPipelinebyPropertyName = $true)]
        $SecondarySMTPAddress,
        [Parameter(Mandatory = $false,
            ValueFromPipelinebyPropertyName = $true)]
        $DisplayName,
        [Parameter()]
        $Path
    )
    Begin {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    }
    Process {
        $Proxies = $null
        $Proxies += ("smtp:" + $($SecondarySMTPAddress))
        Write-Host "Display   : `t" $DisplayName
        write-Host "Primary   : `t" $primarySMTPAddress
        write-Host "Secondary : `t" $SecondarySMTPAddress
        Try {
            Get-ADObject -LDAPFILTER "(mail=$primarySMTPAddress)" -SearchBase $Path | Set-ADGroup -Add @{proxyaddresses = $Proxies} -erroraction Stop
            ($DisplayName + "," + $primarySMTPAddress + "," + $SecondarySMTPAddress) | Out-File -FilePath ".\UserSecondarySUCCESS.csv" -append
        }
        Catch {
            $Error[0]
            ($DisplayName + "," + $primarySMTPAddress + "," + $SecondarySMTPAddress) | Out-File -FilePath ".\UserSecondaryCatch.csv" -append
        }
    }
    End {

    }
}