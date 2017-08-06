<### Collect Active Directory information
# Author: James Brennan, EnPointe
# Destroyer: David Stein, EnPointe
#
# Version 1.2
# 09/17/2016
#
### Requires the following modules:
### ActiveDirectory, DNSServer, GroupPolicy, BestPractices
#
# 051016 - JB - Added parameters to specify forest and collected data
# 091716 - DS - Ran through tidy-ish formatting and minor changes
#>
Param(
    [parameter(Mandatory=$False)] [string] $ADForest,
    [parameter(Mandatory=$False)] [switch] $getAll,
    [parameter(Mandatory=$False)] [switch] $getDC,
    [parameter(Mandatory=$False)] [switch] $getAD,
    [parameter(Mandatory=$False)] [switch] $getDNS,
    [parameter(Mandatory=$False)] [switch] $getDHCP,
    [parameter(Mandatory=$False)] [switch] $getSites,
    [parameter(Mandatory=$False)] [switch] $getGPO,
    [parameter(Mandatory=$False)] [switch] $getReplication,
    [parameter(Mandatory=$False)] [switch] $getMissingSubnets
)
#
Import-Module ActiveDirectory
Import-Module GroupPolicy
[string] $DataPath = ".\Data"

Function Get-ActiveDirectoryForestObject {
    Param ([string]$ForestName, [System.Management.Automation.PsCredential]$Credential)
    Write-Debug "FUNCTION: Get-ActiveDirectoryForestObject"
    if (!$ForestName) {       
        $ForestName = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Name.ToString()    
    }        
    if ($Credential) {        
        $credentialUser = $Credential.UserName.ToString()
        $credentialPassword = $Credential.GetNetworkCredential().Password.ToString()
        $adCtx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("forest", $ForestName, $credentialUser, $credentialPassword )
    }    
    else {        
        $adCtx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("forest", $ForestName)    
    }        
    $output = ([System.DirectoryServices.ActiveDirectory.Forest]::GetForest($adCtx))    
    Return $output
}

Function Export-DNSServerIPConfiguration {
    param($Domain)
    Write-Debug "FUNCTION: Export-DNSServerIPConfiguration"
    $DNSReport = @()

    ForEach ($DomainEach in $Domain) {
        $DCs = netdom query /domain:$DomainEach dc |
            Where-Object {$_ -notlike "*accounts*" -and $_ -notlike "*completed*" -and $_}

        ForEach ($dc in $DCs) {
            $dnsFwd = Get-WMIObject -ComputerName $("$dc.$DomainEach") -Namespace root\MicrosoftDNS -Class MicrosoftDNS_Server -ErrorAction SilentlyContinue

            # Primary/Secondary (Self/Partner)
            # http://msdn.microsoft.com/en-us/library/windows/desktop/aa393295(v=vs.85).aspx
            $nic = Get-WMIObject -ComputerName $("$dc.$DomainEach") -Query "Select * From Win32_NetworkAdapterConfiguration Where IPEnabled=TRUE" -ErrorAction SilentlyContinue

            $DNSReport += 1 | 
                Select-Object `
                @{name="DC";expression={$dc}}, `
                @{name="Domain";expression={$DomainEach}}, `
                @{name="DNSHostName";expression={$nic.DNSHostName}}, `
                @{name="IPAddress";expression={$nic.IPAddress}}, `
                @{name="DNSServerAddresses";expression={$dnsFwd.ServerAddresses}}, `
                @{name="DNSServerSearchOrder";expression={$nic.DNSServerSearchOrder}}, `
                @{name="Forwarders";expression={$dnsFwd.Forwarders}}, `
                @{name="BootMethod";expression={$dnsFwd.BootMethod}}, `
                @{name="ScavengingInterval";expression={$dnsFwd.ScavengingInterval}}
        }
    }
    #$DNSReport | Format-Table -AutoSize -Wrap
    $DNSReport | Export-CSV $LogFile-DC_DNS_IP_Report.csv -NoTypeInformation
}

Function Export-DNSServerZoneReport {
    param($Domain)
    Write-Debug "FUNCTION: Export-DNSServerZoneReport"
    $Report = @()

    ForEach ($DomainEach in $Domain) {
        $DCs = netdom query /domain:$DomainEach dc |
            Where-Object {$_ -notlike "*accounts*" -and $_ -notlike "*completed*" -and $_}

        ForEach ($dc in $DCs) {
            $DCZones = $null
            Try {
                $DCZones = Get-DnsServerZone -ComputerName $("$dc.$DomainEach") |
                    Select-Object @{Name="Domain";Expression={$DomainEach}}, @{Name="Server";Expression={$("$dc.$DomainEach")}}, `
                        ZoneName, ZoneType, DynamicUpdate, IsAutoCreated, IsDsIntegrated, IsReverseLookupZone, ReplicationScope,    
                        DirectoryPartitionName, MasterServers, NotifyServers, SecondaryServers

                ForEach ($Zone in $DCZones) {
                    if ($Zone.ZoneType -eq 'Primary') {
                        $ZoneAging = Get-DnsServerZoneAging -ComputerName $("$dc.$DomainEach") -ZoneName $Zone.ZoneName |
                            Select-Object ZoneName, AgingEnabled, NoRefreshInterval, RefreshInterval, ScavengeServers
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name AgingEnabled -Value $ZoneAging.AgingEnabled
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name NoRefreshInterval -Value $ZoneAging.NoRefreshInterval
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name RefreshInterval -Value $ZoneAging.RefreshInterval
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name ScavengeServers -Value $ZoneAging.ScavengeServers
                    } 
                    else {
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name AgingEnabled -Value $null
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name NoRefreshInterval -Value $null
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name RefreshInterval -Value $null
                        Add-Member -InputObject $Zone -MemberType NoteProperty -Name ScavengeServers -Value $null
                    }
                }
                $Report += $DCZones
            } Catch {
                Write-Warning "Error connecting to $dc.$DomainEach."
            }
        }
    }
    $Report | Export-CSV -Path $LogFile-DNS_Zones.csv -NoTypeInformation -Force -Confirm:$false
}

