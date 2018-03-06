$contacts = Get-MailContact -ResultSize unlimited | select PrimarySmtpAddress, @{n = "EmailAddresses"; e = {$_.EmailAddresses}}
$hashset = [System.Collections.Generic.HashSet[string]]::new()
ForEach ($contact in $contacts) {
    (($contact.emailaddresses).split(";")| ? {$_ -like "x500:/o=ExchangeLabs/ou=Exchange Administrative Group*"}) |
        % {
        $hashset.add($_)
    }
}