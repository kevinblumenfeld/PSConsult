$source = get-adgroup "my-source-group"
$group = Get-ADGroup -Identity "mygroup" #target group

    $SourceMembersLdapFilter = "(memberOf:1.2.840.113556.1.4.1941:=$($source.DistinguishedName))"
    Write-Output "Listing allowed users."
    $targetMembers = New-Object "Collections.Generic.HashSet[string]"
    foreach ($ADUser in (Get-ADUser -LDAPFilter $SourceMembersLdapFilter)) {
        $null = $targetMembers.Add($ADUser.DistinguishedName)
    }
    Write-Output "Found $($targetMembers.Count) users"
    if (!$targetMembers.Count) {
        Write-Warning "The source group is empty. No flattening will be done."
        exit
    }

    Write-Output "Listing currently allowed users."
    $currentMembers = New-Object "Collections.Generic.HashSet[string]"
    foreach ($ADUser in (Get-ADUser -LDAPFilter "(memberOf:=$($group.DistinguishedName))")) {
        $null = $currentMembers.Add($ADUser.DistinguishedName)
    }
    Write-Output "Found $($currentMembers.Count) users."

    [Collections.Generic.HashSet[string]]$formerMembers = [System.Linq.Enumerable]::Except($currentMembers,$targetMembers)
    [Collections.Generic.HashSet[string]]$newMembers    = [System.Linq.Enumerable]::Except($targetMembers,$currentMembers)

    if ($formerMembers) {
        foreach ($member in $formerMembers.GetEnumerator()) {
            Set-ADGroup -Identity $group.DistinguishedName -Remove @{'member'=$member}
            Write-Output "Removing $member"
        }
    }

    if ($newMembers) {
        foreach ($member in $newMembers.GetEnumerator()) {
            Set-ADGroup -Identity $group.DistinguishedName -Add @{'member'=$member}
            Write-Output "Adding $member"
        }
    }

    if (!$formerMembers -and !$newMembers) {
        Write-Output "No changes made."
    }