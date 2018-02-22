$objects = Get-ADGroup -ResultSetSize $null -Filter * -Properties *
$properties = [System.Collections.Generic.HashSet[String]]::new()
foreach ($object in $objects) {
    foreach ($property in $object.PSObject.Properties) {
        $null = $properties.Add($property.Name)
    }
}
$objects | Select-Object ([String[]]$properties)