$Credentials = Get-Credential
# $MigrationEndpointOnPrem = New-MigrationEndpoint -ExchangeRemoteMove -Name OnpremEndpoint -Autodiscover -EmailAddress administrator@onprem.contoso.com -Credentials $Credentials
$MigrationEndpointOnPrem = Get-MigrationEndpoint -Identity "Hybrid Migration Endpoint - webmail.contoso.com"
$OnboardingBatch = New-MigrationBatch

$MBSplat = @{
    Name                 = "2018_10_30_Pilot"
    SourceEndpoint       = $MigrationEndpointOnprem.Identity
    TargetDeliveryDomain = "contoso.mail.onmicrosoft.com"
    CSVData              = ([System.IO.File]::ReadAllBytes("C:\scripts\Pilot.csv"))
}

#Start-MigrationBatch -Identity $OnboardingBatch.Identity




# IF MX is pointing On-Premises, in onprem Exchange set domains to internal relay
# IF MX is pointing CLOUD, in Cloud set domains to internal relay
Get-AcceptedDomain | Where {
    $_.DomainName -eq 'contoso.mail.onmicrosoft.com'
} | Set-AcceptedDomain -Name 'PublicFolderDestination_78c0b207_5ad2_4fee_8cb9_f373175b3f99'

Get-MailPublicFolder | Get-ADPermission |  ? {
    $_.ExtendedRights -like "*Send-as*" -and
    $_.User -Notlike "NT AUTHORITY\SYSTEM"
}| select Identity, User, AccessRights, ExtendedRights, Deny, Inherited |
    Export-Csv 'C:\Scripts\PF_SENDAS_BACKUP.csv' -NoTypeInformation -Encoding UTF8

# MUST SYNC (AD OBJECTS) of PF MAILBOXES with AD CONNECT!!!
# COEXISTENCE ARTICLE FOR MODERN PF AND EXO (need 2 articles, one for coexistence and one for migration)
# https://docs.microsoft.com/en-us/exchange/hybrid-deployment/set-up-modern-hybrid-public-folders
# RUN THIS IN EMS (it connects to EXO)
# scripts are linked in article.. confirm this is up to date https://www.microsoft.com/en-us/download/details.aspx?id=46381
# Sync-MailPublicFolders.ps1  & SyncMailPublicFolders.strings.psd1

$cred = Get-Credential
Sync-MailPublicFolders.ps1 -Credential $cred -CsvSummaryFile:sync_summary60.csv

# Run this in EXO replacing with ONPREM PUBLIC FOLDER MAILBOXES
Set-OrganizationConfig -PublicFoldersEnabled Remote -RemotePublicFolderMailboxes PFMailbox1, PFMailbox2, PFMailbox3
# MIGHT HAVE TO DO ABOVE MORE THAN ONCE

# ***** DELETES IN EXO ONLY IF NEED TO ****
Get-MailPublicFolder -ResultSize Unlimited | where {$_.EntryId -ne $null}| Disable-MailPublicFolder -Confirm:$false
Get-PublicFolder -GetChildren \ -ResultSize Unlimited | Remove-PublicFolder -Recurse -Confirm:$false

$hierarchyMailboxGuid = $(Get-OrganizationConfig).RootPublicFolderMailbox.HierarchyMailboxGuid
Get-Mailbox -PublicFolder | Where-Object {$_.ExchangeGuid -ne $hierarchyMailboxGuid} | Remove-Mailbox -PublicFolder -Confirm:$false -Force
Get-Mailbox -PublicFolder | Where-Object {$_.ExchangeGuid -eq $hierarchyMailboxGuid} | Remove-Mailbox -PublicFolder -Confirm:$false -Force
## Get-Mailbox -PublicFolder -SoftDeletedMailbox | Remove-Mailbox -PublicFolder -PermanentlyDelete:$true
Get-Mailbox -PublicFolder -SoftDeletedMailbox | % { Remove-Mailbox -Identity $_.alias -PublicFolder -PermanentlyDelete:$true -Force -Confirm:$False }

