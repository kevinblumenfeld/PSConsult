import-csv c:\scripts\list.csv | 
    ForEach-Object {
    Get-ADUser -identity $_.samaccountname -properties SamAccountName, UserPrincipalName, ProxyAddresses | 
        Set-ADUser -userprincipalname $_.PrimarySMTPAddress
}

<#
Get-ADUser -filter * -Properties ProxyAddresses, SamAccountName, UserPrincipalName | 
    ? {($_.ProxyAddresses -ne $null) -and !($_.SamAccountName).startswith("SM_")} |
    Select SamAccountName, @{n = "PrimarySMTP" ; e = {( $_.ProxyAddresses | ? {$_ -cmatch "SMTP:*"}).Substring(5)}} | % {
    Set-ADUser $_.SamAccountName -UserPrincipalName $_.PrimarySMTP
}
#>
