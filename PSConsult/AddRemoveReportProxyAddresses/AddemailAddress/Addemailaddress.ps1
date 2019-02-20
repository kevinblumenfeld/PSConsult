####################################################################################
# 			Author: Alex Rodrick
#                       Reviewer: Vikas Sukhija
# 			Date:- 01/23/2015
#           Description:- This script will add email address to users for reverting
#           the process done by remove email address script
####################################################################################
###########################Define variables#########################################
# Add Exchange Shell...

If ((Get-PSSnapin | where {$_.Name -match "Microsoft.Exchange.Management.PowerShell.E2010"}) -eq $null) {
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
}


$z = import-csv $args[0]
$count = $z.count
write-host " Total Count of rows to process is $count" -foregroundcolor green

for ($i = 0; $i -le $count - 1 ; $i++) {
    $alias = $z[$i].alias
    Write-host "Processing ................. $alias" -foregroundcolor green
    $x = $z[$i].alias
    $s = $z[$i].SmtpAddress
    Set-Mailbox $x -EmailAddresses @{add = $s}
}

#####################################################################################
<#

foreach ($CurAdd in $Add) {
    try {
        Set-RemoteMailbox -identity $CurAdd.UserPrincipalName -EmailAddresses @{Add = $CurAdd.Secondary} -erroraction stop
        Write-Host "SUCCESS ADDING TO REMOTE MAILBOX: `t $($CurAdd.DisplayName)"
    }
    catch {
        Write-Host "Not a Remote: `t $($CurAdd.DisplayName)"
    }
}


foreach ($curA in $a) {
    $mail = (($CurA.PrimarySmtpAddress -split '@')[0] + '@contoso.com')
    $mail
    Set-UnifiedGroup -Identity $CurA.Name -EmailAddresses @{add = $mail}
}

#>