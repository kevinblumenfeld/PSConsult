function Add-IPtoAllowList {
    <#
	.SYNOPSIS
		Adds a list of IP Addresses to a Hosted Connection Filter Policy.  If the policy does not exist it creates it.
	
	.DESCRIPTION
		Adds a list of IP Addresses to a Hosted Connection Filter Policy.  If the policy does not exist it creates it.
	
	.PARAMETER IPs
		The IP addresses to be added to the Allow List of a Hosted Connection Filter Policy.
        
		You enter the IP addresses using the following syntax:

		Single IP   For example, 192.168.1.1
		IP range   You can use an IP address range, for example, 192.168.0.1-192.168.0.254
		CIDR IP   You can use Classless InterDomain Routing (CIDR), for example, 192.168.0.1/25
	
	.PARAMETER ConnectionFilterPolicy
		Name of the Connection Filter Policy to use.  If Connection Filter Policy does not exist it will be created.
	
	.PARAMETER OutputPath
		Where to write the report files to.
		By default it will write to the current path.
	
	.EXAMPLE
		Import-Csv .\IP.csv | Add-IPtoAllowList -ConnectionFilterPolicy "IP Addresses of Partners"
                
		Example of IP.csv
		
		IP
		64.43.44.42
		68.44.41.41
		72.32.32.11
#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('IP')]
        [Alias('Address')]
        [string[]]
        $IPs,
		
        [Parameter(Mandatory = $true)]
        [String]
        $ConnectionFilterPolicy,
		
        [string]
        $OutputPath = "."
    )
    begin {
        $headerstring = ("Policy" + "," + "IP")
        $errheaderstring = ("Policy" + "," + "IP" + "," + "Error")
		
        $successPath = Join-Path $OutputPath "Success.csv"
        $failedPath = Join-Path $OutputPath "Failed.csv"
        Out-File -FilePath $successPath -InputObject $headerstring -Encoding UTF8 -append
        Out-File -FilePath $failedPath -InputObject $errheaderstring -Encoding UTF8 -append
		
        if (!(Get-HostedConnectionFilterPolicy -Identity $ConnectionFilterPolicy -ErrorAction SilentlyContinue)) {
            Try {
                New-HostedConnectionFilterPolicy -name $ConnectionFilterPolicy
                Write-Verbose "Connection Filter Policy `"$ConnectionFilterPolicy`" has been created."
            }
            Catch {
                $_
                Write-Verbose "Unable to Create Connection Filter Policy"
                Throw
            }
        }
        else { 
            Write-Verbose "Connection Filter Policy `"$ConnectionFilterPolicy`" already exists."
        }
    }
    process {
        foreach ($IP in $IPs) {
            try {
                Set-HostedConnectionFilterPolicy -Identity $ConnectionFilterPolicy -IPAllowList @{add = $IP}
                Write-Verbose "IP Address added: `t $IP" 
                $ConnectionFilterPolicy + "," + $IP | Out-file $successPath -Encoding UTF8 -append
            }
            catch {
                Write-Warning $_
                $ConnectionFilterPolicy + "," + $IP + "," + $_ | Out-file $failedPath -Encoding UTF8 -append
            }
        }
    }
    end {
		
    }
}
