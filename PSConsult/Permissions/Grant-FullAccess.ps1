function Grant-FullAccess {
    [CmdletBinding()]
    <#
    .SYNOPSIS
    Add full access to mailboxes when you using the UPN for -Identity

    .EXAMPLE
    Import-Csv .\AllPermissions.csv | Grant-FullAccess

    #>
    Param 
    (
        [parameter(ValueFromPipelineByPropertyName = $true)]
        $Mailbox,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        $UPN,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        $GrantedUPN,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        $Permission
    )
    Begin {
        $headerstring = ("UPN" + "," + "GrantedUPN")
        $errheaderstring = ("UPN" + "," + "GrantedUPN" + "," + "Error")
        Out-File -FilePath ./SuccessToSetFullAccess.csv -InputObject $headerstring -Encoding UTF8 -append
        Out-File -FilePath ./FailedToSetFullAccess.csv -InputObject $errheaderstring -Encoding UTF8 -append
    } 
    Process {
        $saved = $global:ErrorActionPreference
        $global:ErrorActionPreference = 'stop'
        if ($Permission -eq "FullAccess") {
            Try {
                $gms = Add-MailboxPermission -Identity $UPN -User $GrantedUPN -AccessRights FullAccess -InheritanceType All
                $UPN + "," + $GrantedUPN | Out-file ./SuccessToSetFullAccess.csv -Encoding UTF8 -append
            }
            Catch {
                Write-Warning $_
                $UPN + "," + $GrantedUPN + "," + $_ | Out-file ./FailedToSetFullAccess.csv -Encoding UTF8 -append
            }
            Finally {
                $global:ErrorActionPreference = $saved
            }
        }

    }
    End {
        
    }
}