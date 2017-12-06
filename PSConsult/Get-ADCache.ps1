Function Get-ADCache {
    $Script:ADHash = @{}
    $Script:ADHashDN = @{}
    Get-ADUser -filter 'proxyaddresses -ne "$null"' -server ($dc + ":3268") -SearchBase (Get-ADRootDSE).rootdomainnamingcontext -SearchScope Subtree -Properties displayname, canonicalname | 
        Select distinguishedname, displayname, userprincipalname, @{n = "logon"; e = {$_.canonicalname.split('.')[0] + "\" + $_.samaccountname}} | % {
        $Script:ADHash[$_.logon] = @{
            DisplayName = $_.DisplayName
            UPN         = $_.UserPrincipalName
        }
        $Script:ADHashDN[$_.DistinguishedName] = @{
            DisplayName = $_.DisplayName
            UPN         = $_.UserPrincipalName
            Logon       = $_.logon
        }
    }
}