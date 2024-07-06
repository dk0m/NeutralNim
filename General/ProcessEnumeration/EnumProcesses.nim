import winim

proc toString(chars: openArray[CHAR]): string =
    for c in chars:
        if c == '\0':
            break
        result.add((c))


proc GetProcessIdFromName*(name: LPCSTR): DWORD =

    var processIds: array[1024, DWORD]
    var bytesNeeded: DWORD

    EnumProcesses(&processIds[0], cast[DWORD](sizeof(processIds)), &bytesNeeded)

    var amountOfIds = int(bytesNeeded / sizeof(DWORD))

    for i in 0..amountOfIds:
        var currentId = processIds[i]
        var hProcess = OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, currentId)

        var mainModule: HMODULE
        var neededSize: DWORD

        var processName: array[MAX_PATH, CHAR]

        if (EnumProcessModules(hProcess, &mainModule, cast[DWORD](sizeof(mainModule)), &neededSize)):
            GetModuleBaseNameA(hProcess, mainModule, &processName[0], MAX_PATH)

            var procName = processName.toString()

            if lstrcmpA(procName, name) == 0:
                return currentId


# Example Of Usage #

#[

var explorerId = GetProcessIdFromName("explorer.exe")
echo("Explorer Process Id: " , $explorerId)

]#


