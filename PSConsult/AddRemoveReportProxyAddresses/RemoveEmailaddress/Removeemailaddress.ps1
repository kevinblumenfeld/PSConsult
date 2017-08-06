####################################################################################
# 			Author: Alex Rodrick
#                       Reviewer: Vikas Sukhija
# 			Date:- 01/23/2015
#           Description:- This script will extract particular emails addresses
####################################################################################
###########################Define variables#########################################

# Add Exchange Shell...

If ((Get-PSSnapin | where {$_.Name -match "Microsoft.Exchange.Management.PowerShell.E2010"}) -eq $null)
{
	Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
}

$z = import-csv $args[0]
$count = $z.count
write-host " Total Count of rows to process is $count" -foregroundcolor green

for ($i=0; $i -le $count-1 ; $i++)
  {
   $alias = $z[$i].alias
   Write-host "Processing ................. $alias" -foregroundcolor green
   $x =  $alias | Get-Mailbox
   $email = $z[$i].SmtpAddress
   $c = $x.EmailAddresses | where {$_.smtpAddress -like "$email"}
   Set-Mailbox $x -EmailAddresses @{remove=$c}
  }

####################################################################################