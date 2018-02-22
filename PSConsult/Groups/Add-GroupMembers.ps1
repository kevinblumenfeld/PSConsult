function Add-GroupMembers {
    <#

    .SYNOPSIS
    Add member(s) to a group(s) from a CSV that look like this
    Group, Member
    Group01, Joe@contoso.com
    Group01, Sally@contoso.com
    Group02, Fred@contoso.com
    Group03, Joe@contoso.com

    .EXAMPLE
    Import-Csv .\GroupsandMembers.csv | Add-GroupMembers -Path "OU=DistributionGroups,OU=Mail,OU=Internal,OU=contoso-Users,DC=contoso,DC=com"

    #>
    [CmdletBinding()]
    Param 
    (
        [Parameter(Mandatory = $false,
            ValueFromPipelinebyPropertyName = $true)]
        $Group,
        [Parameter(Mandatory = $false,
            ValueFromPipelinebyPropertyName = $true)]
        $Member,
        [Parameter()]
        $Path
    )
    Begin {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    }
    Process {
        Write-Host "Group: `t" $Group
        write-Host "Member:`t" $Member
        $G = (Get-ADObject -LDAPFILTER "(mail=$Group)").distinguishedname
        $M = (Get-ADObject -LDAPFILTER "(mail=$Member)").distinguishedname
        write-Host "GroupDN :`t" $G
        write-Host "MemberDN:`t" $M
        Try {
            Get-ADGroup $G -SearchBase $Path | Add-ADGroupMember -Members $M -erroraction Stop
        }
        Catch {
            ($Group + "," + $Member) | Out-File -FilePath ".\Add_Group_Members_Fail.csv" -append
        }
    }
    End {

    }
}