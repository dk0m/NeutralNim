import winim

const SystemProcessInformation = cast[SYSTEM_INFORMATION_CLASS](5)

proc NT_SUCCESS(code: NTSTATUS): BOOL =
    return code == STATUS_SUCCESS

proc GetProcessIdFromName*(name: LPCSTR): DWORD =

    var processInfoSize: ULONG = 0

    NtQuerySystemInformation(SystemProcessInformation, NULL, processInfoSize, &processInfoSize)

    var processInfo: PSYSTEM_PROCESS_INFORMATION = cast[PSYSTEM_PROCESS_INFORMATION] (HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, processInfoSize))

    if NT_SUCCESS(NtQuerySystemInformation(SystemProcessInformation, processInfo, processInfoSize, &processInfoSize)):
        while processInfo.NextEntryOffset != 0:

            processInfo = cast[PSYSTEM_PROCESS_INFORMATION](cast[DWORD_PTR](processInfo) + processInfo.NextEntryOffset)
            var nameBuffer = processInfo.ImageName.Buffer 
            var processId = cast[DWORD](processInfo.UniqueProcessId)

            if lstrcmpA($nameBuffer, name) == 0:
                return processId
        

# Example Of Usage #

when isMainModule:
    var explorerId = GetProcessIdFromName("explorer.exe")
    echo("Explorer Process Id: " , $explorerId)