$params = @{
    SearchBase = (Get-ADDomain).DistinguishedName
    Filter     = { proxyAddresses -like '*' }
    Properties = 'Displayname',
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
    Where-Object { $_.PrimarySMTP } |
    Export-Csv .\primarySMTPnotMatchUPN.csv -NoTypeInformation