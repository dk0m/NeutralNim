# Thanks To: https://www.codereversing.com/archives/598

import ../../General/PeImageParsing/Parser, winim, ptr_math, os

proc GCPIDHook(): DWORD =
    return 1337


proc allocateJmpNearModule(moduleAddress: PVOID, payloadSize: SIZE_T): PVOID =

    var modInfo: MODULEINFO

    GetModuleInformation(GetCurrentProcess(), cast[HMODULE](moduleAddress), &modInfo, cast[DWORD](sizeof(MODULEINFO)))

    var allocAddress: PVOID = cast[PVOID](cast[DWORD_PTR](modInfo.lpBaseOfDll + modInfo.SizeOfImage))
    var allocatedAddress: PVOID = NULL
    var allocAlign: SIZE_T = 0x10000

    while allocatedAddress == NULL:
        allocatedAddress = VirtualAlloc(allocAddress, payloadSize, MEM_RESERVE or MEM_COMMIT, PAGE_EXECUTE_READWRITE)
        allocAddress = cast[PVOID](cast[DWORD_PTR](allocAddress) + allocAlign)

    return allocatedAddress


proc HookFuncFromEat*(dll: string, targetFnName: string, hookFunc: PVOID, orgFunc: PVOID) =

    # x64 mov rax jmp rax byte array, only works on x64 platforms.
    var jmpByteArray: array[12, byte] = [byte 0x48, 0xB8, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xE0]
    

    var currentPeBase = cast[PVOID](GetModuleHandleA(NULL))

    var peImage = parsePe(cast[PVOID](GetModuleHandleA(dll)))

    var peBase = peImage.ImageBase
    var expDir = peImage.Directories.ExportDirectory

    var funcNames = cast[PDWORD](peBase + expDir.AddressOfNames)
    var funcOrds = cast[PWORD](peBase + expDir.AddressOfNameOrdinals)
    var funcAddrs = cast[PDWORD](peBase + expDir.AddressOfFunctions)

    for i in 0 ..< expDir.NumberOfNames:

        var fnName: LPCSTR = cast[LPCSTR](peBase + funcNames[i])
        var fnOrdinal: WORD = cast[WORD](funcOrds[i])

        var fnRva: DWORD = funcAddrs[DWORD(fnOrdinal)]
        var fnAddr: PVOID = cast[PVOID](peBase + fnRva)

       

        if $fnName == targetFnName:

            # writing original address to our original function

            WriteProcessMemory(
            GetCurrentProcess(),
            orgFunc,
            &fnAddr,
            cast[SIZE_T](sizeof(PVOID)),
            NULL
            )

            var hkfn = hookFunc
            var jmpAddr = allocateJmpNearModule(cast[PVOID](peBase), cast[SIZE_T](sizeof(jmpByteArray)))

            # preparing the byte array

            copyMem(&jmpByteArray[2], &hkFn ,sizeof(PVOID))
            
            copyMem(jmpAddr, &jmpByteArray[0], sizeof(jmpByteArray))
            
            # calculating our new RVA

            var hookFnRva = cast[DWORD](jmpAddr - cast[DWORD](GetModuleHandleA(dll)))

            var rvaAddr = addr(funcAddrs[DWORD(fnOrdinal)]) # legitimate address

            var oldpro: DWORD
            VirtualProtect(cast[PVOID](rvaAddr), cast[SIZE_T](sizeof(DWORD)), PAGE_READWRITE, &oldpro)

            # writing the new rva to the legitimate function rva

            WriteProcessMemory(
                GetCurrentProcess(),
                cast[PVOID](rvaAddr),
                &hookFnRva,
                cast[SIZE_T](sizeof(DWORD)),
                NULL
            )

            VirtualProtect(cast[PVOID](rvaAddr), cast[SIZE_T](sizeof(DWORD)), oldpro, &oldpro)



# Example Of Usage #

when isMainModule:
    type
     typeGCPID* = proc (): DWORD {.stdcall.}

    var orgGetCurrProcId: typeGCPID

    HookFuncFromEat("kernel32","GetCurrentProcessId", cast[PVOID](GCPIDHook), cast[PVOID](&orgGetCurrProcId))

    var getCurrProcId = cast[typeGCPID](GetProcAddress(GetModuleHandleA("kernel32"), "GetCurrentProcessId"))

    echo("(HOOKED) Current Process Id: " & $getCurrProcId()) # Hooked
    echo("(NOT HOOKED) Current Process Id: " & $orgGetCurrProcId()) # Not Hooked
