$LogPath   = [Environment]::GetFolderPath("Desktop") + "\KioskLogs"


ForEach ($arg in $args)
{

    if ($arg -match "procmon")
    {

        $IsProcMon = $TRUE

    }
    elseif ($arg -match "eventlog")
    {

        $IsEventLog = $TRUE

    }

}


$AssignedAccessProviders = @(

    '{355d4f62-3d5b-5372-213f-6d9d804c75df}' # Microsoft.Windows.AssignedAccess.MdmAlert
    '{94097d3d-2a5a-5b8a-cdbd-194dd2e51a00}' # Microsoft.Windows.AssignedAccess
    '{8530DB6E-51C0-43D6-9D02-A8C2088526CD}' # Microsoft-Windows-AssignedAccess
    '{F2311B48-32BE-4902-A22A-7240371DBB2C}' # Microsoft-Windows-AssignedAccessBroker

)


$RegistryKeys = @{

    "HKLM:SOFTWARE\Microsoft\Windows\AssignedAccessConfiguration"                                       = "AssignedAccessConfiguration";
    "HKLM:SOFTWARE\Microsoft\Windows\AssignedAccessCsp"                                                 = "AssignedAccessCsp";
    "HKLM:SOFTWARE\Microsoft\Windows Embedded\Shell Launcher"                                           = "ShellLauncher";
    "HKLM:SOFTWARE\Microsoft\Provisioning\Diagnostics\ConfigManager\AssignedAccess"                     = "AssignedAccessDiag";
    "HKLM:SOFTWARE\Microsoft\Windows\EnterpriseResourceManager\AllowedNodePaths\CSP\AssignedAccess"     = "AssignedAccessCSPNodePaths";
    "HKLM:SYSTEM\CurrentControlSet\Services\AssignedAccessManagerSvc"                                   = "AssignedAccessManagerSvc"

}


Function ElevationCheck
{

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        
    if (-Not($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)))
    {
        
        Write-Host "Please run the script as Administrator" -ForegroundColor Red
        break

    }

}     


Function CreateLogFolder
{

    if (-Not(Test-Path $LogPath))
    {
    
        New-Item -Path ([Environment]::GetFolderPath("Desktop")) -Name "KioskLogs" -ItemType "Directory" | Out-Null
        Write-Host "`nCreated folder " $LogPath -ForegroundColor DarkCyan

    }
    else
    {

        Write-Host "`nFound existing folder `"$LogPath`". Clearing contents." -ForegroundColor DarkCyan
        Remove-Item ($LogPath + "\*") -Recurse

    }

}


Function DownloadProcMon
{

    $URL = "https://download.sysinternals.com/files/ProcessMonitor.zip"
    Write-Host "`nDownloading and starting ProcMon" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $URL -OutFile ($LogPath + "\ProcessMonitor.zip")
    Expand-Archive -Path ($LogPath + "\ProcessMonitor.zip") -DestinationPath $LogPath
    
}


Function StartProcMon
{

    $BackingFile = $LogPath + "\kiosklog.pml"
    start-process -filepath ($LogPath + "\procmon.exe") -argumentlist "/accepteula /quiet /minimized /backingfile `"$BackingFile`"" -Passthru | Out-Null
    Write-Host "`nProcMon started" -ForegroundColor DarkCyan

}


Function StopProcMon
{

    start-process -filepath ($LogPath + "\procmon.exe") -argumentlist '/terminate' -wait | Out-Null

    Remove-Item -Path ($LogPath + "\eula.txt")  
    Remove-Item -Path ($LogPath + "\procmon.exe")    
    Remove-Item -Path ($LogPath + "\procmon64.exe")
    Remove-Item -Path ($LogPath + "\procmon64a.exe")
    Remove-Item -Path ($LogPath + "\procmon.chm")
    Remove-Item -Path ($LogPath + "\ProcessMonitor.zip")

}


Function StartDataCollectorSet
{

    $TraceName = "AssignedAccess"
    logman create trace $TraceName -ow -o ($LogPath + "\" + $TraceName + ".etl") -mode Circular -bs 64 -f bincirc -max 2048 -ft 60 -ets | Out-Null

    ForEach ($Provider in $AssignedAccessProviders)
    {

        logman update trace $TraceName -p "$Provider" 0xffffffffffffffff 0xff -ets | Out-Null

    }

     Write-Host "`nTrace started" -ForegroundColor Green

}


Function StopDataCollectorSet
{
    
    logman -stop "AssignedAccess" -ets | Out-Null

}


Function GetSingleAppKioskConfiguration
{

    $SingleApp = Get-AssignedAccess

    if ($SingleApp)
    {

        $configuration = "Single App Kiosk Configuration found for user " + $SingleApp.UserName + "`n`nUserSID = " + $SingleApp.UserSID + "`nApp: " + $SingleApp.AppName + "`nAUMID: " + $SingleApp.AppUserModelId
        $configuration >> ($LogPath + "\SingleApp.txt")

    }
    else
    {

        "No Single App Configuration found" >> ($LogPath + "\SingleApp.txt")

    }

}


Function GetRegistryKeys
{

    ForEach ($Key in $RegistryKeys.Keys)
    {
        
        if (Test-Path $Key)
        {

            Get-ItemProperty -Path $Key >> ($LogPath + "\REG_" + $RegistryKeys.$Key + ".txt")
            Get-ChildItem -Path $Key -Recurse >> ($LogPath + "\REG_" + $RegistryKeys.$Key + ".txt")
            
        }
        else
        {

            "Key doesn't exist" >> ($LogPath + "\REG_" + $RegistryKeys.$Key + ".txt")

        }

    }

}


Function GetEventLogs
{

    $EventLogPath = $env:SystemRoot + "\System32\winevt\Logs"
    Copy-Item $EventLogPath -Destination $LogPath -Recurse

}


Function Main
{

    ElevationCheck
    CreateLogFolder

    if ($IsProcMon)
    {
        
        DownloadProcMon
        StartProcMon         

    }

    StartDataCollectorSet
   
    Write-Host -NoNewLine "`nReproduce the problem then press Enter to stop the trace" -ForegroundColor Yellow
    Read-Host
     
    StopDataCollectorSet

    if ($IsProcMon)  { StopProcMon }
    if ($IsEventLog) { GetEventLogs }

    GetSingleAppKioskConfiguration
    GetRegistryKeys
    Get-AppxPackage -AllUsers >> ($LogPath + "\AppxAllUsers.txt")

    Write-Host "Logs saved at" $LogPath -ForegroundColor Green

}


Main