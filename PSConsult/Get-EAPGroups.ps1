Get-DistributionGroup -ResultSize unlimited -Filter {EmailAddressPolicyEnabled -eq $false} |
    select Displayname, UserPrincipalName, SamAccountName, EmailAddressPolicyEnabled,
@{n = "OU" ; e = {$_.Distinguishedname | ForEach-Object {($_ -split '(OU=)', 2)[1, 2] -join ''}}} |
    Export-Csv .\EAPnotEnabledGroups.csv -NoTypeInformation