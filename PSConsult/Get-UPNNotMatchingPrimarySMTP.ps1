<#
    .SYNOPSIS
    Export key attributes for any ADUSer that has data in the proxyaddresses attribute.

    .EXAMPLE
    Export key attributes for any ADUSer that has data in the proxyaddresses attribute, where PrimarySMTPAddress does not match UPN.
    If the user does not have a PrimarySMTPAddress no data is given for that user.
    
    #>

$params = @{
    SearchBase    = (Get-ADDomain).DistinguishedName
    ResultSetSize = $null
    Filter        = { proxyAddresses -like '*' }
    Properties    = 'Displayname',
                    'SamAccountName',
                    'UserPrincipalName',
                    'ProxyAddresses',
                    'DistinguishedName'
}
Get-ADUser @params |
    Select-Object DisplayName, SamAccountName, UserPrincipalName,
        @{n="OU"; e={ $_.DistinguishedName -replace 'CN=[^=]+,' }},
        @{n="PrimarySMTP"; e={
            $upn = $_.UserPrincipalName
            ($_.proxyAddresses | Where-Object { $_ -clike 'SMTP:*' } |
                ForEach-Object { $_.Substring(5) } |
                Where-Object { $_ -ne $upn }) -join ', '
        }} |
    Where-Object { $_.PrimarySMTP }
