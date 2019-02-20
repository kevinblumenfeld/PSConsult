$sourceFile = 'C:\scripts\noheader.csv'
$csvImport = Get-Content $sourceFile
$resultsarray = @()
ForEach ($row in $csvImport) {
    $dataSet = [ordered]@{} 
    ForEach ($cell in @($row -split ',')) {
        $cellKeyVal = $cell.Trim('"') -split '='
        If ($cellKeyVal[0]) {
            $dataSet.add($cellKeyVal[0], $cellKeyVal[1])
        }
    }
    $resultsarray += [PSCustomObject]$dataSet
}
$resultsarray


$sourceFile = 'C:\scripts\noheader.csv'
$header = Get-Content $sourceFile | Select-Object -First 1
$header = $header -split '"?,"?' -replace '^"|"$|=.*$'
Import-Csv $sourceFile -Header $header | ForEach-Object {
    foreach ($property in $_.PSObject.Properties) {
        $property.Value = ($property.Value -split '=', 2)[1]
    }
    $_
}


$sourceFile = 'C:\scripts\noheader.csv'
Get-Content $sourceFile | ForEach-Object {
    [PSCustomObject]($_ -replace '","', "`n" -replace '^"|"$' | ConvertFrom-StringData)
}

