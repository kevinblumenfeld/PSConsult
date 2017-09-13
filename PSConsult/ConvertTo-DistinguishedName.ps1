<#
.Synopsis
   Converts an AD canonical name into a distinguished name.
.DESCRIPTION
   Converts an AD canonical name into a distinguished name, and handles
   the case where USERS, COMPUTERS etc. are containers not OUs
   and need to be CN= instead of OU=
.EXAMPLE
   PS C:\> ConvertTo-DistinguishedName "corp.ad.contoso.com/CORP/Place/on02"
   
   CN=on02,OU=Place,OU=CORP,DC=corp,DC=ad,DC=contoso,DC=com
 #>
 function ConvertTo-DistinguishedName {
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        # e.g. 'corp.ad.contoso.com/CORP/USERS/Person'
        [Parameter(Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        # must be at least a.b/w - no single character domain or missing path
        [ValidatePattern('^.+\..+/.+$')]
        $CanonicalName
    )
 
    $distinguishedNameParts = New-Object -TypeName System.Collections.ArrayList
 
    # separate into domain part (a.b.c.d) and path+user part (/x/y/z/Person)
    [string]$domain, [array]$remainder = $CanonicalName.Split('/')
     
    #
    # domain:  'a.b.c.d' -> 'DC=a,DC=b,DC=c,DC=d'
    #
    $null = $distinguishedNameParts.AddRange($domain.Split('.').ForEach({"DC=$_"}))
 
    $specialContainers = @('Users', 'Computers', 'Builtin', 'ForeignSecurityPrincipals', 'lostAndFound', 'Managed Service Accounts','Program Data', 'Microsoft Exchange System Objects')
 
    0..($remainder.Count - 1) | ForEach-Object {
        #
        # handle domain.com/{first} which might be
        #   OU={first}
        # or a special container 
        #   CN={first}
        #
        # and handle /Person at the end, which is CN=
        # all other parts are OU=
        #
        $template = if ((($_ -eq 0) -and ($specialContainers -contains $remainder[$_])) -or ($_ -eq ($remainder.Count - 1))) {
            'CN={0}'
        }
        else {
            'OU={0}'
        }
        $null = $distinguishedNameParts.Insert(0, ($template -f $remainder[$_]))
    }
    $distinguishedNameParts -join ','
}
