import winim, ptr_math

type
    SYSTEM_HANDLE_TABLE_ENTRY_INFO* = object
     UniqueProcessId: USHORT
     CreatorBackTraceIndex: USHORT
     ObjectTypeIndex: UCHAR
     HandleValue: USHORT
     Object: PVOID
     GrantedAccess: ULONG

    PSYSTEM_HANDLE_TABLE_ENTRY_INFO* = ptr SYSTEM_HANDLE_TABLE_ENTRY_INFO

    SYSTEM_HANDLE_INFORMATION* = object
     NumberOfHandles: ULONG
     Handles: array[1, SYSTEM_HANDLE_TABLE_ENTRY_INFO]

    PSYSTEM_HANDLE_INFORMATION* = ptr SYSTEM_HANDLE_INFORMATION


proc `{}`[T](flexableArray: array[1, T], index: int): T =
    var pEntry = cast[ptr T](addr(flexableArray) + index)
    return cast[T](pEntry[])


proc EnumerateSysHandles*(): PSYSTEM_HANDLE_INFORMATION =
    var handleInfoSize: ULONG = 0
    var qInfoStatus: NTSTATUS = STATUS_INFO_LENGTH_MISMATCH

    var sysHandleInfo: PVOID

    while qInfoStatus == STATUS_INFO_LENGTH_MISMATCH:
        qInfoStatus = NtQuerySystemInformation(systemHandleInformation, sysHandleInfo, handleInfoSize, &handleInfoSize)
        sysHandleInfo = realloc(sysHandleInfo, handleInfoSize)
        
    return cast[PSYSTEM_HANDLE_INFORMATION](sysHandleInfo)


# Example Of Usage #

when isMainModule:
    var handleInfo = EnumerateSysHandles()
    
    var handles = handleInfo.Handles
    var countHandles = handleInfo.NumberOfHandles

    for i in 0..countHandles:

        var currHandleEntry = handleInfo.Handles{i}
        
        var typeIndex = currHandleEntry.ObjectTypeIndex
        var ownerProcId = cast[DWORD](currHandleEntry.UniqueProcessId)

        echo("Owner Process Id: " & $ownerProcId & " Handle Type: " & $typeIndex)

    