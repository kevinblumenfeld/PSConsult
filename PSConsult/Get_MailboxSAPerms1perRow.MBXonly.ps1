Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -EA SilentlyContinue
Set-AdServerSettings -ViewEntireForest $true
$resultArray = @()
$Mailboxes = Get-Mailbox -ResultSize:Unlimited | Select DistinguishedName, UserPrincipalName, DisplayName, Alias,
@{n = "OU" ; e = {$_.Distinguishedname | ForEach-Object {($_ -split '(OU=)', 2)[1, 2] -join ''}}}

ForEach ($Mailbox in $Mailboxes) { 
    $SendAs = (Get-RecipientPermission $Mailbox.DistinguishedName | ? {$_.AccessRights -match "SendAs" -and $_.Trustee -ne "NT AUTHORITY\SELF" -and !$_.Trustee.tostring().startswith('S-1-5-21-')} | select -ExpandProperty trustee)
    if ($SendAs) {
        $SendAs | % {
            $SAHash = @{}
            $SAHash['Mailbox'] = ($Mailbox.DisplayName)
            $SAHash['SendAs'] = (Get-Mailbox $_).DisplayName
            $resultArray += [pscustomobject]$SAHash
        }
    }
}  
$resultArray 