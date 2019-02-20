function Sync-GroupMember {
    <#
	.SYNOPSIS
		Update membership of a group based on a LDAP filter
#>
    [CmdletBinding()]
    param(
        # LDAP query to get all users that should be in the group
        [Parameter(Mandatory = $True)]
        [Collections.Generic.HashSet[string]]$TargetMembers,

        # Distinguished Name of the group to update
        [Parameter(Mandatory = $True)]
        [String]$GroupDN
    )
    if (!$targetMembers.Count) {
        Write-Warning "The LDAP query didn't return any data. No synching will be done."
        return
    }

    $currentMembersFilter = "(memberof=$GroupDN)"
    $currentMembers = New-Object "Collections.Generic.HashSet[string]"
    foreach ($ADUser in (Get-ADObject -LDAPFilter $currentMembersFilter)) {
        $null = $currentMembers.Add($ADUser.DistinguishedName)
    }

    [Collections.Generic.HashSet[string]]$formerMembers = [System.Linq.Enumerable]::Except($currentMembers, $targetMembers)
    [Collections.Generic.HashSet[string]]$newMembers = [System.Linq.Enumerable]::Except($targetMembers, $currentMembers)

    if ($formerMembers) {
        foreach ($member in $formerMembers.GetEnumerator()) {
            Set-ADGroup -Identity $GroupDN -Remove @{'member' = $member}
            Write-Output "Removing $member from $GroupDN"
        }
    }

    if ($newMembers) {
        foreach ($member in $newMembers.GetEnumerator()) {
            Set-ADGroup -Identity $GroupDN -Add @{'member' = $member}
            Write-Output "Adding $member to $GroupDN"
        }
    }
}