function Get-PermissionsFA {
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
            [string]$FullAccess = (Get-MailboxPermission $Mailbox.DistinguishedName | ? {$_.AccessRights -eq "FullAccess" -and !$_.IsInherited -and !$_.user.tostring().startswith('S-1-5-21-')} | Select -ExpandProperty User) -join "*"
            if ($FullAccess) {
                ($FullAccess).split("*") | % {
                    $ADType = (Get-ADAccountType -name $_)
                    if ($ADType -eq 'User') {
                        Get-Permitted -Display $Mailbox.DisplayName -User $_
                    }
                    if ($ADType -eq 'Group') {
                        Get-Group $user | select -expandproperty members | % {
                            Get-GroupPermitted -Display $Mailbox.DisplayName -Group $_
                        }
                    }
                } 
            } 
        }
    }
    End {
        
    }
}

function Get-Permitted {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [string]$Display,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [string]$user
    )
    Begin {
        
    }
    Process {
        $resultArray = @()
        $FAHash = @{}
        $FAHash['FullAccess'] = ((Get-Mailbox $user).DisplayName)
        $FAHash['Mailbox'] = $Display
        $resultArray += [psCustomObject]$FAHash
        $resultArray
    }
    End {

    }
}
function Get-GroupPermitted {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [string]$Display,
    
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [string]$Group
    )
    Begin {

    }
    Process {
        $GroupMembers = (Get-Group $Group | select -expandproperty members) -join "*" 
        if ($GroupMembers) {
            ($GroupMembers).split("*") | % {
                $ADType = (Get-ADAccountType -name $_)
                if ($ADType -eq 'User') {
                    Get-Permitted -Display $Mailbox.DisplayName -User $_
                }
                if ($ADType -eq 'Group') {
                    Get-Group $user | select -expandproperty members | % {
                        Get-GroupPermitted -Display $Mailbox.DisplayName -Group $_
                    }
                }
            }
        }
    }
    End {
        
    }
}


function Get-ADAccountType {
    param (
        [string] $Name
    )
    if ($Name.Contains('\')) {
        $Domain = $Name.Split('\')[0]
        $Name = $Name.Split('\')[1]
    }
    $strFilter = "(&(objectCategory=*)(samAccountName=$Name))"
    if ($Domain) {
        $objSearcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]"LDAP://$Domain")
    }
    Else {
        $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
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