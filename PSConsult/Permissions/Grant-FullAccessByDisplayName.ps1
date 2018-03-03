function Grant-FullAccessByDisplayName {
    [CmdletBinding()]
    <#
    .SYNOPSIS
    Add full access to mailboxes when you using the display name for -Identity

    .EXAMPLE
    Import-Csv .\Full_Access.csv | Grant-FullAccessByDisplayName

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
        $headerstring = ("Mailbox" + "," + "GrantedUPN")
        $errheaderstring = ("Mailbox" + "," + "GrantedUPN" + "," + "Error")
        Out-File -FilePath ./SuccessToSetFullAccess.csv -InputObject $headerstring -Encoding UTF8 -append
        Out-File -FilePath ./FailedToSetFullAccess.csv -InputObject $errheaderstring -Encoding UTF8 -append
    } 
    Process {
        $saved = $global:ErrorActionPreference
        $global:ErrorActionPreference = 'stop'
        if ($Permission -eq "FullAccess") {
            Try {
                $gms = Add-MailboxPermission -Identity $Mailbox -User $GrantedUPN -AccessRights FullAccess -InheritanceType All
                $Mailbox + "," + $GrantedUPN | Out-file ./SuccessToSetFullAccess.csv -Encoding UTF8 -append
            }
            Catch {
                Write-Warning $_
                $Mailbox + "," + $GrantedUPN + "," + $_ | Out-file ./FailedToSetFullAccess.csv -Encoding UTF8 -append
            }
            Finally {
                $global:ErrorActionPreference = $saved
            }
        }

    }
    End {
        
    }
}