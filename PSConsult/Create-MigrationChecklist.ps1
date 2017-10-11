$properties = @('DisplayName','Title','Office','Department','FirstName','LastName','StreetAddress'
                'City','State','PostalCode','Country','MobilePhone','PhoneNumber','Fax','UserPrincipalName'
                'UserType','WhenCreated','BlockCredential','CloudExchangeRecipientDisplayType','UsageLocation'
                'IsLicensed','LastDirSyncTime','LastPasswordChangeTimestamp','MSExchRecipientTypeDetails','ImmutableId')

Get-MsolUser -All | select $properties