Function Find-Missing-Subnets {
    <# START:Find_missing_subnets_in_ActiveDirectory
    This script will get all the missing subnets from the NETLOGON.LOG file from each
    Domain Controller in the Domain. It does this by copying all the NETLOGON.LOG files
    locally and then parsing them all to create a CSV output of unique IP Addresses.
    The CSV file is sorted by IP Address to make it easy to group them into subnets.
    Script Name: Find_missing_subnets_in_ActiveDirectory.ps1
    Release 1.2
    
    Syntax examples:
    - To execute the script in the current Domain:
        Find_missing_subnets_in_ActiveDirectory.ps1
        This script was derived from the AD-Find_missing_subnets_in_ActiveDirectory.ps1
    script written by Francois-Xavier CAT.
    - Report the AD Missing Subnets from the NETLOGON.log
        http://www.lazywinadmin.com/2013/10/powershell-report-ad-missing-subnets.html
    Changes:
    - Stripped down the code to remove the e-mail functionality. This is a nice to
        have feature and can be added back in for a future release. I felt that it was
        more important to focus on ensuring the core functionality of the script was
        working correctly and efficiently.
    Improvements:
    - Reordered the Netlogon.log collection to make it more efficient.
    - Implemented a fix to deal with the changes to the fields in the Netlogon.log
        file from Windows 2012 and above:
        - http://www.jhouseconsulting.com/2013/12/13/a-change-to-the-fields-in-the-netlogon-log-file-from-windows-2012-and-above-1029
    - Tidied up the way it writes the CSV file.
    - Changed the write-verbose and write-warning messages to write-host to vary the
        message colors and improve screen output.
    - Added a "replay" feature so that you have the ability to re-create the CSV
        from collected log files.
    #>
    #-------------------------------------------------------------
    param($TrustedDomain)
    #-------------------------------------------------------------
    Write-Debug "FUNCTION: Find-Missing-Subnets"
    # Set this to the last number of lines to read from each NETLOGON.log file.
    # This allows the report to contain the most recent and relevant errors.
    [Int]$LogsLines = "200"

    # Set this to $True to remove txt and log files from the output folder.
    $Cleanup = $False

    # Set this to $True if you have not removed the log files and want to replay
    # them to create a CSV.
    $ReplayLogFiles = $False

    #-------------------------------------------------------------

    # PATH Information 
    # Date and Time Information
    $DateFormat = Get-Date -Format "yyyyMMdd_HHmmss"
    $ScriptPathOutput = ".\$Logfile-Subnets"
    $OutputFile = "$LogFile-AD-Sites-MissingSubnets.csv"
    $CombineAndProcess = $False

    if ($ReplayLogFiles -eq $False) {
        if (-not(Test-Path -Path $ScriptPathOutput)) {
            Write-Host -ForegroundColor green "Creating the Output Folder: $ScriptPathOutput"
            New-Item -Path $ScriptPathOutput -ItemType Directory | Out-Null
        }

        if ([String]::IsNullOrEmpty($TrustedDomain)) {
            # Get the Current Domain Information
            $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        } 
        else {
            $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$TrustedDomain)
            Try {
                $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($context)
            }
            Catch [exception] {
                Write-Host -ForegroundColor Red $_.Exception.Message
                Exit
            }
        }

        Write-Host -ForegroundColor Green "Domain: $domain"
        Write-Host -ForegroundColor Green "Getting all Domain Controllers from $domain ..."
        $DomainControllers = $domain | 
            ForEach-Object -Process { $_.DomainControllers } | 
                Select-Object -Property Name

        Write-Host -ForegroundColor Green "Processing each Domain controller..."
        foreach ($dc in $DomainControllers) {
            $DCName = $($dc.Name)

            Write-Host -ForegroundColor Green "Gathering the log from $DCName..."

            if (Test-Connection -Cn $DCName -BufferSize 16 -Count 1 -ea 0 -quiet) {

                # NETLOGON.LOG path for the current Domain Controller
                $path = "\\$DCName\admin`$\debug\netlogon.log"

                if ((Test-Path -Path $path) -and ((Get-Item -Path $path).Length -ne $null)) {
                    # Copy the NETLOGON.log locally for the current DC
                    Write-Host -ForegroundColor Green "- Copying the $path file..."
                    $TotalTime = Measure-Command {Copy-Item -Path $path -Destination $ScriptPathOutput\$($dc.Name)-$DateFormat-netlogon.log}
                    $TotalSeconds = $TotalTime.TotalSeconds
                    Write-Host -ForegroundColor Green "- Copy completed in $TotalSeconds seconds."

                    if ((Get-Content -Path $path | Measure-Object -Line).lines -gt 0) {
                        # Export the $LogsLines last lines of the NETLOGON.log and send it to a file
                        ((Get-Content -Path $ScriptPathOutput\$DCName-$DateFormat-netlogon.log -ErrorAction Continue)[-$LogsLines .. -1]) | 
                        Foreach-Object {$_ -replace "\[\d{1,5}\] ", ""} |
                            Out-File -FilePath "$ScriptPathOutput\$DCName.txt" -ErrorAction 'Continue' -ErrorVariable ErrorOutFileNetLogon
                        Write-Host -ForegroundColor Green "- Exported the last $LogsLines lines to $ScriptPathOutput\$DCName.txt."
                    }
                    else {
                        Write-Host -ForegroundColor Green "- File Empty."
                    }
                } 
                else {
                    Write-Host -ForegroundColor Red "- $DCName is not reachable via the $path path."
                }
            } 
            else {
                Write-Host -ForegroundColor Red "- $DCName is not reachable or offline."
            }
            $CombineAndProcess = $True
        }
    } 
    else {
        Write-Host -ForegroundColor Green "Replaying the log files..."
        if (Test-Path -Path $ScriptPathOutput) {
            if ((Get-ChildItem $scriptpathoutput\*.log | Measure-Object).Count -gt 0) {
                $LogFiles = Get-ChildItem $scriptpathoutput\*.log
                ForEach ($LogFile in $LogFiles) {
                    $DCName = $LogFile.Name -Replace("-\d{7,8}_\d{6}-netlogon.log")
                    Write-Host -ForegroundColor Green "Processing the log from $DCName..."
                    if ((Get-Content -Path "$ScriptPathOutput\$($LogFile.Name)" | Measure-Object -Line).lines -gt 0) {
                        # Export the $LogsLines last lines of the NETLOGON.log and send it to a file
                        ((Get-Content -Path "$ScriptPathOutput\$($LogFile.Name)" -ErrorAction Continue)[-$LogsLines .. -1]) | 
                        Foreach-Object {$_ -replace "\[\d{1,5}\] ", ""} |
                            Out-File -FilePath "$ScriptPathOutput\$DCName.txt" -ErrorAction 'Continue' -ErrorVariable ErrorOutFileNetLogon
                        Write-Host -ForegroundColor Green "- Exported the last $LogsLines lines to $ScriptPathOutput\$DCName.txt."
                    } 
                    else {
                        Write-Host -ForegroundColor Green "- File Empty."
                    }
                    $CombineAndProcess = $True
                }
            } 
            else {
                Write-Host -ForegroundColor Red "There are no log files to process."
            }
        } 
        else {
            Write-Host -ForegroundColor Red "The $ScriptpathOutput folder is missing."
        }
    }

    if ($CombineAndProcess) {
        $FilesToCombine = Get-Content -Path "$ScriptPathOutput\*.txt" -Exclude "*All_Export.txt" -ErrorAction SilentlyContinue |
            Foreach-Object {$_ -replace "\[\d{1,5}\] ", ""}

        if ($FilesToCombine) {
            $FilesToCombine | Out-File -FilePath $ScriptPathOutput\$dateformat-All_Export.txt

            # Convert the TXT file to a CSV format
            Write-Host -ForegroundColor Green "Importing exported data to a CSV format..."
            $importString = Import-Csv -Path $ScriptPathOutput\$dateformat-All_Export.txt -Delimiter ' ' -Header Date,Time,Domain,Error,Name,IPAddress

            # Get Only the entries for the Missing Subnets
            $MissingSubnets = $importString | 
                Where-Object {$_.Error -like "*NO_CLIENT_SITE*"}
            Write-Host -ForegroundColor Green "Total of NO_CLIENT_SITE errors found within the last $LogsLines lines across all log files: $($MissingSubnets.count)"
            # Get the other errors from the log
            $OtherErrors = Get-Content $ScriptPathOutput\$dateformat-All_Export.txt | 
                Where-Object {$_ -notlike "*NO_CLIENT_SITE*"} | 
                    Sort-Object -Unique
            Write-Host -ForegroundColor Green "Total of other Error(s) found within the last $LogsLines lines across all log files: $($OtherErrors.count)"

            # Export to a CSV File
            $UniqueIPAddresses = $importString | 
                Select-Object -Property Date, Name, IPAddress, Domain, Error | 
                    Sort-Object -Property IPAddress -Unique
            $UniqueIPAddresses | Export-Csv -NoTypeInformation -Path "$OutputFile"
            
            # Remove the quotes
            (Get-Content "$OutputFile") | % {$_ -replace '"',""} | 
                Out-File "$OutputFile" -Force -Encoding ascii
            Write-Host -ForegroundColor Green "$($UniqueIPAddresses.count) unique IP Addresses exported to $OutputFile."
        }
        else {
            Write-Host -ForegroundColor Red "No .txt files to process."
        }

        if ($Cleanup) {
            Write-Host -ForegroundColor Green "Removing the .txt and .log files..."
            Remove-Item -Path $ScriptpathOutput\*.txt -Force
            Remove-Item -Path $ScriptPathOutput\*.log -Force
        }
    }
    Write-Host -ForegroundColor Green "Script Completed."
}

