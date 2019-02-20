function Grant-SendOnBehalf {
    [CmdletBinding()]
    <#
    .SYNOPSIS
    Add SendOnBehalf to mailboxes when you using the UPN for -Identity

    .EXAMPLE
    Import-Csv .\AllPermissions.csv | Grant-SendOnBehalf

    #>
    Param 
    (
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias("Object")]
        $Mailbox,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias("ObjectPrimarySMTP")]
        $UPN,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias("GrantedPrimarySMTP")]
        $GrantedUPN,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        $Permission
    )
    Begin {
        $headerstring = ("UPN" + "," + "GrantedUPN")
        $errheaderstring = ("UPN" + "," + "GrantedUPN" + "," + "Error")
        Out-File -FilePath ./SuccessToSetSendOnBehalf.csv -InputObject $headerstring -Encoding UTF8 -append
        Out-File -FilePath ./FailedToSetSendOnBehalf.csv -InputObject $errheaderstring -Encoding UTF8 -append
    } 
    Process {
        $saved = $global:ErrorActionPreference
        $global:ErrorActionPreference = 'stop'
        if ($Permission -eq "SendOnBehalf") {
            Try {
                $gms = Set-Mailbox $UPN -GrantSendOnBehalfTo $GrantedUPN -Confirm:$false
                $UPN + "," + $GrantedUPN | Out-file ./SuccessToSetSendOnBehalf.csv -Encoding UTF8 -append
            }
            Catch {
                Write-Warning $_
                $UPN + "," + $GrantedUPN + "," + $_ | Out-file ./FailedToSetSendOnBehalf.csv -Encoding UTF8 -append
            }
            Finally {
                $global:ErrorActionPreference = $saved
            }
        }

    }
    End {
        
    }
}