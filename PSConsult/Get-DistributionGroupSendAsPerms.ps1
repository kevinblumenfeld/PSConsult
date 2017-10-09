
### Distribution Groups ###
# To Check on-premises #
Get-DistributionGroup |  Get-ADPermission | where {($_.ExtendedRights -like "*Send-As*") -and ($_.IsInherited -eq $false) -and !($_.User -like "NT AUTHORITY\SELF") -and !($_.User.tostring().startswith('S-1-5-21-')) } | Export-Csv .\SendAsRightsToDGs.csv -NoTypeInformation

# To Check in Cloud #
Get-DistributionGroup  | Get-RecipientPermission -AccessRights SendAs | export-csv .\DGsSendAsRights.csv -NoTypeInformation