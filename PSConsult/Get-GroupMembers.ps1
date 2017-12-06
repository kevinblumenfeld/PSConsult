function Get-GroupMembers {
    <#

    .SYNOPSIS

    .EXAMPLE
    (Get-DistributionGroup -ResultSize unlimited).identity | Get-GroupMembers | Export-Csv .\riob.csv -NoTypeInformation -Encoding UTF8 
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
            (Get-DistributionGroupMember $Group).PrimarySMTPAddress | ForEach-Object {
                [PSCustomObject]@{
                    Group  = $Group 
                    Member = $($_)
                }
            }
        }
    }

    End {

    }
}