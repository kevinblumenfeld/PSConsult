$Userlist = Import-Csv "c:\scripts\CSV4mailuser.csv"
foreach ($Entry in $Userlist)
     {
     $Entry.UserPrincipalName
     $Entry.RemoteRoutingAddress
     Enable-MailUser $Entry.UserPrincipalName –ExternalEmailAddress $Entry.RemoteRoutingAddress
     Set-ADUser $Entry.UserPrincipalName –Replace @{msExchRecipientDisplayType = “-2147483642”}
     Set-ADUser $Entry.UserPrincipalName –Replace @{msExchRecipientTypeDetails = “2147483648”}
     Set-ADUser $Entry.UserPrincipalName –Replace @{msExchRemoteRecipientType = “4”}
     Set-ADUser $Entry.UserPrincipalName –Replace @{“targetaddress” = $Entry.RemoteRoutingAddress}
     }
