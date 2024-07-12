import winim

type
    SYSTEM_FIRMWARE_TABLE_ACTION* = enum
     SystemFirmwareTable_Enumerate
     SystemFirmwareTable_Get

    SYSTEM_FIRMWARE_TABLE_INFORMATION* = object
     ProviderSignature: ULONG
     Action: SYSTEM_FIRMWARE_TABLE_ACTION
     TableID: ULONG
     TableBufferLength: ULONG
     TableBuffer: PUCHAR

    PSYSTEM_FIRMWARE_TABLE_INFORMATION* = ptr SYSTEM_FIRMWARE_TABLE_INFORMATION
     

proc GetSmbiosTable*(): PSYSTEM_FIRMWARE_TABLE_INFORMATION =

    var bufferSize: ULONG = 65536

    var firmwareTableInfo: PSYSTEM_FIRMWARE_TABLE_INFORMATION = cast[PSYSTEM_FIRMWARE_TABLE_INFORMATION](HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, cast[SIZE_T](bufferSize)))

    firmwareTableInfo.Action = SystemFirmwareTable_Get
    firmwareTableInfo.ProviderSignature = cast[ULONG](1381190978) # 'RSMB'
    firmwareTableInfo.TableBufferLength = bufferSize

    NtQuerySystemInformation(cast[SYSTEM_INFORMATION_CLASS](0x4c), firmwareTableInfo, bufferSize, &bufferSize)

    return firmwareTableInfo