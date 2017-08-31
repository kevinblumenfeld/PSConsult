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
                    $FAHash = @{}
                    $FAHash['Mailbox'] = ($Mailbox.DisplayName)
                    $Permitted = (Get-Permitted -feed $_)
                    $FAHash['FullAccess'] = $Permitted
                    $resultArray += [psCustomObject]$FAHash
                } 
            } 
        }
    }
    End {
        $resultArray
    }
}

function Get-Permitted {
    [CmdletBinding()]
    Param 
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [string]$feed
    )
    Begin {

    }
    Process {
        Try {
            [string]$FullAccess = ((Get-Mailbox $feed -ErrorAction Stop).DisplayName)

        }
        Catch {
            [string]$FullAccess = Get-GroupPermitted $feed -ErrorAction Stop
        }  
    }
    End {
        $FullAccess
    }
}

function Get-GroupPermitted {
    [CmdletBinding()]
    Param 
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [string]$feed
    )
    Begin {

    }
    Process {
        Try {
            [string]$groupMembers = (Get-Group $feed -ErrorAction Stop | select -expandproperty members) -join "*"
            if ($groupMembers) {
                ($groupMembers).split("*") | % {
                    Get-Permitted -feed $_
                }
            }
        }
            Catch {
            }   
        }
        End {
            $FullAccess
        }
    }