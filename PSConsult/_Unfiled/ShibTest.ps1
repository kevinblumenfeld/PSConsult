


$dom = "contosotest.online"
$fedBrandName = "contosoTest"
$url = "https://login.contoso.edu/idp/profile/SAML2/POST/SSO"
$uri = "https://login.contoso.edu/idp/shibboleth"
$logoutUrl = "https://login.contoso.edu/idp/profile/Logout"
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("C:\scripts\idp-signing.crt")
$certData = [system.convert]::tobase64string($cert.rawdata)

$Splat = @{
    DomainName                      = $dom
    federationBrandName             = $FedBrandName
    Authentication                  = 'Federated'
    PassiveLogOnUri                 = $url
    SigningCertificate              = $certData
    IssuerUri                       = $uri
    LogOffUri                       = $logoutUrl
    PreferredAuthenticationProtocol = 'SAMLP'
}

Set-MsolDomainAuthentication @Splat





