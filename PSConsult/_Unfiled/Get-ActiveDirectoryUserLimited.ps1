function Get-ActiveDirectoryUserLimited { 
    <#
    .SYNOPSIS
    Export Active Directory Users
    
    .DESCRIPTION
    Export Active Directory Users
    
    .PARAMETER ADUserFilter
    Provide specific AD Users to report on.  Otherwise, all AD Users will be reported.  Please review the examples provided.
    
    .EXAMPLE
    Get-ActiveDirectoryUser | Export-Csv c:\scripts\ADUsers.csv -notypeinformation -encoding UTF8
    
    .EXAMPLE
    Get-ActiveDirectoryUser | Export-Csv c:\scripts\ADUsers.csv -notypeinformation -encoding UTF8
    
    .EXAMPLE
    '{proxyaddresses -like "*contoso.com"}' | Get-ActiveDirectoryUser | Export-Csv c:\scripts\ADUsers.csv -notypeinformation -encoding UTF8
    
    .EXAMPLE
    '{proxyaddresses -like "*contoso.com"}' | Get-ActiveDirectoryUser | Export-Csv c:\scripts\ADUsers.csv -notypeinformation -encoding UTF8
    
    .EXAMPLE
    '{proxyaddresses -like "*contoso.com"}' | Get-ActiveDirectoryUser | Export-Csv c:\scripts\ADUsers_Detailed.csv -notypeinformation -encoding UTF8
    
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, Mandatory = $false)]
        [string[]] $ADUserFilter
    )
    Begin {
        $Selectproperties = @(
            'DisplayName', 'UserPrincipalName', 'Name', 'GivenName', 'Surname'
        )

        $CalculatedProps = @(
            @{n = "OU" ; e = {$_.DistinguishedName -replace '^.+?,(?=(OU|CN)=)'}}
        )
    }
    Process {
        if ($ADUserFilter) {
            foreach ($CurADUserFilter in $ADUserFilter) {
                Get-ADUser -Filter $CurADUserFilter -Properties * -ResultSetSize $null | Select-Object ($Selectproperties + $CalculatedProps)
            }
        }
        else {
            Get-ADUser -Filter * -Properties $Props -ResultSetSize $null | Select-Object ($Selectproperties + $CalculatedProps)
        }
    }
    End {
        
    }
}