Function Get-PrivilegedGroupChanges {
    Param(
        $Server = (Get-ADDomainController -Discover | Select-Object -ExpandProperty HostName),
        $Hour = 24
    )
    Write-Debug "FUNCTION: Get-PrivilegedGroupChanges"
    $ProtectedGroups = Get-ADGroup -Filter 'AdminCount -eq 1' -Server $Server
    $Members = @()

    ForEach ($Group in $ProtectedGroups) {
        $Members += Get-ADReplicationAttributeMetadata -Server $Server `
            -Object $Group.DistinguishedName -ShowAllLinkedValues |        
                Where-Object {$_.IsLinkValue} | 
                    Select-Object @{name='GroupDN';expression={$Group.DistinguishedName}}, `
                        @{name='GroupName';expression={$Group.Name}}, *
    }

    $Members |
        Where-Object {$_.LastOriginatingChangeTime -gt (Get-Date).AddHours(-1 * $Hour)}
}

Function Get-GPOInformation {
    param (
        [parameter(Mandatory=$True)] [string] $DCName
    )
    Write-Debug "FUNCTION: Get-GPOInformation"
    Write-Output "Collecting Group Policy Information from $DCName..."
    Get-GPO -Server $DCName -All | Export-CSV $LogFile-AllGPO.csv
    Get-GPOReport -Server $DCName -All -ReportType Html -Path $LogFile-GPO.htm

    $AllADOU = Get-ADOrganizationalUnit -Server $DCName -Filter * -Properties * | 
        Sort-Object Canonicalname
    ForEach ($ADOU in $AllADOU) {
        $GPOLinks = Get-GPInheritance $ADOU.DistinguishedName
        ForEach ($GPOLink in $GPOLinks) {
            ForEach ($GPOID in $GPOLink.GpoLinks) {
                $ADOU.CanonicalName+"!"+$ADOU.ObjectGUID+"!"+$GPOID.DisplayName+"!Link!"+$GPOID.Enabled+"!"+$GPOID.Enforced+"!"+$GPOID.GpoId | 
                    Out-File $LogFile-GPOLinks.txt -Append
            }
            ForEach ($GPOID in $GPOLink.InheritedGpoLinks) {
                $ADOU.CanonicalName+"!"+$ADOU.ObjectGUID+"!"+$GPOID.DisplayName+"!Inherit!"+$GPOID.Enabled+"!"+$GPOID.Enforced+"!"+$GPOID.GpoId | 
                    Out-File $LogFile-GPOLinks.txt -Append
            }
        } 
    }
}

