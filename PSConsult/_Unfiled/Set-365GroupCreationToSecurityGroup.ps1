# Uninstall/Install necessary modules on Windows 10.
# Run PowerShell as an admin by right clicking and "Run as Administrator"
try {Uninstall-Module -Name AzureADPreview -ErrorAction stop} catch {}
try {Uninstall-Module -Name AzureAD -ErrorAction stop} catch {}
Install-Module -Name AzureADPreview -SkipPublisherCheck -Force
Install-Module -Name MSOnline -SkipPublisherCheck -Force

# Get Global Admin credential to connect to all services
$Credential = Get-Credential

# Connect to Exchange Online
$ExoSplat = @{
    ConfigurationName = "Microsoft.Exchange"
    ConnectionUri     = "https://outlook.office365.com/powershell-liveid/"
    Credential        = $Credential
    Authentication    = "Basic"
    AllowRedirection  = $True
}

$Session = New-PSSession @ExoSplat
Import-PSSession $Session

# Connect to Microsoft Online
Connect-MsolService -Credential $Credential

# Connect to Azure AD Version 2 Preview
Connect-AzureAD -Credential $Credential

# Restrict Office 365 Groups Creation to a Security Groups
# Create Security Group. Change DisplayName and MailNickName to suit.
# This Security Group will not be mail-enabled
$GroupSplat = @{
    DisplayName     = "AllowedtoCreate365Groups"
    MailEnabled     = $false
    MailNickName    = "AllowedtoCreate365Groups"
    SecurityEnabled = $True
}
$SecGroup = New-AzureADGroup @GroupSplat

# Add members to the Security Group you just created from a txt file of UPNs
# No header is required in the text file named UPNs.txt - Change path of text file as needed.
(Get-Content c:\scripts\UPNs.txt | ForEach-Object {Get-AzureADUser -ObjectId  $_}).ObjectId |
    Add-AzureADGroupMember -ObjectId $SecGroup.ObjectID

$Template = Get-AzureADDirectorySettingTemplate | Where-Object {$_.DisplayName -eq 'Group.Unified'}
$Setting = $Template.CreateDirectorySetting()
try {New-AzureADDirectorySetting -DirectorySetting $Setting -erroraction stop} catch {}
$Setting = Get-AzureADDirectorySetting -Id (Get-AzureADDirectorySetting | Where-Object -Property DisplayName -Value "Group.Unified" -EQ).id
$Setting["EnableGroupCreation"] = $False
$Setting["GroupCreationAllowedGroupId"] = (Get-AzureADGroup -ObjectId $SecGroup.ObjectID).ObjectId
Set-AzureADDirectorySetting -Id (Get-AzureADDirectorySetting | Where-Object -Property DisplayName -Value "Group.Unified" -EQ).id -DirectorySetting $Setting
(Get-AzureADDirectorySetting).Values

# Restart PowerShell as an administrator and uninstall the preview version of AzureAD
Uninstall-Module -Name AzureADPreview -Force

# To remove the restriction, reconnect and run from PowerShell as administrator
$SettingId = Get-AzureADDirectorySetting -All $True | Where-Object {$_.DisplayName -eq "Group.Unified"}
Remove-AzureADDirectorySetting -Id $SettingId.Id
