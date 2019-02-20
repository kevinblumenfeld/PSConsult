

# Assign user to Management Role of "Address Lists" - Restart PowerShell after this command
New-ManagementRoleAssignment –Name:'AssignAdminToAddressList' –Role:'Address Lists' –User:'admin@contoso.onmicrosoft.com'

# Create New Global Address List (GAL)
New-GlobalAddressList -Name 'Contoso GAL' -RecipientFilter '((RecipientType -eq "UserMailbox") -and (CustomAttribute15 -eq "Tenured"))'

# Create Address List (AL)
New-AddressList -Name 'Contoso AL' -ConditionalStateOrProvince 'Washington' -IncludedRecipients 'MailboxUsers'

# Create Address List with all Conference Room List (RL)
New-AddressList -Name 'Contoso RL' -RecipientFilter 'RecipientDisplayType -eq "ConferenceRoomMailbox"'

# Create Offline Address Book (OAB)
New-OfflineAddressBook -Name 'Contoso OAB' -AddressLists 'Contoso GAL', 'Contoso AL', 'Contoso RL'

# Create Address Book Policy (ABP)
New-AddressBookPolicy -Name 'Contoso ABP' -AddressLists 'Contoso AL' -RoomList 'Contoso RL' -OfflineAddressBook 'Contoso OAB' -GlobalAddressList 'Contoso GAL'




# Accounting Address Lists, GAL, OAB and Address Book Policy

New-AddressList -Name "Accounting-GROUPS" -RecipientFilter {(((RecipientType -eq 'MailUniversalDistributionGroup') -or (RecipientType -eq 'DynamicDistributionGroup')) -and (CustomAttribute2 -eq 'Accounting'))}

New-GlobalAddressList -name "Accounting-GAL" -RecipientFilter {((Alias -ne $null) -and ((ObjectClass -eq 'user') -or
            (ObjectClass -eq 'contact')) -or (((RecipientType -eq 'MailUniversalDistributionGroup') -or
                (RecipientType -eq 'DynamicDistributionGroup')) -and (CustomAttribute2 -eq 'Accounting')))}

New-OfflineAddressBook -name "Accounting-OAB" -AddressLists "Accounting-GAL"

New-AddressBookPolicy -name "Accounting-ABP" -AddressLists "\All Users", "\All Contacts", "\Accounting-GROUPS" -OfflineAddressBook "\Accounting-OAB" -GlobalAddressList "\Accounting-GAL" -RoomList "\All Rooms"

# Tickle-MailRecipients.ps1


# Corp Address Lists, GAL, OAB and Address Book Policy

New-AddressList -Name "CORP-GROUPS" -RecipientFilter {(((RecipientType -eq 'MailUniversalDistributionGroup') -or (RecipientType -eq 'DynamicDistributionGroup')) -and (CustomAttribute1 -eq 'CORP'))}

New-GlobalAddressList -name "CORP-GAL" -RecipientFilter {((Alias -ne $null) -and ((ObjectClass -eq 'user') -or
            (ObjectClass -eq 'contact')) -or (((RecipientType -eq 'MailUniversalDistributionGroup') -or
                (RecipientType -eq 'DynamicDistributionGroup')) -and (CustomAttribute1 -eq 'CORP')))}

New-OfflineAddressBook -name "CORP-OAB" -AddressLists "CORP-GAL"

New-AddressBookPolicy -name "CORP-ABP" -AddressLists "\All Users", "\All Contacts", "\CORP-GROUPS" -OfflineAddressBook "\CORP-OAB" -GlobalAddressList "\CORP-GAL" -RoomList "\All Rooms"

# Tickle-MailRecipients.ps1


############################################################
# Tickle Mail Recipients Script (Tickle-MailRecipients.ps1)#
#       Seems Contacts Must be Tickled On Premises         #
############################################################

$mailboxes = Get-Mailbox -Resultsize Unlimited
$count = $mailboxes.count
$i = 0

Write-Host
Write-Host "Mailboxes Found:" $count

foreach ($mailbox in $mailboxes) {
    $i++
    Set-Mailbox $mailbox.alias -SimpleDisplayName $mailbox.SimpleDisplayName -WarningAction silentlyContinue
    Write-Progress -Activity "Tickling Mailboxes [$count]..." -Status $i
}

$mailusers = Get-MailUser -Resultsize Unlimited
$count = $mailusers.count
$i = 0

