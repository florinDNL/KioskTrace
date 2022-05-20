# KioskTrace
Powershell script for collecting AssignedAccess traces (+ProcMon)

# Usage

1) Open powershell as administrator
2) Run the script
- To collect only etw provider trace:

		.\KioskTrace.ps1              
- To collect etw provider trace + ProcMon [ProcMon will be automatically downloaded, started and removed upon completion]:

		.\KioskTrace.ps1 -ProcMon
    
3) You will be prompted to reproduce the issue while the capture is ongoing. When done, press Enter in Powershell to stop the traces and save the logs to Desktop
