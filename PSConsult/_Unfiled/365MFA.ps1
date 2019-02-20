
# To view methods and default method

$Properties = @('UserPrincipalName', 'DisplayName', 'Country', 'Department', 'Title', '*phone*')
$Calculated = @(
    @{n = "MFA_State"; e = {($_.StrongAuthenticationRequirements).State}},
    @{n = "DefaultMethod"; e = {($_.StrongAuthenticationMethods).Where( {$_.IsDefault} ).MethodType}},
    @{n = "Methods"; e = {(($_.StrongAuthenticationMethods).MethodType) -join ";"}},
    @{n = "MethodChoice"; e = {(($_.StrongAuthenticationMethods).IsDefault) -join ";"}},
    @{n = "Auth_AlternatePhoneNumber"; e = {($_.StrongAuthenticationUserDetails).AlternativePhoneNumber}},
    @{n = "Auth_Email"; e = {($_.StrongAuthenticationUserDetails).Email}},
    @{n = "Auth_OldPin"; e = {($_.StrongAuthenticationUserDetails).OldPin}},
    @{n = "Auth_PhoneNumber"; e = {($_.StrongAuthenticationUserDetails).PhoneNumber}},
    @{n = "Auth_Pin"; e = {($_.StrongAuthenticationUserDetails).Pin}}
)

Get-MsolUser -All | Select ($Properties + $Calculated)

# Adding App wouldn't necessarily work (user has to use QR Code to register the app)
# but you have to build the object with all methods that were originally chosen by user during setup
# You could add phone verification methods if the MobilePhone attribute is populated or you populate it for the user:
# Set-MsolUser -UserPrincipalName $UPN -MobilePhone 555-555-1212

$UPN = "Kevin3@contoso.com"

$m1 = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationMethod
$m1.IsDefault = $true
$m1.MethodType = "PhoneAppNotification"

$m2 = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationMethod
$m2.IsDefault = $false
$m2.MethodType = "PhoneAppOTP"

$m3 = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationMethod
$m3.IsDefault = $false
$m3.MethodType = "OneWaySMS"

$m4 = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationMethod
$m4.IsDefault = $false
$m4.MethodType = "TwoWayVoiceMobile"

$methods = @($m1, $m2, $m3, $m4)

Set-MsolUser -UserPrincipalName $UPN -StrongAuthenticationMethods $methods



Start-ADSyncSyncCycle -PolicyType Delta