# THIS IS FOR MIGRATION NOT COEXISTENCE!!!!!
.\Export-ModernPublicFolderStatistics.ps1 stats.csv
.\ModernPublicFolderToMailboxMapGenerator.ps1 -MailboxSize "10GB" -MailboxRecoverableItemSize "2GB" -ImportFile ".\stats.csv" -ExportFile "map.csv"

$mappings = Import-Csv 'c:\scripts\PF\map.csv'
$primaryMailboxName = ($mappings | Where-Object FolderPath -eq "\" ).TargetMailbox;
New-Mailbox -HoldForMigration:$true -PublicFolder -IsExcludedFromServingHierarchy:$false $primaryMailboxName
($mappings | Where-Object TargetMailbox -ne $primaryMailboxName).TargetMailbox | Sort-Object -unique | ForEach-Object { New-Mailbox -PublicFolder -IsExcludedFromServingHierarchy:$false $_ }

$Cred = Get-Credential
.\Sync-ModernMailPublicFolders.ps1 -Credential $Cred -CsvSummaryFile:sync_summary20.csv

$Source_Credential = Get-Credential 'contoso\Kevin.Blumenfeld'
$Source_RemoteServer = 'webmail.contoso.com'

$PfEndpoint = New-MigrationEndpoint -PublicFolder -Name PublicFolderEndpoint -RemoteServer $Source_RemoteServer -Credentials $Source_Credential

[byte[]]$bytes = Get-Content -Encoding Byte 'C:\Scripts\SFPF\map.csv'
New-MigrationBatch -Name PublicFolderMigration -CSVData $bytes -SourceEndpoint $PfEndpoint.Identity -NotificationEmails 'kevin.blumenfeld@contoso.com'

$CalculatedProps = @(
    @{n = "EmailAddresses" ; e = {($_.emailAddresses | Where-Object {$_ -like "smtp:*"}) -join ";" }}
)

$Props = @('Alias', 'mail', 'ObjectGuid', 'Identity', 'PrimarySmtpAddress', 'DistinguishedName')

Get-MailPublicFolder -ResultSize unlimited | Select ($Props + $CalculatedProps) | Export-csv C:\Scripts\PFsmtp11.csv -NoTypeInformation -Encoding UTF8



get-adobject -Filter {proxyaddresses -like "*contoso*"} -Properties proxyaddresses -ResultSetSize $null |
    Select distinguishedname, @{n = 'bad'; e = {($_.proxyaddresses | Where {$_ -like "*contoso*"}) -join ";" }}

# [run on-premises in EMS - Exchange 2013]
AccessRights
Get-PublicFolder -Recurse | Get-PublicFolderClientPermission | select FolderName, User, @{Name = 'Access Rights'; Expression = {[string]::join('|', [string[]]$_.AccessRights)}} | Export-Csv PF2013permissionsACCESSRIGHTS.csv -NTI

SendonBehalf
Get-MAILPublicFolder -Recurse | Get-PublicFolderClientPermission | select FolderName, User, @{Name = 'GrantSendOnBehalfTo'; Expression = {[string]::join('|', [string[]]$_.GrantSendOnBehalfTo)}} | Export-Csv PF2013permissionsSENDONBEHALF.csv -NTI

SendAs
Get-MailPublicFolder | Get-ADPermission |  ? { ($_.ExtendedRights -like "Send-as*") -or ($_.AccessRights -eq "GenericAll") -and ($_.User -Notlike "NT AUTHORITY\SYSTEM") }| select identity, user, AccessRights, ExtendedRights | Export-Csv PF2013permissionsSENDAS.csv -NTI

# [run on-premises in EMS - Exchange 2010]
AccessRights
Get-PublicFolder -Recurse | Get-PublicFolderClientPermission | select Identity, User, @{Name = 'Access Rights'; Expression = {[string]::join('|', [string[]]$_.AccessRights)}} | Export-Csv PF2010permissionsACCESSRIGHTS.csv -NTI

# check PoshPermissionTree for SA and SOB permission to Legacy 2010 PFs