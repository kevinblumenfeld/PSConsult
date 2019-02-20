Function Get-CustomerInfo {

    $hash = @{
        'ABC' = 'foo'
        'XYZ' = 'fighters'

    }

    $hash.keys | ForEach-Object {
        $id = $_
        [pscustomobject]@{
            Id   = $id
            Name = $hash["$id"]
        }
    }

}