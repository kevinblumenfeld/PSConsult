# The script requires the EWS managed API, which can be downloaded here:
# https://www.microsoft.com/en-us/download/details.aspx?id=42951
# For Exchange 2010 or lower use EWS 1.2, download here:
# https://www.microsoft.com/en-us/download/details.aspx?id=28952
# Also comment out: Import-Module -Name "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"
# and uncomment out Import-Module -Name "C:\Program Files\Microsoft\Exchange\Web Services\1.2\Microsoft.Exchange.WebServices.dll"
# This also requires PowerShell 2.0 or higher
# Make sure the Import-Module command below matches the DLL location of the API.
# This path must match the install location of the EWS managed API. Change it if needed.
# For On-Prem Exchange change URL of CAS Server
# For On-Prem Exchange and EXO give impersonation rights to the service account you will use:
# New-ManagementRoleAssignment –Name:impersonationAssignmentName –Role:ApplicationImpersonation –User:serviceAccount
# Scroll to bottom of script for mailboxes.txt example and to specify which folders are to be created and tagged (by Retention Policy Tags)
# Replace GUID specified with -RetID with the RETENTIONID of the retention policy tag. Find the Retention ID with this PowerShell cmd:
# Get-RetentionPolicyTag | FT name, RetentionId
# Place this script and the mailboxes.txt file in the folder c:\scripts


[string]$LogFile = "C:\Scripts\Log.txt"   # Path of the Log File
function CreateFolder {
    Param (
        
        [Parameter(Mandatory = $true)]
        [string] $Email,

        [Parameter(Mandatory = $true)]
        [string] $FolderName
    )
    Write-host "Creating Folder for Mailbox Name:" $Email -foregroundcolor  "White"
    Add-Content $LogFile ("Creating Folder for Mailbox Name:" + $Email)

    #Change the user to Impersonate
    $service.ImpersonatedUserId = new-object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress, $Email);

    #Create the folder object
    $oFolder = new-object Microsoft.Exchange.WebServices.Data.Folder($service)
    $oFolder.DisplayName = $FolderName

    #Call Save to actually create the folder
    $oFolder.Save([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot)

    Write-host "Folder Created for " $Email -foregroundcolor  "Yellow"
    Add-Content $LogFile ("Folder Created for " + $Email)

    $service.ImpersonatedUserId = $null
} ##### END OF CreateFolder FUNCTION #####

function StampPolicyOnFolder {
    Param (
        
        [Parameter(Mandatory = $true)]
        [string] $Email,

        [Parameter(Mandatory = $true)]
        [string] $FolderName,

        [Parameter(Mandatory = $true)]
        [GUID] $RetID

    )
    Write-host "Stamping Policy on folder for Mailbox Name:" $Email -foregroundcolor  "White"
    Add-Content $LogFile ("Stamping Policy on folder for Mailbox Name:" + $Email)

    #Change the user to Impersonate
    $service.ImpersonatedUserId = new-object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress, $Email);

    #Search for the folder you want to stamp the property on
    $oFolderView = new-object Microsoft.Exchange.WebServices.Data.FolderView(1)
    $oSearchFilter = new-object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo([Microsoft.Exchange.WebServices.Data.FolderSchema]::DisplayName, $FolderName)

    #Uncomment the line below if the folder is in the regular mailbox
    $oFindFolderResults = $service.FindFolders([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot, $oSearchFilter, $oFolderView)

    #Comment the line below and uncomment the line above if the folder is in the regular mailbox
    # $oFindFolderResults = $service.FindFolders([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::ArchiveMsgFolderRoot, $oSearchFilter, $oFolderView)

    if ($oFindFolderResults.TotalCount -eq 0) {
        Write-host "Folder does not exist in Mailbox:" $Email -foregroundcolor  "Yellow"
        Add-Content $LogFile ("Folder does not exist in Mailbox:" + $Email)
    }
    else {
        Write-host "Folder found in Mailbox:" $Email -foregroundcolor  "White"

        #PR_POLICY_TAG 0x3019
        $PolicyTag = New-Object Microsoft.Exchange.WebServices.Data.ExtendedPropertyDefinition(0x3019, [Microsoft.Exchange.WebServices.Data.MapiPropertyType]::Binary);

        #PR_RETENTION_FLAGS 0x301D    
        $RetentionFlags = New-Object Microsoft.Exchange.WebServices.Data.ExtendedPropertyDefinition(0x301D, [Microsoft.Exchange.WebServices.Data.MapiPropertyType]::Integer);
        
        #PR_RETENTION_PERIOD 0x301A
        $RetentionPeriod = New-Object Microsoft.Exchange.WebServices.Data.ExtendedPropertyDefinition(0x301A, [Microsoft.Exchange.WebServices.Data.MapiPropertyType]::Integer);

        #Bind to the folder found
        $oFolder = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service, $oFindFolderResults.Folders[0].Id)
       
        #Same as the value in the PR_RETENTION_FLAGS property
        $oFolder.SetExtendedProperty($RetentionFlags, 137)

        #Same as the value in the PR_RETENTION_PERIOD property
        $oFolder.SetExtendedProperty($RetentionPeriod, 1095)

        #Change the GUID based on your policy tag
        $PolicyTagGUID = new-Object Guid("{$RetID}");

        $oFolder.SetExtendedProperty($PolicyTag, $PolicyTagGUID.ToByteArray())

        $oFolder.Update()

        Write-host "Retention policy stamped!" -foregroundcolor "White"
        Add-Content $LogFile ("Retention policy stamped!")
    
    }    

    $service.ImpersonatedUserId = $null
} ##### END OF StampPolicyOnFolder FUNCTION #####

