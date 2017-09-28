Get-OutlookAnywhere -Server "SV001-HYEXCH01" | Set-OutlookAnywhere -ExternalHostname webmail.contoso.com -InternalHostname webmail.contoso.com -ExternalClientsRequireSsl $true -InternalClientsRequireSsl $true -DefaultAuthenticationMethod NTLM -SSLOffloading $false

Get-OwaVirtualDirectory -server "SV001-HYEXCH01" | Set-OwaVirtualDirectory -ExternalUrl https://webmail.contoso.com/owa -InternalUrl https://webmail.contoso.com/owa

Get-EcpVirtualDirectory -server "SV001-HYEXCH01" | Set-EcpVirtualDirectory -ExternalUrl https://webmail.contoso.com/ecp -InternalUrl https://webmail.contoso.com/ecp

Get-ActiveSyncVirtualDirectory -server "SV001-HYEXCH01" | Set-ActiveSyncVirtualDirectory -ExternalUrl https://webmail.contoso.com/Microsoft-Server-ActiveSync -InternalUrl https://webmail.contoso.com/Microsoft-Server-ActiveSync

Get-WebServicesVirtualDirectory -server "SV001-HYEXCH01" | Set-WebServicesVirtualDirectory -ExternalUrl https://webmail.contoso.com/EWS/Exchange.asmx -InternalUrl https://webmail.contoso.com/EWS/Exchange.asmx # -BasicAuthentication $true
# If needing to migrate cross forest or if this is a hybrid server: Set-WebServicesVirtualDirectory -BasicAuthentication $true

Get-OabVirtualDirectory -server "SV001-HYEXCH01" | Set-OabVirtualDirectory -ExternalUrl https://webmail.contoso.com/OAB -InternalUrl https://webmail.contoso.com/OAB

Get-ClientAccessServer -Identity "SV001-HYEXCH01" | Set-ClientAccessServer -AutoDiscoverServiceInternalUri https://webmail.contoso.com/Autodiscover/Autodiscover.xml

Get-MapiVirtualDirectory -server "SV001-HYEXCH01" | Set-MapiVirtualDirectory -ExternalUrl https://webmail.contoso.com/MAPI -InternalUrl https://webmail.contoso.com/MAPI


Import-ExchangeCertificate -FileData ([Byte[]]$(Get-Content -Path "C:\scripts\contosoCertExchange.pfx" -Encoding byte -ReadCount 0)) -Password:(Get-Credential).password

Enable-ExchangeCertificate -Thumbprint XXXXXXXXXXXXXXX -Server "SV001-HYEXCH01" -Services POP,IMAP,SMTP,IIS

 

 
