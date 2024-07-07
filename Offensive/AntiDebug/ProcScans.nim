import winim

# Credit To ScyllaHide
const
  BadProcessnameList: array[30, string] = [
    "ollydbg.exe",
    "ida.exe",
    "ida64.exe",
    "idag.exe",
    "idag64.exe",
    "idaw.exe",
    "idaw64.exe",
    "idaq.exe",
    "idaq64.exe",
    "idau.exe",
    "idau64.exe",
    "scylla.exe",
    "scylla_x64.exe",
    "scylla_x86.exe",
    "protection_id.exe",
    "x64dbg.exe",
    "x32dbg.exe",
    "windbg.exe",
    "reshacker.exe",
    "ImportREC.exe",
    "IMMUNITYDEBUGGER.EXE",
    "devenv.exe",
    "Procmon.exe",
    "Procmon64.exe",
    "APIMonitor.exe",
    "apimonitor-x64.exe",
    "apimonitor-x86.exe",
    "cheatengine-i386.exe",
    "cheatengine-x86_64.exe",
    "cheatengine-x86_64-SSE4-AVX2.exe"
  ]

proc toString(chars: openArray[WCHAR]): string =
    for c in chars:
        if cast[char](c) == '\0':
            break
        result.add(cast[char](c))


proc IsProcessBL(name: string): bool =
    return BadProcessnameList.contains(name)

proc CheckForBlackListedProcesses*(): bool =
    var pe32: PROCESSENTRY32
    pe32.dwSize = cast[DWORD](sizeof(PROCESSENTRY32))
    let processSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)

    while Process32Next(processSnapshot, &pe32):
        var processName = pe32.szExeFile
        var processId = pe32.th32ProcessID
        var procName = processName.toString()
        if IsProcessBL(procName):
            echo("Detected Debugger Process '" & procName & "'")
            CloseHandle(processSnapshot)
            return true
        
    CloseHandle(processSnapshot)
    return false

if CheckForBlackListedProcesses():
    echo("Detected Debugger Processes!")
else:
    echo("Didn't Detect Debugger Processes")
