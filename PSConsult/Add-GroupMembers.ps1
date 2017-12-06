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
    Import-Csv .\GroupsandMembers.csv | Add-GroupMembers

    #>
    [CmdletBinding()]
    Param 
    (
    [Parameter(Mandatory = $false,
    ValueFromPipelinebyPropertyName = $true)]
    $Group,
    [Parameter(Mandatory = $false,
    ValueFromPipelinebyPropertyName = $true)]
    $Member
    )
    Begin {
        Import-Module ActiveDirectory
    }
    Process {
	Write-Host "Group: `t" $Group
	write-Host "Member:`t" $Member
            Add-DistributionGroupMember -Identity $Group -Members $Member
         }
    End {

    }
}