function Add-ProxyAddress {
    <#
	.SYNOPSIS
		Add Proxy Addresses to an AD User
	
	.DESCRIPTION
		Add Proxy Addresses to an AD User
	
	.PARAMETER EmailAddress
		The address of the mailboxes to which add ProxyAddresses.
	
	.PARAMETER OutputPath
		Where to write the report files to.
		By default it will write to the current path.
	
	.EXAMPLE
        Import-Csv .\EmailAddresses.csv | Add-ProxyAddress
                
        Example of EmailAddresses.csv
        
        Email, emailaddresses
        joe@contoso.com, joe@fabrikam.com joe@domain.com 
        sally@contoso.com, sally@fabrikam.com sally@domain.com 
        
#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('PrimarySmtpAddress')]
        [string[]]
        $Email,

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('ProxyAddresses')]
        [string[]]
        $EmailAddresses,
		
        [string]
        $OutputPath = "."
    )
    begin {
        $headerstring = ("mail" + "," + "ProxyAddress")
        $errheaderstring = ("mail" + "," + "Error")
		
        $successPath = Join-Path $OutputPath "Success.csv"
        $failedPath = Join-Path $OutputPath "Failed.csv"
        Out-File -FilePath $successPath -InputObject $headerstring -Encoding UTF8 -append
        Out-File -FilePath $failedPath -InputObject $errheaderstring -Encoding UTF8 -append
    }
    process {
        $dn = (Get-ADUser -LDAPFilter "(mail=$($Email))" -ErrorAction stop).distinguishedname
        $EmailAddresses -split (" ") | % {
            Try {
                Set-ADUser -Identity $dn -add @{"ProxyAddresses" = "smtp:$($_)"}
                $email + "," + "smtp:$($_)" | Out-file $successPath -Encoding UTF8 -append
            }
            catch {
                Write-Warning $_
                $email + "," + "smtp:$($_)" | Out-file $failedPath -Encoding UTF8 -append
            }
        }
    }
    end {
		
    }
}