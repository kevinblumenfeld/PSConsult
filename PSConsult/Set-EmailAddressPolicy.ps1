import-csv c:\scripts\list.csv | 
    ForEach-Object {
    Get-Mailbox -identity $_.samaccountname | 
        try {
        Set-Mailbox -EmailAddressPolicyEnabled:$True -ErrorAction stop
        Write-Output "Successfully enabled EAP: $_.SamAccountName"
    }
    catch {
        Write-Output "Error on: $_.SamAccountName"
    }
}