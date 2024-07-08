import winim, cligen, ./Debugger/Debug, ./Debugger/Process

proc MainDbg(processName: string, args: seq[string]) =
    var procId = DWORD(GetProcessIdFromName(processName))

    if AttachToDebugger(DWORD(GetProcessIdFromName(processName))):
        echo("[+] Attached To Debugger Successfully!")
        MainDebuggingLoop()



dispatch MainDbg