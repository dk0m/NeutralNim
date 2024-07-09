import winim
import ../ProcessEnumeration/CreateToolHelp32

proc toStringA(chars: openArray[CHAR]): string =
    for c in chars:
        if c == '\0':
            break
        result.add((c))

proc GetProcessModules*(hProcess: HANDLE): seq[HMODULE] =
    var processModules: array[1024, HMODULE]
    var neededSize: DWORD

    EnumProcessModules(hProcess, &processModules[0], cast[DWORD](sizeof(processModules)), &neededSize)

    var amountOfModules = int(neededSize / sizeof(HMODULE))
    let procModules = processModules[0 .. amountOfModules]

    return procModules

proc GetModuleInfo*(hProcess: HANDLE, targetModuleName: LPCSTR): MODULEINFO =
    let procModules = GetProcessModules(hProcess)

    for i in 0 .. sizeof(procModules):

        var currModule = procModules[i]

        var modName: array[MAX_PATH, CHAR]
        GetModuleBaseNameA(hProcess, currModule, &modName[0], MAX_PATH)

        if lstrcmpA(modName.toStringA(), targetModuleName) == 0:
            var modInfo: MODULEINFO
            GetModuleInformation(hProcess, currModule, &modInfo, cast[DWORD](sizeof(MODULEINFO)))
            return modInfo

proc GetModuleBaseAddress*(hProcess: HANDLE, targetModuleName: LPCSTR): PVOID =
    return GetModuleInfo(hProcess, targetModuleName).lpBaseOfDll

# Example Of Usage #

while isMainModule:
    var procId = GetProcessIdFromName("notepad.exe")
    var hProcess = OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, procId)
    echo GetModuleBaseAddress(hProcess, "ntdll.dll").repr()
