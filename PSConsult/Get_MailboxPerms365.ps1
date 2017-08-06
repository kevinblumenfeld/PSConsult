$OutFile = ".\365_Permission_Export.csv"
"DisplayName" + "!" + "Alias" + "!" + "PrimarySMTP" + "!" + "FullAccess" + "!" + "SendAs" + "!" + "SendonBehalf" | Out-File $OutFile -Force -encoding ascii

# $Mailboxes = import-csv .\perms.csv
$Mailboxes = Get-Mailbox -ResultSize:Unlimited 
ForEach ($Mailbox in $Mailboxes) { 
    Write-Output "Mailbox: $($Mailbox.PrimarySMTPAddress)"
    $SendAs = (Get-RecipientPermission $Mailbox.PrimarySMTPAddress | ? {$_.AccessRights -match "SendAs" -and $_.Trustee -ne "NT AUTHORITY\SELF"} | select -ExpandProperty trustee) -join ";" 
    $FullAccess = (Get-MailboxPermission $Mailbox.PrimarySMTPAddress | ? {$_.AccessRights -eq "FullAccess" -and !$_.IsInherited} | Select -ExpandProperty User) -join ";"
    $sendbehalf = (Get-Mailbox $Mailbox.PrimarySMTPAddress | select-object -ExpandProperty GrantSendOnBehalfTo) -join ";"
    if (!$SendAs -and !$FullAccess -and !$sendbehalf) {continue}
    $Mailbox.DisplayName + "!" + $Mailbox.Alias + "!" + $Mailbox.PrimarySMTPAddress + "!" + $FullAccess + "!" + $SendAs + "!" + $sendbehalf | Out-File $OutFile -Append -encoding ascii
}  