function Add-PrimaryProxyAddressDG {
    <#

    .SYNOPSIS
    Add member(s) to a group(s) from a CSV that look like this
    DisplayName, PrimarySMTPAddress
    Group01, Joe@contoso.com
    Group01, Sally@contoso.com
    Group02, Fred@contoso.com
    Group03, Joe@contoso.com

    .EXAMPLE
    . .\Add-PrimaryProxyAddressDG.ps1
    Import-Csv .\Users.csv | Add-PrimaryProxyAddressDG -Path "OU=Users,OU=Mail,OU=Internal,OU=contoso-Users,DC=contoso,DC=com"

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
        [Parameter(Mandatory = $true)]
        $Path
    )
    Begin {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    }
    Process {
        $Proxies = $null
        $Proxies += ("SMTP:" + $($primarySMTPAddress))
        Write-Host "Display   : `t" $DisplayName
        write-Host "Primary   : `t" $primarySMTPAddress
        # write-Host "Secondary : `t" $SecondarySMTPAddress
        Try {
            Get-ADObject -LDAPFILTER "(mail=$primarySMTPAddress)" -SearchBase $Path | Set-ADGroup -Add @{proxyaddresses = $Proxies} -erroraction Stop
            ($DisplayName + "," + $primarySMTPAddress) | Out-File -FilePath ".\GroupPrimarySUCCESS.csv" -append
        }
        Catch {
            $Error[0]
            ($DisplayName + "," + $primarySMTPAddress) | Out-File -FilePath ".\GroupPrimaryFAIL.csv" -append
        }
    }
    End {

    }
}