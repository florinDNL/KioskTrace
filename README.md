# KioskTrace
Powershell script for collecting AssignedAccess traces (+ProcMon)

# Usage

1) Open powershell as administrator
2) Run the script
- To collect only etw provider trace and registry keys:

		.\KioskTrace.ps1  

- Available arguments: 
		
		-EventLogs  | Collects all event logs in addition to etw traces and registry keys
		-ProcMon    | Starts a ProcMon trace in addition to etw traces and registry keys [ProcMon will be automatically downloaded, started and removed upon completion]
		
- These can be used independently or combined
		
		.\KioskTrace.ps1 -EventLogs
		.\KioskTrace.ps1 -ProcMon	

- To collect everything:

		.\KioskTrace.ps1 -EventLogs -ProcMon
    
3) You will be prompted to reproduce the issue while the capture is ongoing. When done, press Enter in Powershell to stop the traces and save the logs to Desktop
