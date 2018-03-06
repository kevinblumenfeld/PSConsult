$contacts = Import-Csv D:\docs\contacts\galsync\GalSync.csv | Select primarysmtpaddress, x500
ForEach ($contact in $contacts) {
    (($contact.x500).split(";")| ? {($_ -like "x500:/o=ExchangeLabs/ou=Exchange Administrative Group*") -and $_ -notin $hashset}) |
        % {
        [PSCustomObject]@{
            PrimarySMTPAddress = $contact.primarysmtpaddress
            x500               = $_
        }
    }
}