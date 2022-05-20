$LogPath   = [Environment]::GetFolderPath("Desktop") + "\KioskLogs"
$IsProcMon = $FALSE

$AssignedAccessProviders = @(

    '{355d4f62-3d5b-5372-213f-6d9d804c75df}' # Microsoft.Windows.AssignedAccess.MdmAlert
    '{94097d3d-2a5a-5b8a-cdbd-194dd2e51a00}' # Microsoft.Windows.AssignedAccess
    '{8530DB6E-51C0-43D6-9D02-A8C2088526CD}' # Microsoft-Windows-AssignedAccess
    '{F2311B48-32BE-4902-A22A-7240371DBB2C}' # Microsoft-Windows-AssignedAccessBroker

)

if ($args)
{

    if ($args[0].ToString().ToLower() -eq "-procmon")
    {

        $IsProcMon = $TRUE

    }
    else
    {

        Write-Host "`nInvalid Parameter: " $args[0] -ForegroundColor Red
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

        Write-Host "`nFound existing folder" $LogPath -ForegroundColor DarkCyan

    }

}


Function DownloadProcMon
{

    $URL = "https://download.sysinternals.com/files/ProcessMonitor.zip"
    Invoke-WebRequest -Uri $URL -OutFile ($LogPath + "\ProcessMonitor.zip")
    Expand-Archive -Path ($LogPath + "\ProcessMonitor.zip") -DestinationPath $LogPath
    
}


Function StartProcMon
{

    $BackingFile = $LogPath + "\kiosklog.pml"
    start-process -filepath ($LogPath + "\procmon.exe") -argumentlist "/accepteula /quiet /minimized /backingfile `"$BackingFile`"" -Passthru | Out-Null

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

}

Function StopDataCollectorSet
{
    
    logman -stop "AssignedAccess" -ets | Out-Null

}


Function Main
{

    CreateLogFolder
    if ($IsProcMon)
    {
        Write-Host "`nDownloading and starting ProcMon" -ForegroundColor Cyan
        DownloadProcMon
        StartProcMon 
        Write-Host "`nProcMon started" -ForegroundColor DarkCyan

    }
    StartDataCollectorSet
    Write-Host "`nTrace started" -ForegroundColor Green

    Read-Host ("`nReproduce the problem then press Enter to stop the trace")
    StopDataCollectorSet
    if ($IsProcMon)
    {

        StopProcMon

    }

    Write-Host "Logs saved at" $LogPath -ForegroundColor Green

}


Main