#======================================================================================================

Write-Output "Collecting Forest and Domain Information..."
$DCs = @() #Initialize the DC array
$Forest = Get-ActiveDirectoryForestObject ($ADForest)
$DomainList = $forest.Domains
$LogFile = $DomainList[0].Name
if (!(Test-Path $DataPath)) {
    md $DataPath
}
$LogFile = "$DataPath\$LogFile"

$DomainList | % {
    $DCs += $_.DomainControllers | Select Name
}
$closestDC = (Get-ADDomainController -DomainName $Forest -Discover).Name
Write-Output "Closest Domain Controller is $closestDC"

if ($getAll -eq $true -or $getDC -eq $true) {
    Write-Output "Collecting Domain Controller Information..."
    $DCs | % { 
        $DCName = $_.name
        $PingHost = Test-Connection -ComputerName $DCName -Quiet
        Write-Output "DC Name: $DCName"
        if (!$Pinghost) {
            Write-Host "Return Ping: $Pinghost" -Foreground Red 
        } 
        else { 
            Write-Output "Return Ping: $Pinghost" 
        }
        try {
            $ErrorActionPreference = "Stop"; #Throw a terminating error for a non-terminating error (can't contact server)
            Get-WmiObject Win32_LogicalDisk -Computername $DCName | 
                Where-Object { $_.DriveType -eq 3 } | 
                    Select @{label="Drive";expression={$_.DeviceId}}, @{label="Free Space (%)";expression={[Math]::Round(($_.FreeSpace/$_.Size)*100, 0)}} |
                        Export-CSV $LogFile-$DCName-Disks.csv 
        }
        catch { 
            'Error: {0}' -f $_.Exception.Message
        }
        finally { 
            $ErrorActionPreference = "Continue"; #Reset the error action pref to default
            Get-EventLog SYSTEM -Newest 5000 -Computer $DCName | 
                Where-Object {$_.EntryType -match "Error" -or $_.EntryType -match "Warning"} |
                    Export-CSV $LogFile-$DCName-SYSTEM.csv
        }
    }
}

