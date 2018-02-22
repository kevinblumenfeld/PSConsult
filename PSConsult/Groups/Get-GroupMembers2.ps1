function Get-GroupMembers2 {
    <#

    .SYNOPSIS

    .EXAMPLE
     (Get-DistributionGroup -ResultSize unlimited).identity | Get-GroupMembers2 | Export-Csv .\riob.csv -NoTypeInformation -Encoding UTF8    
    #>
    
    Param 
    (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true)]
        $Groups
    )
    Begin {
        Import-Module ActiveDirectory
    }
    Process {
        ForEach ($Group in $Groups) {
            [PSCustomObject]@{
                Group  = $Group 
                Member = (Get-DistributionGroupMember $Group).PrimarySMTPAddress
            }
        }
    }

    End {

    }
}