
### Distribution Groups ###

# Assign in Cloud #
Get-DistributionGroup "GroupPerm" | Add-RecipientPermission -Trustee "Cloud01" -AccessRights SendAs
# Assign on-Premises #
Get-DistributionGroup "GroupPerm" | Set-DistributionGroup -GrantSendOnBehalfTo "Mailbox02"

### Mailboxes ###

# Assign on-Premises #
Add-ADPermission TestMailbox -ExtendedRights "Send As" -User TUser
Get-Mailbox TestMailbox | Add-ADPermission -ExtendedRights "Send As" -User TUser

# Assign in Cloud #
Get-Mailbox “Mailbox01” | Add-RecipientPermission -Trustee "Cloud01" -AccessRights SendAs
Get-Mailbox “Mailbox01” | Add-MailboxPermission -User "Cloud01" -AccessRights FullAccess
Get-Mailbox “Mailbox01” | Set-Mailbox -GrantSendOnBehalfTo "Cloud01"