if ($getAll -eq $true -or $getAD -eq $true) {
    Write-Output "Collecting AD Information..."
    Get-ADForest | 
        Export-CSV $LogFile-ADForest.csv -NoTypeInformation
    Get-ADDomain | 
        Export-CSV $LogFile-ADDomain.csv -NoTypeInformation
    Get-ADUser -server $closestDC -Filter * -Properties * | 
        Export-CSV $LogFile-ADUsers.csv -NoTypeInformation
    Get-ADComputer -server $closestDC -Filter * -Properties * | 
        Export-CSV $LogFile-ADComputers.csv -NoTypeInformation
    Get-ADGroup -server $closestDC -Filter * -Properties * | 
        Export-CSV $LogFile-ADGroups.csv -NoTypeInformation
    Get-ADUser -server $closestDC -Filter 'AdminCount -eq 1' -Properties MemberOf | 
        Select DistinguishedName,Enabled,GivenName,Name,SamAccountName,SID,Surname,ObjectClass,@{Name="MemberOf";expression={$_.MemberOf -join "'n"}},ObjectGUID,UserPrincipalName |
            Export-Csv $LogFile-ADUsers-Admin.csv -NoTypeInformation
    Get-ADGroup -server $closestDC -Filter 'AdminCount -eq 1' -Properties Members | 
        Select DistinguishedName,GroupCategory,GroupScope,Name,SamAccountName,ObjectClass,@{Name="Members";expression={$_.Members -join "'n"}},ObjectGUID,SID |
            Export-Csv $LogFile-ADGroups-Admin.csv -NoTypeInformation
    Get-PrivilegedGroupChanges -Hour (365*24) | 
        Export-Csv $LogFile-PrivGrpMemberChange.csv -NoTypeInformation
}

