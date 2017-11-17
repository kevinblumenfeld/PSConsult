################################################################################
#
#  Import-RetentionTags.ps1
#
#  $Path: File from which Retention Policy Tags and Policies are imported.
#  $Organization: Name of organization. Required only if new location is in  datacenter. 
#  $DomainController: Domain Controller. Optional.
#  $Update: Set true for updating. Default is True.
#  $Delete: Set true for deleting. Default is True.
#  $Confirm: Set true for asking input for update and delete. If it is false, then update 
#			and delete actions are performed based on Update and Delete parameters above.
################################################################################

Param($Path, $Organization, $DomainController, $Update, $Delete, $Confirm)

Import-LocalizedData -BindingVariable MigrateTags_Strings -FileName MigrateRetentionTags.strings.psd1

$parsedConfirm  = $True
$parsedUpdate = $True
$parsedDelete = $True

if ($Confirm -ne $null)
{
	if ($Confirm.ToLower().Equals("false"))
	{
		$parsedConfirm = $False;
	}
}

if ($Update -ne $null)
{
	if ($Update.ToLower().Equals("false"))
	{
		$parsedUpdate = $False;
	}
}

if ($Delete -ne $null)
{
	if ($Delete.ToLower().Equals("false"))
	{
		$parsedDelete = $False
	}
}

function EscapeXml([String]$text)
{
	return $text.replace('&', '&amp;').replace("'", '&apos;').replace('"', '&quot;').replace('<', '&lt;').replace('>', '&gt;') 
}

