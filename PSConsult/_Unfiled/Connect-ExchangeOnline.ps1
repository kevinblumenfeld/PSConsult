function Switch-HybridServer {
    <#
    .SYNOPSIS
    With two hybrid servers in the same forest, one simply for DR, this script allows user or workflow to quickly toggle between the two.

    .DESCRIPTION
    With two hybrid servers in the same forest, one simply for DR, this script allows user or workflow to quickly toggle between the two.

    .EXAMPLE
    . .\Switch-HybridServer
    Switch-HybridServer -Site NYC

    .EXAMPLE
    . .\Switch-HybridServer
    Switch-HybridServer -Site Miami

    .NOTES
    Run this from an Exchange 2016 Hybrid Server within the Exchange Management Shell (EMS)

    #>
    Param (
        [Parameter(Mandatory = $true)]
        [validateset('Miami', 'NYC')]
        $Site
    )

    Start-Transcript

    Try {
        Get-EXOAcceptedDomain -erroraction Stop | Out-Null
        Write-Host "You are already connected to Exchange Online with EXO Prefix"
    }
    Catch {
        Write-Host "You need to first connect to Exchange Online"
        Write-Host "We will now attempt to connect you to Exchange Online"
        Write-Host "You will be prompted to enter your Office 365 Global Admin credentials"
        Write-Host "Please enter both Username and Password"
        Write-Host "Once connected, all Exchange Online commands will need to be prefixed with EXO"
        Write-Host "For example Get-Mailbox will be Get-EXOMailbox"
        Connect-ExchangeOnline
    }

    $OnPremHybridConfigSplat = @{

    }

    $OnPremSendConnectorSplat = @{
        Identity = 'Outbound to Office 365'
    }

    $CloudConnectorSplat = @{
        Identity = 'Outbound to 8d277b2c-a459-1234-abb8-280e45a88488'
    }
    switch ( $Site ) {
        Miami {
            $OnPremHybridConfigSplat['OnPremisesSmartHost'] = 'hybrid1.contoso.com'
            $OnPremHybridConfigSplat['SendingTransportServers'] = 'MIA-HYBRID2'
            $OnPremHybridConfigSplat['ReceivingTransportServers'] = 'MIA-HYBRID2'
            $CloudConnectorSplat['SmartHosts'] = 'hybrid1.contoso.com'
            $OnPremSendConnectorSplat['SourceTransportServers'] = 'MIA-HYBRID2'
        }
        NYC {
            $OnPremHybridConfigSplat['OnPremisesSmartHost'] = 'hybrid.contoso.com'
            $OnPremHybridConfigSplat['SendingTransportServers'] = 'NYC-HYBRID1'
            $OnPremHybridConfigSplat['ReceivingTransportServers'] = 'NYC-HYBRID1'
            $CloudConnectorSplat['SmartHosts'] = 'hybrid.contoso.com'
            $OnPremSendConnectorSplat['SourceTransportServers'] = 'NYC-HYBRID1'
        }
    }
    # Set Values
    Write-Host "`n"
    Write-Host "Seting Hybrid Configuration`n" -foregroundNYCr "magenta" -backgroundNYCr "white"
    Set-HybridConfiguration @OnPremHybridConfigSplat
    Write-Host "Setting On Premises Send Connnector`n" -foregroundNYCr "magenta" -backgroundNYCr "white"
    Set-SendConnector @OnPremSendConnectorSplat
    Write-Host "Setting Exchange Online Outbound Connector`n" -foregroundNYCr "magenta" -backgroundNYCr "white"
    Set-EXOOutboundConnector @CloudConnectorSplat

    # Get verMIAe output of cmdlets
    Write-Host "`n"
    Write-Host "Below are now the new settings" -foregroundNYCr "blue" -backgroundNYCr "white"
    Write-Host "`n"
    Write-Host "(ONPREM) Get-HybridConfiguration" -foregroundNYCr "blue" -backgroundNYCr "white"
    Get-HybridConfiguration | FL
    Write-Host "(ONPREM) Get-SendConnector" -foregroundNYCr "blue" -backgroundNYCr "white"
    Get-SendConnector -identity 'Outbound to Office 365' | FL
    Write-Host "(Exchange Online) Get-EXOOutboundConnector" -foregroundNYCr "blue" -backgroundNYCr "white"
    Get-EXOOutboundConnector -identity 'Outbound to 8d277b2c-a459-4914-abb8-280e45a88488' | FL
    Write-Host "END `n"  -foregroundNYCr "blue" -backgroundNYCr "white"

}

function Connect-ExchangeOnline {
    <#
    .SYNOPSIS
    Connects to Exchange Online prefixing all Exchange Online commands with EXO

    .DESCRIPTION
    Connects to Exchange Online prefixing all Exchange Online commands with EXO

    .EXAMPLE
    Connect-ExchangeOnline

    .NOTES
    General notes
    #>

    $UserCredential = Get-Credential -Message "Enter 365 Global Admin Credentials"

    $ConnectSplat = @{
        ConfigurationName = 'Microsoft.Exchange'
        ConnectionUri     = 'https://outlook.office365.com/powershell-liveid/'
        Credential        = $UserCredential
        Authentication    = 'Basic'
        AllowRedirection  = $true
    }

    $Session = New-PSSession @ConnectSplat
    Import-PSSession $Session –Prefix "EXO"

}
