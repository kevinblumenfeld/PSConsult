Import-Csv "C:\Scripts\msolgroups.csv" | Select -ExpandProperty Displayname | % {
    $id = $_  
    try {
        $on = Get-Group -Identity $id -ErrorAction stop
        $dn = $on.name
        $ou = $on.organizationalunit
        write-log -Log C:\Scripts\whereDG77.csv -AddToLog ("$dn" + "," + "$ou")
    } 
    catch {
        write-log -Log C:\Scripts\DGBadLOG77.csv -AddToLog $id
    }
}