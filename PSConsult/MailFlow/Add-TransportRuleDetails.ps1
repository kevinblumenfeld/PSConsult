function Add-TransportRuleDetails {
    <#
	.SYNOPSIS
        Adds details to Transport Rule.  If the transport rule does not exist it creates it.
	
	.DESCRIPTION
        Adds details to Transport Rule.  If the transport rule does not exist it creates it.
	
	.PARAMETER RecipientAddressContainsWords
        This parameter specifies a condition or part of a condition for the rule. The name of the corresponding exception parameter starts with ExceptIf.

        In on-premises Exchange, this condition is only available on Mailbox servers.

        The RecipientAddressContainsWords parameter specifies a condition that looks for words in recipient email addresses.
        You can specify multiple words separated by commas. This parameter works when the recipient is an individual user.
        This parameter doesn't work with distribution groups.
    
    .PARAMETER ExceptIfRecipientAddressContainsWords
        This parameter specifies an exception or part of an exception for the rule. The name of the corresponding condition doesn't include the ExceptIf prefix.

        In on-premises Exchange, this exception is only available on Mailbox servers.

        The ExceptIfRecipientAddressContainsWords parameter specifies an exception that looks for words in recipient email addresses.
        You can specify multiple words separated by commas. This parameter works when the recipient is an individual user.
        This parameter doesn't work with distribution groups.

        .PARAMETER SubjectOrBodyContainsWords
        This parameter specifies a condition or part of a condition for the rule. The name of the corresponding exception parameter starts with ExceptIf.

        In on-premises Exchange, this condition is available on Mailbox servers and Edge Transport servers.

        The SubjectOrBodyContainsWords parameter specifies a condition that looks for words in the Subject field or body of messages.

        .PARAMETER ExceptIfSubjectOrBodyContainsWords
        This parameter specifies an exception or part of an exception for the rule. The name of the corresponding condition doesn't include the ExceptIf prefix.

        In on-premises Exchange, this exception is available on Mailbox servers and Edge Transport servers.

        The ExceptIfSubjectOrBodyContainsWords parameter specifies an exception that looks for words in the Subject field or body of messages.

	.PARAMETER TransportRule
        Name of the Transport Rule to use.  If Transport Rule does not exist it will be created.
	
	.PARAMETER OutputPath
        Where to write the report files to.
        By default it will write to the current path.

	.EXAMPLE
        Import-Csv .\RuleDetails.csv | Add-TransportRuleDetails -TransportRule "Block Macros Except when Certain Words are used"
                
        Example of RuleDetails.csv

        AddressWords, SubjectWords
        fred@contoso.com, moon 
        jane@fabrikam.com, sun fire
        potato.com, ocean
#>
    [CmdletBinding()]
    param (
		
        [Parameter(Mandatory = $true)]
        [String]
        $TransportRule,

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('AddressWords')]
        [string[]]
        $RecipientAddressContainsWords,
        
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('ExceptAddressWords')]
        [string[]]
        $ExceptIfRecipientAddressContainsWords,
        
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('SubjectBodyWords')]
        [Alias('SBWords')]
        [string[]]
        $SubjectOrBodyContainsWords,
        
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('ExceptSubjectBodyWords')]
        [Alias('ExceptWords')]
        [string[]]
        $ExceptIfSubjectOrBodyContainsWords,

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('AttachmentWords')]
        [string[]]
        $AttachmentContainsWords,
                
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('AttachmentPatterns')]
        [string[]]
        $AttachmentMatchesPatterns,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("DeleteMessage", "NotifyRecipients")]
        $Action01,

        [string]
        $OutputPath = "."
    )
    begin {
        $Params = @{}
        $listAddressWords = $setAddressWords = New-Object System.Collections.Generic.List[System.Object]
        $headerstring = ("TransportRule" + "," + "IP")
        $errheaderstring = ("TransportRule" + "," + "IP" + "," + "Error")
		
        $successPath = Join-Path $OutputPath "Success.csv"
        $failedPath = Join-Path $OutputPath "Failed.csv"
        Out-File -FilePath $successPath -InputObject $headerstring -Encoding UTF8 -append
        Out-File -FilePath $failedPath -InputObject $errheaderstring -Encoding UTF8 -append
		
    }
    process {
        if ($RecipientAddressContainsWords) {
                $listAddressWords.add($RecipientAddressContainsWords)
                # Write-Host $RecipientAddressContainsWords
        }
        if ($ExceptIfRecipientAddressContainsWords) {

        }
        if ($SubjectOrBodyContainsWords) {

        }
        if ($ExceptIfSubjectOrBodyContainsWords) {

        }
        if ($AttachmentContainsWords) {

        }
        if ($AttachmentMatchesPatterns) {

        }
    }
    end {
        if ($Action01 -eq "DeleteMessage") {
            $Params.Add("DeleteMessage", $true)
        }
        if ($AddAddressWords) {
            $Params.Add("RecipientAddressContainsWords", $listAddressWords)
        }
        if (!(Get-TransportRule -Identity $TransportRule -ErrorAction SilentlyContinue)) {
            Try {
                New-TransportRule -Name $TransportRule @Params -ErrorAction Stop
                Write-Verbose "Transport Rule `"$TransportRule`" has been created."
            }
            Catch {
                $_
                Write-Verbose "Unable to Create Transport Rule"
                Throw
            }
        }
        else { 
            Write-Verbose "Transport Rule `"$TransportRule`" already exists."
            try {
                Set-TransportRule -Identity $TransportRule @Params
                Write-Verbose "Parameters: `t $Params" 
                $TransportRule + "," + $Params | Out-file $successPath -Encoding UTF8 -append
            }
            catch {
                Write-Warning $_
                $TransportRule + "," + $Params + "," + $_ | Out-file $failedPath -Encoding UTF8 -append
            }
        }
    }
}