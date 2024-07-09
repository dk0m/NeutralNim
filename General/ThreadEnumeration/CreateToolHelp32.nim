import winim, ../ProcessEnumeration/CreateToolHelp32

proc GetAllThreads*(): seq[THREADENTRY32] =
    var te32: THREADENTRY32
    te32.dwSize = cast[DWORD](sizeof(THREADENTRY32))
    let threadSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0)
    
    while Thread32Next(threadSnapshot, &te32):
        result.add(te32)


proc GetProcessThreads*(hProcess: HANDLE): seq[THREADENTRY32] =
    var targetProcId = GetProcessId(hProcess)
    var allThreads = GetAllThreads()

    for threadEntry in allThreads:
        if threadEntry.th32OwnerProcessId == targetProcId:
            result.add(threadEntry)

# Example Of Usage #

#[
var hProcess = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, GetProcessIdFromName("notepad.exe"))

var procThreads = GetProcessThreads(hProcess)

for threadEntry in procThreads:
    echo("Process Thread ID: " & $threadEntry.th32ThreadId)

]#