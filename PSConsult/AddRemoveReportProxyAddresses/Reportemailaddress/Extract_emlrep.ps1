####################################################################################
# 			Author: Alex Rodrick
#                       Reviewer: Vikas Sukhija
# 			Date:- 01/23/2015
#           Description:- This script will extract particular emails addresses
####################################################################################
###########################Define variables#########################################


$email = "*@labtest.com"

$days = (get-date).adddays(-60)
$date = get-date -format d
$date = $date.ToString().Replace(“/”, “-”)
$time = get-date -format t
$month = get-date 
$month1 = $month.month
$year1 = $month.year
$time = $time.ToString().Replace(":", "-")
$time = $time.ToString().Replace(" ", "")

$output1 = ".\" + "ExtractemailRep_" + $date + "_" + $time + "_.csv"

# Add Exchange Shell...

If ((Get-PSSnapin | where {$_.Name -match "Microsoft.Exchange.Management.PowerShell.E2010"}) -eq $null)
{
	Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
}



$a = get-mailbox -resultsize unlimited 

$b = $a | select DisplayName,@{Name="EmailAddresses";Expression={$_.emailaddresses}},Alias -expand EmailAddresses | where {$_.smtpAddress -like "$email"} | Select DisplayName , Alias , smtpAddress,EmailAddresses

$b  | Export-csv $output1 -notypeinformation 

####################################################################################