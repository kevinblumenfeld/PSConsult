#region Import Modules and Check needed apps
#Modules are required otherwise information is not retrieveable

        If (Test-Path "HKLM:\SOFTWARE\Microsoft\Exchange\v8.0")
        {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin -EA SilentlyContinue
        Write-Host "Exchange 2007 is not supported and NO information will be retrieved from 2007 Exchange servers" -ForegroundColor Red

        }
        ElseIf ((Test-Path "HKLM:\SOFTWARE\Microsoft\ExchangeServer\v14") -or (Test-Path "HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15"))
        {
         Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -EA SilentlyContinue
		 }
        Else
        {Write-Host "No Exchange Console install could be found!" -ForegroundColor Red}
#endregion Import Modules


#Create an Empty Array to store the results of each file in.
$Data = @()

#Function Filter Data out of each RPC Client Access Log file 
Function Filter-Data
{Param($FullFilePath)
If (Test-Path $FullFilePath)
    {
$Results = @(Get-Content -path $FullFilePath  | ConvertFrom-Csv -Header date-time,session-id,`
seq-number,client-name,organization-info,client-software,client-software-version,client-mode,client-ip,server-ip,protocol,application-id,`
operation,rpc-status,processing-time,operation-specific,failures | `
?{($_."client-software" -eq 'OUTLOOK.EXE') -and ($_."client-name" -ne $null)} |`
 Select client-software,client-software-version,client-mode,@{Name='client-name';Expression={($_."client-name")}} -Unique)
Return $Results 
   }
}


$Servers = @(Get-ExchangeServer |?{(($_.IsClientAccessServer -eq '$true') -and (($_.AdminDisplayVersion).major -eq '14')) `
-or (($_.IsMailboxServer -eq '$true') -and (($_.AdminDisplayVersion).major -ge '15')) } | `
Select Name,@{Name='Path';Expression={("\\$($_.fqdn)\" + "$($_.Datapath)").Replace(':','$').Replace("Mailbox","Logging\RPC Client Access")}} )

ForEach ($Item in $Servers)
{
$Thefile = @(GCI -Path $Item.Path -Filter *.log | ?{$_.LastWriteTime -gt (Get-Date).AddDays(-5)} | Select @{Name='File';Expression={("$($Item.Path)" + "\$($_.Name)")}})
    Foreach ($F in $Thefile)
    {
    Write-Host "Working with file $($F.File)" -ForegroundColor DarkYellow
    $Data += (Filter-Data $F.File)
    }
}
$Data | Select * -Unique | Export-Csv .\Report.csv
$Data |Group-Object -Property "client-software-version" | Select @{Name='Version';Expression={$_.Name}},Count |Export-Csv .\breakdown.csv

