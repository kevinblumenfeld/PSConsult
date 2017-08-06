# Get-ADGroup  -Filter 'proxyaddresses -ne "$null"' -SearchBase "OU=Distribution Groups,DC=GALLS,DC=local" -properties displayname,SamAccountName,mailnickname  | Select DisplayName, SamAccountName, Mailnickname | Export-Csv c:\scripts\dgs.csv -NoTypeInformation
import-csv c:\scripts\dgs.csv | 
    ForEach-Object {
    get-adgroup -identity $_.SamAccountName |? {$ProxyAddresses -ne "$null"} | 
        Set-ADGroup -add @{ proxyaddresses = ("smtp:" + $($_.mailnickname) + "@GallsLLC.onmicrosoft.com") }
}