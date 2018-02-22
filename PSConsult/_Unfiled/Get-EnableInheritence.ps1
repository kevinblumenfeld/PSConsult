# This script produces an output of each ADUser's status of "Allow Inheritable Permissions to Propagate to this Object" (Or in 2012+ "Enable Inheritance")
# The output also includes the value, if any, for each ADUser's attribute "AdminCount".
# Open File in Excel, remove all rows of ADUsers that should not have their attributes modified. Re-Save.
$ADProperties = @(
	'adminCount',
	'distinguishedName',
	'canonicalName',
	'nTSecurityDescriptor',
	'proxyAddresses'
)
$ExcludeProxyAddresses = @(
	'SystemMailbox',
	'FederatedEmail',
	'HealthMailbox',
	'migration',
	'SearchMailbox',
	'DiscoverySearch',
	'Administrator',
	'MSExchApproval',
	'MsExchDiscovery'
)
$LdapFilter = '(&' + '(proxyaddresses=*)' + (-join ($ExcludeProxyAddresses | % {"(!(proxyaddresses=*$($_)*))"})) + ')'

Get-ADUser -LdapFilter $LdapFilter -Properties $ADProperties -ResultSetSize 1000000 |
	Select-Object -Property `
		@{Name='dn'; Expression={$_.distinguishedName}},
		@{Name='InheritenceNeedsToBeEnabled'; Expression={$_.nTSecurityDescriptor.AreAccessRulesProtected}},
		@{Name='adminCount'; Expression={$_.adminCount}},
		@{Name='OU'; Expression={([IO.Path]::GetDirectoryName($_.canonicalName)).Replace('\', '/')}} |
	Sort-Object -Property canonicalName |
	Export-Csv -Path c:\scripts\IsInheritanceEnabled.csv -NoTypeInformation -Encoding ASCII

<#
# Ticks the checkbox, "Allow Inheritable Permissions to Propagate to this Object" (Or in 2012+ clicks the button, "Enable Inheritance") for ADUsers in CSV
# Also clears the same ADUser's attribute "admincount"
$ToBeModified = import-csv c:\scripts\IsInheritanceEnabled.csv
foreach ($obj in $ToBeModified) {
Set-ADObject $obj.dn -Clear AdminCount
Invoke-Expression "dsacls.exe '$($obj.dn)' /P:N"
    }
#>
 