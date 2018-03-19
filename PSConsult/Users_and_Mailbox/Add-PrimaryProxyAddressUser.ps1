function Add-PrimaryProxyAddressUser {
    <#

    .SYNOPSIS
    Add member(s) to a group(s) from a CSV that look like this
    DisplayName, PrimarySMTPAddress
    Group01, Joe@contoso.com
    Group01, Sally@contoso.com
    Group02, Fred@contoso.com
    Group03, Joe@contoso.com

    .EXAMPLE
    . .\Add-PrimaryProxyAddressUser.ps1
    Import-Csv .\Users.csv | Add-PrimaryProxyAddressUser -Path "OU=Users,OU=Mail,OU=Internal,OU=contoso-Users,DC=contoso,DC=com"

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
        Try {
            import-module activedirectory -ErrorAction Stop
        }
        Catch {
            Write-Host "This module depends on the ActiveDirectory module."
            Write-Host "Please download and install from https://www.microsoft.com/en-us/download/details.aspx?id=45520"
            throw
        }
    }
    Process {
        $Proxies = $null
        $Proxies += ("SMTP:" + $($primarySMTPAddress))
        Write-Host "Display   : `t" $DisplayName
        write-Host "Primary   : `t" $primarySMTPAddress

        Try {
            Get-ADObject -LDAPFILTER "(mail=$primarySMTPAddress)" -SearchBase $Path | Set-ADUser -Add @{proxyaddresses = $Proxies} -erroraction Stop
            ($DisplayName + "," + $primarySMTPAddress) | Out-File -FilePath ".\UserPrimarySUCCESS.csv" -append
        }
        Catch {
            $Error[0]
            ($DisplayName + "," + $primarySMTPAddress) | Out-File -FilePath ".\UserPrimaryFAIL.csv" -append
        }
    }
    End {

    }
}