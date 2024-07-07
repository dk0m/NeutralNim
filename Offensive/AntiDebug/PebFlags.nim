import winim, ptr_math, ../../General/PebEnumeration/Local

const
    FLG_HEAP_ENABLE_TAIL_CHECK = 0x10
    FLG_HEAP_ENABLE_FREE_CHECK = 0x20
    FLG_HEAP_VALIDATE_PARAMETERS = 0x40
    NT_GLOBAL_FLAG_DEBUGGED = FLG_HEAP_ENABLE_TAIL_CHECK or FLG_HEAP_ENABLE_FREE_CHECK or FLG_HEAP_VALIDATE_PARAMETERS 

var processPeb = GetPeb()

proc PebBeingDebugged*(): bool =
    return processPeb.BeingDebugged == 1

proc NtGlobalFlag*(): bool =
    var ntGlobalFlag = cast[PDWORD](cast[PBYTE](processPeb) + 0xBC)[]
    return (ntGlobalFlag and NT_GLOBAL_FLAG_DEBUGGED)


proc IsBeingDebugged*(): bool =
    return PebBeingDebugged() or NtGlobalFlag()

if IsBeingDebugged():
    echo("Process Is Being Debugged")
else:
    echo("Process Is Not Being Debugged")
