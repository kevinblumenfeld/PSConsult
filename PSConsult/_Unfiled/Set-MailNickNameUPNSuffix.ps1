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
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    }
    Process {
        Try {
            $OUs = (Get-OrganizationalUnit -SearchText "Users" -IncludeContainers:$false | ? {$_.distinguishedname -like "OU=Users*" -or ($_.distinguishedname -notlike "*privileged*" -and $_.distinguishedname -notlike "*adonly*")}).DistinguishedName
            foreach ($OU in $OUs) {
                Get-ADUser -Server SJRIDC1:3268 -searchbase $OU -SearchScope OneLevel -Filter { mailnickname -ne '*' -and samaccountname -notlike 'Health*' -and samaccountname -notlike 'SM_*'} -Properties mailnickname -ResultSetSize 5 |
                    ForEach-Object {
                    Set-ADUser -Server SJRIDC1:3268 -Identity $_.DistinguishedName -replace @{mailnickname = $_.userprincipalname.split('@')[0]} -erroraction stop -whatif
                    $_.distinguishedname + "," + $_.Userprincipalname + "," + $_.SamAccountName | Out-file ./SuccessLog.csv -append
                    $dn = $_.DistinguishedName
                    $upn = $_.UserPrincipalName
                    $sam = $_.SamAccountName
                }
            }
        }
        Catch {
            $Error[0]
            $dn + "," + $upn + "," + $sam | Out-file ./ErrorLog.csv -append
        }
        
    }
    End {

    }
}