####################################
#             SCRIPT               #
####################################

# Import-Module -Name "C:\Program Files\Microsoft\Exchange\Web Services\1.2\Microsoft.Exchange.WebServices.dll"
Import-Module -Name "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"

$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013_SP1)

# Set the Credentials

if (Test-Path "c:\scripts\imp.cred") {
    $PwdSecureString = Get-Content "c:\scripts\imp.cred" | ConvertTo-SecureString
    $UsernameString = Get-Content "c:\scripts\imp.ucred"
    $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $UsernameString, $PwdSecureString 
}
else {
    $Credential = Get-Credential -Message "Enter a username and password"
    $Credential.Password | ConvertFrom-SecureString | Out-File "c:\scripts\imp.cred" -Force
    $Credential.UserName | Out-File "c:\scripts\imp.ucred"
}

$service.Credentials = new-object Microsoft.Exchange.WebServices.Data.WebCredentials($Credential)


# Change the URL to point to your cas server
$service.Url = new-object Uri("https://outlook.office365.com/EWS/Exchange.asmx")

# Set $UseAutoDiscover to $true if you want to use AutoDiscover else it will use the URL set above
$UseAutoDiscover = $false

#Read data from the UserAccounts.txt
import-csv .\Mailboxes.txt | foreach-object {
    $PrimarySmtpAddress = $_.PrimarySmtpAddress.ToString()

    if ($UseAutoDiscover -eq $true) {
        Write-host "Autodiscovering.." -foregroundcolor "White"
        $UseAutoDiscover = $false
        $service.AutodiscoverUrl($PrimarySmtpAddress)
        Write-host "Autodiscovering Done!" -foregroundcolor "White"
        Write-host "EWS URL set to :" $service.Url -foregroundcolor "White"

    }
    #To catch the Exceptions generated
    trap [System.Exception] {
        Write-host ("Error: " + $_.Exception.Message) -foregroundcolor "Red";
        Add-Content $LogFile ("Error: " + $_.Exception.Message);
        continue;
    }
    ########################    
    ## CALL EACH FUNCTION ##
    ########################

    #########################
    #     mailboxes.txt     #
    # should look like this #
    #-----------------------#
    # PrimarySmtpAddress    #
    # mailbox01@contoso.com #
    # mailbox02@contoso.com #
    # mailbox03@contoso.com #
    #########################
    
    CreateFolder -Email $PrimarySmtpAddress -Folder "Test Folder1"
    StampPolicyOnFolder -Email $PrimarySmtpAddress -Folder "Test Folder1" -RetID "8a6e3718-26cf-445d-b203-4ca58d2508a8"
    CreateFolder -Email $PrimarySmtpAddress -Folder "Test Folder2"
    StampPolicyOnFolder -Email $PrimarySmtpAddress -Folder "Test Folder2" -RetID "8a6e3718-26cf-445d-b203-4ca58d2508a8"
    CreateFolder -Email $PrimarySmtpAddress -Folder "Test Folder3"
    StampPolicyOnFolder -Email $PrimarySmtpAddress -Folder "Test Folder3" -RetID "8a6e3718-26cf-445d-b203-4ca58d2508a8"
}
