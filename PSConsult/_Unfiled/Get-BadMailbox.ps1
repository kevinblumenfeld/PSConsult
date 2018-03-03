function Get-BadMailbox {
    [CmdletBinding()]
    <#
    .SYNOPSIS
    Try Catch instead (try this later)
     $Global:ErrorActionPreferene = 'Stop' before your Get-Mailbox and set it back after.
     https://social.technet.microsoft.com/Forums/scriptcenter/en-US/dbb95788-28ca-4327-89f2-26ca070fda63/powershell-remote-sessions-trycatch-erroractionpreference?forum=ITCG
    .EXAMPLE

    #>
    Param 
    (

    )
    Begin {

    } 
    Process {

        Import-Csv .\testmbx.csv | % {    
            $null = $checkuser
            write-host "email address:  " $($_.emailaddress)      
                $checkuser = Get-Mailbox -Identity $_.emailaddress
            if (! $checkuser) {
                write-host "TEST"
                $_.EmailAddress | Out-file ./eFailed.csv -append
            }
        }
    }
    End {
        
    }
}