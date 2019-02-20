function Move-ToOU {
    <#

    .SYNOPSIS
    Set attribute for AD Users including proxy addresses. 
    
    .EXAMPLE
    . .\Move-ToOU.ps1
    Get-Content ./test.txt | Move-ToOU 

    #>
    Param 
    (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        $users
    )
    Begin {
        $Target = "OU=ADOnly,OU=Users,OU=SJ,DC=contoso,DC=com"
        $DC = "DC1.contoso.com"
    }
    Process {
        Foreach ($user in $users) {
            # Get-ADUser -Identity $user | Move-ADObject -TargetPath $Target -Server $DC
            Get-ADUser -Filter { displayName -eq $user } | Move-ADObject -TargetPath $Target -Server $DC
        }
    }

    End {

    }
}