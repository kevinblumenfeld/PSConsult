function Set-LitigationHold {
    param
    (

        [Parameter()]
        [string] $LogFile = "LitLog.txt",

        [Parameter()]
        [string] $LogFilePath = "C:\Scripts\lit",

        [Parameter()]
        [string] $ArchiveLogPath = "C:\Scripts\lit\Archive",

        [Parameter()]
        [string] $Owner = "admin@contoso.onmicrosoft.com"

    )

    $CurrentErrorActionPref = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    $Time = Get-Date -Format "yyyy-MM-dd-HHmm"

    $LogFilePath = $LogFilePath.Trim('\')
    $ErrorLogFile = ('Error_{0}') -f $LogFile

    $Log = Join-Path $LogFilePath $LogFile
    $ErrorLog = Join-Path $LogFilePath $ErrorLogFile

    Write-Log -Log $Log -AddToLog ("Script executed at {0} " -f $Time)
    Start-Transcript -Path ("{0}\Transcript\Transcript_{1:yyyyMMddhhmm}.log" -f $LogFilePath, $Time)

    $User = Get-Content -Path ("{0}\SS\User.txt" -f $LogFilePath)
    $Pass = Get-Content -Path ("{0}\SS\Pass.txt" -f $LogFilePath) | ConvertTo-SecureString
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass

    $Connect = @{
        Name              = "LitScript"
        ConfigurationName = "Microsoft.Exchange"
        ConnectionUri     = "https://outlook.office365.com/powershell"
        Credential        = $Cred
        Authentication    = "Basic"
        AllowRedirection  = $True
    }

    $EXOSession = New-PSSession @Connect
    Import-Module (Import-PSSession $EXOSession -AllowClobber -WarningAction SilentlyContinue) -Global | Out-Null

    Write-Log -Log $Log -AddToLog '=========================================================================================='
    Write-Log -Log $Log -AddToLog "Searching for licensed mailboxes (UserMailbox, SharedMailbox, RoomMailbox & EquipmentMailbox)"

    $HardSplat = @{
        Filter               = 'MailboxPlan -ne $null'
        ResultSize           = "Unlimited"
        RecipientTypeDetails = 'UserMailbox', 'SharedMailbox', 'RoomMailbox', 'EquipmentMailbox'
    }
    $SoftSplat = @{
        Filter               = 'MailboxPlan -ne $null'
        ResultSize           = "Unlimited"
        RecipientTypeDetails = 'UserMailbox', 'SharedMailbox', 'RoomMailbox', 'EquipmentMailbox'
        SoftDeletedMailbox   = $true
    }

    try {
        $Hard = Get-Mailbox @HardSplat
    }
    catch {
        Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
        Write-Log -Log $ErrorLog -AddToLog 'Error executing this line of code: $Hard = Get-Mailbox @HardSplat  (Full Error Below)'
        Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
        Write-Log -Log $ErrorLog -AddToLog $_.Exception.Message
    }

    try {
        $Soft = Get-Mailbox @SoftSplat
    }

    catch {
        Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
        Write-Log -Log $ErrorLog -AddToLog 'Error executing this line of code: $Soft = Get-Mailbox @SoftSplat  (Full Error Below)'
        Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
        Write-Log -Log $ErrorLog -AddToLog $_.Exception.Message
    }

    $All = $Hard + $Soft

    Write-Log -Log $Log -AddToLog ("`tFound {0} Mailboxes - Total" -f $All.Count)
    Write-Log -Log $Log -AddToLog ("`tFound {0} Mailboxes - (not soft-deleted)" -f $Hard.Count)
    Write-Log -Log $Log -AddToLog ("`tFound {0} Mailboxes - (soft-deleted)" -f $Soft.Count)
    Write-Log -Log $Log -AddToLog '=========================================================================================='

    Write-Log -Log $Log -AddToLog "Report: Litigation Hold"
    Write-Log -Log $Log -AddToLog ("`tFound {0} litigation hold enabled" -f ($All.LitigationHoldEnabled -eq $true).count)
    Write-Log -Log $Log -AddToLog ("`tFound {0} litigation hold disabled" -f ($All.LitigationHoldEnabled -eq $false).count)
    Write-Log -Log $Log -AddToLog ("`tFound {0} litigation hold duration is not set to unlimited" -f ($All.LitigationHoldDuration -ne "Unlimited").count)
    Write-Log -Log $Log -AddToLog '=========================================================================================='

    $SetHard = $Hard | Where-Object {
        $_.LitigationHoldEnabled -eq $false -or
        $_.LitigationHoldDuration -ne "Unlimited"
    }

    $SetSoft = $Soft | Where-Object {
        $_.LitigationHoldEnabled -eq $false -or
        $_.LitigationHoldDuration -ne "Unlimited"
    }

    $SetHardSplat = @{
        LitigationHoldEnabled  = $True
        LitigationHoldDuration = "Unlimited"
        LitigationHoldOwner    = $Owner
    }

    $SetSoftSplat = @{
        LitigationHoldEnabled  = $True
        LitigationHoldDuration = "Unlimited"
        InactiveMailbox        = $True
    }

    foreach ($CurHard in $SetHard) {
        try {
            $HardMail = $CurHard.PrimarySmtpAddress
            $HardGuid = $CurHard | Select-Object -ExpandProperty guid
            Set-Mailbox @SetHardSplat -Identity $HardGuid
            Write-Log -Log $Log -AddToLog ("`tSuccessfully applied litigation hold to Mailbox {0}" -f $HardMail)
        }
        catch {
            Write-Log -Log $Log -AddToLog ("`tFAILED to apply litigation hold to Mailbox {0}" -f $HardMail)
            Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
            Write-Log -Log $ErrorLog -AddToLog ("`tFAILED to apply litigation hold to Mailbox {0}" -f $HardMail)
            Write-Log -Log $ErrorLog -AddToLog 'Error executing this line of code: $CurHard | Set-Mailbox @SetHardSplat (Full Error Below)'
            Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
            Write-Log -Log $ErrorLog -AddToLog $_.Exception.Message
        }
    }

    foreach ($CurSoft in $SetSoft) {
        try {
            $SoftMail = $CurSoft.PrimarySmtpAddress
            $SoftGuid = $CurSoft | Select-Object -ExpandProperty guid
            Set-Mailbox @SetSoftSplat -Identity $SoftGuid
            Write-Log -Log $Log -AddToLog ("`tSuccessfully applied litigation hold to Mailbox {0}" -f $SoftMail)
        }
        catch {
            Write-Log -Log $Log -AddToLog ("`tFAILED to apply litigation hold to Mailbox {0}" -f $SoftMail)
            Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
            Write-Log -Log $ErrorLog -AddToLog ("`tFAILED to apply litigation hold to Mailbox {0}" -f $SoftMail)
            Write-Log -Log $ErrorLog -AddToLog 'Error executing this line of code: Set-Mailbox @SetSoftSplat (Full Error Below)'
            Write-Log -Log $ErrorLog -AddToLog '=========================================================================================='
            Write-Log -Log $ErrorLog -AddToLog $_.Exception.Message
        }
    }

    Write-Log -Log $Log -AddToLog '=========================================================================================='

    $HardSplat.Filter = 'MailboxPlan -ne $null -and LitigationHoldEnabled -eq $true'
    $SoftSplat.Filter = 'MailboxPlan -ne $null -and LitigationHoldEnabled -eq $true'
    $HardCheck = Get-Mailbox @HardSplat
    $SoftCheck = Get-Mailbox @SoftSplat
    $AllCheckLit = $HardCheck + $SoftCheck
    $AllCheckDur = $AllCheckLit | Where-Object {$_.LitigationHoldDuration -eq "Unlimited"}

    Write-Log -Log $Log -AddToLog ('{0} mailboxes with litigation hold enabled' -f $AllCheckLit.count)
    Write-Log -Log $Log -AddToLog ('{0} mailboxes with litigation hold enabled and litigation hold duration is unlimited' -f $AllCheckDur.count)

    $AllCheckMail = $AllCheckLit.PrimarySmtpAddress | Sort-Object

    foreach ($CurCheck in $AllCheckMail) {
        Write-Log -Log $Log -AddToLog ("`t{0}" -f $CurCheck)
    }

    Move-Item -Path $Log -Destination ("{0}\Archive\{1:yyyyMMddhhmm}.log" -f $LogFilePath, $Time)
    Move-Item -Path $ErrorLog -Destination ("{0}\Archive\Error_{1:yyyyMMddhhmm}.log" -f $LogFilePath, $Time) -ErrorAction SilentlyContinue

    Get-PSSession | Remove-PSSession

    $ErrorActionPreference = $CurrentErrorActionPref
}
