$resultArray = @()
$mailboxes = Import-Csv .\cloudupn.csv 
foreach ($mailbox in $mailboxes) {
    $each = Get-mailbox -identity $mailbox.userprincipalname |
    select DisplayName, samaccountname, Alias, PrimarySmtpAddress,
@{n = "smtp" ; e = {( $_.EmailAddresses | ? {$_ -cmatch "smtp:*"}).Substring(5) -join ";" }},
@{n = "SIP" ; e = {( $_.EmailAddresses | ? {$_ -like "SIP:*"}).Substring(4) -join ";" }},
@{n = "x500" ; e = {( $_.EmailAddresses | ? {$_ -like "X500:*"}).Substring(0) -join ";" }} 
    $resultArray += $all
}
    $resultArray #Export-Csv 365mailboxes.csv -NTI
