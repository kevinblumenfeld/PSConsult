<#
.SYNOPSIS
Get-DAGHealth.ps1 - Exchange Server 2010/2013 Database Availability Group Health Check Script.

.DESCRIPTION 
Performs a series of health checks on the Database Availability Groups
and outputs the results to screen or HTML email.

.OUTPUTS
Results are output to screen or HTML email

.PARAMETER Detailed
When this parameter is used a more detailed report is shown in the output.

.PARAMETER HTMLFile
When this parameter is used the HTML report is also writte to a file.

.PARAMETER SendEmail
Sends the HTML report via email using the SMTP configuration within the script.

.EXAMPLE
.\Get-DAGHealth.ps1
Checks all DAGs in the organization and outputs a health summary to the PowerShell window.

.EXAMPLE
.\Get-DAGHealth.ps1 -Detailed
Checks all DAGs in the organization and outputs a detailed health report to the PowerShell
window. Due to the amount of detail the full report may get cut off in your window. I recommend
detailed reports be output to HTML file or email instead.

.EXAMPLE
.\Get-DAGHealth.ps1 -Detailed -SendEmail
Checks all DAGs in the organization and outputs a detailed health report via email using
the SMTP settings you configure in the script.

.LINK
http://exchangeserverpro.com/get-daghealth-ps1-database-availability-group-health-check-script/

.NOTES
Written by: Paul Cunningham

Find me on:

* My Blog:	http://paulcunningham.me
* Twitter:	https://twitter.com/paulcunningham
* LinkedIn:	http://au.linkedin.com/in/cunninghamp/
* Github:	https://github.com/cunninghamp

For more Exchange Server tips, tricks and news
check out Exchange Server Pro.

* Website:	http://exchangeserverpro.com
* Twitter:	http://twitter.com/exchservpro

Change Log
V1.00, 14/02/2013 - Initial version
V1.01, 24/04/2013 - Bug fixes, Exchange 2013 testing
V1.02, 15/10/2014 - Updated to include fixes from Test-ExchangeServerHealth.ps1
#>

[CmdletBinding()]
param(
	[Parameter( Mandatory=$false)]
	[switch]$SendEmail,
	
	[Parameter( Mandatory=$false)]
	[switch]$HTMLFile,
	
	[Parameter( Mandatory=$false)]
	[switch]$Detailed,

	[Parameter( Mandatory=$false)]
	[switch]$Log
	)


#...................................
# Variables
#...................................

$now = Get-Date											#Used for timestamps
$date = $now.ToShortDateString()						#Short date format for email message subject
$pass = "Green"
$warn = "Yellow"
$fail = "Red"
$ip = $null
[array]$dagsummary = @()								#Summary of issues found during DAG health checks
[array]$report = @()
[bool]$alerts = $false
[array]$dags = @()										#Array for DAG health check
[array]$dagdatabases = @()								#Array for DAG databases
[int]$replqueuewarning = 8								#Threshold to consider a replication queue unhealthy
$dagreportbody = $null

$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$ignorelistfile = "$myDir\ignorelist.txt"
$logfile = "$myDir\get-daghealth.log"
$reportfile = "$myDir\get-daghealth.html"


#...................................
# SMTP settings are stored in
# Settings.xml file
#...................................

# Import Settings.xml config file
[xml]$ConfigFile = Get-Content "$MyDir\Settings.xml"

# Email settings from Settings.xml
$smtpsettings = @{
    To = $ConfigFile.Settings.EmailSettings.MailTo
    From = $ConfigFile.Settings.EmailSettings.MailFrom
    SmtpServer = $ConfigFile.Settings.EmailSettings.SMTPServer
    Subject = "$($ConfigFile.Settings.EmailSettings.Subject) - $now"
    }


#...................................
# Logfile Strings
#...................................

$logstring0 = "====================================="
$logstring1 = " Exchange Server DAG Health Check"

#...................................
# Initialization Strings
#...................................

$initstring0 = "Initializing..."
$initstring1 = "Loading the Exchange Server PowerShell snapin"
$initstring2 = "The Exchange Server PowerShell snapin did not load."
$initstring3 = "Setting scope to entire forest"

#...................................
# Error/Warning Strings
#...................................

$string3 = "------ Checking"
$string14 = "Sending email. "
$string15 = "Done."
$string16 = "------ Finishing"
$string19 = "No alerts found, and AlertsOnly switch was used. No email sent. "
$string22 = "The file $ignorelistfile could not be found. No servers, DAGs or databases will be ignored."
$string28 = "Servers, DAGs and databases to ignore:"
$string51 = "Skipped"
$string60 = "Beginning the DAG health checks"
$string61 = "Could not determine server with active database copy"
$string62 = "mounted on server that is activation preference"
$string63 = "unhealthy database copy count is"
$string64 = "healthy copy/replay queue count is"
$string65 = "(of"
$string66 = ")"
$string67 = "unhealthy content index count is"
$string68 = "DAGs to check:"
$string69 = "DAG databases to check"



#...................................
# Functions
#...................................

