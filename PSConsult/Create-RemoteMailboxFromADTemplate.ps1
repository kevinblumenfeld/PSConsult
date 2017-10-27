Param (
    
    [Parameter(Mandatory = $True)]
    $FirstName,
    [Parameter(Mandatory = $True)]
    $LastName,
    [Parameter(Mandatory = $False)]
    $StorePhone,
    [Parameter(Mandatory = $False)]
    $MobilePhone,
    [Parameter(Mandatory = $False)]
    $Description,
    [Parameter(Mandatory = $True)]    
    $Prefix,
    [Parameter(Mandatory = $True)]    
    $Template,
    [Parameter(Mandatory = $False)]    
    [switch]$NoMail,
    [Parameter(Mandatory = $False)]
    $password = "contoso2830!!",
    [Parameter(Mandatory = $False)]
    $changepw = $true,
    [Parameter(Mandatory = $False)]
    $ou
)
<#
    .SYNOPSIS
    
    1. Copies the properties of an existing AD User to a new AD User
    2. Enables the ADUser as a Remote Mailbox in Office 365
    3. Syncs changes to Office 365 with Azure AD Connect (AADC)

    Must be run (run as administrator) from Exchange Management Shell (EMS) on Exchange 2016 or later ...

    ##########
    #    ...OR a jump box configured like so:
    # RSAT(AD tools), Exchange Management Tools and PowerShell 5.1 or higher
    # Must be run from Exchange Management Shell (EMS) where PowerShell 5.1 is installed
    # Change EMS shortcut to -version 5.0 like so:
    # C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -version 5.0 -noexit -command ". 'D:\ex2010\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto"
    #
    #  Connect to Exchange with Remote PowerShell:
    #
    #  $UserCredential = Get-Credential
    #  $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://SV001-HYEXCH01.contoso.local/PowerShell/ -Authentication Kerberos -Credential $UserCredential
    #  Import-PSSession $Session
    #
    ##########

    .EXAMPLE

    .\Create-RemoteMailboxFromADTemplate.ps1 -FirstName Kevin -LastName Jones -Mobile "678-437-7468" -StorePhone "678-437-7468,,1234" -Description "This is a test Description"  -Template raela

    .\Create-RemoteMailboxFromADTemplate.ps1 -NoMail -FirstName Kevin -LastName Smith -Mobile "404-555-1212" -StorePhone "800-486-8555,,8845" -Description "This Person Has No Mailbox"  -Template raela
    
    #>
#######################################
# Copy ADUser (Template) & Create New #
#######################################
Import-Module ActiveDirectory
$template_obj = Get-ADUser -Identity $Template -Server $domainController -Properties Enabled, StreetAddress, City, State, PostalCode, MemberOf
$groupMembership = Get-ADUser -Identity $Template -Server $domainController -Properties memberof | select -ExpandProperty memberof

#########################################
#  Set DisplayName and Name attributes  #
#########################################
$domainController = "SV001-DC03.contoso.local"
$name = $LastName + ", " + $FirstName

##############################################
# If SamAccountName is taken, follow rules:  #
#                                            #
#  - use 1 letter from first name,           #
#     then increment # (from 1)              #
#      EXAMPLE: John Smith                   #
# smithj, smithj1, smithj2, smithj3          #
##############################################

if (!$Prefix) {
    $samaccountname = (($LastName).replace(" ", "")).Substring(0, 7) + $($FirstName[0])
    
    $i = 1
    while (get-aduser -LDAPfilter "(samaccountname=$samaccountname)") {
        $samaccountname = (($LastName).replace(" ", "")).Substring(0, 6) + $($FirstName[0]) + $i
        $i++
    }
}

else {
    $samaccountname = $Prefix + (($LastName).replace(" ", "")).Substring(0, 5) + $($FirstName[0])
    
    $i = 1
    while (get-aduser -LDAPfilter "(samaccountname=$samaccountname)") {
        $samaccountname = $Prefix + (($LastName).replace(" ", "")).Substring(0, 4) + $($FirstName[0]) + $i
        $i++
    }
}

#########################################
# Break if UserPrincipalName is in use  #
#########################################
$userprincipalname = ($LastName).replace(" ", "") + "-" + ($FirstName).replace(" ", "") + "@contoso.com"

if (get-aduser -LDAPfilter "(userprincipalname=$userprincipalname)") {
    Write-Output "UserPrincipalName is already in use.  Please manually create."
    Break
}

#########################################
#   Create Parameters for New ADUser    #
#########################################
$password_ss = ConvertTo-SecureString -String $password -AsPlainText -Force
$ou = (Get-ADOrganizationalUnit -Server $domainController -filter * -SearchBase (Get-ADDomain).distinguishedname -Properties canonicalname | 
        where {$_.canonicalname -match "Users" -or $_.canonicalname -match "Contractors"
    } | Select canonicalname, distinguishedname| sort canonicalname | 
        Out-GridView -PassThru -Title "Choose OU where to create the new user and click OK").distinguishedname

$params = @{
    "Instance"              = $template_obj
    "Name"                  = $name
    "DisplayName"           = $name
    "GivenName"             = $FirstName
    "SurName"               = $LastName
    "OfficePhone"           = $StorePhone
    "mobile"                = $MobilePhone
    "description"           = $Description
    "SamAccountName"        = $samaccountname
    "UserPrincipalName"     = $userprincipalname
    "AccountPassword"       = $password_ss
    "ChangePasswordAtLogon" = $changepw
    "Path"                  = $ou
}

#########################################
#          Create New ADUser            #
#########################################

New-ADUser @params -Server $domainController
$groupMembership | Add-ADGroupMember -Server $domainController -Members $samaccountname

# Purge old jobs
Get-Job | where {$_.State -ne 'Running'}| Remove-Job

if (!$NoMail) {
    #######################################
    # Enable Remote Mailbox in Office 365 #
    #######################################

    $tenant = "@contosollc.mail.onmicrosoft.com"
    Enable-RemoteMailbox -DomainController $domainController -Identity $samaccountname -RemoteRoutingAddress ($samaccountname + $tenant) -Alias $samaccountname 

    ########################################
    # Job to Sleep 60 Sec & Sync with O365 #
    ########################################

    Start-Job -ScriptBlock {
    
        Start-Sleep -Seconds 60
        $aadComputer = "SV001-ADCON01.contoso.local"
        $session = New-PSSession -ComputerName $aadComputer
        Invoke-Command -Session $session -ScriptBlock {Import-Module -Name 'ADSync'}
        Invoke-Command -Session $session -ScriptBlock {Start-ADSyncSyncCycle -PolicyType Delta}
        Remove-PSSession $session

    }
}
