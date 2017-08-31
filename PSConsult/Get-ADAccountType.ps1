function Get-ADAccountType {
    param (
        [string] $Name
    )
    if ($Name.Contains('\')) {
        $Domain = $Name.Split('\')[0]
        $Name = $Name.Split('\')[1]
    }
    $strFilter = "(&(objectCategory=*)(samAccountName=$Name))"
    if ($Domain) {
        $objSearcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]"LDAP://$Domain")
    }
    Else {
        $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
    }
    $objSearcher.Filter = $strFilter
    try {
        $objPath = $objSearcher.FindOne()
        $objAccount = $objPath.GetDirectoryEntry()
        if ($objAccount.Properties.objectclass[1] -eq 'Group') {
            $ObjectType = 'Group'
        }
        Elseif ($objAccount.Properties.objectclass[3] -eq 'User') {
            $ObjectType = 'User'
        }
    }
    catch {
        Write-Warning "no such object: $Name"
    }
    $ObjectType
}