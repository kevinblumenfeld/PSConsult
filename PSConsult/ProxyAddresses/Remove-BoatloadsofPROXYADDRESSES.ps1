##################

Get-MsolUser -UserPrincipalName "NoProxy@contoso.com" |
    Select firstname, lastname, userprincipalname, @(
    @{n = 'proxyaddresses'; e = {[string]::join('|', [string[]]$_.proxyaddresses)}}
)


##################

$Ou = get-content C:\scripts\OU.txt
$AD = import-csv C:\Scripts\RawADUsersDISABLED.csv

$output = foreach ($CurAD in $AD) {
    $GetInt = $CurAD.CanonicalName.LastIndexOf('/')
    $CN = $CurAD.CanonicalName.substring(0, $GetInt)
    $CurAD | where {$CN -in $Ou}
}

##################
##################

$Pf = 'foo@apple.com'

$Domain = @(
    'pear.com', 'banana.com', 'parsley.com', 'beer.com', 'strawberry.com', 'luke.com'
    'orange.com', 'star.com', 'contoso.mail.onmicrosoft.com'
)

$DomainNoMS = @(
    'pear.com', 'banana.com', 'parsley.com', 'beer.com', 'strawberry.com', 'luke.com'
    'orange.com', 'star.com'
)

$Smtp = (Get-MailPublicFolder -Identity $Pf | Select -ExpandProperty EmailAddresses |
        Where-Object {
        ($_ -split "@")[1] -in $Domain
    })

$Primary = $Smtp | Where-Object {
    ($_ -clike "SMTP:*") -and
    ($_ -split "@")[1] -in $DomainNoMS
}

$OnMicrosoft = ($Smtp | Where-Object {
        -not ($_ -clike "SMTP:*") -and
        ($_ -split "@")[1] -match 'contoso.mail.onmicrosoft.com'
    }) -replace 'SMTP:', ''

$Remove = $Smtp.tolower() | Where-Object {
    -not ($_ -match 'contoso.mail.onmicrosoft.com')
}

if ($Primary -and $OnMicrosoft) {
    Set-MailPublicFolder -Identity $Pf -PrimarySmtpAddress $OnMicrosoft
}

if ($Remove) {
    Set-MailPublicFolder -Identity $Pf -EmailAddresses @{ Remove = $Remove }
}

##################
##################


Get-Recipient -filter "recipienttypedetails -ne 'PublicFolder'" | Select displayname, recipienttypedetails, @{
    n = 'capabilities'
    e = {$_.Capabilies | where {$_ -ne 'masteredonpremises'} }
}

$DomainNoMS = @(
    'apple.com', 'pear.com', 'grape.com', 'pineapple.com', 'rose.com', 'strawberry.com'
    'lemon.com', 'pea.com', 'rice.com'
)

$All = Get-Recipient -ResultSize unlimited -filter "recipienttypedetails -ne 'PublicFolder' -and
    (emailaddresses -like '*@apple.com' -or
    emailaddresses -like '*@pear.com' -or
    emailaddresses -like '*@grape.com' -or
    emailaddresses -like '*@pineapple.com' -or
    emailaddresses -like '*@rose.com' -or
    emailaddresses -like '*@strawberry.com' -or
    emailaddresses -like '*@lemon.com' -or
    emailaddresses -like '*@pea.com' -or
    emailaddresses -like '*@rice.com')" | Select DisplayName, RecipientTypeDetails, Capabilities,
@{
    Name       = 'EmailAddresses'
    Expression = {[string]::join('|', [string[]]$_.EmailAddresses)}
}

$ALL | Where-Object { -not ($_.Capabilities -match "masteredonpremise") }


$DomainNoMS = @(
    'apple.com', 'pear.com', 'grape.com', 'pineapple.com', 'rose.com', 'strawberry.com'
    'lemon.com', 'pea.com', 'rice.com'
)

$UPN = Get-MsolUser -All | Where-Object {
    ($_.UserPrincipalName -split '@')[1] -in $DomainNoMS -and -not $_.ImmutableID
}| Select DisplayName, UserPrincipalName, ImmutableId



$Loop = $true
while ($Loop) {
    "TRUE"
    $Loop = Read-Host -Prompt "Go again? (y/n)"
    If ($Loop -eq "n") {
        "FALSE"
        $Loop = $false
    }
}



Get-MsolUser -UserPrincipalName "NoProxy@contoso.com" |
    Select firstname, lastname, userprincipalname, @(
    @{n = 'proxyaddresses'; e = {[string]::join('|', [string[]]$_.proxyaddresses)}}
)




$OG = Get-SendConnector | Select @(
    'Name'
    'DNSRoutingEnabled'
    'Enabled'
    @{
        n = 'SourceServers'
        e = {[string]::join('|', [string[]]$_.SourceTransportServers)}
    }
    @{
        n = 'SmartHosts'
        e = {[string]::join('|', [string[]]$_.SmartHosts)}
    }
)

$OG | OGV