#This function is used to generate HTML for the DAG member health report
Function New-DAGMemberHTMLTableCell()
{
	param( $lineitem )
	
	$htmltablecell = $null

	switch ($($line."$lineitem"))
	{
		$null { $htmltablecell = "<td>n/a</td>" }
		"Passed" { $htmltablecell = "<td class=""pass"">$($line."$lineitem")</td>" }
		default { $htmltablecell = "<td class=""warn"">$($line."$lineitem")</td>" }
	}
	
	return $htmltablecell
}


#This function is used to write the log file if -Log is used
Function Write-Logfile()
{
	param( $logentry )
	$timestamp = Get-Date -DisplayHint Time
	"$timestamp $logentry" | Out-File $logfile -Append
}


#This function is used to test replication health for Exchange 2010 DAG members in mixed 2010/2013 organizations
Function Test-E14ReplicationHealth()
{
	param ( $e14mailboxserver )

	$e14replicationhealth = $null
	
    #Find an E14 CAS in the same site
    $ADSite = (Get-ExchangeServer $e14mailboxserver).Site
    $e14cas = (Get-ExchangeServer | where {$_.IsClientAccessServer -and $_.AdminDisplayVersion -match "Version 14" -and $_.Site -eq $ADSite} | select -first 1).FQDN

	Write-Verbose "Creating PSSession for $e14cas"
    $url = (Get-PowerShellVirtualDirectory -Server $e14cas -AdPropertiesOnly | Where {$_.Name -eq "Powershell (Default Web Site)"}).InternalURL.AbsoluteUri
    if ($url -eq $null)
    {
        $url = "http://$e14cas/powershell"
    }

    Write-Verbose "Using URL $url"

	try
	{
	    $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $url -ErrorAction STOP
	}
	catch
	{
	    Write-Verbose "Something went wrong"
		if ($Log) {Write-Log $_.Exception.Message}
    	Write-Warning $_.Exception.Message
		#$e14replicationhealth = "Fail"
	}

	try
	{
	    Write-Verbose "Running replication health test on $e14mailboxserver"
	    #$e14replicationhealth = Invoke-Command -Session $session {Test-ReplicationHealth} -ErrorAction STOP
        $e14replicationhealth = Invoke-Command -Session $session -Args $e14mailboxserver.Name {Test-ReplicationHealth $args[0]} -ErrorAction STOP
	}
	catch
	{
	    Write-Verbose "An error occurred"
		if ($Log) {Write-Log $_.Exception.Message}
	    Write-Warning $_.Exception.Message
	    #$e14replicationhealth = "Fail"
	}

	#Write-Verbose "Replication health test: $e14replicationhealth"
	Write-Verbose "Removing PSSession"
	Remove-PSSession $session.Id

	return $e14replicationhealth
}


#...................................
# Initialize
#...................................

#Log file is overwritten each time the script is run to avoid
#very large log files from growing over time
if ($Log) {
	$timestamp = Get-Date -DisplayHint Time
	"$timestamp $logstring0" | Out-File $logfile
	Write-Logfile $logstring1
	Write-Logfile "  $now"
	Write-Logfile $logstring0
}

Write-Host $initstring0
if ($Log) {Write-Logfile $initstring0}

