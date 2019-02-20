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

# Restrict Office 365 Groups Creation to all Global Admins
$GlobalAdmins = Get-MsolRole -RoleName "Company Administrator"
$GlobalAdminsObjectID = $GlobalAdmins.ObjectId.ToString()
$Template = Get-AzureADDirectorySettingTemplate | Where-Object {$_.DisplayName -eq "Group.Unified"}
$Setting = $Template.CreateDirectorySetting()
$Setting["EnableGroupCreation"] = "false"
$Setting["GroupCreationAllowedGroupId"] = $GlobalAdminsObjectID
New-AzureADDirectorySetting -DirectorySetting $Setting
Get-OwaMailboxPolicy | Where-Object {$_.IsDefault -eq $true} |
    Set-OwaMailboxPolicy -GroupCreationEnabled $false

# To reverse this setting run PowerShell as an administrator, connect and run:
$Template = Get-AzureADDirectorySettingTemplate | Where-Object {$_.DisplayName -eq "Group.Unified"}
$setting = $Template.CreateDirectorySetting()
$Setting["EnableGroupCreation"] = "true"
$Setting["GroupCreationAllowedGroupId"] = $null
Get-AzureADDirectorySetting | Set-AzureADDirectorySetting -DirectorySetting $Setting
Get-OwaMailboxPolicy | ? { $_.IsDefault -eq $true } | Set-OwaMailboxPolicy -GroupCreationEnabled $true