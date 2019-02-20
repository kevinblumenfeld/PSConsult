<#
.SYNOPSIS
Sets the Autodiscover service connection point (SCP) in Active Directory, Outlook Anywhere FQDNs, and virtual directory URLs for new Exchange servers as they are being installed.

Author/Copyright:    Jeff Guillet, MCSM | MVP - All rights reserved
Email/Blog/Twitter:  jeff@expta.com | www.expta.com | @expta

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

.NOTES
Version 1.0, October 7, 2015
Version 2.0, July 22, 2016

Revision History
---------------------------------------------------------------------
1.0    Initial release
1.1    Updated online link; Added code to install RSAT-AD-PowerShell if required
2.0    Major update:
        Made setting the new values easier by cloning an existing server
        Now also configures Outlook Anywhere and Exchange virtual directory internal and external URLs
        Revised verbiage and use *-ClientAccessService cmdlets for Exchange 2016
        Added -Verbose output to display the values we're configuring
        Improved overall display output

.DESCRIPTION
Sets the Autodiscover service connection point (SCP) in Active Directory, Outlook Anywhere FQDNs, and virtual directory URLs for new Exchange servers as they are being installed.

Exchange setup always configures the new SCP with the FQDN of the server which throws certificate warnings in Outlook because the self-signed Exchange certificate is not trusted. Read https://blogs.technet.microsoft.com/exchange/2015/11/18/exchange-active-directory-deployment-site for more information about this behavior.

This script should be run from an existing Exchange server of the same version, and is designed to be run while the new Exchange server is being installed. It loops until it finds an existing SCP for the target server and then configures it to match the same SCP and virtual directory URL values from the server to clone.

.PARAMETER Server
Specifies the Exchange 2010/2013/2016 server to configure.

.PARAMETER ServerToClone
Specifies the Exchange 2010/2013/2016 server to use for reference. The SCP, Outlook Anywhere, and internal/external URL values will be copied from this server to the target server.

.PARAMETER DomainController
Query and set on the specified domain controller, otherwise uses the current binding DC.

.LINK
http://www.expta.com/2016/07/new-set-autodiscoverscp-v2-script-is-on.html

.EXAMPLE
PS C:\>Set-AutodiscoverSCP.ps1 -Server exch02 -ServerToClone exch01

This command continually queries the current configuration domain controller until it finds an SCP for server EXCH02 and then sets it to match the SCP of EXCH01. It also configures Outlook Anywhere and the internal/external virtual directory URLs to match those found on EXCH01.

.EXAMPLE
PS C:\>Set-AutodiscoverSCP.ps1 -Server exch02 -ServerToClone exch01 -DomainController dc03

This command is almost the same as the command in the previous example, except it continually queries DC03 for the SCP record and configures it on that domain controller. This is useful when configuring a new Exchange server in a different Active Directory site.
#>

# Define the script parameters
Param (
    [CmdletBinding()]
    [Parameter(Position = 1, Mandatory = $true)]
    [string]$Server,
    [Parameter(Position = 2, Mandatory = $true)]
    [string]$ServerToClone,
    [Parameter(Position = 3, Mandatory = $false)]
    [string]$DomainController
)

