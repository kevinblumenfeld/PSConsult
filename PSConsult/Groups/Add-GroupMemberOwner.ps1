function Add-GroupMemberOwner {
    <#

    .SYNOPSIS


    .EXAMPLE
    $dn = Get-DistributionGroup -resultsize 5 | select distinguishedname
    $dn | Add-GroupMemberOwner -AddManager NikkiEdit

    #>
    [CmdletBinding()]
    Param 
    (
        [Parameter(Mandatory = $false,
            ValueFromPipelinebyPropertyName = $true)]
        $distinguishedname,
        [Parameter(Mandatory = $false)]
        $AddManager
    )
    Begin {
        
    }
    Process {
        Try {
            Foreach ($CurGroup in $distinguishedname) {
                $mgr = (Get-DistributionGroup -identity $CurGroup).Managedby
                $newmanage = $mgr + $AddManager
                write-output $newmanage
                Set-DistributionGroup $CurGroup -Managedby $newmanage -bypasssecuritygroupmanagercheck -ErrorAction Stop
                ($CurGroup + ";" + $newmanage) | Out-File -FilePath ".\Add_Group_Member_Owner_Succeed.csv" -append
            }
            
        }
        Catch {
            $Error[0]
            ($CurGroup + ";" + $mem) | Out-File -FilePath ".\Add_Group_Member_Owner_Fail.csv" -append
        }
    }
    End {

    }
}