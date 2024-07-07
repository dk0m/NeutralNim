import winim

proc IsBeingDebuggedFromDebugPort*(): bool =
    var processDP: DWORD
    NtQueryInformationProcess(GetCurrentProcess(), processDebugPort, &processDP, cast[DWORD](sizeof(DWORD)), NULL)
    return processDP == -1

proc IsBeingDebuggedFromDebugFlags*(): bool =
    var processDF: DWORD
    NtQueryInformationProcess(GetCurrentProcess(), processDebugFlags, &processDF, cast[DWORD](sizeof(DWORD)), NULL)
    return processDF == 0

proc IsBeingDebuggedFromDebugObjectHandle*(): bool =
    var processDOH: HANDLE
    NtQueryInformationProcess(GetCurrentProcess(), processDebugObjectHandle, &processDOH, cast[DWORD](sizeof(HANDLE)), NULL)
    return processDOH != 0


if IsBeingDebuggedFromDebugPort() or IsBeingDebuggedFromDebugFlags() or IsBeingDebuggedFromDebugObjectHandle():
    echo("Process Is Being Debugged")
else:
    echo("Process Is Not Being Debugged")