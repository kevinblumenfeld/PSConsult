$PFs = import-csv .\HidePFs.csv

$PFs | % {Set-MailPublicFolder $_.identity -HiddenFromAddressListsEnabled:$True}