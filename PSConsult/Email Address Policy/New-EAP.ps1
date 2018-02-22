New-EmailAddressPolicy -Name 'Shared' -EnabledEmailAddressTemplates "SMTP:%s@contoso.com", "smtp:%m@contosollc.mail.onmicrosoft.com" -RecipientFilter {
    ((givenname -eq 'Shared') -and (UserPrincipalName -like '*@contoso.com'))
} -Priority 1

New-EmailAddressPolicy -Name 'SharedMailboxes' -EnabledEmailAddressTemplates "SMTP:%s@contoso.com", "smtp:%m@contoso.mail.onmicrosoft.com" -RecipientFilter {
    ((Firstname -eq 'Shared') -and (UserPrincipalName -like '*@contoso.com'))
} -Priority 2