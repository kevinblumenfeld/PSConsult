function Switch-HybridServer {
    <#
    .SYNOPSIS
    With two hybrid servers in the same forest, one simply for DR, this script allows user or workflow to quickly toggle between the two.

    .DESCRIPTION
    With two hybrid servers in the same forest, one simply for DR, this script allows user or workflow to quickly toggle between the two.

    .EXAMPLE
    Switch-HybridServer -Site NYC

    .EXAMPLE
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
        Identity = 'Outbound to 8d277b2c-1234-1234-abb8-280e45a88488'
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
    Write-Host "Seting Hybrid Configuration`n" -foregroundcolor "magenta" -backgroundcolor "white"
    Set-HybridConfiguration @OnPremHybridConfigSplat
    Write-Host "Setting On Premises Send Connnector`n" -foregroundcolor "magenta" -backgroundcolor "white"
    Set-SendConnector @OnPremSendConnectorSplat
    Write-Host "Setting Exchange Online Outbound Connector`n" -foregroundcolor "magenta" -backgroundcolor "white"
    Set-EXOOutboundConnector @CloudConnectorSplat

    # Get output of cmdlets
    Write-Host "`n"
    Write-Host "Below are now the new settings" -foregroundcolor "blue" -backgroundcolor "white"
    Write-Host "`n"
    Write-Host "(ONPREM) Get-HybridConfiguration" -foregroundcolor "blue" -backgroundcolor "white"
    Get-HybridConfiguration | FL
    Write-Host "(ONPREM) Get-SendConnector" -foregroundcolor "blue" -backgroundcolor "white"
    Get-SendConnector -identity 'Outbound to Office 365' | FL
    Write-Host "(Exchange Online) Get-EXOOutboundConnector" -foregroundcolor "blue" -backgroundcolor "white"
    Get-EXOOutboundConnector -identity 'Outbound to 8d277b2c-1234-1234-abb8-280e45a88488' | FL
    Write-Host "END `n"  -foregroundcolor "blue" -backgroundcolor "white"

}