#Add Exchange 2010 snapin if not already loaded in the PowerShell session
if (!(Get-PSSnapin | where {$_.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010"}))
{
	Write-Verbose $initstring1
	if ($Log) {Write-Logfile $initstring1}
	try
	{
		Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction STOP
	}
	catch
	{
		#Snapin was not loaded
		Write-Verbose $initstring2
		if ($Log) {Write-Logfile $initstring2}
		Write-Warning $_.Exception.Message
		EXIT
	}
	. $env:ExchangeInstallPath\bin\RemoteExchange.ps1
	Connect-ExchangeServer -auto -AllowClobber
}


#Set scope to include entire forest
Write-Verbose $initstring3
if ($Log) {Write-Logfile $initstring3}
if (!(Get-ADServerSettings).ViewEntireForest)
{
	Set-ADServerSettings -ViewEntireForest $true -WarningAction SilentlyContinue
}


#...................................
# Script
#...................................

#This is the list of servers, DAGs, and databases to never alert for
try
{
    $ignorelist = @(Get-Content $ignorelistfile -ErrorAction STOP)
	if ($Log) {Write-Logfile $string28}
	if ($Log) {
		if ($($ignorelist.count) -gt 0)
		{
			foreach ($line in $ignorelist)
			{
				Write-Logfile "- $line"
			}
		}
		else
		{
			Write-Logfile $string38
		}
	}
}
catch
{
	Write-Warning $string22
	if ($Log) {Write-Logfile $string22}
}
    

### Check if any Exchange 2013 servers exist
if (Get-ExchangeServer | Where {$_.AdminDisplayVersion -like "Version 15.*"})
{
	[bool]$HasE15 = $true
}


### Begin DAG Health Report


if ($Log) {Write-Logfile $string60}
Write-Verbose "Retrieving Database Availability Groups"

#Get all DAGs
$tmpdags = @(Get-DatabaseAvailabilityGroup)
$tmpstring = "$($tmpdags.count) DAGs found"
Write-Verbose $tmpstring
if ($Log) {Write-Logfile $tmpstring}

#Remove DAGs in ignorelist
foreach ($tmpdag in $tmpdags)
{
	if (!($ignorelist -icontains $tmpdag.name))
	{
		$dags += $tmpdag
	}
}

$tmpstring = "$($dags.count) DAGs will be checked"
Write-Verbose $tmpstring
if ($Log) {Write-Logfile $tmpstring}

if ($Log) {Write-Logfile $string68}
if ($Log) {
	foreach ($dag in $dags)
	{
		Write-Logfile "- $dag"
	}
}


if ($($dags.count) -gt 0)
{
	foreach ($dag in $dags)
	{
		
		#Strings for use in the HTML report/email
		$dagsummaryintro = "<p>Database Availability Group <strong>$($dag.Name)</strong> Health Summary:</p>"
		$dagdetailintro = "<p>Database Availability Group <strong>$($dag.Name)</strong> Health Details:</p>"
		$dagmemberintro = "<p>Database Availability Group <strong>$($dag.Name)</strong> Member Health:</p>"

		$dagdbcopyReport = @()		#Database copy health report
		$dagciReport = @()			#Content Index health report
		$dagmemberReport = @()		#DAG member server health report
		$dagdatabaseSummary = @()	#Database health summary report
		$dagdatabases = @()			#Array of databases in the DAG
		
		$tmpstring = "---- Processing DAG $($dag.Name)"
		Write-Verbose $tmpstring
		if ($Log) {Write-Logfile $tmpstring}
		
		$dagmembers = @($dag | Select-Object -ExpandProperty Servers | Sort-Object Name)
		$tmpstring = "$($dagmembers.count) DAG members found"
		Write-Verbose $tmpstring
		if ($Log) {Write-Logfile $tmpstring}
		
		#Get all databases in the DAG
        if ($HasE15)
        {
		    $tmpdatabases = @(Get-MailboxDatabase -Status -IncludePreExchange2013 | Where-Object {$_.MasterServerOrAvailabilityGroup -eq $dag.Name} | Sort-Object Name)
        }
        else
        {
		    $tmpdatabases = @(Get-MailboxDatabase -Status | Where-Object {$_.MasterServerOrAvailabilityGroup -eq $dag.Name} | Sort-Object Name)
        }

		foreach ($tmpdatabase in $tmpdatabases)
		{
			if (!($ignorelist -icontains $tmpdatabase.name))
			{
				$dagdatabases += $tmpdatabase
			}
		}
				
		$tmpstring = "$($dagdatabases.count) DAG databases will be checked"
		Write-Verbose $tmpstring
		if ($Log) {Write-Logfile $tmpstring}

		if ($Log) {Write-Logfile $string69}
		if ($Log) {
			foreach ($database in $dagdatabases)
			{
				Write-Logfile "- $database"
			}
		}
		
		foreach ($database in $dagdatabases)
		{
			$tmpstring = "---- Processing database $database"
			Write-Verbose $tmpstring
			if ($Log) {Write-Logfile $tmpstring}

			#Custom object for Database
			$objectHash = @{
				"Database" = $database.Identity
				"Mounted on" = "Unknown"
				"Preference" = $null
				"Total Copies" = $null
				"Healthy Copies" = $null
				"Unhealthy Copies" = $null
				"Healthy Queues" = $null
				"Unhealthy Queues" = $null
				"Lagged Queues" = $null
				"Healthy Indexes" = $null
				"Unhealthy Indexes" = $null
				}
			$databaseObj = New-Object PSObject -Property $objectHash

			$dbcopystatus = @($database | Get-MailboxDatabaseCopyStatus)
			$tmpstring = "$database has $($dbcopystatus.Count) copies"
			Write-Verbose $tmpstring
			if ($Log) {Write-Logfile $tmpstring}
			
			foreach ($dbcopy in $dbcopystatus)
			{
				#Custom object for DB copy
				$objectHash = @{
					"Database Copy" = $dbcopy.Identity
					"Database Name" = $dbcopy.DatabaseName
					"Mailbox Server" = $null
					"Activation Preference" = $null
					"Status" = $null
					"Copy Queue" = $null
					"Replay Queue" = $null
					"Replay Lagged" = $null
					"Truncation Lagged" = $null
					"Content Index" = $null
					}
				$dbcopyObj = New-Object PSObject -Property $objectHash
				
				$tmpstring = "Database Copy: $($dbcopy.Identity)"
				Write-Verbose $tmpstring
				if ($Log) {Write-Logfile $tmpstring}
				
				$mailboxserver = $dbcopy.MailboxServer
				$tmpstring = "Server: $mailboxserver"
				Write-Verbose $tmpstring
				if ($Log) {Write-Logfile $tmpstring}
                
                if ($database.AdminDisplayVersion -like "Version 14.*")
                {
				    $pref = ($database | Select-Object -ExpandProperty ActivationPreference | Where-Object {$_.Key -eq $mailboxserver}).Value
                }
                else
                {
                    $pref = $dbcopy.ActivationPreference
                }

				$tmpstring = "Activation Preference: $pref"
				Write-Verbose $tmpstring
				if ($Log) {Write-Logfile $tmpstring}

				$copystatus = $dbcopy.Status
				$tmpstring = "Status: $copystatus"
				Write-Verbose $tmpstring
				if ($Log) {Write-Logfile $tmpstring}
				
				[int]$copyqueuelength = $dbcopy.CopyQueueLength
				$tmpstring = "Copy Queue: $copyqueuelength"
				Write-Verbose $tmpstring
				if ($Log) {Write-Logfile $tmpstring}
				
				[int]$replayqueuelength = $dbcopy.ReplayQueueLength
				$tmpstring = "Replay Queue: $replayqueuelength"
				Write-Verbose $tmpstring
				if ($Log) {Write-Logfile $tmpstring}
				
				if ($($dbcopy.ContentIndexErrorMessage -match "is disabled in Active Directory"))
                {
                    $contentindexstate = "Disabled"
                }
                else
                {
                    $contentindexstate = $dbcopy.ContentIndexState
                }
				$tmpstring = "Content Index: $contentindexstate"
				Write-Verbose $tmpstring
				if ($Log) {Write-Logfile $tmpstring}				

				#Checking whether this is a replay lagged copy
				$replaylagcopies = @($database | Select -ExpandProperty ReplayLagTimes | Where-Object {$_.Value -gt 0})
				if ($($replaylagcopies.count) -gt 0)
	            {
	                [bool]$replaylag = $false
	                foreach ($replaylagcopy in $replaylagcopies)
				    {
					    if ($replaylagcopy.Key -eq $mailboxserver)
					    {
						    $tmpstring = "$database is replay lagged on $mailboxserver"
							Write-Verbose $tmpstring
							if ($Log) {Write-Logfile $tmpstring}
						    [bool]$replaylag = $true
					    }
				    }
	            }
	            else
				{
				   [bool]$replaylag = $false
				}
	            $tmpstring = "Replay lag is $replaylag"
				Write-Verbose $tmpstring
				if ($Log) {Write-Logfile $tmpstring}				
						
				#Checking for truncation lagged copies
				$truncationlagcopies = @($database | Select -ExpandProperty TruncationLagTimes | Where-Object {$_.Value -gt 0})
				if ($($truncationlagcopies.count) -gt 0)
	            {
	                [bool]$truncatelag = $false
	                foreach ($truncationlagcopy in $truncationlagcopies)
				    {
					    if ($truncationlagcopy.Key -eq $mailboxserver)
					    {
						    $tmpstring = "$database is truncate lagged on $mailboxserver"
							Write-Verbose $tmpstring
							if ($Log) {Write-Logfile $tmpstring}							
							[bool]$truncatelag = $true
					    }
				    }
	            }
	            else
				{
				   [bool]$truncatelag = $false
				}
	            $tmpstring = "Truncation lag is $truncatelag"
				Write-Verbose $tmpstring
				if ($Log) {Write-Logfile $tmpstring}
				
				$dbcopyObj | Add-Member NoteProperty -Name "Mailbox Server" -Value $mailboxserver -Force
				$dbcopyObj | Add-Member NoteProperty -Name "Activation Preference" -Value $pref -Force
				$dbcopyObj | Add-Member NoteProperty -Name "Status" -Value $copystatus -Force
				$dbcopyObj | Add-Member NoteProperty -Name "Copy Queue" -Value $copyqueuelength -Force
				$dbcopyObj | Add-Member NoteProperty -Name "Replay Queue" -Value $replayqueuelength -Force
				$dbcopyObj | Add-Member NoteProperty -Name "Replay Lagged" -Value $replaylag -Force
				$dbcopyObj | Add-Member NoteProperty -Name "Truncation Lagged" -Value $truncatelag -Force
				$dbcopyObj | Add-Member NoteProperty -Name "Content Index" -Value $contentindexstate -Force
				
				$dagdbcopyReport += $dbcopyObj
			}
		
			$copies = @($dagdbcopyReport | Where-Object { ($_."Database Name" -eq $database) })
		
			$mountedOn = ($copies | Where-Object { ($_.Status -eq "Mounted") })."Mailbox Server"
			if ($mountedOn)
			{
				$databaseObj | Add-Member NoteProperty -Name "Mounted on" -Value $mountedOn -Force
			}
		
			$activationPref = ($copies | Where-Object { ($_.Status -eq "Mounted") })."Activation Preference"
			$databaseObj | Add-Member NoteProperty -Name "Preference" -Value $activationPref -Force

			$totalcopies = $copies.count
			$databaseObj | Add-Member NoteProperty -Name "Total Copies" -Value $totalcopies -Force
		
			$healthycopies = @($copies | Where-Object { (($_.Status -eq "Mounted") -or ($_.Status -eq "Healthy")) }).Count
			$databaseObj | Add-Member NoteProperty -Name "Healthy Copies" -Value $healthycopies -Force
			
			$unhealthycopies = @($copies | Where-Object { (($_.Status -ne "Mounted") -and ($_.Status -ne "Healthy")) }).Count
			$databaseObj | Add-Member NoteProperty -Name "Unhealthy Copies" -Value $unhealthycopies -Force

			$healthyqueues  = @($copies | Where-Object { (($_."Copy Queue" -lt $replqueuewarning) -and (($_."Replay Queue" -lt $replqueuewarning)) -and ($_."Replay Lagged" -eq $false)) }).Count
	        $databaseObj | Add-Member NoteProperty -Name "Healthy Queues" -Value $healthyqueues -Force

			$unhealthyqueues = @($copies | Where-Object { (($_."Copy Queue" -ge $replqueuewarning) -or (($_."Replay Queue" -ge $replqueuewarning) -and ($_."Replay Lagged" -eq $false))) }).Count
			$databaseObj | Add-Member NoteProperty -Name "Unhealthy Queues" -Value $unhealthyqueues -Force

			$laggedqueues = @($copies | Where-Object { ($_."Replay Lagged" -eq $true) -or ($_."Truncation Lagged" -eq $true) }).Count
			$databaseObj | Add-Member NoteProperty -Name "Lagged Queues" -Value $laggedqueues -Force

			$healthyindexes = @($copies | Where-Object { ($_."Content Index" -eq "Healthy" -or $_."Content Index" -eq "Disabled") }).Count
			$databaseObj | Add-Member NoteProperty -Name "Healthy Indexes" -Value $healthyindexes -Force
			
			$unhealthyindexes = @($copies | Where-Object { ($_."Content Index" -ne "Healthy" -and $_."Content Index" -ne "Disabled") }).Count
			$databaseObj | Add-Member NoteProperty -Name "Unhealthy Indexes" -Value $unhealthyindexes -Force
			
			$dagdatabaseSummary += $databaseObj
		
		}
		
		#Get Test-Replication Health results for each DAG member
		foreach ($dagmember in $dagmembers)
		{
            $replicationhealth = $null

            $replicationhealthitems = @{ClusterService = $null
                                        ReplayService = $null
                                        ActiveManager = $null
                                        TasksRpcListener = $null
                                        TcpListener = $null
                                        ServerLocatorService = $null
                                        DagMembersUp = $null
                                        ClusterNetwork = $null
                                        QuorumGroup = $null
                                        FileShareQuorum = $null
                                        DatabaseRedundancy = $null
                                        DatabaseAvailability = $null
                                        DBCopySuspended = $null
                                        DBCopyFailed = $null
                                        DBInitializing = $null
                                        DBDisconnected = $null
                                        DBLogCopyKeepingUp = $null
                                        DBLogReplayKeepingUp = $null
                                        }

			$memberObj = New-Object PSObject -Property $replicationhealthitems
			$memberObj | Add-Member NoteProperty -Name "Server" -Value $dagmember
		
			$tmpstring = "---- Checking replication health for $dagmember"
			Write-Verbose $tmpstring
			if ($Log) {Write-Logfile $tmpstring}
			
			try
            {
                $replicationhealth = $dagmember | Invoke-Command {Test-ReplicationHealth -ErrorAction STOP} 
            }
            catch
            {
		        if ($Log) {Write-Logfile "Using E14 replication health test workaround"}
                $replicationhealth = Test-E14ReplicationHealth $dagmember
            }
			
	        foreach ($healthitem in $replicationhealth)
	        {
                if ($($healthitem.Result) -eq $null)
                {
                    $healthitemresult = "n/a"
                }
                else
                {
                    $healthitemresult = $($healthitem.Result)
                }
                $tmpstring = "$($healthitem.Check) $healthitemresult"
		        Write-Verbose $tmpstring
		        if ($Log) {Write-Logfile $tmpstring}
		        $memberObj | Add-Member NoteProperty -Name $($healthitem.Check) -Value $healthitemresult -Force
	        }
			$dagmemberReport += $memberObj
		}

		
		#Generate the HTML from the DAG health checks
		if ($SendEmail -or $HTMLFile)
		{
		
			####Begin Summary Table HTML
			$dagdatabaseSummaryHtml = $null
			#Begin Summary table HTML header
			$htmltableheader = "<p>
							<table>
							<tr>
							<th>Database</th>
							<th>Mounted on</th>
							<th>Preference</th>
							<th>Total Copies</th>
							<th>Healthy Copies</th>
							<th>Unhealthy Copies</th>
							<th>Healthy Queues</th>
							<th>Unhealthy Queues</th>
							<th>Lagged Queues</th>
							<th>Healthy Indexes</th>
							<th>Unhealthy Indexes</th>
							</tr>"

			$dagdatabaseSummaryHtml += $htmltableheader
			#End Summary table HTML header
			
			#Begin Summary table HTML rows
			foreach ($line in $dagdatabaseSummary)
			{
				$htmltablerow = "<tr>"
				$htmltablerow += "<td><strong>$($line.Database)</strong></td>"
				
				#Warn if mounted server is still unknown
				switch ($($line."Mounted on"))
				{
					"Unknown" {
						$htmltablerow += "<td class=""warn"">$($line."Mounted on")</td>"
						$dagsummary += "$($line.Database) - $string61"
						}
					default { $htmltablerow += "<td>$($line."Mounted on")</td>" }
				}
				
				#Warn if DB is mounted on a server that is not Activation Preference 1
				if ($($line.Preference) -gt 1)
				{
					$htmltablerow += "<td class=""warn"">$($line.Preference)</td>"
					$dagsummary += "$($line.Database) - $string62 $($line.Preference)"
				}
				else
				{
					$htmltablerow += "<td class=""pass"">$($line.Preference)</td>"
				}
				
				$htmltablerow += "<td>$($line."Total Copies")</td>"
				
				#Show as info if health copies is 1 but total copies also 1,
	            #Warn if healthy copies is 1, Fail if 0
				switch ($($line."Healthy Copies"))
				{	
					0 {$htmltablerow += "<td class=""fail"">$($line."Healthy Copies")</td>"}
					1 {
						if ($($line."Total Copies") -eq $($line."Healthy Copies"))
						{
							$htmltablerow += "<td class=""info"">$($line."Healthy Copies")</td>"
						}
						else
						{
							$htmltablerow += "<td class=""warn"">$($line."Healthy Copies")</td>"
						}
					  }
					default {$htmltablerow += "<td class=""pass"">$($line."Healthy Copies")</td>"}
				}

				#Warn if unhealthy copies is 1, fail if more than 1
				switch ($($line."Unhealthy Copies"))
				{
					0 {	$htmltablerow += "<td class=""pass"">$($line."Unhealthy Copies")</td>" }
					1 {
						$htmltablerow += "<td class=""warn"">$($line."Unhealthy Copies")</td>"
						$dagsummary += "$($line.Database) - $string63 $($line."Unhealthy Copies") $string65 $($line."Total Copies") $string66"
						}
					default {
						$htmltablerow += "<td class=""fail"">$($line."Unhealthy Copies")</td>"
						$dagsummary += "$($line.Database) - $string63 $($line."Unhealthy Copies") $string65 $($line."Total Copies") $string66"
						}
				}

				#Warn if healthy queues + lagged queues is less than total copies
				#Fail if no healthy queues
				if ($($line."Total Copies") -eq ($($line."Healthy Queues") + $($line."Lagged Queues")))
				{
					$htmltablerow += "<td class=""pass"">$($line."Healthy Queues")</td>"
				}
				else
				{
					$dagsummary += "$($line.Database) - $string64 $($line."Healthy Queues") $string65 $($line."Total Copies") $string66"
					switch ($($line."Healthy Queues"))
					{
						0 {	$htmltablerow += "<td class=""fail"">$($line."Healthy Queues")</td>" }
						default { $htmltablerow += "<td class=""warn"">$($line."Healthy Queues")</td>" }
					}
				}
				
				#Fail if unhealthy queues = total queues
				#Warn if more than one unhealthy queue
				if ($($line."Total Queues") -eq $($line."Unhealthy Queues"))
				{
					$htmltablerow += "<td class=""fail"">$($line."Unhealthy Queues")</td>"
				}
				else
				{
					switch ($($line."Unhealthy Queues"))
					{
						0 { $htmltablerow += "<td class=""pass"">$($line."Unhealthy Queues")</td>" }
						default { $htmltablerow += "<td class=""warn"">$($line."Unhealthy Queues")</td>" }
					}
				}
				
				#Info for lagged queues
				switch ($($line."Lagged Queues"))
				{
					0 { $htmltablerow += "<td>$($line."Lagged Queues")</td>" }
					default { $htmltablerow += "<td class=""info"">$($line."Lagged Queues")</td>" }
				}
				
				#Pass if healthy indexes = total copies
				#Warn if healthy indexes less than total copies
				#Fail if healthy indexes = 0
				if ($($line."Total Copies") -eq $($line."Healthy Indexes"))
				{
					$htmltablerow += "<td class=""pass"">$($line."Healthy Indexes")</td>"
				}
				else
				{
					$dagsummary += "$($line.Database) - $string67 $($line."Unhealthy Indexes") $string65 $($line."Total Copies") $string66"
					switch ($($line."Healthy Indexes"))
					{
						0 { $htmltablerow += "<td class=""fail"">$($line."Healthy Indexes")</td>" }
						default { $htmltablerow += "<td class=""warn"">$($line."Healthy Indexes")</td>" }
					}
				}
				
				#Fail if unhealthy indexes = total copies
				#Warn if unhealthy indexes 1 or more
				#Pass if unhealthy indexes = 0
				if ($($line."Total Copies") -eq $($line."Unhealthy Indexes"))
				{
					$htmltablerow += "<td class=""fail"">$($line."Unhealthy Indexes")</td>"
				}
				else
				{
					switch ($($line."Unhealthy Indexes"))
					{
						0 { $htmltablerow += "<td class=""pass"">$($line."Unhealthy Indexes")</td>" }
						default { $htmltablerow += "<td class=""warn"">$($line."Unhealthy Indexes")</td>" }
					}
				}
				
				$htmltablerow += "</tr>"
				$dagdatabaseSummaryHtml += $htmltablerow
			}
			$dagdatabaseSummaryHtml += "</table>
									</p>"
			#End Summary table HTML rows
			####End Summary Table HTML

			####Begin Detail Table HTML
			$databasedetailsHtml = $null
			#Begin Detail table HTML header
			$htmltableheader = "<p>
							<table>
							<tr>
							<th>Database Copy</th>
							<th>Database Name</th>
							<th>Mailbox Server</th>
							<th>Activation Preference</th>
							<th>Status</th>
							<th>Copy Queue</th>
							<th>Replay Queue</th>
							<th>Replay Lagged</th>
							<th>Truncation Lagged</th>
							<th>Content Index</th>
							</tr>"

			$databasedetailsHtml += $htmltableheader
			#End Detail table HTML header
			
			#Begin Detail table HTML rows
			foreach ($line in $dagdbcopyReport)
			{
				$htmltablerow = "<tr>"
				$htmltablerow += "<td><strong>$($line."Database Copy")</strong></td>"
				$htmltablerow += "<td>$($line."Database Name")</td>"
				$htmltablerow += "<td>$($line."Mailbox Server")</td>"
				$htmltablerow += "<td>$($line."Activation Preference")</td>"
				
				Switch ($($line."Status"))
				{
					"Healthy" { $htmltablerow += "<td class=""pass"">$($line."Status")</td>" }
					"Mounted" { $htmltablerow += "<td class=""pass"">$($line."Status")</td>" }
					"Failed" { $htmltablerow += "<td class=""fail"">$($line."Status")</td>" }
					"FailedAndSuspended" { $htmltablerow += "<td class=""fail"">$($line."Status")</td>" }
					"ServiceDown" { $htmltablerow += "<td class=""fail"">$($line."Status")</td>" }
					"Dismounted" { $htmltablerow += "<td class=""fail"">$($line."Status")</td>" }
					default { $htmltablerow += "<td class=""warn"">$($line."Status")</td>" }
				}
				
				if ($($line."Copy Queue") -lt $replqueuewarning)
				{
					$htmltablerow += "<td class=""pass"">$($line."Copy Queue")</td>"
				}
				else
				{
					$htmltablerow += "<td class=""warn"">$($line."Copy Queue")</td>"
				}
				
				if (($($line."Replay Queue") -lt $replqueuewarning) -or ($($line."Replay Lagged") -eq $true))
				{
					$htmltablerow += "<td class=""pass"">$($line."Replay Queue")</td>"
				}
				else
				{
					$htmltablerow += "<td class=""warn"">$($line."Replay Queue")</td>"
				}
				

				Switch ($($line."Replay Lagged"))
				{
					$true { $htmltablerow += "<td class=""info"">$($line."Replay Lagged")</td>" }
					default { $htmltablerow += "<td>$($line."Replay Lagged")</td>" }
				}

				Switch ($($line."Truncation Lagged"))
				{
					$true { $htmltablerow += "<td class=""info"">$($line."Truncation Lagged")</td>" }
					default { $htmltablerow += "<td>$($line."Truncation Lagged")</td>" }
				}
				
				Switch ($($line."Content Index"))
				{
					"Healthy" { $htmltablerow += "<td class=""pass"">$($line."Content Index")</td>" }
                    "Disabled" { $htmltablerow += "<td class=""info"">$($line."Content Index")</td>" }
					default { $htmltablerow += "<td class=""warn"">$($line."Content Index")</td>" }
				}
				
				$htmltablerow += "</tr>"
				$databasedetailsHtml += $htmltablerow
			}
			$databasedetailsHtml += "</table>
									</p>"
			#End Detail table HTML rows
			####End Detail Table HTML
			
			
			####Begin Member Table HTML
			$dagmemberHtml = $null
			#Begin Member table HTML header
			$htmltableheader = "<p>
								<table>
								<tr>
								<th>Server</th>
								<th>Cluster Service</th>
								<th>Replay Service</th>
								<th>Active Manager</th>
								<th>Tasks RPC Listener</th>
								<th>TCP Listener</th>
								<th>Server Locator Service</th>
								<th>DAG Members Up</th>
								<th>Cluster Network</th>
								<th>Quorum Group</th>
								<th>File Share Quorum</th>
								<th>Database Redundancy</th>
								<th>Database Availability</th>
								<th>DB Copy Suspended</th>
								<th>DB Copy Failed</th>
								<th>DB Initializing</th>
								<th>DB Disconnected</th>
								<th>DB Log Copy Keeping Up</th>
								<th>DB Log Replay Keeping Up</th>
								</tr>"
			
			$dagmemberHtml += $htmltableheader
			#End Member table HTML header
			
			#Begin Member table HTML rows
			foreach ($line in $dagmemberReport)
			{
				$htmltablerow = "<tr>"
				$htmltablerow += "<td><strong>$($line."Server")</strong></td>"
				$htmltablerow += (New-DAGMemberHTMLTableCell "ClusterService")
				$htmltablerow += (New-DAGMemberHTMLTableCell "ReplayService")
				$htmltablerow += (New-DAGMemberHTMLTableCell "ActiveManager")
				$htmltablerow += (New-DAGMemberHTMLTableCell "TasksRPCListener")
				$htmltablerow += (New-DAGMemberHTMLTableCell "TCPListener")
				$htmltablerow += (New-DAGMemberHTMLTableCell "ServerLocatorService")
				$htmltablerow += (New-DAGMemberHTMLTableCell "DAGMembersUp")
				$htmltablerow += (New-DAGMemberHTMLTableCell "ClusterNetwork")
				$htmltablerow += (New-DAGMemberHTMLTableCell "QuorumGroup")
				$htmltablerow += (New-DAGMemberHTMLTableCell "FileShareQuorum")
				$htmltablerow += (New-DAGMemberHTMLTableCell "DatabaseRedundancy")
				$htmltablerow += (New-DAGMemberHTMLTableCell "DatabaseAvailability")
				$htmltablerow += (New-DAGMemberHTMLTableCell "DBCopySuspended")
				$htmltablerow += (New-DAGMemberHTMLTableCell "DBCopyFailed")
				$htmltablerow += (New-DAGMemberHTMLTableCell "DBInitializing")
				$htmltablerow += (New-DAGMemberHTMLTableCell "DBDisconnected")
				$htmltablerow += (New-DAGMemberHTMLTableCell "DBLogCopyKeepingUp")
				$htmltablerow += (New-DAGMemberHTMLTableCell "DBLogReplayKeepingUp")
				$htmltablerow += "</tr>"
				$dagmemberHtml += $htmltablerow
			}
			$dagmemberHtml += "</table>
			</p>"
		}
		
		#Output the report objects to console, and optionally to email and HTML file
		#Forcing table format for console output due to issue with multiple output
		#objects that have different layouts

		#Write-Host "---- Database Copy Health Summary ----"
		#$dagdatabaseSummary | ft
				
		#Write-Host "---- Database Copy Health Details ----"
		#$dagdbcopyReport | ft
		
		#Write-Host "`r`n---- Server Test-Replication Report ----`r`n"
		#$dagmemberReport | ft
		
		if ($SendEmail -or $HTMLFile)
		{
			$dagreporthtml = $dagsummaryintro + $dagdatabaseSummaryHtml + $dagdetailintro + $databasedetailsHtml + $dagmemberintro + $dagmemberHtml
			$dagreportbody += $dagreporthtml
		}
		
	}
}
else
{
	$tmpstring = "No DAGs found"
	if ($Log) {Write-LogFile $tmpstring}
	Write-Verbose $tmpstring
	$dagreporthtml = "<p>No database availability groups found.</p>"
}
### End DAG Health Report

Write-Host $string16
### Begin report generation
if ($HTMLFile -or $SendEmail)
{
	#Get report generation timestamp
	$reportime = Get-Date

	#Create HTML Report
	#Common HTML head and styles
	$htmlhead="<html>
				<style>
				BODY{font-family: Arial; font-size: 8pt;}
				H1{font-size: 16px;}
				H2{font-size: 14px;}
				H3{font-size: 12px;}
				TABLE{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}
				TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}
				TD{border: 1px solid black; padding: 5px; }
				td.pass{background: #7FFF00;}
				td.warn{background: #FFE600;}
				td.fail{background: #FF0000; color: #ffffff;}
				td.info{background: #85D4FF;}
				</style>
				<body>
				<h1 align=""center"">Exchange Server Health Check Report</h1>
				<h3 align=""center"">Generated: $reportime</h3>"

	#Check if the DAG summary has 1 or more entries
	if ($($dagsummary.count) -gt 0)
	{
		#Set alert flag to true
		$alerts = $true
	
		#Generate the HTML
		$dagsummaryhtml = "<h3>Database Availability Group Health Check Summary</h3>
						<p>The following DAG errors and warnings were detected.</p>
						<p>
						<ul>"
		foreach ($reportline in $dagsummary)
		{
			$dagsummaryhtml +="<li>$reportline</li>"
		}
		$dagsummaryhtml += "</ul></p>"
		$alerts = $true
	}
	else
	{
		#Generate the HTML to show no alerts
		$dagsummaryhtml = "<h3>Database Availability Group Health Check Summary</h3>
						<p>No Exchange DAG errors or warnings.</p>"
	}


	$htmltail = "</body>
				</html>"

	$htmlreport = $htmlhead +  $dagsummaryhtml + $dagreportbody + $htmltail
	
	if ($HTMLFile)
	{
        Write-Verbose "Writing HTML report file"
		$htmlreport | Out-File $ReportFile -Encoding UTF8
	}

	if ($SendEmail)
	{
		if ($alerts -eq $false -and $AlertsOnly -eq $true)
		{
			#Do not send email message
			Write-Host $string19
			if ($Log) {Write-Logfile $string19}
		}
		else
		{
			#Send email message
			Write-Host $string14
			Send-MailMessage @smtpsettings -Body $htmlreport -BodyAsHtml -Encoding ([System.Text.Encoding]::UTF8)
		}
	}
}
### End report generation


Write-Host $string15


#...................................
# End
#...................................

if ($Log) {
	$timestamp = Get-Date -DisplayHint Time
	"$timestamp $logstring0" | Out-File $logfile
	Write-Logfile $logstring1
	Write-Logfile "  $now"
	Write-Logfile $logstring0
}
