function Add-LitigationHold {
    param
    (

        [Parameter(Mandatory)]
        [string] $LogFile,

        [Parameter(Mandatory)]
        [string] $LogFilePath,
        
        [Parameter(Mandatory)]
        [string] $ArchiveLogPath,

        [Parameter(Mandatory)]
        [string] $Owner

    )

    $CurrentErrorActionPref = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    $Time = Get-Date -Format "yyyy-MM-dd-HH:mm"

    Write-Log -Log $Log -AddToLog ("Script executed at {0} " -f $Time)
    Start-Transcript -Path ("{0}\Transcript\Transcript_{1:yyyyMMddhhmm}.log" -f $LogFilePath, $Time)

    $LogFilePath = $LogFilePath.Trim('\')
    $ErrorLogFile = ('Error_{0}') -f $LogFile
    
    $Log = Join-Path $LogFilePath $LogFile
    $ErrorLog = Join-Path $LogFilePath $ErrorLogFile

    $User = Get-Content -Path "{0}\SS\User.txt" -f $LogFilePath
    $Pass = Get-Content -Path "{0}\SS\Pass.txt" -f $LogFilePath | ConvertTo-SecureString
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass

    $Connect = @{
        Name              = "LitScript"
        ConfigurationName = "Microsoft.Exchange"
        ConnectionUri     = "https://outlook.office365.com/powershell"
        Credential        = $Cred
        Authentication    = "Basic"
        AllowRedirection  = "True"
    }

    $EXOSession = New-PSSession @Connect
    Import-Module (Import-PSSession $EXOSession -AllowClobber -WarningAction SilentlyContinue) -Global | Out-Null

    #####
    # Search for Litigation Hold Enable Get-Mailbox -RecipientTypeDetails  -Filter {LitigationHoldEnabled -ne $true -and MailboxPlan -ne $null}
    #####

    Write-Log -Log $Log -AddToLog "Searching for licensed mailboxes with Litigation Hold Enabled"

    $LitSplat = @{
        Filter               = "LitigationHoldEnabled -eq '$true'"
        ResultSize           = "Unlimited"
        RecipientTypeDetails = "UserMailbox, SharedMailbox, RoomMailbox, EquipmentMailbox"
    }
    $LitSoftSplat = @{
        Filter               = "LitigationHoldEnabled -eq '$true'"
        ResultSize           = "Unlimited"
        RecipientTypeDetails = "UserMailbox, SharedMailbox, RoomMailbox, EquipmentMailbox"
        SoftDeletedMailbox   = $true
    }

    try {
        $Lit = Get-Mailbox @LitSplat
        $LitCount = $Lit.Guid.Count
        Write-Log -Log $Log -AddToLog ("`tFound {0} Litigation Hold Enabled Mailboxes" -f $LitCount)
    }
    catch {
        Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
        Write-Log -Log $ErrorLog -AddToLog 'Error executing this line of code: $Lit = Get-Mailbox @LitSplat'
        Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
        Write-Log -Log $ErrorLog -AddToLog $_.Exception.Message
    }

    try {
        $LitSoft = Get-Mailbox @LitSoftSplat
        $LitSoftCount = $LitSoft.Guid.Count
        Write-Log -Log $Log -AddToLog ("`tFound {0} Litigation Hold Enabled Soft Deleted" -f $LitSoftCount)
    }
    catch {
        Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
        Write-Log -Log $ErrorLog -AddToLog 'Error executing this line of code: $LitSoft = Get-Mailbox @LitSoftSplat'
        Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
        Write-Log -Log $ErrorLog -AddToLog $_.Exception.Message
    }
        
    $AllLitCount = $LitCount + $LitSoftCount    
    Write-Log -Log $Log -AddToLog ("`tFound {0} Litigation Hold Enabled Total" -f $AllLitCount)
    
    #####
    # Search for Litigation Hold Disabled
    #####
    
    $NoLitSplat = @{
        Filter               = "LitigationHoldEnabled -ne '$true'"
        ResultSize           = "Unlimited"
        RecipientTypeDetails = "UserMailbox, SharedMailbox, RoomMailbox, EquipmentMailbox"
    }
    $NoLitSoftSplat = @{
        Filter               = "LitigationHoldEnabled -ne '$true'"
        ResultSize           = "Unlimited"
        RecipientTypeDetails = "UserMailbox, SharedMailbox, RoomMailbox, EquipmentMailbox"
        SoftDeletedMailbox   = $true
    }

    try {
        $NoLit = Get-Mailbox @NoLitSplat
        $NoLitCount = $NoLit.Guid.Count
        Write-Log -Log $Log -AddToLog ("`tFound {0} Litigation Hold Disabled Mailboxes" -f $NoLitCount)
    }
    catch {
        Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
        Write-Log -Log $ErrorLog -AddToLog 'Error executing this line of code: $NoLit = Get-Mailbox @NoLitSplat'
        Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
        Write-Log -Log $ErrorLog -AddToLog $_.Exception.Message
    }

    try {
        $NoLitSoft = Get-Mailbox @NoLitSoftSplat
        $NoLitSoftCount = $NoLitSoft.Guid.Count
        Write-Log -Log $Log -AddToLog ("`tFound {0} Litigation Hold Disabled Soft Deleted" -f $NoLitSoftCount)
    }
    catch {
        Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
        Write-Log -Log $ErrorLog -AddToLog 'Error executing this line of code: $NoLitSoft = Get-Mailbox @NoLitSoftSplat'
        Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
        Write-Log -Log $ErrorLog -AddToLog $_.Exception.Message
    }

    $AllNoLitCount = $NoLitCount + $NoLitSoftCount
    Write-Log -Log $Log -AddToLog ("`tFound {0} Litigation Hold Disabled Total" -f $AllNoLitCount)

    $AllCount = $AllNoLitCount + $AllLitCount
    Write-Log -Log $Log -AddToLog ("`tFound {0} Mailboxes Total" -f $AllCount)


    ##########################################
    # Setting Litigation Hold where Disabled #
    ##########################################

    $SetLit = @{
        LitigationHoldEnabled  = $True
        LitigationHoldDuration = "Unlimited"
        LitigationHoldOwner    = $Owner
        Identity               = ""
    }
    $SetLitSoft = @{
        LitigationHoldEnabled  = $True
        LitigationHoldDuration = "Unlimited"
        InactiveMailbox        = $True
    }

    $NoLitSoftMailbox = Get-Mailbox @NoLitSoftSplat

    Foreach ($CurNoLit in $NoLit) {
        try {

            $SetLit.Identity = $CurNoLit.Identity
            Set-Mailbox @SetLit

        }
        catch {

            Write-Log

        }
    }
    Foreach ($CurNoLitSoft in $NoLitSoftMailbox) {
        try {
            $Filter = ('GUID -eq "{0}"') -f $CurNoLitSoft.GUID
            Get-Mailbox -Filter $Filter -SoftDeletedMailbox | 
                Set-Mailbox @SetLitSoft -InactiveMailbox
        }
        catch {
            
        }
    }

    Move-Item -Path $Log -Destination ("{0}\Archive\{1:yyyyMMddhhmm}.log" -f $LogFilePath, $Time)
    Move-Item -Path $ErrorLog -Destination ("{0}\Archive\Error_{1:yyyyMMddhhmm}.log" -f $LogFilePath, $Time)
    
    Get-PSSession | Remove-PSSession
    
    $ErrorActionPreference = $CurrentErrorActionPref

}

Function Write-Log {
    param
    (

        [Parameter()]
        [string] $Log,

        [Parameter()]
        [string] $AddToLog

    )

    Add-Content -Path $Log -Value $AddToLog
}