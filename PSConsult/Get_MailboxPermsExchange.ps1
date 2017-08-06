Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -EA SilentlyContinue
$OutFile = ".\Exchange_Permission_Export.csv"
"DisplayName" + "!" + "Alias" + "!" + "OU" + "!" + "PrimarySMTP" + "!" + "FullAccess" + "!" + "SendAs" + "!" + "SendonBehalf" | Out-File $OutFile -Force -encoding ascii

# $Mailboxes = import-csv .\perms.csv
$Mailboxes = Get-Mailbox -ResultSize:Unlimited | Select DistinguishedName, UserPrincipalName, DisplayName, Alias,
@{n = "OU" ; e = {$_.Distinguishedname | ForEach-Object {($_ -split '(OU=)', 2)[1, 2] -join ''}}}
ForEach ($Mailbox in $Mailboxes) { 
    Write-Output "Mailbox: $($Mailbox.UserPrincipalName)"
    $SendAs = (Get-RecipientPermission $Mailbox.DistinguishedName | ? {$_.AccessRights -match "SendAs" -and $_.Trustee -ne "NT AUTHORITY\SELF" -and !$_.Trustee.tostring().startswith('S-1-5-21-')} | select -ExpandProperty trustee) -join ";" 
    $FullAccess = (Get-MailboxPermission $Mailbox.DistinguishedName | ? {$_.AccessRights -eq "FullAccess" -and !$_.IsInherited -and !$_.user.tostring().startswith('S-1-5-21-')} | Select -ExpandProperty User) -join ";"
    $sendbehalf = (Get-Mailbox $Mailbox.DistinguishedName | select-object -ExpandProperty GrantSendOnBehalfTo) -join ";"
    if (!$SendAs -and !$FullAccess -and !$sendbehalf) {continue}
    $Mailbox.DisplayName + "!" + $Mailbox.Alias + "!" + $Mailbox.OU + "!" + $Mailbox.UserPrincipalName + "!" + $FullAccess + "!" + $SendAs + "!" + $sendbehalf | Out-File $OutFile -Append -encoding ascii
}  