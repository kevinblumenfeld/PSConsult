function Set-MailNickNameUPNSuffix {
    <#

    .SYNOPSIS


    .EXAMPLE


    #>
    [CmdletBinding()]
    Param 
    (

    )
    Begin {
        Try {
            import-module activedirectory -ErrorAction Stop
        }
        Catch {
            Write-Host "This module depends on the ActiveDirectory module."
            Write-Host "Please download and install from https://www.microsoft.com/en-us/download/details.aspx?id=45520"
            throw
        }
    }
    Process {
        Try {
            $OUs = (Get-OrganizationalUnit -SearchText "Users" -IncludeContainers:$false | ? {
                    $_.distinguishedname -like "OU=Users*" -or 
                    ($_.distinguishedname -notlike "*privileged*" -and 
                        $_.distinguishedname -notlike "*adonly*") -and
                    $_.distinguishedname -like "*DC=contoso,DC=corp,DC=com"
                }).DistinguishedName
            foreach ($OU in $OUs) {
                Get-RemoteMailbox  -OnPremisesOrganizationalUnit $OU -ResultSize 4 | % {
                    write-host "DN:   " $_.distinguishedname
                    Set-RemoteMailbox  -identity $_.distinguishedname -EmailAddressPolicyEnabled:$true -erroraction stop -verbose
                    $_.distinguishedname + "," + $_.Userprincipalname + "," + $_.SamAccountName | Out-file ./SuccessRMLog.csv -append
                    $dn = $_.DistinguishedName
                    $upn = $_.UserPrincipalName
                    $sam = $_.SamAccountName
                }
            }
        }
        Catch {
            $Error[0]
            $dn + "," + $upn + "," + $sam | Out-file ./ErrorRMLog.csv -append
        }
            
    }
    End {

    }
}