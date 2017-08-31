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
            [string]$SendOnBehalf = (Get-Mailbox $Mailbox.DistinguishedName | select-object -ExpandProperty GrantSendOnBehalfTo) -join "*"
            if ($SendOnBehalf) {
                ($SendOnBehalf).split("*") | % {
                    $SOBHash = @{}
                    $SOBHash['Mailbox'] = ($Mailbox.DisplayName)
                    $Permitted = (Get-Permitted -feed $_)
                    $SOBHash['SendOnBehalf'] = $Permitted
                    $resultArray += [psCustomObject]$SOBHash
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
            [string]$SendOnBehalf = ((Get-Mailbox $feed -ErrorAction Stop).DisplayName)

        }
        Catch {
            [string]$SendOnBehalf = Get-GroupPermitted $feed -ErrorAction Stop
        }
        # $SOBHash['SendOnBehalf'] = (Get-Mailbox $_).DisplayName 
        # $isGroup = Get-Group 'GALLS\ACE mailbox users' | select -expandproperty members | % {(Get-Mailbox $_).displayname}
        # $SOBHash['SendOnBehalf'] = (Get-Group $_).DisplayName      
    }
    End {
        $SendOnBehalf
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
            [string]$SendOnBehalf = Get-Group $feed -ErrorAction Stop | select -expandproperty members | % {
                Get-Permitted -feed $_
            }
        }
        Catch {
        }   
    }
    End {
      $SendOnBehalf
    }
}