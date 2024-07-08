import winim

proc toString(chars: openArray[WCHAR]): string =
    for c in chars:
        if cast[char](c) == '\0':
            break
        result.add(cast[char](c))

proc GetProcessIdFromName*(name: LPCSTR): DWORD =
    var pe32: PROCESSENTRY32
    pe32.dwSize = cast[DWORD](sizeof(PROCESSENTRY32))
    let processSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)

    while Process32Next(processSnapshot, &pe32):
        var processName = pe32.szExeFile
        var processId = pe32.th32ProcessID
        
        if lstrcmpA(processName.toString(), name) == 0:
            CloseHandle(processSnapshot)
            return processId

    CloseHandle(processSnapshot)