# Collect AD Sites and Subnets

if ($getAll -eq $true -or $getSites -eq $true) {
    Write-Output "Collecting Site Information..."
    if (!$ADForest) {
        [array] $ADSites = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Sites
    }
    else {
        $adCtx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("forest", $ADForest)
        [array] $ADSites = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($adCtx).Sites
    }

    $ADSiteFile=$LogFile+'-ADSites.txt'
    # Header
    Add-Content $ADSiteFile “Domains!SiteName!Subnets!Servers!AdjacentSites!SiteLink!InterSiteTopologyGenerator!Options”

    ForEach ($Site in $ADSites) {
        $SiteName = $Site.Name
        $SiteDomains = $Site.Domains
        $SiteSubnets = $Site.Subnets
        $SiteServers = $Site.Servers
        $SiteAdjacentSites = $Site.AdjacentSites
        $SiteSiteLinks = $Site.SiteLinks
        $SiteInterSiteTopologyGenerator = $Site.InterSiteTopologyGenerator
        $SiteOptions = $Site.Options

        $IPSubnets += $SiteSubnets

        Add-Content $ADSiteFile “$SiteDomains!$SiteName!$SiteSubnets!$SiteServers!$SiteAdjacentSites!$SiteSiteLink!$SiteInterSiteTopologyGenerator!$SiteOptions”
    }
    # Export array to CSV
    $IPSubnets|Select Site,Name,Location |Export-CSV $LogFile-IPSubnets.csv -NoTypeInformation
    # Site Links
    Get-ADObject -Filter 'objectClass -eq "siteLink"' -Searchbase (Get-ADRootDSE).ConfigurationNamingContext -Property Options, Cost, ReplInterval, SiteList, Schedule | 
        Select-Object Name, @{Name="SiteCount";Expression={$_.SiteList.Count}}, Cost, ReplInterval, `
            @{Name="Schedule";Expression={If ($_.Schedule){If(($_.Schedule -Join " ").Contains("240")){"NonDefault"}Else{"24x7"}}Else{"24x7"}}}, Options | 
            Format-Table * -AutoSize | 
                Out-File $LogFile-ADSiteLinks.txt
}

# Check Replication
if ($getAll -eq $true -or $getReplication -eq $true) {
    Write-Output "Collecting DC Diagnostics Information..."
    Write-Host "`tNote: this step might take a minute or two..." -ForegroundColor Green
    dcdiag /a /c /v /f:$LogFile-dcdiag.log
    Write-Output "Counting test output errors..."
    $dcErrors = Get-Content $LogFile-dcdiag.log | ?{$_ -like "*failed test*"}
    Write-Output "$($dcErrors.length) test errors were found"
    Write-Output "Collecting DC Replication Information..."
    repadmin /showrepl * /csv >$LogFile-showrepl.csv
}

# GPO
if ($getAll -eq $true -or $getGPO -eq $true) {
    Get-GPOInformation -DCName $closestDC
}

# Collect DHCP Export
if ($getAll -eq $true -or $getDHCP -eq $true) {
    Write-Output "Collecting DHCP Information..."
    netsh.exe dhcp server dump > $LogFile-DHCPdump.txt
}

# DNS
if ($getAll -eq $true -or $getDNS -eq $true) {
    Write-Output "Collecting DNS Information..."
    Import-Module DNSServer
    # Requires Domain to be entered
    Export-DNSServerIPConfiguration -Domain $DomainList[0]
    Export-DNSServerZoneReport -Domain $DomainList[0]
}

# Best Practices
if ($getAll -eq $true -or $getBPA -eq $true) {
    Write-Output "Collecting BPA..."
    Import-Module BestPractices
    Invoke-Bpamodel -ModelId Microsoft/Windows/DirectoryServices
    Get-Bparesult -ModelID Microsoft/Windows/DirectoryServices | 
        Where { $_.Severity -ne "Information" } | 
            Set-BpaResult -Exclude $true| 
                Export-CSV -Path $LogFile-BPA-DC.csv
}

# Missing Subnets
if ($getAll -eq $true -or $getMissingSubnets -eq $true) {
    Write-Output "Collecting Missing Subnets..."
    Find-Missing-Subnets -TrustedDomain $DomainList[0].Name
}

Write-Output "Finished"
	