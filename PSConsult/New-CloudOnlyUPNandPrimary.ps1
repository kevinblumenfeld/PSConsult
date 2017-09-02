$Mailboxes = Import-Csv .\NewUPNs.csv

Foreach ($Mailbox in $Mailboxes) {
    get-MsolUser -UserPrincipalName $Mailbox.UPN | Set-MsolUserPrincipalName -NewUserPrincipalName $Mailbox.NewUPN
}