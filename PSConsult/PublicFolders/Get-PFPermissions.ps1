[run on-premises in EMS - Exchange 2013]
AccessRights
Get-PublicFolder -Recurse | Get-PublicFolderClientPermission | select FolderName,User,@{Name='Access Rights';Expression={[string]::join(', ', $_.AccessRights)}} | Export-Csv PF2013permissionsACCESSRIGHTS.csv -NTI

SendonBehalf
Get-MAILPublicFolder -Recurse | Get-PublicFolderClientPermission | select FolderName,User,@{Name='GrantSendOnBehalfTo';Expression={[string]::join(', ', $_.GrantSendOnBehalfTo)}} | Export-Csv PF2013permissionsSENDONBEHALF.csv -NTI

SendAs
Get-MailPublicFolder | Get-ADPermission |  ? { ($_.ExtendedRights-like "Send-as*") -or ($_.AccessRights  -eq "GenericAll") -and ($_.User -Notlike "NT AUTHORITY\SYSTEM") }| select identity, user, AccessRights, ExtendedRights | Export-Csv PF2013permissionsSENDAS.csv -NTI

[run on-premises in EMS - Exchange 2010]
AccessRights
Get-PublicFolder -Recurse | Get-PublicFolderClientPermission | select Identity,User,@{Name='Access Rights';Expression={[string]::join(', ', $_.AccessRights)}} | Export-Csv PF2010permissionsACCESSRIGHTS.csv -NTI

# check PoshPermissionTree for SA and SOB permission to Legacy 2010 PFs