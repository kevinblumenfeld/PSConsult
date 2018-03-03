function Grant-SendAsArray {
    [CmdletBinding()]
    <#
    .SYNOPSIS
    Add SendAs to mailboxes when you using the UPN for -Identity
    when the GrantedUPN column is a semicolon separated list

    .EXAMPLE
    Import-Csv .\AllPermissions.csv | Grant-SendAsArray

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
        if ($Permission -eq "SendAs") {
            ($GrantedUPN).split(";") | % {
                $saved = $global:ErrorActionPreference
                $global:ErrorActionPreference = 'stop'
                Try {
                    $Granted = $_
                    $gms = Add-RecipientPermission $UPN -AccessRights SendAs -Trustee $Granted -Confirm:$false
                    $UPN + "," + $Granted | Out-file ./SuccessToSetSendAs.csv -Encoding UTF8 -append
                }
                Catch {
                    Write-Warning $_
                    $UPN + "," + $Granted + "," + $_ | Out-file ./FailedToSetSendAs.csv -Encoding UTF8 -append
                }
                Finally {
                    $global:ErrorActionPreference = $saved
                }
            }
        }
    }
    End {
        
    }
}