function CreateIdentity([String]$name)
{
	if($DCAdmin)
	{
		return ($Organization +  '\' + $name)
	}
	
	return $name;
}

function RemoveRetentionTags([String[]]$tagNames)
{
 	foreach($tagName in $tagNames)
	{
		$identity = CreateIdentity -name:$tagName
		Remove-RetentionPolicyTag $identity -Confirm:$false -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
	}
}

function RemoveRetentionPolicies([String[]]$policyNames)
{
 	foreach($policyName in $policyNames)
	{
		$identity = CreateIdentity -name:$policyName	
		Remove-RetentionPolicy $identity -Confirm:$false -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue
	}
}

function ArrayToString($array)
{
	$isFirst = $true;
	$str = "";
	foreach($i in $array)
	{
		if ($isFirst)
		{
			$isFirst = $false;
			$str = " " + $i;
		}
		else
		{
			$str += ", " + $i;
		}
	}
	
	$str += "."
	return $str
}

function FindInArray([String[]] $array, [String] $str)
{
	foreach($item in $array)
	{
		if ($item -eq $str)
		{
			return $true;
		}
	}
	
	return $false;
}


function CompareArrays([String[]]$a, [String[]]$b)
{
	if ($a -eq $null -and $b -eq $null)
	{
		return $true;
	}
	
	if ($a -eq $null -or $b -eq $null)
	{
		return $false;
	}
	
	if ($a.Length -eq 0 -and $b.Length -eq 0)
	{
		return $true;
	}

	if ($a.Length -eq 0 -or $b.Length -eq 0)
	{
		return $false;
	}
	
	if ($a.Length -ne $b.Length)
	{
		return $false;
	}

	$c = $a | Sort-Object
	$d = $b | Sort-Object

	$enum1 = $c.GetEnumerator()
	$enum2 = $d.GetEnumerator()

	while ($enum1.MoveNext() -and $enum2.MoveNext())
	{
		if($enum1.Current -ne $enum2.Current)
	  	{
			return $false;
		}
	}

	return $true;
}

if(!$Path)
{
	Write-Host $MigrateTags_Strings.SpecifyImportFile  -ForegroundColor:Red
   	exit;
}

$DCAdmin = $false
$OrgParam = Get-ManagementRole -Cmdlet Get-RetentionPolicyTag -CmdletParameters Organization
#	if any management roles have access to Organization paramenter, then this is a DC Admin.
$DCAdmin = !!$OrgParam

if($DCAdmin)
{
    if (!$Organization)
    {
	# Setting $DCadmin to false, so that Organization parameter is not used. 
		$DCAdmin = $false;
    }
}

$GetParams = @{
    ErrorAction = "SilentlyContinue"
	WarningAction = "SilentlyContinue"
}

if($DCAdmin)
{
    $GetParams["Organization"] = $Organization
}

[xml]$tags = Get-Content $Path

if ($tags)
{
    if ($tags.RetentionData.RetentionPolicyTag)
    {
		$duplicateTags = @()
		$readConfirmation = "n"

		foreach($tag in $tags.RetentionData.RetentionPolicyTag)
		{
			[Boolean]$RetentionEnabled = [System.Convert]::ToBoolean($tag.RetentionEnabled)
			[Boolean]$SystemTag = [System.Convert]::ToBoolean($tag.SystemTag)
			[Boolean]$MustDisplayCommentEnabled = [System.Convert]::ToBoolean($tag.MustDisplayCommentEnabled)
	    	
			$RetentionId = $tag.RetentionId
			$TagExists = Get-RetentionPolicyTag @GetParams  | where {$_.RetentionId -eq "$RetentionId" }
			if ($TagExists)
			{
				$tagName = $tag.Name
				
				if ($tagExists.Comment -eq $tag.Comment -and
					$tagExists.Name -eq $tag.Name  -and
					$tagExists.LabelForJournaling -eq $tag.LabelForJournaling -and
					$tagExists.MessageClass -eq $tag.MessageClass -and
					$tagExists.MessageFormatForJournaling -eq $tag.MessageFormatForJournaling -and
					$tagExists.MustDisplayCommentEnabled -eq $MustDisplayCommentEnabled -and
					$tagExists.RetentionAction -eq $tag.RetentionAction -and
					$tagExists.Type -eq $tag.Type -and
					$tagExists.RetentionEnabled -eq $RetentionEnabled -and
					$tagExists.SystemTag -eq $SystemTag -and 
					$tagExists.DomainController -eq $DomainController)
				{
					$commentArray = @()
					if ($tag.LocalizedComment.Comment)
					{
						foreach($comment in $tag.LocalizedComment.Comment)
						{
							$commentArray = $commentArray + $comment
						}
					}
					
					if (CompareArrays -a:$commentArray -b:$tagExists.LocalizedComment)
					{
						$locNameArray = @()
						
						if ($tag.LocalizedRetentionPolicyTagName.LocalizedName)
						{
							foreach($locName in $tag.LocalizedRetentionPolicyTagName.LocalizedName)
							{
								$locNameArray  = $locNameArray  + $locName
							}
						}
						
						if (CompareArrays -a:$locNameArray -b:$tagExists.LocalizedRetentionPolicyTagName)
						{
							if(!$tagExists.AgeLimitForRetention -and !$tag.AgeLimitForRetention)
							{
								continue;
							}
							
							if($tagExists.AgeLimitForRetention -eq $tag.AgeLimitForRetention)
							{
								continue;
							}
						}
					}
				}
				
				$duplicateTags = $duplicateTags + $tagName
			}
		}

		$tagsUpdatedMessage = ''
		$updateTags = $parsedUpdate
		if ($duplicateTags.Length -gt 0)
		{
			$tagsUpdatedMessage = ArrayToString($duplicateTags);
			if ($parsedConfirm -and -$parsedUpdate) 
			{
				do 
				{
					Write-Host ($MigrateTags_Strings.TagsAlreadyExist -f $tagsUpdatedMessage) -ForegroundColor:Yellow
					$readConfirmation = Read-Host
				} while ($readConfirmation.ToLower() -ne "y" -and $readConfirmation.ToLower() -ne "n")

				$updateTags = ($readConfirmation -eq "y")
			}
		}
		
		$tagsAdded = @()
		foreach($tag in $tags.RetentionData.RetentionPolicyTag)
		{
			[Boolean]$RetentionEnabled = [System.Convert]::ToBoolean($tag.RetentionEnabled)
			[Boolean]$SystemTag = [System.Convert]::ToBoolean($tag.SystemTag)
			[Boolean]$MustDisplayCommentEnabled = [System.Convert]::ToBoolean($tag.MustDisplayCommentEnabled)
	    	
			$RetentionId = $tag.RetentionId
			$TagExists = Get-RetentionPolicyTag @GetParams  | where {$_.RetentionId -eq "$RetentionId" }

			if (FindInArray -array:$duplicateTags -str:$tag.Name)
			{
			# Tag exists and different from on file.
				if (!$updateTags)
				{
				# User opted for not changing
					continue;
				}
			}
			elseif ($TagExists)
			{
			# Tag exists and same as on file.
				continue;
			}
			else
			{
				$tagsAdded += $tag.Name
			}
	        
			$newRetentionPolicyTagParameters = @{
				Name = $tag.Name
				Comment = $tag.Comment
				RetentionId = $tag.RetentionId 
				MessageClass = $tag.MessageClass 
				MustDisplayCommentEnabled = $MustDisplayCommentEnabled
				RetentionAction = $tag.RetentionAction 
				Type = $tag.Type 
				RetentionEnabled = $RetentionEnabled 
				SystemTag = $SystemTag 
				ErrorAction = "SilentlyContinue"
				WarningAction = "SilentlyContinue"
			}
	    	

			if($tag.AgeLimitForRetention)
			{
				$newRetentionPolicyTagParameters["AgeLimitForRetention"] = $tag.AgeLimitForRetention
			}

			if ($DomainController)
			{
				$newRetentionPolicyTagParameters["DomainController"] = $DomainController
			}

			if($DCAdmin)
			{
				$newRetentionPolicyTagParameters["Organization"] = $Organization
			}

			$commentArray = @()
			if ($tag.LocalizedComment.Comment)
			{
				foreach($comment in $tag.LocalizedComment.Comment)
				{
					$commentArray = $commentArray + $comment
				}
			}
			$newRetentionPolicyTagParameters["LocalizedComment"] = $commentArray		

			$locNameArray = @()
			if ($tag.LocalizedRetentionPolicyTagName.LocalizedName)
			{
				foreach($locName in $tag.LocalizedRetentionPolicyTagName.LocalizedName)
				{
					$locNameArray  = $locNameArray  + $locName
				}
			}	    		
			$newRetentionPolicyTagParameters["LocalizedRetentionPolicyTagName"] = $locNameArray 
			
			if ($TagExists)
			{
				$GetParams.Remove("Identity")
				$newRetentionPolicyTagParameters.Remove("Type")
				$newRetentionPolicyTagParameters.Remove("Organization")
				$newRetentionPolicyTagParameters.Remove("RetentionId")
				$RetentionId = $tag.RetentionId
				Get-RetentionPolicyTag @GetParams  | where {$_.RetentionId -eq "$RetentionId" } | Set-RetentionPolicyTag @newRetentionPolicyTagParameters -Confirm:$false
			}
			else
			{
				New-RetentionPolicyTag @newRetentionPolicyTagParameters
			}
		}

		if($tagsAdded -ne $null -and $tagsAdded.Length -gt 0)
		{
			$message = ArrayToString -array:$tagsAdded
			Write-Host ($MigrateTags_Strings.TagsCreated  -f $message) -ForegroundColor:Yellow
		}
		
		if ($updateTags)
		{
			if($tagsUpdatedMessage)
			{
				Write-Host ($MigrateTags_Strings.TagsUpdated  -f $tagsUpdatedMessage) -ForegroundColor:Yellow
			}	
		}
    }
	
	$GetParams.Remove("Identity")
	$destinationTags = Get-RetentionPolicyTag @GetParams
	$tagsToDelete = @();	
	if(!!$destinationTags)
	{
		foreach ($destinationTag in $destinationTags)
		{
			$tagRetentionId = $destinationTag.RetentionId
			$tagPath = "/RetentionData/RetentionPolicyTag[RetentionId='$tagRetentionId']"
			$t = $tags.SelectNodes($tagPath);
			if ($t.Count -eq 0)
			{
				$tagsToDelete += $destinationTag.Name;
			}
		}
	}
	
	$deleteTags = $parsedDelete
	if ($tagsToDelete.Length -gt 0)
	{
		if ($parsedConfirm -and $parsedDelete)
		{
	
			$tagMessage = ArrayToString($tagsToDelete);
			do 
			{
				Write-Host ($MigrateTags_Strings.TagsToBeDeleted -f $tagMessage) -ForegroundColor:Yellow
				$readConfirmation = Read-Host
 			 } while ($readConfirmation.ToLower() -ne "y" -and $readConfirmation.ToLower() -ne "n")

			$deleteTags = $readConfirmation -eq "y"
		}
		 
		if ($deleteTags)
		{
			RemoveRetentionTags -tagNames:$tagsToDelete 
			Write-Host ($MigrateTags_Strings.TagsDeleted -f $tagMessage) -ForegroundColor:Yellow
		}
	}

    if ($tags.RetentionData.RetentionPolicy)
    {
		$duplicatePolicies = @()
		$readConfirmation = "n"

		foreach($policy in $tags.RetentionData.RetentionPolicy)
		{
			$RetentionId = $policy.RetentionId
			$policyExists = Get-RetentionPolicy @GetParams | where {$_.RetentionId -eq "$RetentionId" }

			if ($policyExists)
			{
				$policyName = $policy.Name
				
				if ($policyExists.Name -eq $policy.Name  -and
					$policyExists.DomainController -eq $DomainController)
				{
					$tagArray = @()
					if ($policy.RetentionPolicyTagLinks.TagLink)
					{
						foreach($tagLink in $policy.RetentionPolicyTagLinks.TagLink)
						{
							$tagArray = $tagArray + $tagLink
						}
					}
	
					$ADPolicyTagLinks = @()	
			        foreach($tagLink in $policyExists.RetentionPolicyTagLinks)
					{
						$ADPolicyTagLinks += $tagLink.Name;
					}

					if (CompareArrays -a:$tagArray -b:$ADPolicyTagLinks)
					{
						continue;
					}
				}
				
				$duplicatePolicies= $duplicatePolicies+ $policyName 
			}

		}

		$policiesUpdatedMessage = ''
		$updatePolicies = $parsedUpdate
		if ($duplicatePolicies.Length -gt 0)
		{
			if ($parsedConfirm -and $parsedUpdate)
			{
				$policiesUpdatedMessage = ArrayToString($duplicatePolicies);
				do 
				{
					Write-Host ($MigrateTags_Strings.PoliciesAlreadyExist -f $policiesUpdatedMessage) -ForegroundColor:Yellow
					$readConfirmation = Read-Host
				} while ($readConfirmation.ToLower() -ne "y" -and $readConfirmation.ToLower() -ne "n")

				$updatePolicies = ($readConfirmation -eq "y")
			}
		}

		$policiesAdded = @()
		foreach($policy in $tags.RetentionData.RetentionPolicy)
		{
			$RetentionId = $policy.RetentionId
			$policyExists = Get-RetentionPolicy @GetParams | where {$_.RetentionId -eq "$RetentionId" }
			if (FindInArray -array:$duplicatePolicies -str:$policy.Name)
			{
			# Policy exists but different from on file.
				if (!$updatePolicies)
				{
				# User opted for not updating.
					continue;
				}
			}
			elseif ($PolicyExists)
			{
			# Policy exists but is not different from in file.
				continue;
			}
			else
			{
			
				$policiesAdded += $policy.Name
			}

			$newRetentionPolicyParameters = @{
				Name = $policy.Name
				RetentionId = $policy.RetentionId 
				ErrorAction = "SilentlyContinue"
				WarningAction = "SilentlyContinue"
			}
	        
			$tagArray = @()
			foreach($tagLink in $policy.RetentionPolicyTagLinks.TagLink)
			{
				$tagArray = $tagArray + $tagLink
			}
	        
			$newRetentionPolicyParameters["RetentionPolicyTagLinks"] = $tagArray
	                    
			if ($DomainController)
			{
				$newRetentionPolicyParameters["DomainController"] = $DomainController
			}

			if($DCAdmin)
			{
				$newRetentionPolicyParameters["Organization"] = $Organization
			}

			if ($PolicyExists)
			{
				$GetParams.Remove("Identity")
				$newRetentionPolicyParameters.Remove("Organization")
				$newRetentionPolicyParameters.Remove("RetentionId")
				$RetentionId = $policy.RetentionId
				Get-RetentionPolicy @GetParams  | where {$_.RetentionId -eq "$RetentionId" } | Set-RetentionPolicy @newRetentionPolicyParameters -Confirm:$false
			}
			else
			{
				New-RetentionPolicy @newRetentionPolicyParameters
			}
		}

		if($policiesAdded.Length -gt 0)
		{
			$message = ArrayToString -array:$policiesAdded
			Write-Host ($MigrateTags_Strings.PoliciesCreated -f $message) -ForegroundColor:Yellow
		}
		
		if ($updatePolicies)
		{
			if ($policiesUpdatedMessage)
			{
				Write-Host ($MigrateTags_Strings.PoliciesUpdated -f $policiesUpdatedMessage) -ForegroundColor:Yellow
			}
		}
	}
	
	$GetParams.Remove("Identity")
	$destinationPolicies = Get-RetentionPolicy @GetParams | where {$_.Name -ne "ArbitrationMailbox"}
	$policiesToDelete = @();	
	if(!!$destinationPolicies)
	{
		foreach ($destinationPolicy in $destinationPolicies)
		{
			$policyRetentionId = $destinationPolicy.RetentionId;
			$policyPath = "/RetentionData/RetentionPolicy[RetentionId='$policyRetentionId']"
			
			$p = $tags.SelectNodes($policyPath);
			if ($p.Count -eq 0)
			{
				$policiesToDelete += $destinationPolicy.Name;
			}
		}
	}
	
	if ($policiesToDelete.Length -gt 0)
	{
		$tagMessage = ArrayToString($policiesToDelete);
		if ($parsedConfirm -and $parsedDelete)
		{
			do 
			{
				Write-Host ($MigrateTags_Strings.PoliciesToBeDeleted -f $tagMessage) -ForegroundColor:Yellow
				$readConfirmation = Read-Host
			} while ($readConfirmation.ToLower() -ne "y" -and $readConfirmation.ToLower() -ne "n")

			$parsedDelete = ($readConfirmation -eq "y")
		}
		 
		if ($parsedDelete)
		{
			RemoveRetentionPolicies -policyNames:$policiesToDelete 
			Write-Host ($MigrateTags_Strings.PoliciesDeleted -f $tagMessage) -ForegroundColor:Yellow
		}
	}
}

# SIG # Begin signature block
# MIIdsQYJKoZIhvcNAQcCoIIdojCCHZ4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3U+9a2GnNxKnszWdy+7Sl467
# PZygghhlMIIEwzCCA6ugAwIBAgITMwAAAMhHIp2jDcrAWAAAAAAAyDANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTYwOTA3MTc1ODU0
# WhcNMTgwOTA3MTc1ODU0WjCBszELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjENMAsGA1UECxMETU9QUjEnMCUGA1UECxMebkNpcGhlciBEU0UgRVNO
# Ojk4RkQtQzYxRS1FNjQxMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoUNNyknhIcQy
# V4oQO4+cu9wdeLc624e9W0bwCDnHpdxJqtEGkv7f+0kYpyYk8rpfCe+H2aCuA5F0
# XoFWLSkOsajE1n/MRVAH24slLYPyZ/XO7WgMGvbSROL97ewSRZIEkFm2dCB1DRDO
# ef7ZVw6DMhrl5h8s299eDxEyhxrY4i0vQZKKwDD38xlMXdhc2UJGA0GZ16ByJMGQ
# zBqsuRyvxAGrLNS5mjCpogEtJK5CCm7C6O84ZWSVN8Oe+w6/igKbq9vEJ8i8Q4Vo
# hAcQP0VpW+Yg3qmoGMCvb4DVRSQMeJsrezoY7bNJjpicVeo962vQyf09b3STF+cq
# pj6AXzGVVwIDAQABo4IBCTCCAQUwHQYDVR0OBBYEFA/hZf3YjcOWpijw0t+ejT2q
# fV7MMB8GA1UdIwQYMBaAFCM0+NlSRnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3Rz
# L01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsG
# AQUFBzAChjxodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jv
# c29mdFRpbWVTdGFtcFBDQS5jcnQwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
# hvcNAQEFBQADggEBAJqUDyiyB97jA9U9vp7HOq8LzCIfYVtQfJi5PUzJrpwzv6B7
# aoTC+iCr8QdiMG7Gayd8eWrC0BxmKylTO/lSrPZ0/3EZf4bzVEaUfAtChk4Ojv7i
# KCPrI0RBgZ0+tQPYGTjiqduQo2u4xm0GbN9RKRiNNb1ICadJ1hkf2uzBPj7IVLth
# V5Fqfq9KmtjWDeqey2QBCAG9MxAqMo6Epe0IDbwVUbSG2PzM+rLSJ7s8p+/rxCbP
# GLixWlAtuY2qFn01/2fXtSaxhS4vNzpFhO/z/+m5fHm/j/88yzRvQfWptlQlSRdv
# wO72Vc+Nbvr29nNNw662GxDbHDuGN3S65rjPsAkwggYHMIID76ADAgECAgphFmg0
# AAAAAAAcMA0GCSqGSIb3DQEBBQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAX
# BgoJkiaJk/IsZAEZFgltaWNyb3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290
# IENlcnRpZmljYXRlIEF1dGhvcml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMx
# MzAzMDlaMHcxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAf
# BgNVBAMTGE1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAJ+hbLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn
# 0UytdDAgEesH1VSVFUmUG0KSrphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0
# Zxws/HvniB3q506jocEjU8qN+kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4n
# rIZPVVIM5AMs+2qQkDBuh/NZMJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YR
# JylmqJfk0waBSqL5hKcRRxQJgp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54
# QTF3zJvfO4OToWECtR0Nsfz3m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8G
# A1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsG
# A1UdDwQEAwIBhjAQBgkrBgEEAYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJg
# QFYnl+UlE/wq4QpTlVnkpKFjpGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcG
# CgmSJomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3Qg
# Q2VydGlmaWNhdGUgQXV0aG9yaXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJ
# MEcwRaBDoEGGP2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1
# Y3RzL21pY3Jvc29mdHJvb3RjZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYB
# BQUHMAKGOGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9z
# b2Z0Um9vdENlcnQuY3J0MBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEB
# BQUAA4ICAQAQl4rDXANENt3ptK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1i
# uFcCy04gE1CZ3XpA4le7r1iaHOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+r
# kuTnjWrVgMHmlPIGL4UD6ZEqJCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGct
# xVEO6mJcPxaYiyA/4gcaMvnMMUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/F
# NSteo7/rvH0LQnvUU3Ih7jDKu3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbo
# nXCUbKw5TNT2eb+qGHpiKe+imyk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0
# NbhOxXEjEiZ2CzxSjHFaRkMUvLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPp
# K+m79EjMLNTYMoBMJipIJF9a6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2J
# oXZhtG6hE6a/qkfwEm/9ijJssv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0
# eFQF1EEuUKyUsKV4q7OglnUa2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng
# 9wFlb4kLfchpyOZu6qeXzjEp/w7FW1zYTRuh2Povnj8uVRZryROj/TCCBhEwggP5
# oAMCAQICEzMAAACOh5GkVxpfyj4AAAAAAI4wDQYJKoZIhvcNAQELBQAwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMTAeFw0xNjExMTcyMjA5MjFaFw0xODAy
# MTcyMjA5MjFaMIGDMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQ
# MA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9u
# MQ0wCwYDVQQLEwRNT1BSMR4wHAYDVQQDExVNaWNyb3NvZnQgQ29ycG9yYXRpb24w
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDQh9RCK36d2cZ61KLD4xWS
# 0lOdlRfJUjb6VL+rEK/pyefMJlPDwnO/bdYA5QDc6WpnNDD2Fhe0AaWVfIu5pCzm
# izt59iMMeY/zUt9AARzCxgOd61nPc+nYcTmb8M4lWS3SyVsK737WMg5ddBIE7J4E
# U6ZrAmf4TVmLd+ArIeDvwKRFEs8DewPGOcPUItxVXHdC/5yy5VVnaLotdmp/ZlNH
# 1UcKzDjejXuXGX2C0Cb4pY7lofBeZBDk+esnxvLgCNAN8mfA2PIv+4naFfmuDz4A
# lwfRCz5w1HercnhBmAe4F8yisV/svfNQZ6PXlPDSi1WPU6aVk+ayZs/JN2jkY8fP
# AgMBAAGjggGAMIIBfDAfBgNVHSUEGDAWBgorBgEEAYI3TAgBBggrBgEFBQcDAzAd
# BgNVHQ4EFgQUq8jW7bIV0qqO8cztbDj3RUrQirswUgYDVR0RBEswSaRHMEUxDTAL
# BgNVBAsTBE1PUFIxNDAyBgNVBAUTKzIzMDAxMitiMDUwYzZlNy03NjQxLTQ0MWYt
# YmM0YS00MzQ4MWU0MTVkMDgwHwYDVR0jBBgwFoAUSG5k5VAF04KqFzc3IrVtqMp1
# ApUwVAYDVR0fBE0wSzBJoEegRYZDaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3Br
# aW9wcy9jcmwvTWljQ29kU2lnUENBMjAxMV8yMDExLTA3LTA4LmNybDBhBggrBgEF
# BQcBAQRVMFMwUQYIKwYBBQUHMAKGRWh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2lvcHMvY2VydHMvTWljQ29kU2lnUENBMjAxMV8yMDExLTA3LTA4LmNydDAMBgNV
# HRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4ICAQBEiQKsaVPzxLa71IxgU+fKbKhJ
# aWa+pZpBmTrYndJXAlFq+r+bltumJn0JVujc7SV1eqVHUqgeSxZT8+4PmsMElSnB
# goSkVjH8oIqRlbW/Ws6pAR9kRqHmyvHXdHu/kghRXnwzAl5RO5vl2C5fAkwJnBpD
# 2nHt5Nnnotp0LBet5Qy1GPVUCdS+HHPNIHuk+sjb2Ns6rvqQxaO9lWWuRi1XKVjW
# kvBs2mPxjzOifjh2Xt3zNe2smjtigdBOGXxIfLALjzjMLbzVOWWplcED4pLJuavS
# Vwqq3FILLlYno+KYl1eOvKlZbiSSjoLiCXOC2TWDzJ9/0QSOiLjimoNYsNSa5jH6
# lEeOfabiTnnz2NNqMxZQcPFCu5gJ6f/MlVVbCL+SUqgIxPHo8f9A1/maNp39upCF
# 0lU+UK1GH+8lDLieOkgEY+94mKJdAw0C2Nwgq+ZWtd7vFmbD11WCHk+CeMmeVBoQ
# YLcXq0ATka6wGcGaM53uMnLNZcxPRpgtD1FgHnz7/tvoB3kH96EzOP4JmtuPe7Y6
# vYWGuMy8fQEwt3sdqV0bvcxNF/duRzPVQN9qyi5RuLW5z8ME0zvl4+kQjOunut6k
# LjNqKS8USuoewSI4NQWF78IEAA1rwdiWFEgVr35SsLhgxFK1SoK3hSoASSomgyda
# Qd691WZJvAuceHAJvDCCB3owggVioAMCAQICCmEOkNIAAAAAAAMwDQYJKoZIhvcN
# AQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAw
# BgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDEx
# MB4XDTExMDcwODIwNTkwOVoXDTI2MDcwODIxMDkwOVowfjELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9zb2Z0IENvZGUg
# U2lnbmluZyBQQ0EgMjAxMTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIB
# AKvw+nIQHC6t2G6qghBNNLrytlghn0IbKmvpWlCquAY4GgRJun/DDB7dN2vGEtgL
# 8DjCmQawyDnVARQxQtOJDXlkh36UYCRsr55JnOloXtLfm1OyCizDr9mpK656Ca/X
# llnKYBoF6WZ26DJSJhIv56sIUM+zRLdd2MQuA3WraPPLbfM6XKEW9Ea64DhkrG5k
# NXimoGMPLdNAk/jj3gcN1Vx5pUkp5w2+oBN3vpQ97/vjK1oQH01WKKJ6cuASOrdJ
# Xtjt7UORg9l7snuGG9k+sYxd6IlPhBryoS9Z5JA7La4zWMW3Pv4y07MDPbGyr5I4
# ftKdgCz1TlaRITUlwzluZH9TupwPrRkjhMv0ugOGjfdf8NBSv4yUh7zAIXQlXxgo
# tswnKDglmDlKNs98sZKuHCOnqWbsYR9q4ShJnV+I4iVd0yFLPlLEtVc/JAPw0Xpb
# L9Uj43BdD1FGd7P4AOG8rAKCX9vAFbO9G9RVS+c5oQ/pI0m8GLhEfEXkwcNyeuBy
# 5yTfv0aZxe/CHFfbg43sTUkwp6uO3+xbn6/83bBm4sGXgXvt1u1L50kppxMopqd9
# Z4DmimJ4X7IvhNdXnFy/dygo8e1twyiPLI9AN0/B4YVEicQJTMXUpUMvdJX3bvh4
# IFgsE11glZo+TzOE2rCIF96eTvSWsLxGoGyY0uDWiIwLAgMBAAGjggHtMIIB6TAQ
# BgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQUSG5k5VAF04KqFzc3IrVtqMp1ApUw
# GQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB
# /wQFMAMBAf8wHwYDVR0jBBgwFoAUci06AjGQQ7kUBU7h6qfHMdEjiTQwWgYDVR0f
# BFMwUTBPoE2gS4ZJaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJv
# ZHVjdHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNybDBeBggrBgEFBQcB
# AQRSMFAwTgYIKwYBBQUHMAKGQmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kv
# Y2VydHMvTWljUm9vQ2VyQXV0MjAxMV8yMDExXzAzXzIyLmNydDCBnwYDVR0gBIGX
# MIGUMIGRBgkrBgEEAYI3LgMwgYMwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvZG9jcy9wcmltYXJ5Y3BzLmh0bTBABggrBgEFBQcC
# AjA0HjIgHQBMAGUAZwBhAGwAXwBwAG8AbABpAGMAeQBfAHMAdABhAHQAZQBtAGUA
# bgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAZ/KGpZjgVHkaLtPYdGcimwuWEeFj
# kplCln3SeQyQwWVfLiw++MNy0W2D/r4/6ArKO79HqaPzadtjvyI1pZddZYSQfYtG
# UFXYDJJ80hpLHPM8QotS0LD9a+M+By4pm+Y9G6XUtR13lDni6WTJRD14eiPzE32m
# kHSDjfTLJgJGKsKKELukqQUMm+1o+mgulaAqPyprWEljHwlpblqYluSD9MCP80Yr
# 3vw70L01724lruWvJ+3Q3fMOr5kol5hNDj0L8giJ1h/DMhji8MUtzluetEk5CsYK
# wsatruWy2dsViFFFWDgycScaf7H0J/jeLDogaZiyWYlobm+nt3TDQAUGpgEqKD6C
# PxNNZgvAs0314Y9/HG8VfUWnduVAKmWjw11SYobDHWM2l4bf2vP48hahmifhzaWX
# 0O5dY0HjWwechz4GdwbRBrF1HxS+YWG18NzGGwS+30HHDiju3mUv7Jf2oVyW2ADW
# oUa9WfOXpQlLSBCZgB/QACnFsZulP0V3HjXG0qKin3p6IvpIlR+r+0cjgPWe+L9r
# t0uX4ut1eBrs6jeZeRhL/9azI2h15q/6/IvrC4DqaTuv/DDtBEyO3991bWORPdGd
# Vk5Pv4BXIqF4ETIheu9BCrE/+6jMpF3BoYibV3FWTkhFwELJm3ZbCoBIa/15n8G9
# bW1qyVJzEw16UM0xggS2MIIEsgIBATCBlTB+MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5n
# IFBDQSAyMDExAhMzAAAAjoeRpFcaX8o+AAAAAACOMAkGBSsOAwIaBQCggcowGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFBk95unj+rCG+5iEMXGrV5BUERjiMGoGCisG
# AQQBgjcCAQwxXDBaoDKAMABJAG0AcABvAHIAdAAtAFIAZQB0AGUAbgB0AGkAbwBu
# AFQAYQBnAHMALgBwAHMAMaEkgCJodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vZXhj
# aGFuZ2UgMA0GCSqGSIb3DQEBAQUABIIBAKJBIxXWDHVJ+VK9FymGlYYR+h8cBzga
# YgPD4b5Xydsk9tEtkYQ06/kMlie+TFUpdO8VphqWWC4W31q4k9G3hSsDpAheEmNW
# /p03wyrSbVkVS4Z/ZBWQAJdTOt8LPea+x9k2WsoZoEmnAaZ7J9kr3lKy8SfQ58MP
# pEQ3mu2pWRvvElNq7Pqq8AyDSBTR4IclKO1rl+PSGs6aBOgg2MJbJQQ5hyoNXxYR
# gvhFDLC7hI0wKcS9tpzEAs19V7FNfc3zycEQ2ACds2R9KCzAk9+M55HmO1gZ3VwS
# Jx8t/Ve3P/vPQrYrfcTtw6jenHP2fKixwcSkUma8soimgbCyL3ouUC6hggIoMIIC
# JAYJKoZIhvcNAQkGMYICFTCCAhECAQEwgY4wdzELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEhMB8GA1UEAxMYTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# UENBAhMzAAAAyEcinaMNysBYAAAAAADIMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0B
# CQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0xNzA5MDcxODMxNDJaMCMG
# CSqGSIb3DQEJBDEWBBTjRm4XcL5fAKEGt1MXzV0VtbCf8zANBgkqhkiG9w0BAQUF
# AASCAQBxVNDA00ZES6oB7rCsRe2FzuwymFUMW4WlFJ7lMCvwJHlmUstmB85MsX4c
# ecVZnTFjCUH/OaTP9xKZNPcyozZjsNEY6F2CWl1OwYq4Qcy3MMw44hTfgu0UCSFI
# 2SV7hLdfLmA5CGZ63UG68V/yIOUBhLkZyuokkS7P2Vusu/k4Lp4RTAVEkI9oVez3
# qp9Dn6Z6ziCZEsYAZ0kxCQ5m6iu40M4AzK97rpbu43DIvSNt6rUU/DNgdEnlBmep
# zha5IissqaBTkiGWCDslkZPweBgGXcjre3dpz05fkpkSTO6fH1AqOyS5s7/NiVbh
# zYrRwFznbxSe9OQJKity6f5kqEc3
# SIG # End signature block
