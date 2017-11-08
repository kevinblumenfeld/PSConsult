Import-CSV .\Domains.csv | Foreach {New-MsolDomain -Name $_.DomainName}
Get-MsolDomain -Status unverified | Foreach {Get-MsolDomainVerificationDns -DomainName $_.Name -Mode DNSTxtRecord}
Get-MsolDomain -Status unverified | Foreach {Confirm-MsolDomain -DomainName $_.Name}
