
$cas = Get-ClientAccessServer | Select-Object name
$cas | ForEach-Object {
    Get-WebServicesVirtualDirectory -Server $_.name |
        Set-WebServicesVirtualDirectory -MRSProxyEnabled:$true -BasicAuthentication:$true -ExternalUrl "https://webmail.contoso.com/EWS/Exchange.asmx"
}