Process {
    # Validate the target server
    $ErrorActionPreference = "SilentlyContinue"
    $Server = $Server.ToUpper()
    $Ping = New-Object System.Net.NetworkInformation.Ping
    $Reply = $Ping.Send($Server).Status
    if ($Reply –ne "Success") {
        Write-Host "ERROR: $Server is not online or is not a valid server name." -Foreground Red
        Exit(1)
    }

    # Validate the server to clone
    $ServerToClone = $ServerToClone.ToUpper()
    $Reply = $null
    $Reply = $Ping.Send($ServerToClone).Status
    if ($Reply –ne "Success") {
        Write-Host "ERROR: $ServerToClone is not online or is not a valid server name." -Foreground Red
        Exit(1)
    }

    # Select the Domain Controller to run against
    if ($DomainController) {
        if ((Get-WindowsFeature RSAT-AD-PowerShell).InstallState -eq "Available") {
            Add-WindowsFeature RSAT-AD-PowerShell
        }
        Import-Module ActiveDirectory
        $Error.Clear()
        $DomainController = (Get-ADDomainController $DomainController).HostName
        $DomainController = $DomainController.ToUpper()
        If ($Error) {
            Write-Host "ERROR: $DomainController is not online or is not a valid domain controller." -Foreground Red
            Exit(1)
        }
    }
    else {
        $DomainController = (Get-ADServerSettings).DefaultConfigurationDomainController.Domain
    }

    # Discover where the PSSession is established and show Exchange version warning
    $PSSessionServer = Get-ExchangeServer (Get-PSSession | Where-Object {$_.State -eq 'Opened'}).ComputerName
    if ($PSSessionServer.AdminDisplayVersion.Major -eq 14) { $ExVersion = "2010" }
    if ($PSSessionServer.AdminDisplayVersion.Major -eq 15 -and $PSSessionServer.AdminDisplayVersion.Minor -eq 0) { $ExVersion = "2013" }
    if ($PSSessionServer.AdminDisplayVersion.Major -eq 15 -and $PSSessionServer.AdminDisplayVersion.Minor -eq 1) { $ExVersion = "2016" }
    if ($ExVersion -eq $null) {
        Write-Host "ERROR: This script must be run from the Exchange Management Shell on an Exchange 2010-2016 server." -Foreground Red
        Exit(1)
    }
    elseif ($ExVersion -eq "2010") {
        Write-Host "This script is currently running in an Exchange 2010 PowerShell session. Make sure $Server is installing Exchange 2010." -Foreground White -BackGround Red
        if ((Get-OwaVirtualDirectory -Server $ServerToClone -DomainController $DomainController -ADPropertiesOnly).InternalUrl.AbsoluteUri -eq $null) {
            Write-Host "ERROR: $ServerToClone is a higher version of Exchange than this server." -Foreground Red
            Exit(1)
        }
        Write-Host "NOTE: If you're installing your first Exchange 2013/2016 server in this environment you should run this script from that server while setup is running."
        Write-Host
    }
    else {
        Write-Host "This script is currently running in an Exchange $ExVersion PowerShell session. Make sure $Server is installing Exchange 2013 or later." -Foreground White -BackGround Red
        Write-Host
    }
    $ErrorActionPreference = "Continue"

    # Get the SCP, Outlook Anywhere, and virtual directory URL values from $ServerToClone
    Write-Host -NoNewline "Gathering SCP, Outlook Anywhere, and Exchange virtual directory values from $ServerToClone... " -Foreground White
    $SCPValue = (Get-ClientAccessServer $ServerToClone -DomainController $DomainController -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).AutoDiscoverServiceInternalUri.AbsoluteUri
    $EasInternal = (Get-ActiveSyncVirtualDirectory -Server $ServerToClone -DomainController $DomainController -ADPropertiesOnly).InternalUrl.AbsoluteUri
    $EasExternal = (Get-ActiveSyncVirtualDirectory -Server $ServerToClone -DomainController $DomainController -ADPropertiesOnly).ExternalUrl.AbsoluteUri
    $EcpInternal = (Get-EcpVirtualDirectory -Server $ServerToClone -DomainController $DomainController -ADPropertiesOnly).InternalUrl.AbsoluteUri
    $EcpExternal = (Get-EcpVirtualDirectory -Server $ServerToClone -DomainController $DomainController -ADPropertiesOnly).ExternalUrl.AbsoluteUri
    If ($ExVersion -ne "2010") {
        $MapiInternal = (Get-MapiVirtualDirectory -Server $ServerToClone -DomainController $DomainController -ADPropertiesOnly).InternalUrl.AbsoluteUri
        $MapiExternal = (Get-MapiVirtualDirectory -Server $ServerToClone -DomainController $DomainController -ADPropertiesOnly).ExternalUrl.AbsoluteUri
    }
    $OabInternal = (Get-OabVirtualDirectory -Server $ServerToClone -DomainController $DomainController -ADPropertiesOnly).InternalUrl.AbsoluteUri
    $OabExternal = (Get-OabVirtualDirectory -Server $ServerToClone -DomainController $DomainController -ADPropertiesOnly).ExternalUrl.AbsoluteUri
    $OwaInternal = (Get-OwaVirtualDirectory -Server $ServerToClone -DomainController $DomainController -ADPropertiesOnly).InternalUrl.AbsoluteUri
    $OwaExternal = (Get-OwaVirtualDirectory -Server $ServerToClone -DomainController $DomainController -ADPropertiesOnly).ExternalUrl.AbsoluteUri
    $EwsInternal = (Get-WebServicesVirtualDirectory -Server $ServerToClone -DomainController $DomainController -ADPropertiesOnly).InternalUrl.AbsoluteUri
    $EwsExternal = (Get-WebServicesVirtualDirectory -Server $ServerToClone -DomainController $DomainController -ADPropertiesOnly).ExternalUrl.AbsoluteUri
    $OaInternal = (Get-OutlookAnywhere -Server $ServerToClone -DomainController $DomainController -AdPropertiesOnly).InternalHostname.HostnameString
    $OaExternal = (Get-OutlookAnywhere -Server $ServerToClone -DomainController $DomainController -AdPropertiesOnly).ExternalHostname.HostnameString
    Write-Host "Done!" -Foreground White

    # Verbose output shows cloned values
    Write-Verbose "SCP -  $SCPValue"
    Write-Verbose "EAS -  $EasInternal | $EasExternal"
    Write-Verbose "ECP -  $EcpInternal | $EcpExternal"
    Write-Verbose "MAPI - $MapiInternal | $MapiExternal"
    Write-Verbose "OAB -  $OabInternal | $OabExternal"
    Write-Verbose "OWA -  $OwaInternal | $OwaExternal"
    Write-Verbose "EWS -  $EwsInternal | $EwsExternal"
    Write-Verbose "OA -   $OaInternal | $OaExternal"

    # Check if we're running this script from the target server
    if ([System.Net.Dns]::GetHostByName($Server).HostName -eq [System.Net.Dns]::GetHostByName(($env:computerName)).HostName) {
        Write-Host
        Write-Host "NOTE: You are running this script from the same server you're configuring. If you're running it while installing Exchange the script may stall during configuration since setup restarts IIS and web services several times. If that happens simply CTRL-C and restart the script." -Foreground Yellow
        Write-Host
    }

    # Continually query AD for SCP value for $Server
    do {
        if ($ExVersion -eq "2016") {
            $SCP = (Get-ClientAccessService $Server -DomainController $DomainController -ErrorAction SilentlyContinue).AutoDiscoverServiceInternalUri.AbsoluteUri
        }
        else {
            $SCP = (Get-ClientAccessServer $Server -DomainController $DomainController -ErrorAction SilentlyContinue).AutoDiscoverServiceInternalUri.AbsoluteUri
        }
        $PercentComplete++
        if ($PercentComplete -eq 101) { $PercentComplete = 1 }
        Write-Progress -Activity "Searching for the SCP value for Exchange server $Server in Active Directory..." -PercentComplete $PercentComplete -Status "Please wait."
    }
    until ($SCP -ne $null)

    # Set the new SCP value in Active Directory
    $Error.Clear()
    if ($ExVersion -eq "2016") {
        Set-ClientAccessService $Server -AutoDiscoverServiceInternalUri $SCPValue -DomainController $DomainController
    }
    else {
        Set-ClientAccessServer $Server -AutoDiscoverServiceInternalUri $SCPValue -DomainController $DomainController
    }
    If ($Error) { Exit(1) }
    Write-Host "Setting SCP value for $Server to $SCPValue" -Foreground Green

    # Set the internal and external URLs for all virtual directories
    Write-Host -NoNewLine "Setting ActiveSyncVirtualDirectory internal and external URLs... " -Foreground Cyan
    Get-ActiveSyncVirtualDirectory -Server $Server -DomainController $DomainController -ADPropertiesOnly | Set-ActiveSyncVirtualDirectory -InternalUrl $EasInternal -ExternalUrl $EasExternal -DomainController $DomainController -WarningAction SilentlyContinue
    Write-Host "Done!" -Foreground Cyan
    Write-Host -NoNewLine "Setting EcpVirtualDirectory internal and external URLs... " -Foreground Cyan
    Get-EcpVirtualDirectory -Server $Server -DomainController $DomainController -ADPropertiesOnly | Set-EcpVirtualDirectory -InternalUrl $EcpInternal -ExternalUrl $EcpExternal -DomainController $DomainController -WarningAction SilentlyContinue
    Write-Host "Done!" -Foreground Cyan
    If ($MapiInternal -ne $null) {
        Write-Host -NoNewLine "Setting MapiVirtualDirectory internal and external URLs... " -Foreground Cyan
        Get-MapiVirtualDirectory -Server $Server -DomainController $DomainController -ADPropertiesOnly | Set-MapiVirtualDirectory -InternalUrl $MapiInternal -ExternalUrl $MapiExternal -DomainController $DomainController -WarningAction SilentlyContinue
        Write-Host "Done!" -Foreground Cyan
    }
    Write-Host -NoNewLine "Setting OabVirtualDirectory internal and external URLs... " -Foreground Cyan
    Get-OabVirtualDirectory -Server $Server -DomainController $DomainController -ADPropertiesOnly | Set-OabVirtualDirectory -InternalUrl $OabInternal -ExternalUrl $OabExternal -DomainController $DomainController -WarningAction SilentlyContinue
    Write-Host "Done!" -Foreground Cyan
    Write-Host -NoNewLine "Setting OwaVirtualDirectory internal and external URLs... " -Foreground Cyan
    Get-OwaVirtualDirectory -Server $Server -DomainController $DomainController -ADPropertiesOnly | Set-OwaVirtualDirectory -InternalUrl $OwaInternal -ExternalUrl $OwaExternal -DomainController $DomainController -WarningAction SilentlyContinue
    Write-Host "Done!" -Foreground Cyan
    Write-Host -NoNewLine "Setting WebServicesVirtualDirectory internal and external URLs... " -Foreground Cyan
    Get-WebServicesVirtualDirectory -Server $Server -DomainController $DomainController -ADPropertiesOnly | Set-WebServicesVirtualDirectory -InternalUrl $EwsInternal -ExternalUrl $EwsExternal -DomainController $DomainController -WarningAction SilentlyContinue
    Write-Host "Done!" -Foreground Cyan
    Write-Host -NoNewLine "Setting Outlook Anywhere FQDNs... " -Foreground White
    $OA = Get-OutlookAnywhere -Server $Server -DomainController $DomainController -AdPropertiesOnly
    If ($ExVersion -ne "2010") {
        $OA | Set-OutlookAnywhere -InternalHostname $OaInternal -InternalClientsRequireSsl $OA.InternalClientsRequireSsl -InternalClientAuthenticationMethod $OA.InternalClientAuthenticationMethod -ExternalHostname $OaExternal -ExternalClientsRequireSsl $OA.ExternalClientsRequireSsl -ExternalClientAuthenticationMethod $OA.ExternalClientAuthenticationMethod -DomainController $DomainController -WarningAction SilentlyContinue
    }
    else {
        $OA | Set-OutlookAnywhere -ExternalHostname $OAExternal -DomainController $DomainController -WarningAction SilentlyContinue
    }
    Write-Host "Done!" -Foreground White
    Write-Host
    Write-Host "Be sure to install and enable the same trusted SSL certificate that's configured on $Server to complete configuration." -Foreground Red
}