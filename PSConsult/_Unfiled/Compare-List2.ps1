function Compare-List2 {
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $AZURE,

        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo] $AD  
    )
    $dataSet1 = @{}
    Import-Csv $AD | ForEach-Object { 
        $UPN = $_.UserPrincipalName
        Write-Verbose $UPN
        $dataSet1.Add($_.UserPrincipalName, $_) 
    }

    Import-Csv $AZURE | ForEach-Object { 
        if (-not $dataSet1.Contains($_.UserPrincipalName)) {
            [PSCustomObject]@{
                UserPrincipalName = $_.UserPrincipalName
                DisplayName       = $_.DisplayName
            }        
        }
    }
    
}
