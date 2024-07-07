import winim, ptr_math

proc GetCurrentModuleInfo*(): MODULEINFO =
    var modInfo: MODULEINFO
    GetModuleInformation(GetCurrentProcess(), GetModuleHandleA(NULL), &modInfo, cast[DWORD](sizeof(modInfo)))
    return modInfo


proc CheckForBpsInCurrentModule*(): bool =
    var currModInfo = GetCurrentModuleInfo()
    var modBase = cast[DWORD_PTR](currModInfo.lpBaseOfDll)
    var modSize = currModInfo.SizeOfImage

    var foundInt3 = false

    for i in 0..modSize:
        var readByte = cast[PBYTE](modBase + i)[]

        if readByte == 0xCC:
            foundInt3 = true
            break

    return foundInt3

# This Most Of The Time Raises False Positives, So Be Aware.

if CheckForBpsInCurrentModule():
    echo("Int3s Were Found In Current Module")
else:
    echo("Int3s Were Not Found In Current Module")