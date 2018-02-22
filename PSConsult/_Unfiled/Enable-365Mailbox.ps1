function Enable-365Mailbox {
    <#

    .SYNOPSIS
    Enables Office 365 Mailbox from on prem Exchange Server 
    
    .EXAMPLE
    . .\Enable-365Mailbox.ps1
    Import-Csv ./test.csv | Enable-365Mailbox

    #>
    Param 
    (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        $UserPrincipalName,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        $RemoteRoutingAddress
    )
    Begin {

    }
    Process {
        Enable-RemoteMailbox -Identity $UserPrincipalName -RemoteRoutingAddress $RemoteRoutingAddress
    }
    End {

    }
}