Write-Host
Write-Host "Mail Users Found:" $count

foreach ($mailuser in $mailusers) {
    $i++
    Set-MailUser $mailuser.alias -SimpleDisplayName $mailuser.SimpleDisplayName -WarningAction silentlyContinue
    Write-Progress -Activity "Tickling Mail Users [$count]..." -Status $i
}

$distgroups = Get-DistributionGroup -Resultsize Unlimited
$count = $distgroups.count
$i = 0

Write-Host
Write-Host "Distribution Groups Found:" $count

foreach ($distgroup in $distgroups) {
    $i++
    Set-DistributionGroup $distgroup.alias -SimpleDisplayName $distgroup.SimpleDisplayName -WarningAction silentlyContinue
    Write-Progress -Activity "Tickling Distribution Groups. [$count].." -Status $i
}
# It appears tickling of contacts must happen on-premises

<#
Get-MailContact -Resultsize unlimited |  ForEach-Object {
    Set-MailContact $_.identity -SimpleDisplayName $_.SimpleDisplayName
}
#>

Write-Host
Write-Host "Tickling Complete"

# END Tickle Mail Recipients Script




################
#    TESTS     #
################

New-AddressList -Name GroupAddressList -RecipientFilter {
    ((RecipientType -eq 'UserMailbox') -and
        ((StateOrProvince -eq 'GA') -or (StateOrProvince -eq 'Georgia'))) -and
    (((RecipientType -eq 'MailUniversalDistributionGroup') -or (RecipientType -eq 'MailUniversalSecurityGroup')) -and
        ((CustomAttribute1 -eq 'TEST') -or (CustomAttribute1 -eq 'TEST1')))}



Get-Recipient -ResultSize Unlimited | ? { (($_.RecipientType -eq 'UserMailbox') -and
        (($_.StateOrProvince -eq 'GA') -or ($_.CustomAttribute2 -eq 'USER'))) -or
    ((($_.RecipientType -eq 'MailUniversalDistributionGroup') -or ($_.RecipientType -eq 'MailUniversalSecurityGroup')) -and
        (($_.CustomAttribute1 -eq 'TEST') -or ($_.CustomAttribute1 -eq 'TEST1')))}


New-AddressList -Name KevinList3 -RecipientFilter {
    ((RecipientType -eq 'UserMailbox') -and
        ((StateOrProvince -eq 'GA') -or (CustomAttribute2 -eq 'USER'))) -or
    (((RecipientType -eq 'MailUniversalDistributionGroup') -or (RecipientType -eq 'MailUniversalSecurityGroup')) -and
        ((CustomAttribute1 -eq 'TEST') -or (CustomAttribute1 -eq 'TEST1')))
    -or (RecipientType -eq 'MailContact')}

New-AddressList -Name "Kevin3Contacts" -RecipientFilter {(RecipientType -eq 'MailContact') }
New-AddressList -Name "Kevin3Mailboxes" -RecipientFilter {(RecipientType -eq 'UserMailbox') -and (StateOrProvince -eq 'GA')}
New-AddressList -Name "Kevin3Groups" -RecipientFilter {(RecipientType -eq 'MailUniversalDistributionGroup') -and (CustomAttribute1 -eq 'TEST')}
New-AddressList -Name "Kevin3Resources" -RecipientFilter {(RecipientTypeDetails -eq 'RoomMailbox')}


New-GlobalAddressList -name Kevin3GAL -RecipientFilter {(RecipientType -eq 'MailContact') -or
    ((RecipientType -eq 'UserMailbox') -and (StateOrProvince -eq 'GA')) -or
    ((RecipientType -eq 'MailUniversalDistributionGroup') -and (CustomAttribute1 -eq 'TEST')) -or
    (RecipientTypeDetails -eq 'RoomMailbox')}

New-OfflineAddressBook -name "Kevin3OAB" -AddressLists "Kevin3GAL"
New-AddressBookPolicy -name "Kevin3ABP" -AddressLists "\Kevin3Contacts", "\Kevin3Mailboxes", "\Kevin3Groups" -OfflineAddressBook "\Kevin3OAB" -GlobalAddressList "\Kevin3GAL" -RoomList "\Kevin3Resources"

Get-Recipient -ResultSize unlimited | ? {$_.StateOrProvince -eq 'GA'} |  Set-Mailbox -AddressBookPolicy "Kevin3ABP"

# Tickle-MailRecipients.ps1







