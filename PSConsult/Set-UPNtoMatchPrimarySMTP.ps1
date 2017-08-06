import-csv c:\scripts\list.csv | 
    ForEach-Object {
    get-aduser -identity $_.samaccountname -properties SamAccountName, UserPrincipalName, ProxyAddresses | 
        set-aduser -userprincipalname $_.PrimarySMTPAddress
}