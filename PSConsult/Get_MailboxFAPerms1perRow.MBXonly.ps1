Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -EA SilentlyContinue
Set-AdServerSettings -ViewEntireForest $true
$resultArray = @()
$Mailboxes = Get-Mailbox -ResultSize:Unlimited | Select DistinguishedName, UserPrincipalName, DisplayName, Alias,
@{n = "OU" ; e = {$_.Distinguishedname | ForEach-Object {($_ -split '(OU=)', 2)[1, 2] -join ''}}}

ForEach ($Mailbox in $Mailboxes) { 
    [string]$FullAccess = (Get-MailboxPermission $Mailbox.DistinguishedName | ? {$_.AccessRights -eq "FullAccess" -and !$_.IsInherited -and !$_.user.tostring().startswith('S-1-5-21-')} | Select -ExpandProperty User) -join "*"
    if ($fullaccess) {
        ($FullAccess).split("*") | % {
            $fullHash = @{}
            $fullHash['Mailbox'] = ($Mailbox.DisplayName)
            $fullHash['FullAccess'] = (Get-Mailbox $_).DisplayName
            $resultArray += [pscustomobject]$fullHash
        }
        
    }
    
}  
$resultArray 