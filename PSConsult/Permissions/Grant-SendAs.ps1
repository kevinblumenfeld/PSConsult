function Grant-SendAs {
    [CmdletBinding()]
    <#
    .SYNOPSIS
    Add SendAs to mailboxes when you using the UPN for -Identity

    .EXAMPLE
    Import-Csv .\AllPermissions.csv | Grant-SendAs

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
        Out-File -FilePath ./SuccessToSetSendAs.csv -InputObject $headerstring -Encoding UTF8 -append
        Out-File -FilePath ./FailedToSetSendAs.csv -InputObject $errheaderstring -Encoding UTF8 -append
    } 
    Process {
        $saved = $global:ErrorActionPreference
        $global:ErrorActionPreference = 'stop'
        if ($Permission -eq "SendAs") {
            Try {
                $gms = Add-RecipientPermission $UPN -AccessRights SendAs -Trustee $GrantedUPN
                $UPN + "," + $GrantedUPN | Out-file ./SuccessToSetSendAs.csv -Encoding UTF8 -append
            }
            Catch {
                Write-Warning $_
                $UPN + "," + $GrantedUPN + "," + $_ | Out-file ./FailedToSetSendAs.csv -Encoding UTF8 -append
            }
            Finally {
                $global:ErrorActionPreference = $saved
            }
        }

    }
    End {
        
    }
}