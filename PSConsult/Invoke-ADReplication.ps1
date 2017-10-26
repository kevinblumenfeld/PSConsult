Param (
    
)
<#
    .SYNOPSIS
    
    .EXAMPLE

    .\Create-RemoteMailboxFromADTemplate.ps1 -givenname Kevin -surname White -template SmithJ
  
    #>
    Import-Module ActiveDirectory
   
    ### Force Replication on each Domain Controller in the Forest ###
    $session = New-PSSession -ComputerName ($env:LOGONSERVER).Split("\")[2]
    Invoke-Command -Session $session -ScriptBlock {Import-Module -Name 'ActiveDirectory'}
    Invoke-Command -Session $session -ScriptBlock {((Get-ADForest).Domains | % { Get-ADdomainController -Filter * -Server $_ }).hostname | % {repadmin /syncall /APeqd $_}}
    Remove-PSSession $session
