# $Credentials = Get-Credential
# $MigrationEndpointOnPrem = New-MigrationEndpoint -ExchangeRemoteMove -Name OnpremEndpoint -Autodiscover -EmailAddress administrator@onprem.contoso.com -Credentials $Credentials
# $MigrationEndpointOnPrem = Get-MigrationEndpoint -Identity "Hybrid Migration Endpoint - webmail.contoso.com"

$MBSplat = @{
    Name                 = "2018_10_30_Pilot"
    SourceEndpoint       = "Hybrid Migration Endpoint - webmail.contoso.com"
    TargetDeliveryDomain = "contoso.mail.onmicrosoft.com"
    CSVData              = ([System.IO.File]::ReadAllBytes("C:\scripts\2018_10_30_Pilot.csv"))
    TimeZone             = "Eastern Standard Time"
    AutoStart            = $True
    BadItemLimit         = "40"
    LargeItemLimit       = "40"
    NotificationEmails   = "kevin.blumenfeld@contoso.com"
}

$OnboardingBatch = New-MigrationBatch @MBSplat


$notTrashSplat = @{
    Identity = 'CN=Recycle Bin Feature,CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=contoso,DC=com'
    Scope    = 'ForestOrConfigurationSet'
    Target   = 'contoso.com'
}

Enable-ADOptionalFeature @notTrashSplat


$identities = (Get-MigrationBatch).identity
ForEach ($identity in $identities) {
    Set-MigrationBatch -identity $identity -NotificationEmails 'foo@contoso.com' -BadItemLimit 100 -LargeItemLimit 100 -whatif
}