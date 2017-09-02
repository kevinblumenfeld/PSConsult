function Get-MbxPermissions {
    [CmdletBinding()]
    Param 
    (

    )
    Begin {

    }
    Process {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -EA SilentlyContinue
        Set-AdServerSettings -ViewEntireForest $true
        $resultArray = @()
        $Mailboxes = Get-Mailbox -ResultSize:Unlimited | Select DistinguishedName, UserPrincipalName, DisplayName, Alias,
        @{n = "OU" ; e = {$_.Distinguishedname | ForEach-Object {($_ -split '(OU=)', 2)[1, 2] -join ''}}}
        
        ForEach ($Mailbox in $Mailboxes) { 
            [string]$FullAccess = (Get-MailboxPermission $Mailbox.DistinguishedName | ? {
                    $_.AccessRights -eq "FullAccess" -and !$_.IsInherited -and !$_.user.tostring().startswith('S-1-5-21-')
                } | Select -ExpandProperty User) -join "*"
            if ($FullAccess) {
                ($FullAccess).split("*") | % {
                    $ADType = (Get-ADAccountType -name $_ -FA)
                    if ($ADType -eq 'User') {
                        $FAHash = @{}
                        $FAHash['Mailbox'] = ($Mailbox.DisplayName)
                        try {
                            $FAHash['FullAccess'] = ((Get-Mailbox $_ -ErrorAction SilentlyContinue).DisplayName)
                            if ($FAHash.FullAccess) {
                                $resultArray += [psCustomObject]$FAHash
                            }
                        }
                        Catch {

                        }
                    }
                    if ($ADType -eq 'Group') {
                        if ($_.Contains('\')) {
                            $Name = $_.Split('\')[1]
                        }
                        Get-ADGroupMember $Name -Recursive | % {
                            $FAHash = @{}
                            $FAHash['Mailbox'] = ($Mailbox.DisplayName)
                            try {
                                $FAHash['FullAccess'] = ((Get-Mailbox $_.distinguishedName -ErrorAction SilentlyContinue).DisplayName)
                                if ($FAHash.FullAccess) {
                                    $resultArray += [psCustomObject]$FAHash
                                }
                            }
                            Catch {

                            }
                        }
                    }
                } 
            } 
        }
    }
    End {
        $resultArray | Sort -Unique -Property Mailbox, FullAccess
    }
}

function Get-PermissionsSA {
    [CmdletBinding()]
    Param 
    (

    )
    Begin {

    }
    Process {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -EA SilentlyContinue
        Set-AdServerSettings -ViewEntireForest $true
        $resultArray = @()
        $Mailboxes = Get-Mailbox -ResultSize:Unlimited | Select DistinguishedName, UserPrincipalName, DisplayName, Alias,
        @{n = "OU" ; e = {$_.Distinguishedname | ForEach-Object {($_ -split '(OU=)', 2)[1, 2] -join ''}}}
        
        ForEach ($Mailbox in $Mailboxes) { 
            $SendAs = (Get-RecipientPermission $Mailbox.DistinguishedName | ? {$_.AccessRights -match "SendAs" -and $_.Trustee -ne "NT AUTHORITY\SELF" -and !$_.Trustee.tostring().startswith('S-1-5-21-')} | select -ExpandProperty trustee)
            if ($SendAs) {
                ($SendAs).split("*") | % {
                    $DN = ConvertTo-DistinguishedName -CanonicalName $_
                    $ADType = (Get-ADAccountType -name $DN -SA)
                    if ($ADType -eq 'User') {
                        $SAHash = @{}
                        $SAHash['Mailbox'] = ($Mailbox.DisplayName)
                        try {
                            $SAHash['SendAs'] = ((Get-Mailbox $_ -ErrorAction SilentlyContinue).DisplayName)
                            if ($SAHash.SendAs) {
                                $resultArray += [psCustomObject]$SAHash
                            }
                        }
                        Catch {

                        }
                    }
                    if ($ADType -eq 'Group') {
                        if ($_.Contains('\')) {
                            $Name = $_.Split('\')[1]
                        }
                        Get-ADGroupMember $Name -Recursive | % {
                            $SAHash = @{}
                            $SAHash['Mailbox'] = ($Mailbox.DisplayName)
                            try {
                                $SAHash['SendAs'] = ((Get-Mailbox $_.distinguishedName -ErrorAction SilentlyContinue).DisplayName)
                                if ($SAHash.SendAs) {
                                    $resultArray += [psCustomObject]$SAHash
                                }
                            }
                            Catch {

                            }
                        }
                    }
                } 
            } 
        }
    }
    End {
        $resultArray | Sort -Unique -Property Mailbox, SendAs
    }
}

function Get-PermissionsSOB {
    [CmdletBinding()]
    Param 
    (

    )
    Begin {

    }
    Process {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -EA SilentlyContinue
        Set-AdServerSettings -ViewEntireForest $true
        $resultArray = @()
        $Mailboxes = Get-Mailbox -ResultSize:Unlimited | Select DistinguishedName, UserPrincipalName, DisplayName, Alias,
        @{n = "OU" ; e = {$_.Distinguishedname | ForEach-Object {($_ -split '(OU=)', 2)[1, 2] -join ''}}}
        
        ForEach ($Mailbox in $Mailboxes) { 
            [string]$SendOnBehalf = (Get-Mailbox $Mailbox.DistinguishedName | select-object -ExpandProperty GrantSendOnBehalfTo).distinguishedName -join "*"
            if ($SendOnBehalf) {
                ($SendOnBehalf).split("*") | % {
                    $ADType = (Get-ADAccountType -name $_ -SOB)
                    if ($ADType -eq 'User') {
                        $SOBHash = @{}
                        $SOBHash['Mailbox'] = ($Mailbox.DisplayName)
                        try {
                            $SOBHash['SendOnBehalf'] = ((Get-Mailbox $_ -ErrorAction SilentlyContinue).DisplayName)
                            if ($SOBHash.SendOnBehalf) {
                                $resultArray += [psCustomObject]$SOBHash
                            }
                        }
                        Catch {

                        }
                    }
                    if ($ADType -eq 'Group') {
                        if ($_.Contains('\')) {
                            $Name = $_.Split('\')[1]
                        }
                        Get-ADGroupMember $Name -Recursive | % {
                            $SOBHash = @{}
                            $SOBHash['Mailbox'] = ($Mailbox.DisplayName)
                            try {
                                $SOBHash['SendOnBehalf'] = ((Get-Mailbox $_.distinguishedName -ErrorAction SilentlyContinue).DisplayName)
                                if ($SOBHash.SendOnBehalf) {
                                    $resultArray += [psCustomObject]$SOBHash
                                }
                            }
                            Catch {

                            }
                        }
                    }
                } 
            } 
        }
    }
    End {
        $resultArray | Sort -Unique -Property Mailbox, SendOnBehalf
    }
}
function Get-ADAccountType {
    param (
        [string] $Name,
        [switch] $FA,
        [switch] $SOB,
        [switch] $SA
    )
    if ($FA) {
        if ($Name.Contains('\')) {
            $Domain = $Name.Split('\')[0]
            $Name = $Name.Split('\')[1]
            $strFilter = "(&(objectCategory=*)(samAccountName=$Name))"
            if ($Domain) {
                $objSearcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]"LDAP://$Domain")
            }
            Else {
                $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
            }
        }
        elseif ($Name.Contains('/')) {
            $Domain = $Name.Split("/")[0]
            $Name = $Name.Split("/")[$Name.Split("/").count - 1]
            $strFilter = "(&(objectCategory=*)(distinguishedname=$Name))"
            $Domain = (($name -Split '(,DC=)', 2)[2]).Replace(',DC=', ".")
            $objSearcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]"LDAP://$Domain")
        }
    }
    if ($SA) {
        $strFilter = "(&(objectCategory=*)(distinguishedname=$Name))"
        $Domain = (($name -Split '(,DC=)', 2)[2]).Replace(',DC=', ".")
        $objSearcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]"LDAP://$Domain")
    }
    if ($SOB) {
        $strFilter = "(&(objectCategory=*)(distinguishedname=$Name))"
        $Domain = (($name -Split '(,DC=)', 2)[2]).Replace(',DC=', ".")
        $objSearcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]"LDAP://$Domain")
    }

    $objSearcher.Filter = $strFilter
    try {
        $objPath = $objSearcher.FindOne()
        $objAccount = $objPath.GetDirectoryEntry()
        if ($objAccount.Properties.objectclass[1] -eq 'Group') {
            $ObjectType = 'Group'
        }
        Elseif ($objAccount.Properties.objectclass[3] -eq 'User') {
            $ObjectType = 'User'
        }
    }
    catch {
        Write-Warning "no such object: $Name"
    }
    $ObjectType
}

<#
.Synopsis
   Converts an AD canonical name into a distinguished name.
.DESCRIPTION
   Converts an AD canonical name into a distinguished name, and handles
   the case where USERS, DOMAINCONTROLLERS, COMPUTERS are containers not OUs
   and need to be CN= instead of OU=
.EXAMPLE
   PS C:\> ConvertTo-DistinguishedName "corp.ad.contoso.com/CORP/Place/on02"
   
   CN=on02,OU=Place,OU=CORP,DC=corp,DC=ad,DC=contoso,DC=com
 #>
function ConvertTo-DistinguishedName {
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # e.g. 'corp.ad.contoso.com/CORP/USERS/Person'
        [Parameter(Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        # must be at least a.b/w - no single character domain or missing path
        [ValidatePattern('^.+\..+/.+$')]
        $CanonicalName
    )
 
    $distinguishedNameParts = New-Object -TypeName System.Collections.ArrayList
 
    # separate into domain part (a.b.c.d) and path+user part (/x/y/z/Person)
    [string]$domain, [array]$remainder = $CanonicalName.Split('/')
     
    #
    # domain:  'a.b.c.d' -> 'DC=a,DC=b,DC=c,DC=d'
    #
    $null = $distinguishedNameParts.AddRange($domain.Split('.').ForEach( {"DC=$_"}))
 
    $specialContainers = @('Users', 'Computers')
 
    0..($remainder.Count - 1) | ForEach-Object {
 
        #
        # handle domain.com/{first} which might be
        #   OU={first}
        # or a special container 
        #   CN={first}
        #
        # and handle /Person at the end, which is CN=
        # all other parts are OU=
        #
        $template = if ((($_ -eq 0) -and ($specialContainers -contains $remainder[$_])) -or ($_ -eq ($remainder.Count - 1))) {
            'CN={0}'
        }
        else {
            'OU={0}'
        }
 
        $null = $distinguishedNameParts.Insert(0, ($template -f $remainder[$_]))
     
    }
 
    $distinguishedNameParts -join ','
 
}
 
