import winim, os

type
    ApiHook* = object
     moduleName*: LPCSTR
     procedureName*: LPCSTR
     hookFunction*: PVOID
     oldProtection*: DWORD
     orgBytes*: array[12, byte]

# Note: This is only x64 api hooking, hence the mov rax jmp rax byte array. 
proc GetFuncAddr(moduleName: LPCSTR, procName: LPCSTR): PVOID =
    return PVOID(GetProcAddress(GetModuleHandleA(moduleName), procName))

proc newApiHook*(moduleName: LPCSTR, procedureName: LPCSTR, hookFunction: PVOID): ApiHook =
    var hookObj: ApiHook = ApiHook(moduleName: moduleName, procedureName: procedureName, hookFunction: hookFunction)
    return hookObj

proc enable*(hookObj: var ApiHook) = 
    var hookByteArray: array[12, byte] = [byte 0x48, 0xB8, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xE0]
    
    var funcToHook = GetFuncAddr(hookObj.moduleName, hookObj.procedureName)
    var hookFunc = hookObj.hookFunction

    copyMem(&hookByteArray[2], &hookFunc, sizeof(PVOID)) # preparing hook byte array
    copyMem(&hookObj.orgBytes[0], funcToHook, sizeof(hookByteArray)) # preparing original bytes array

    var oldProtect: DWORD

    VirtualProtect(funcToHook, DWORD(sizeof(hookByteArray)), PAGE_EXECUTE_READWRITE, &oldProtect)

    hookObj.oldProtection = oldProtect

    copyMem(funcToHook, &hookByteArray[0], sizeof(hookByteArray))


proc disable*(hookObj: var ApiHook) =
    var hookedFunc = GetFuncAddr(hookObj.moduleName, hookObj.procedureName)
    var orgBytes = hookObj.orgBytes
    copyMem(hookedFunc, &orgBytes[0], sizeof(orgBytes))
    var oldProtect: DWORD

    VirtualProtect(hookedFunc, DWORD(sizeof(orgBytes)), hookObj.oldProtection, &oldProtect)
    hookObj.oldProtection = oldProtect

proc DetourMessageBoxA(hWnd: HWND, lpText: LPCSTR, lpCaption: LPCSTR, uType: UINT): BOOL =
    echo("lpText: " & $lpText)
    echo("lpCaption: " & $lpCaption)
    return MessageBoxW(0, L"Get Hooked", "Hooked!", 0)

# Example Of Usage #

when isMainModule:
    var hook = newApiHook(
        "user32",
        "MessageBoxA",
        DetourMessageBoxA
    )

    hook.enable()

    MessageBoxA(
        0,
        "This Will Be Hooked",
        ":(",
        0
    )

    sleep 2000

    hook.disable()


    MessageBoxA(
        0,
        "This Will Run Fine!",
        ":)",
        0
    )