function Enable-ActiveSync {
    <#
	.SYNOPSIS
		Enable ActiveSync for all mailboxes except a list of mailbox Primary SMTP Addresses
	
	.DESCRIPTION
		Enable ActiveSync for all mailboxes except a list of mailbox Primary SMTP Addresses
	
	.PARAMETER EmailAddress
		The address of the mailbox to Enable active sync for.
		Accepts mailbox objects.
	
	.PARAMETER ExceptionListPath
		Path to a plaintext list of email addresses. These will not be processed.
	
	.PARAMETER OutputPath
		Where to write the report files to.
		By default it will write to the current path.
	
	.EXAMPLE
        Get-Mailbox -ResultSize unlimited | Enable-ActiveSync -ExceptionListPath c:\scripts\exceptionlist.txt
                
        Example of ExceptionList.txt
        
        joe@contoso.com
        sally@contoso.com
        harry@contoso.com
#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('PrimarySmtpAddress')]
        [string[]]
        $EmailAddress,
		
        [Parameter()]
        [System.IO.FileInfo]
        $ExceptionListPath,
		
        [string]
        $OutputPath = "."
    )
    begin {
        $headerstring = ("PrimarySMTP")
        $errheaderstring = ("PrimarySMTP" + "," + "Error")
		
        $successPath = Join-Path $OutputPath "SuccessDisableActiveSync.csv"
        $failedPath = Join-Path $OutputPath "FailedDisableActiveSync.csv"
        Out-File -FilePath $successPath -InputObject $headerstring -Encoding UTF8 -append
        Out-File -FilePath $failedPath -InputObject $errheaderstring -Encoding UTF8 -append
		
        if ($ExceptionListPath) {
            $exemptAddresses = Get-Content $ExceptionListPath.FullName
        }
        else { $exemptAddresses = @()}
    }
    process {
        $saved = $global:ErrorActionPreference
        $global:ErrorActionPreference = 'stop'
        foreach ($address in $EmailAddress) {
            if ($exemptAddresses -contains $address) { continue }
            try {
                $gms = Set-CasMailbox -identity $address -ActiveSyncEnabled:$true -ErrorAction stop
                $address | Out-file $successPath -Encoding UTF8 -append
            }
            catch {
                Write-Warning $_
                $address + "," + $_ | Out-file $failedPath -Encoding UTF8 -append
            }
            finally {
                $global:ErrorActionPreference = $saved
            }
        }
    }
    end {
		
    }
}